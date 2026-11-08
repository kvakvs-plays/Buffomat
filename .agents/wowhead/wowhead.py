#!/usr/bin/env python3
"""Wowhead lookup tool for Buffomat maintainers.

DEPRECATED, marked for deletion: Wowhead answers this client with HTTP 403. Use
.agents/foreverdb/foreverdb.py instead.

A human maintainer runs this tool and shares the output files. AI agents must not run it:
Wowhead's robots.txt disallows Anthropic's agents (ClaudeBot, anthropic-ai, Claude-Web) for the
whole site, so network commands refuse to start inside an agent shell (CLAUDECODE or AI_AGENT set).
The offline `selftest` command is allowed everywhere.

The tool identifies itself with an honest User-Agent, obeys robots.txt for that User-Agent on every
host, waits between requests (at least 2 s), caches responses on disk and stops on 403 or repeated
429/503 answers. Read Wowhead's Terms of Use before running it.

Commands (see README.md):
  tooltip TYPE ID...   JSON from nether.wowhead.com/tooltip (needs --data-env)
  xml ID...            Item XML feed: www.wowhead.com/<flavor>/item=ID&xml
  page TYPE ID...      Item/spell/npc page; extracts Listview tables (taught by, sold by, ...)
                       and WH.Gatherer data, and reports the dataEnv the page uses
  batch FILE           Lines of "<tooltip|xml|page> <type> <id> [# note]"
  selftest             Offline tests of the parsers and the robots.txt matcher

Output (default folder .agents/wowhead/out/, see --out-dir):
  runs/<timestamp>-<command>.jsonl   raw records of one run
  wowhead-data.json                  newest record per (command, type, id) across all runs
  summary.txt                        condensed text of every record, for reading or sharing
"""
from __future__ import annotations

import argparse
import hashlib
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from typing import Any, Iterable, Optional

TOOL_VERSION = "1.0"
REPO_URL = "https://github.com/kvakvs-plays/Buffomat"
WWW = "https://www.wowhead.com"
NETHER = "https://nether.wowhead.com"
MIN_DELAY = 2.0
DEFAULT_DELAY = 3.0
DEFAULT_MAX_REQUESTS = 300
CACHE_TTL = 7 * 24 * 3600
ROBOTS_TTL = 24 * 3600
TYPES = ("spell", "item", "npc", "object", "quest", "faction", "zone")
AGENT_ENV_VARS = ("CLAUDECODE", "AI_AGENT")
HERE = os.path.dirname(os.path.abspath(__file__))


class StopRun(Exception):
    """Abort the whole run; continuing would hammer the server or bypass a block."""


# --------------------------------------------------------------------------------------------
# robots.txt


@dataclass
class RobotsGroup:
    agents: list[str] = field(default_factory=list)
    rules: list[tuple[bool, str]] = field(default_factory=list)  # (allow, pattern)
    crawl_delay: Optional[float] = None


def parse_robots(text: str) -> list[RobotsGroup]:
    """Parse robots.txt into groups. Consecutive User-agent lines share one group."""
    groups: list[RobotsGroup] = []
    current: Optional[RobotsGroup] = None
    last_was_agent = False
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].strip()
        if ":" not in line:
            continue
        key, value = (part.strip() for part in line.split(":", 1))
        key = key.lower()
        if key == "user-agent":
            if current is None or not last_was_agent:
                current = RobotsGroup()
                groups.append(current)
            current.agents.append(value.lower())
            last_was_agent = True
            continue
        last_was_agent = False
        if current is None:
            continue
        if key in ("allow", "disallow"):
            if value or key == "allow":
                current.rules.append((key == "allow", value))
        elif key == "crawl-delay":
            try:
                current.crawl_delay = float(value)
            except ValueError:
                pass
    return groups


def select_group(groups: list[RobotsGroup], user_agent: str) -> Optional[RobotsGroup]:
    """Pick the group whose User-agent token appears in our UA, else the '*' group."""
    ua = user_agent.lower()
    best: Optional[RobotsGroup] = None
    best_len = -1
    for group in groups:
        for agent in group.agents:
            if agent != "*" and agent in ua and len(agent) > best_len:
                best, best_len = group, len(agent)
    if best is not None:
        return best
    for group in groups:
        if "*" in group.agents:
            return group
    return None


def _pattern_regex(pattern: str) -> re.Pattern[str]:
    anchored = pattern.endswith("$")
    body = pattern[:-1] if anchored else pattern
    regex = "".join(".*" if ch == "*" else re.escape(ch) for ch in body)
    return re.compile(regex + ("$" if anchored else ""))


def robots_allows(group: Optional[RobotsGroup], path_and_query: str) -> bool:
    """Google semantics: longest matching pattern wins, Allow wins a tie, no match = allowed."""
    if group is None:
        return True
    best_len, allowed = -1, True
    for allow, pattern in group.rules:
        if pattern == "":
            continue
        if _pattern_regex(pattern).match(path_and_query):
            length = len(pattern)
            if length > best_len or (length == best_len and allow):
                best_len, allowed = length, allow
    return allowed


# --------------------------------------------------------------------------------------------
# HTTP client with cache, robots.txt and rate limit


class Client:
    def __init__(self, cache_dir: str, delay: float, max_requests: int, refresh: bool, contact: str):
        self.cache_dir = cache_dir
        self.delay = max(MIN_DELAY, delay)
        self.max_requests = max_requests
        self.refresh = refresh
        self.requests = 0
        self.last_request = 0.0
        self.robots: dict[str, Optional[RobotsGroup]] = {}
        contact_part = f"; {contact}" if contact else ""
        self.user_agent = f"BuffomatClassic-research/{TOOL_VERSION} (+{REPO_URL}{contact_part})"
        os.makedirs(cache_dir, exist_ok=True)

    def _cache_path(self, url: str) -> str:
        return os.path.join(self.cache_dir, hashlib.sha1(url.encode()).hexdigest() + ".json")

    def _read_cache(self, url: str, ttl: float) -> Optional[dict]:
        path = self._cache_path(url)
        if self.refresh or not os.path.exists(path):
            return None
        with open(path, encoding="utf-8") as f:
            entry = json.load(f)
        if time.time() - entry.get("fetched", 0) > ttl:
            return None
        return entry

    def _write_cache(self, url: str, status: int, body: str) -> dict:
        entry = {"url": url, "status": status, "fetched": time.time(), "body": body}
        with open(self._cache_path(url), "w", encoding="utf-8") as f:
            json.dump(entry, f)
        return entry

    def _wait(self, extra: float = 0.0) -> None:
        pause = self.last_request + self.delay + extra - time.time()
        if pause > 0:
            time.sleep(pause)

    def _http_get(self, url: str) -> tuple[int, str, dict]:
        if self.requests >= self.max_requests:
            raise StopRun(f"request limit {self.max_requests} reached; raise --max-requests to continue")
        self._wait()
        self.requests += 1
        self.last_request = time.time()
        req = urllib.request.Request(url, headers={"User-Agent": self.user_agent, "Accept": "*/*"})
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.status, resp.read().decode("utf-8", "replace"), dict(resp.headers)
        except urllib.error.HTTPError as err:
            body = err.read().decode("utf-8", "replace") if err.fp else ""
            return err.code, body, dict(err.headers or {})

    def _robots_group(self, origin: str) -> Optional[RobotsGroup]:
        if origin in self.robots:
            return self.robots[origin]
        url = origin + "/robots.txt"
        entry = self._read_cache(url, ROBOTS_TTL)
        if entry is None:
            status, body, _ = self._http_get(url)
            entry = self._write_cache(url, status, body)
        status = entry["status"]
        if 400 <= status < 500:
            group = None  # no robots.txt: everything is allowed
        elif status != 200:
            raise StopRun(f"{url} answered {status}; not crawling a host whose rules are unknown")
        else:
            group = select_group(parse_robots(entry["body"]), self.user_agent)
            if group is not None and group.crawl_delay:
                self.delay = max(self.delay, group.crawl_delay)
        self.robots[origin] = group
        return group

    def get(self, url: str) -> dict:
        """Return {"status", "body", "cached"} for a URL allowed by robots.txt."""
        parts = urllib.parse.urlsplit(url)
        origin = f"{parts.scheme}://{parts.netloc}"
        path = parts.path + (("?" + parts.query) if parts.query else "")
        if not robots_allows(self._robots_group(origin), path):
            return {"status": None, "body": "", "cached": False, "error": "disallowed by robots.txt"}
        entry = self._read_cache(url, CACHE_TTL)
        if entry is not None:
            return {"status": entry["status"], "body": entry["body"], "cached": True}
        for attempt in range(3):
            status, body, headers = self._http_get(url)
            if status in (429, 503):
                retry_after = headers.get("Retry-After", "")
                wait = min(300.0, float(retry_after)) if retry_after.isdigit() else 30.0 * (attempt + 1)
                print(f"  {status} from server, waiting {wait:.0f} s", file=sys.stderr)
                time.sleep(wait)
                continue
            if status == 403:
                raise StopRun(f"403 for {url}: the server refuses this client. Stopping; do not work around it.")
            if status == 200 or status == 404:
                self._write_cache(url, status, body)
            return {"status": status, "body": body, "cached": False}
        raise StopRun(f"server keeps answering 429/503 for {url}; stopping")


# --------------------------------------------------------------------------------------------
# Parsers


def html_to_text(fragment: str) -> str:
    """Rough tooltip HTML to plain text: <br> becomes a newline, tags are dropped."""
    text = re.sub(r"<br\s*/?>", "\n", fragment, flags=re.I)
    text = re.sub(r"</(div|tr|p|table)>", "\n", text, flags=re.I)
    text = re.sub(r"<!--.*?-->", "", text, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in text.splitlines()]
    return "\n".join(line for line in lines if line)


def match_bracket(text: str, start: int) -> int:
    """Index just past the bracket that closes text[start] ('{' or '['), skipping JS strings."""
    pairs = {"{": "}", "[": "]"}
    stack = [pairs[text[start]]]
    i, quote = start + 1, None
    while i < len(text) and stack:
        ch = text[i]
        if quote:
            if ch == "\\":
                i += 1
            elif ch == quote:
                quote = None
        elif ch in "\"'`":
            quote = ch
        elif ch in pairs:
            stack.append(pairs[ch])
        elif ch in "}]":
            if ch != stack[-1]:
                raise ValueError(f"unbalanced bracket at {i}")
            stack.pop()
        i += 1
    if stack:
        raise ValueError("unterminated bracket")
    return i


def js_literal_to_json(js: str) -> str:
    """Convert a JS object/array literal to JSON: single-quoted strings become double-quoted,
    bare keys get quoted, trailing commas are dropped. Functions and expressions stay invalid."""
    out: list[str] = []
    i, n = 0, len(js)
    while i < n:
        ch = js[i]
        if ch in "\"'":
            j, buf = i + 1, []
            while j < n and js[j] != ch:
                if js[j] == "\\" and j + 1 < n:
                    nxt = js[j + 1]
                    buf.append("'" if nxt == "'" else "\\" + nxt)
                    j += 2
                    continue
                buf.append('\\"' if js[j] == '"' else js[j])
                j += 1
            out.append('"' + "".join(buf) + '"')
            i = j + 1
        elif ch == ",":
            k = i + 1
            while k < n and js[k] in " \t\r\n":
                k += 1
            if k < n and js[k] in "}]":
                i += 1  # trailing comma
            else:
                out.append(ch)
                i += 1
        elif ch.isalpha() or ch in "_$":
            m = re.match(r"[A-Za-z_$][\w$]*", js[i:])
            word = m.group(0)
            rest = js[i + len(word):].lstrip()
            prev = "".join(out).rstrip()[-1:]
            if rest.startswith(":") and prev in ("{", ","):
                out.append('"' + word + '"')
            else:
                out.append(word)
            i += len(word)
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def loads_relaxed(js: str) -> Any:
    """Parse a JS literal that is usually JSON."""
    try:
        return json.loads(js)
    except json.JSONDecodeError:
        return json.loads(js_literal_to_json(js))


def _js_value(obj_text: str, key: str) -> Optional[str]:
    """Raw text of `key: <value>` inside a JS object literal (strings, numbers, arrays, objects)."""
    m = re.search(r'(?:^|[{,\s])["\']?' + re.escape(key) + r'["\']?\s*:\s*', obj_text)
    if not m:
        return None
    i = m.end()
    if i >= len(obj_text):
        return None
    ch = obj_text[i]
    if ch in "[{":
        return obj_text[i:match_bracket(obj_text, i)]
    if ch in "\"'":
        end = i + 1
        while end < len(obj_text) and obj_text[end] != ch:
            end += 2 if obj_text[end] == "\\" else 1
        return obj_text[i:end + 1]
    m2 = re.match(r"[^,}\n]+", obj_text[i:])
    return m2.group(0).strip() if m2 else None


def _unquote(value: Optional[str]) -> Optional[str]:
    if value and len(value) >= 2 and value[0] in "\"'" and value[-1] == value[0]:
        try:
            return json.loads('"' + value[1:-1].replace('\\"', '"').replace('"', '\\"') + '"')
        except json.JSONDecodeError:
            return value[1:-1]
    return value


def extract_listviews(page: str) -> list[dict]:
    """All `new Listview({...})` tables: id, template, name and parsed data rows."""
    out = []
    for m in re.finditer(r"new\s+Listview\s*\(\s*\{", page):
        start = m.end() - 1
        try:
            obj = page[start:match_bracket(page, start)]
        except ValueError:
            continue
        entry: dict[str, Any] = {
            "id": _unquote(_js_value(obj, "id")),
            "template": _unquote(_js_value(obj, "template")),
            "name": _unquote(_js_value(obj, "name")),
        }
        data = _js_value(obj, "data")
        if data is not None:
            try:
                entry["data"] = loads_relaxed(data)
            except (json.JSONDecodeError, ValueError):
                entry["data_raw"] = data[:4000]
        out.append(entry)
    return out


def extract_gatherer(page: str) -> list[dict]:
    """`WH.Gatherer.addData(type, dataEnv, {...})` blocks. The second number is the dataEnv."""
    out = []
    for m in re.finditer(r"WH\.Gatherer\.addData\(\s*(\d+)\s*,\s*(\d+)\s*,\s*\{", page):
        start = m.end() - 1
        try:
            obj = page[start:match_bracket(page, start)]
            data = loads_relaxed(obj)
        except (json.JSONDecodeError, ValueError):
            continue
        out.append({"type": int(m.group(1)), "dataEnv": int(m.group(2)), "data": data})
    return out


def parse_item_xml(body: str) -> dict:
    """Wowhead item XML feed to a dict. `json`/`jsonEquip` CDATA becomes parsed objects."""
    root = ET.fromstring(body)
    err = root.find("error")
    if err is not None:
        return {"error": (err.text or "").strip()}
    item = root.find("item")
    if item is None:
        return {"error": "no <item> element"}
    out: dict[str, Any] = {"id": int(item.get("id", "0"))}
    for child in item:
        text = (child.text or "").strip()
        if child.tag in ("json", "jsonEquip"):
            try:
                out[child.tag] = loads_relaxed("{" + text + "}") if text else {}
            except (json.JSONDecodeError, ValueError):
                out[child.tag + "_raw"] = text
        elif child.tag == "htmlTooltip":
            out["tooltip_text"] = html_to_text(text)
        elif child.tag == "createdBy":
            spells = []
            for spell in child.iter("spell"):
                reagents = [{"id": int(r.get("id", "0")), "count": int(r.get("count", "1"))}
                            for r in spell.iter("reagent")]
                spells.append({"id": int(spell.get("id", "0")), "name": spell.get("name"), "reagents": reagents})
            out["createdBy"] = spells
        else:
            value: Any = text
            if child.get("id") is not None:
                value = {"id": child.get("id"), "name": text}
            out[child.tag] = value
    return out


def summarize_tooltip(body: str) -> dict:
    data = json.loads(body)
    if isinstance(data, dict) and isinstance(data.get("tooltip"), str):
        data["tooltip_text"] = html_to_text(data["tooltip"])
    return data


# --------------------------------------------------------------------------------------------
# Commands


def flavor_prefix(flavor: str) -> str:
    return "" if flavor in ("", "retail") else "/" + flavor


def tooltip_url(kind: str, ident: int, data_env: int, locale: int) -> str:
    return f"{NETHER}/tooltip/{kind}/{ident}?dataEnv={data_env}&locale={locale}"


def xml_url(ident: int, flavor: str) -> str:
    return f"{WWW}{flavor_prefix(flavor)}/item={ident}&xml"


def page_url(kind: str, ident: int, flavor: str) -> str:
    return f"{WWW}{flavor_prefix(flavor)}/{kind}={ident}"


def run_one(client: Client, cmd: str, kind: str, ident: int, args: argparse.Namespace, note: str = "") -> dict:
    record: dict[str, Any] = {"cmd": cmd, "type": kind, "id": ident}
    if note:
        record["note"] = note
    if cmd == "tooltip":
        if args.data_env is None:
            raise StopRun("tooltip needs --data-env; run `page` on one Forever spell to see the value")
        url = tooltip_url(kind, ident, args.data_env, args.locale)
    elif cmd == "xml":
        if kind != "item":
            raise StopRun("the XML feed exists for items only")
        url = xml_url(ident, args.flavor)
    elif cmd == "page":
        url = page_url(kind, ident, args.flavor)
    else:
        raise StopRun(f"unknown command {cmd!r}")
    record["url"] = url
    resp = client.get(url)
    record.update(status=resp["status"], cached=resp["cached"])
    if resp.get("error"):
        record["error"] = resp["error"]
        return record
    if resp["status"] != 200:
        record["error"] = f"HTTP {resp['status']}"
        return record
    try:
        if cmd == "tooltip":
            record["data"] = summarize_tooltip(resp["body"])
        elif cmd == "xml":
            record["data"] = parse_item_xml(resp["body"])
        else:
            gatherer = extract_gatherer(resp["body"])
            title = re.search(r"<title>(.*?)</title>", resp["body"], re.S)
            # The page's own entity: its tooltip is the quickest answer to "what does it do now".
            own = next((g["data"][str(ident)] for g in gatherer
                        if isinstance(g["data"], dict) and isinstance(g["data"].get(str(ident)), dict)), {})
            tooltip_html = next((v for k, v in own.items() if k.startswith("tooltip") and isinstance(v, str)), "")
            record["data"] = {
                "title": html.unescape(title.group(1).strip()) if title else None,
                "dataEnv": sorted({g["dataEnv"] for g in gatherer}),
                "tooltip_text": html_to_text(tooltip_html) if tooltip_html else None,
                "listviews": extract_listviews(resp["body"]),
                "gatherer": gatherer if args.gatherer else None,
            }
    except (json.JSONDecodeError, ET.ParseError, ValueError) as err:
        record["error"] = f"parse error: {err}"
    return record


def read_batch(path: str) -> Iterable[tuple[str, str, int, str]]:
    with open(path, encoding="utf-8") as f:
        for lineno, raw in enumerate(f, 1):
            line, _, note = raw.partition("#")
            parts = line.split()
            if not parts:
                continue
            if len(parts) != 3 or not parts[2].isdigit():
                raise StopRun(f"{path}:{lineno}: expected '<tooltip|xml|page> <type> <id> [# note]'")
            yield parts[0], parts[1], int(parts[2]), note.strip()


def record_key(record: dict) -> str:
    return f"{record['cmd']} {record['type']} {record['id']}"


def merge_runs(out_dir: str) -> dict[str, dict]:
    """Newest record per (cmd, type, id) across every run file."""
    merged: dict[str, dict] = {}
    runs_dir = os.path.join(out_dir, "runs")
    if not os.path.isdir(runs_dir):
        return merged
    for name in sorted(os.listdir(runs_dir)):
        if not name.endswith(".jsonl"):
            continue
        with open(os.path.join(runs_dir, name), encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    record = json.loads(line)
                    merged[record_key(record)] = record
    return merged


def summarize_record(record: dict, max_rows: int = 15) -> list[str]:
    """Condensed text of one record: the facts needed to answer questions about it."""
    head = f"== {record_key(record)}"
    if record.get("note"):
        head += f"  # {record['note']}"
    lines = [head, f"   {record.get('url')}  status={record.get('status')}  fetched={record.get('fetched')}"]
    if record.get("error"):
        lines.append(f"   ERROR: {record['error']}")
    data = record.get("data") or {}
    if record["cmd"] == "page" and data:
        lines.append(f"   title: {data.get('title')}")
        lines.append(f"   dataEnv: {data.get('dataEnv')}")
        lines += ["   | " + line for line in (data.get("tooltip_text") or "").splitlines()]
        for lv in data.get("listviews") or []:
            rows = lv.get("data")
            if isinstance(rows, list):
                names = [str(r.get("name") or r.get("id")) for r in rows[:max_rows] if isinstance(r, dict)]
                more = f" (+{len(rows) - max_rows} more)" if len(rows) > max_rows else ""
                lines.append(f"   listview {lv.get('id')} [{lv.get('template')}] {len(rows)} rows: "
                             + "; ".join(names) + more)
            else:
                lines.append(f"   listview {lv.get('id')} [{lv.get('template')}] unparsed data")
    elif record["cmd"] in ("tooltip", "xml"):
        if record["cmd"] == "xml":
            for key in ("name", "level", "quality", "class", "subclass"):
                if key in data:
                    lines.append(f"   {key}: {data[key]}")
            for spell in data.get("createdBy") or []:
                lines.append(f"   createdBy spell {spell['id']} {spell.get('name')}: reagents "
                             + ", ".join(f"{r['id']}x{r['count']}" for r in spell["reagents"]))
        lines += ["   | " + line for line in (data.get("tooltip_text") or "").splitlines()]
    return lines


def write_outputs(out_dir: str) -> tuple[str, str]:
    merged = merge_runs(out_dir)
    data_path = os.path.join(out_dir, "wowhead-data.json")
    with open(data_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=1, sort_keys=True)
    summary_path = os.path.join(out_dir, "summary.txt")
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(f"# Wowhead data, {len(merged)} records. Full records: wowhead-data.json\n\n")
        for key in sorted(merged):
            f.write("\n".join(summarize_record(merged[key])) + "\n\n")
    return data_path, summary_path


def refuse_inside_agent() -> None:
    found = [name for name in AGENT_ENV_VARS if os.environ.get(name)]
    if found:
        sys.exit(f"Refusing to contact Wowhead: running inside an AI agent ({', '.join(found)} is set). "
                 "Wowhead's robots.txt disallows Anthropic agents. Run this tool yourself in a normal terminal.")


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--flavor", default="forever", help="URL prefix: forever, classic, tbc, wotlk, cata, mop-classic, retail")
    parser.add_argument("--data-env", type=int, help="Tooltip dataEnv number (see `page` output)")
    parser.add_argument("--locale", type=int, default=0, help="Tooltip locale number (0 = enUS)")
    parser.add_argument("--out-dir", default=os.path.join(HERE, "out"),
                        help="Output folder: runs/*.jsonl, merged wowhead-data.json and summary.txt")
    parser.add_argument("--stdout", action="store_true", help="Also print each JSON record to stdout")
    parser.add_argument("--cache", default=os.path.join(HERE, ".cache"), help="Response cache directory")
    parser.add_argument("--delay", type=float, default=DEFAULT_DELAY, help=f"Seconds between requests (min {MIN_DELAY})")
    parser.add_argument("--max-requests", type=int, default=DEFAULT_MAX_REQUESTS, help="Stop after this many HTTP requests")
    parser.add_argument("--refresh", action="store_true", help="Ignore cached responses")
    parser.add_argument("--contact", default="", help="Contact (email or URL) added to the User-Agent")
    parser.add_argument("--gatherer", action="store_true", help="Include raw WH.Gatherer data in page output")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("tooltip", "page"):
        p = sub.add_parser(name)
        p.add_argument("type", choices=TYPES)
        p.add_argument("ids", type=int, nargs="+")
    p = sub.add_parser("xml")
    p.add_argument("ids", type=int, nargs="+")
    p = sub.add_parser("batch")
    p.add_argument("file")
    sub.add_parser("selftest")
    args = parser.parse_args(argv)

    if args.command == "selftest":
        return selftest()
    refuse_inside_agent()

    if args.command == "batch":
        jobs = list(read_batch(args.file))
    elif args.command == "xml":
        jobs = [("xml", "item", i, "") for i in args.ids]
    else:
        jobs = [(args.command, args.type, i, "") for i in args.ids]

    client = Client(args.cache, args.delay, args.max_requests, args.refresh, args.contact)
    runs_dir = os.path.join(args.out_dir, "runs")
    os.makedirs(runs_dir, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    run_path = os.path.join(runs_dir, f"{stamp}-{args.command}.jsonl")
    counter = 1
    while os.path.exists(run_path):
        counter += 1
        run_path = os.path.join(runs_dir, f"{stamp}-{counter}-{args.command}.jsonl")
    code = 0
    with open(run_path, "w", encoding="utf-8") as out:
        try:
            for cmd, kind, ident, note in jobs:
                record = run_one(client, cmd, kind, ident, args, note)
                record["fetched"] = time.strftime("%Y-%m-%dT%H:%M:%S")
                line = json.dumps(record, ensure_ascii=False)
                out.write(line + "\n")
                out.flush()
                if args.stdout:
                    print(line)
                state = "cache" if record.get("cached") else record.get("status")
                print(f"{cmd} {kind} {ident}: {record.get('error') or state}", file=sys.stderr)
        except StopRun as err:
            print(f"Stopped: {err}", file=sys.stderr)
            code = 2
    data_path, summary_path = write_outputs(args.out_dir)
    print(f"{client.requests} HTTP requests. Run file: {run_path}", file=sys.stderr)
    print(f"Merged: {data_path}\nSummary: {summary_path}", file=sys.stderr)
    return code


# --------------------------------------------------------------------------------------------
# Offline self-test (no network)

SAMPLE_ROBOTS = """
User-agent: ClaudeBot
User-agent: anthropic-ai
Disallow: /

User-agent: *
Disallow: /forever/list=*
Disallow: /forever/search
Disallow: /forever/site-achievement/*
Allow: /forever/search/allowed$
Crawl-delay: 5
"""

SAMPLE_PAGE = """<html><head><title>Elune's Grace - Spell - World of Warcraft: Forever</title></head><body>
<script>WH.Gatherer.addData(6, 18, {"2651":{"name_enus":"Elune's Grace","icon":"spell_holy_elunesgrace",
"tooltip_enus":"<b>Elune's Grace<\\/b><br>Lasts 15 sec."}});</script>
<script>
new Listview({template: 'npc', id: 'taught-by-npc', name: WH.TERMS.taughtby, tabs: tabsRelated,
  parent: 'lkljbjkb574', data: [{"id":376,"name":"High Priestess Laurena","react":[1,-1],"location":[1519]}]});
new Listview({"template":"item","id":"reagent-for","data":[{id: 123, name: 'Thing, with comma', 'q': 2,}]});
new Listview({template: 'spell', id: 'broken', data: [function() { return 1 }]});
</script></body></html>"""

SAMPLE_XML = """<?xml version="1.0" encoding="UTF-8"?>
<wowhead><item id="13452"><name><![CDATA[Elixir of the Mongoose]]></name><level>46</level>
<quality id="1">Common</quality><class id="0"><![CDATA[Consumables]]></class>
<subclass id="2"><![CDATA[Elixir]]></subclass><icon displayId="1">inv_potion_32</icon>
<htmlTooltip><![CDATA[<b>Elixir of the Mongoose</b><br />Use: Increases Agility by 25.<br>Lasts 30 min.]]></htmlTooltip>
<json><![CDATA["classs":0,"id":13452,"level":46,"name":"Elixir of the Mongoose","subclass":2]]></json>
<jsonEquip><![CDATA[]]></jsonEquip>
<createdBy><spell id="17571" name="Elixir of the Mongoose" icon="x" minCount="1" maxCount="1">
<reagent id="13465" name="Mountain Silversage" quality="1" icon="y" count="2" /></spell></createdBy>
<link>https://www.wowhead.com/forever/item=13452</link></item></wowhead>"""


def selftest() -> int:
    groups = parse_robots(SAMPLE_ROBOTS)
    ours = select_group(groups, "BuffomatClassic-research/1.0 (+https://example.org)")
    claude = select_group(groups, "Mozilla/5.0 (compatible; ClaudeBot/1.0)")
    assert ours is not None and "*" in ours.agents and ours.crawl_delay == 5
    assert claude is not None and not robots_allows(claude, "/forever/spell=2651")
    assert robots_allows(ours, "/forever/spell=2651")
    assert robots_allows(ours, "/forever/item=13452&xml")
    assert not robots_allows(ours, "/forever/list=123")
    assert not robots_allows(ours, "/forever/search?q=x")
    assert robots_allows(ours, "/forever/search/allowed")
    assert not robots_allows(ours, "/forever/site-achievement/5")

    lvs = extract_listviews(SAMPLE_PAGE)
    assert [lv["id"] for lv in lvs] == ["taught-by-npc", "reagent-for", "broken"], lvs
    assert lvs[0]["template"] == "npc" and lvs[0]["data"][0]["name"] == "High Priestess Laurena"
    assert lvs[1]["data"][0] == {"id": 123, "name": "Thing, with comma", "q": 2}, lvs[1]
    assert loads_relaxed("{a: 'it\\'s', b: [1, 2,], 'c': {d: true}}") == {"a": "it's", "b": [1, 2], "c": {"d": True}}
    assert "data_raw" in lvs[2]
    gat = extract_gatherer(SAMPLE_PAGE)
    assert gat and gat[0]["dataEnv"] == 18 and gat[0]["data"]["2651"]["name_enus"] == "Elune's Grace"

    item = parse_item_xml(SAMPLE_XML)
    assert item["id"] == 13452 and item["name"] == "Elixir of the Mongoose"
    assert item["subclass"] == {"id": "2", "name": "Elixir"}
    assert item["json"]["level"] == 46 and item["jsonEquip"] == {}
    assert item["createdBy"][0]["reagents"][0] == {"id": 13465, "count": 2}
    assert "Lasts 30 min." in item["tooltip_text"].splitlines()
    assert parse_item_xml("<wowhead><error>Item not found!</error></wowhead>") == {"error": "Item not found!"}

    tip = summarize_tooltip(json.dumps({"name": "X", "tooltip": "<b>X</b><br>Lasts 1 hour &amp; more"}))
    assert tip["tooltip_text"] == "X\nLasts 1 hour & more"
    assert xml_url(5, "forever") == "https://www.wowhead.com/forever/item=5&xml"
    assert page_url("spell", 7, "retail") == "https://www.wowhead.com/spell=7"

    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "runs"))
        old = {"cmd": "page", "type": "spell", "id": 2651, "status": 404, "error": "HTTP 404"}
        new = {"cmd": "page", "type": "spell", "id": 2651, "status": 200, "note": "rank 1",
               "data": {"title": "Elune's Grace", "dataEnv": [18], "listviews": lvs}}
        xml_rec = {"cmd": "xml", "type": "item", "id": 13452, "status": 200, "data": item}
        missing = {"cmd": "page", "type": "spell", "id": 999, "status": 404, "error": "HTTP 404"}
        for name, recs in (("20260101-000000-page.jsonl", [old]),
                           ("20260102-000000-batch.jsonl", [new, xml_rec, missing])):
            with open(os.path.join(tmp, "runs", name), "w", encoding="utf-8") as f:
                f.write("".join(json.dumps(r) + "\n" for r in recs))
        data_path, summary_path = write_outputs(tmp)
        with open(data_path, encoding="utf-8") as f:
            merged = json.load(f)
        assert merged["page spell 2651"]["status"] == 200 and len(merged) == 3
        with open(summary_path, encoding="utf-8") as f:
            summary = f.read()
        assert "listview taught-by-npc [npc] 1 rows: High Priestess Laurena" in summary, summary
        assert "createdBy spell 17571 Elixir of the Mongoose: reagents 13465x2" in summary
        assert "   | Lasts 30 min." in summary
        assert "ERROR: HTTP 404" in summary and summary.count("title:") == 1

    # run_one on a page, with the network replaced by a canned response
    class FakeClient:
        def get(self, url: str) -> dict:
            assert url == "https://www.wowhead.com/forever/spell=2651", url
            return {"status": 200, "body": SAMPLE_PAGE, "cached": False}
    fake_args = argparse.Namespace(flavor="forever", data_env=None, locale=0, gatherer=False)
    rec = run_one(FakeClient(), "page", "spell", 2651, fake_args)  # type: ignore[arg-type]
    assert rec["data"]["tooltip_text"] == "Elune's Grace\nLasts 15 sec.", rec["data"]
    assert rec["data"]["dataEnv"] == [18] and len(rec["data"]["listviews"]) == 3
    print("selftest passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
