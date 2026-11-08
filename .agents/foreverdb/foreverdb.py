#!/usr/bin/env python3
"""ForeverDB client for Buffomat research (https://foreverdb.net/developers).

ForeverDB welcomes apps, tools and AI assistants (see https://foreverdb.net/robots.txt and
/llms.txt), so agents may run this tool. The API needs a key: a maintainer requests it on
https://foreverdb.net/developers (Battle.net login), then stores it in the FOREVERDB_API_KEY
environment variable or in .agents/foreverdb/.apikey (git-ignored).

Terms to keep: credit "Data from ForeverDB.net" with a link wherever the data is shown, do not
resell it or present it as our own, and keep to 60 requests a minute and 10,000 a day per key.
The addon data files are GPL-3.0 with an attribution term; Buffomat is not GPL, so use them for
research and verification and do not copy them into Src/.

Commands:
  get PATH...          Any API path, e.g. spells/2651, items/274273, classes/Paladin,
                       "builds/latest?type=ability&class=Priest"
  spell ID... / item ID... / class NAME...   Shortcuts for get
  batch FILE           One API path per line, "# note" allowed
  addon-data [NAME..]  Download the ForeverDB addon data files (no key needed), checking SHA-256
  meta                 GET /meta: build, level cap, counts (useful key check)
  selftest             Offline tests

Output (default folder .agents/foreverdb/out/, see --out-dir):
  runs/<timestamp>-<command>.jsonl   raw records of one run
  foreverdb-data.json                newest record per API path across all runs
  summary.txt                        condensed text of every record
  addon-data/<version>/Data/*.lua    downloaded addon data files
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Iterable, Optional

TOOL_VERSION = "1.0"
REPO_URL = "https://github.com/kvakvs-plays/Buffomat"
SITE = "https://foreverdb.net"
API = SITE + "/api/v1"
MANIFEST_URL = SITE + "/downloads/addon-manifest.json"
PER_MINUTE = 60
MIN_SPACING = 60.0 / PER_MINUTE + 0.05   # stay just under 60 a minute
DEFAULT_MAX_REQUESTS = 2000              # well under the 10,000 daily limit
CACHE_TTL = 24 * 3600
HERE = os.path.dirname(os.path.abspath(__file__))
ATTRIBUTION = "Data from ForeverDB.net (https://foreverdb.net)"


class StopRun(Exception):
    """Abort the run: continuing would break the API terms or hammer the server."""


def read_api_key() -> Optional[str]:
    key = os.environ.get("FOREVERDB_API_KEY", "").strip()
    if key:
        return key
    path = os.path.join(HERE, ".apikey")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return f.read().strip() or None
    return None


def normalize_path(path: str) -> str:
    """'/api/v1/spells/1' or 'spells/1' -> 'spells/1'."""
    path = path.strip()
    for prefix in (API + "/", "/api/v1/", "api/v1/", "/"):
        if path.startswith(prefix):
            path = path[len(prefix):]
    return path


class Client:
    def __init__(self, key: Optional[str], cache_dir: str, max_requests: int, refresh: bool):
        self.key = key
        self.cache_dir = cache_dir
        self.max_requests = max_requests
        self.refresh = refresh
        self.requests = 0
        self.last_request = 0.0
        self.spacing = MIN_SPACING
        self.limits: dict[str, str] = {}
        self.user_agent = f"BuffomatClassic-research/{TOOL_VERSION} (+{REPO_URL})"
        os.makedirs(cache_dir, exist_ok=True)

    def _cache_path(self, url: str) -> str:
        return os.path.join(self.cache_dir, hashlib.sha1(url.encode()).hexdigest() + ".json")

    def _cached(self, url: str) -> Optional[dict]:
        path = self._cache_path(url)
        if self.refresh or not os.path.exists(path):
            return None
        with open(path, encoding="utf-8") as f:
            entry = json.load(f)
        return entry if time.time() - entry.get("fetched", 0) <= CACHE_TTL else None

    def _store(self, url: str, status: int, body: str) -> None:
        with open(self._cache_path(url), "w", encoding="utf-8") as f:
            json.dump({"url": url, "status": status, "fetched": time.time(), "body": body}, f)

    def _raw_get(self, url: str, with_key: bool) -> tuple[int, bytes, dict]:
        if self.requests >= self.max_requests:
            raise StopRun(f"request limit {self.max_requests} reached; raise --max-requests to continue")
        pause = self.last_request + self.spacing - time.time()
        if pause > 0:
            time.sleep(pause)
        self.requests += 1
        self.last_request = time.time()
        headers = {"User-Agent": self.user_agent, "Accept": "application/json"}
        if with_key and self.key:
            headers["X-API-Key"] = self.key
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                return resp.status, resp.read(), {k.lower(): v for k, v in resp.headers.items()}
        except urllib.error.HTTPError as err:
            body = err.read() if err.fp else b""
            return err.code, body, {k.lower(): v for k, v in (err.headers or {}).items()}

    def _note_limits(self, headers: dict) -> None:
        for name, value in headers.items():
            if name.startswith("x-ratelimit") or name.startswith("x-daily"):
                self.limits[name] = value
        remaining = headers.get("x-ratelimit-remaining")
        if remaining is not None and remaining.isdigit() and int(remaining) <= 2:
            self.spacing = max(self.spacing, 5.0)   # slow down near the per-minute limit
        daily = headers.get("x-daily-remaining")
        if daily is not None and daily.isdigit() and int(daily) <= 10:
            raise StopRun(f"only {daily} daily requests left on this key; stopping")

    def api(self, path: str) -> dict:
        """GET an API path. Returns {"status", "body"(parsed JSON or text), "cached"}."""
        if not self.key:
            raise StopRun("no API key: set FOREVERDB_API_KEY or write it to .agents/foreverdb/.apikey "
                          "(request one at https://foreverdb.net/developers)")
        url = f"{API}/{normalize_path(path)}"
        entry = self._cached(url)
        if entry is not None:
            return {"status": entry["status"], "body": _parse(entry["body"]), "cached": True, "url": url}
        for attempt in range(3):
            status, raw, headers = self._raw_get(url, with_key=True)
            self._note_limits(headers)
            body = raw.decode("utf-8", "replace")
            if status == 429:
                retry = headers.get("retry-after", "")
                wait = min(900.0, float(retry)) if retry.replace(".", "", 1).isdigit() else 60.0 * (attempt + 1)
                print(f"  429, waiting {wait:.0f} s", file=sys.stderr)
                time.sleep(wait)
                continue
            if status in (401, 403):
                raise StopRun(f"HTTP {status} for {url}: the key is missing, wrong or suspended. {body[:200]}")
            if status in (200, 404):
                self._store(url, status, body)
            return {"status": status, "body": _parse(body), "cached": False, "url": url}
        raise StopRun(f"still rate limited for {url}; stopping")

    def download(self, url: str) -> bytes:
        status, raw, _ = self._raw_get(url, with_key=False)
        if status != 200:
            raise StopRun(f"HTTP {status} for {url}")
        return raw


def _parse(body: str) -> Any:
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return body


# --------------------------------------------------------------------------------------------
# Summary text

PREFERRED = ("id", "name", "rank", "subtext", "level", "requiredLevel", "quality", "class", "subclass",
             "school", "castTime", "duration", "cooldown", "range", "costs", "description", "auraDescription",
             "effects", "liveClient", "dataFromBuild", "source", "label")


def _short(value: Any, limit: int = 300) -> str:
    text = value if isinstance(value, str) else json.dumps(value, ensure_ascii=False)
    text = " ".join(text.split())
    return text if len(text) <= limit else text[:limit] + " ..."


def summarize_data(data: Any, indent: str = "   ", max_items: int = 25) -> list[str]:
    """Readable lines for an API `data` value of unknown shape: preferred keys first,
    other scalars next, then list sizes with the first names."""
    lines: list[str] = []
    if isinstance(data, list):
        lines.append(f"{indent}{len(data)} entries")
        for entry in data[:max_items]:
            if isinstance(entry, dict):
                label = entry.get("name") or entry.get("title") or entry.get("slug")
                bits = [str(entry.get("id", "")), str(label or "")]
                for key in ("rank", "level", "change", "direction", "type"):
                    if key in entry:
                        bits.append(f"{key}={_short(entry[key], 60)}")
                lines.append(f"{indent}- " + " ".join(b for b in bits if b))
            else:
                lines.append(f"{indent}- {_short(entry, 120)}")
        if len(data) > max_items:
            lines.append(f"{indent}... {len(data) - max_items} more")
        return lines
    if not isinstance(data, dict):
        return [f"{indent}{_short(data)}"]
    keys = [k for k in PREFERRED if k in data] + sorted(k for k in data if k not in PREFERRED)
    for key in keys:
        value = data[key]
        if isinstance(value, list) and value and isinstance(value[0], dict):
            names = [str(v.get("name") or v.get("title") or v.get("id")) for v in value[:max_items]]
            more = f" (+{len(value) - max_items} more)" if len(value) > max_items else ""
            lines.append(f"{indent}{key}: {len(value)}: " + "; ".join(names) + more)
        elif isinstance(value, dict) and len(json.dumps(value)) > 300:
            lines.append(f"{indent}{key}: {{{', '.join(list(value)[:15])}{', ...' if len(value) > 15 else ''}}}")
        else:
            lines.append(f"{indent}{key}: {_short(value)}")
    return lines


def summarize_record(record: dict) -> list[str]:
    head = f"== {record['path']}" + (f"  # {record['note']}" if record.get("note") else "")
    lines = [head, f"   status={record.get('status')}  fetched={record.get('fetched')}"]
    if record.get("error"):
        lines.append(f"   ERROR: {record['error']}")
    body = record.get("body")
    if isinstance(body, dict):
        meta = body.get("meta")
        if isinstance(meta, dict):
            lines.append("   meta: " + _short({k: v for k, v in meta.items() if k != "client"}, 200))
        if "data" in body:
            lines += summarize_data(body["data"])
        elif "error" in body:
            lines.append(f"   ERROR: {_short(body['error'])}")
    elif body:
        lines.append("   " + _short(body))
    return lines


def merge_runs(out_dir: str) -> dict[str, dict]:
    merged: dict[str, dict] = {}
    runs_dir = os.path.join(out_dir, "runs")
    if os.path.isdir(runs_dir):
        for name in sorted(os.listdir(runs_dir)):
            if name.endswith(".jsonl"):
                with open(os.path.join(runs_dir, name), encoding="utf-8") as f:
                    for line in f:
                        if line.strip():
                            record = json.loads(line)
                            merged[record["path"]] = record
    return merged


def write_outputs(out_dir: str) -> tuple[str, str]:
    merged = merge_runs(out_dir)
    data_path = os.path.join(out_dir, "foreverdb-data.json")
    with open(data_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=1, sort_keys=True)
    summary_path = os.path.join(out_dir, "summary.txt")
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(f"# {ATTRIBUTION}. {len(merged)} records; full records in foreverdb-data.json\n\n")
        for key in sorted(merged):
            f.write("\n".join(summarize_record(merged[key])) + "\n\n")
    return data_path, summary_path


# --------------------------------------------------------------------------------------------
# Commands


def read_batch(path: str) -> Iterable[tuple[str, str]]:
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line, _, note = raw.partition("#")
            line = line.strip()
            if line:
                yield normalize_path(line), note.strip()


def new_run_file(out_dir: str, command: str) -> str:
    runs_dir = os.path.join(out_dir, "runs")
    os.makedirs(runs_dir, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    path, counter = os.path.join(runs_dir, f"{stamp}-{command}.jsonl"), 1
    while os.path.exists(path):
        counter += 1
        path = os.path.join(runs_dir, f"{stamp}-{counter}-{command}.jsonl")
    return path


def run_api_jobs(client: Client, jobs: list[tuple[str, str]], out_dir: str, command: str, echo: bool) -> int:
    run_path = new_run_file(out_dir, command)
    code = 0
    with open(run_path, "w", encoding="utf-8") as out:
        try:
            for path, note in jobs:
                resp = client.api(path)
                record: dict[str, Any] = {"path": path, "url": resp["url"], "status": resp["status"],
                                          "cached": resp["cached"], "body": resp["body"],
                                          "fetched": time.strftime("%Y-%m-%dT%H:%M:%S")}
                if note:
                    record["note"] = note
                if resp["status"] != 200:
                    record["error"] = f"HTTP {resp['status']}"
                line = json.dumps(record, ensure_ascii=False)
                out.write(line + "\n")
                out.flush()
                if echo:
                    print(line)
                state = "cache" if resp["cached"] else resp["status"]
                print(f"{path}: {record.get('error') or state}", file=sys.stderr)
        except StopRun as err:
            print(f"Stopped: {err}", file=sys.stderr)
            code = 2
    data_path, summary_path = write_outputs(out_dir)
    if client.limits:
        print("Limits: " + ", ".join(f"{k}={v}" for k, v in sorted(client.limits.items())), file=sys.stderr)
    print(f"{client.requests} HTTP requests. Run file: {run_path}\nMerged: {data_path}\nSummary: {summary_path}",
          file=sys.stderr)
    return code


def download_addon_data(client: Client, out_dir: str, names: list[str]) -> int:
    """Fetch the public addon data files listed in the manifest and check their SHA-256."""
    manifest = json.loads(client.download(MANIFEST_URL).decode("utf-8"))
    data = manifest.get("data") or {}
    version = data.get("version", "unknown")
    target = os.path.join(out_dir, "addon-data", version)
    wanted = {n.lower().removesuffix(".lua") for n in names}
    count = 0
    for entry in data.get("files", []):
        base = os.path.basename(entry["path"]).lower().removesuffix(".lua")
        if wanted and base not in wanted:
            continue
        dest = os.path.join(target, entry["path"])
        if os.path.exists(dest):
            with open(dest, "rb") as f:
                if hashlib.sha256(f.read()).hexdigest() == entry["sha256"]:
                    continue
        raw = client.download(urllib.parse.urljoin(SITE + "/", entry["url"]))
        digest = hashlib.sha256(raw).hexdigest()
        if digest != entry["sha256"]:
            raise StopRun(f"SHA-256 mismatch for {entry['path']}: {digest}")
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "wb") as f:
            f.write(raw)
        count += 1
        print(f"{entry['path']}: {len(raw)} bytes", file=sys.stderr)
    with open(os.path.join(target, "NOTICE-foreverdb.txt"), "w", encoding="utf-8") as f:
        f.write(f"{ATTRIBUTION}\nGPL-3.0 with an attribution term. Research use only; do not copy into Src/.\n"
                f"Manifest: {MANIFEST_URL}\nData version: {version}\n")
    print(f"{count} files downloaded to {target} ({client.requests} HTTP requests)", file=sys.stderr)
    return 0


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out-dir", default=os.path.join(HERE, "out"), help="Output folder")
    parser.add_argument("--cache", default=os.path.join(HERE, ".cache"), help="Response cache directory")
    parser.add_argument("--max-requests", type=int, default=DEFAULT_MAX_REQUESTS, help="Stop after this many requests")
    parser.add_argument("--refresh", action="store_true", help="Ignore cached responses (cache lasts 24 h)")
    parser.add_argument("--stdout", action="store_true", help="Also print each JSON record to stdout")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("get").add_argument("paths", nargs="+")
    sub.add_parser("spell").add_argument("ids", type=int, nargs="+")
    sub.add_parser("item").add_argument("ids", type=int, nargs="+")
    sub.add_parser("class").add_argument("names", nargs="+")
    sub.add_parser("batch").add_argument("file")
    sub.add_parser("meta")
    sub.add_parser("addon-data").add_argument("names", nargs="*", help="e.g. Consumables Assist (default: all)")
    sub.add_parser("selftest")
    args = parser.parse_args(argv)

    if args.command == "selftest":
        return selftest()
    client = Client(read_api_key(), args.cache, args.max_requests, args.refresh)
    try:
        if args.command == "addon-data":
            return download_addon_data(client, args.out_dir, args.names)
    except StopRun as err:
        print(f"Stopped: {err}", file=sys.stderr)
        return 2
    if args.command == "get":
        jobs = [(normalize_path(p), "") for p in args.paths]
    elif args.command == "spell":
        jobs = [(f"spells/{i}", "") for i in args.ids]
    elif args.command == "item":
        jobs = [(f"items/{i}", "") for i in args.ids]
    elif args.command == "class":
        jobs = [(f"classes/{n}", "") for n in args.names]
    elif args.command == "meta":
        jobs = [("meta", "")]
    else:
        jobs = list(read_batch(args.file))
    return run_api_jobs(client, jobs, args.out_dir, args.command, args.stdout)


# --------------------------------------------------------------------------------------------
# Offline self-test


def selftest() -> int:
    import tempfile
    assert normalize_path("/api/v1/spells/1") == "spells/1"
    assert normalize_path("https://foreverdb.net/api/v1/items/2?x=1") == "items/2?x=1"
    assert normalize_path("classes/Paladin") == "classes/Paladin"

    spell = {"data": {"id": 2651, "name": "Elune's Grace", "rank": "Rank 1", "description": "Reduces...",
                      "costs": [{"type": "mana", "amount": 60}], "liveClient": True},
             "meta": {"build": "1.60.1.70862", "client": "dev-1"}}
    lines = summarize_record({"path": "spells/2651", "status": 200, "fetched": "t", "body": spell, "note": "n"})
    text = "\n".join(lines)
    assert "== spells/2651  # n" in text and "name: Elune's Grace" in text and "rank: Rank 1" in text, text
    assert "dev-1" not in text and "1.60.1.70862" in text
    assert lines.index("   id: 2651") < lines.index("   name: Elune's Grace")

    listing = {"data": [{"id": i, "name": f"Thing {i}", "change": "added"} for i in range(30)], "meta": {"total": 30}}
    text = "\n".join(summarize_record({"path": "builds/latest", "status": 200, "body": listing}))
    assert "30 entries" in text and "- 0 Thing 0 change=added" in text and "... 5 more" in text, text

    cls = {"data": {"name": "Paladin", "abilities": [{"id": 1, "name": "Seal of Fury"}] * 3}}
    text = "\n".join(summarize_record({"path": "classes/Paladin", "status": 200, "body": cls}))
    assert "abilities: 3: Seal of Fury; Seal of Fury; Seal of Fury" in text, text

    err = {"path": "spells/1", "status": 404, "error": "HTTP 404", "body": {"error": "not found"}}
    assert "ERROR: not found" in "\n".join(summarize_record(err))

    with tempfile.TemporaryDirectory() as tmp:
        batch = os.path.join(tmp, "b.txt")
        with open(batch, "w", encoding="utf-8") as f:
            f.write("# comment\nspells/2651  # Elune\n/api/v1/items/1\n\n")
        assert list(read_batch(batch)) == [("spells/2651", "Elune"), ("items/1", "")]

        # Full API flow with the network replaced: limits, cache and output files.
        calls: list[str] = []
        responses = {f"{API}/spells/2651": (200, json.dumps(spell)), f"{API}/spells/9": (404, '{"error":"no"}')}

        def fake(self: Client, url: str, with_key: bool) -> tuple[int, bytes, dict]:
            assert with_key and self.key == "k"
            calls.append(url)
            self.requests += 1
            status, body = responses[url]
            return status, body.encode(), {"x-ratelimit-remaining": "59", "x-daily-remaining": "9999"}
        original = Client._raw_get
        Client._raw_get = fake  # type: ignore[assignment]
        try:
            client = Client("k", os.path.join(tmp, "cache"), 10, False)
            jobs = [("spells/2651", "Elune"), ("spells/9", "")]
            assert run_api_jobs(client, jobs, tmp, "batch", False) == 0
            client2 = Client("k", os.path.join(tmp, "cache"), 10, False)
            assert run_api_jobs(client2, jobs, tmp, "batch", False) == 0
            assert len(calls) == 2, calls          # second run fully cached (404 too)
            assert client.limits["x-daily-remaining"] == "9999"
            nokey = Client(None, os.path.join(tmp, "cache"), 10, False)
            try:
                nokey.api("meta")
                raise AssertionError("expected StopRun without a key")
            except StopRun:
                pass
        finally:
            Client._raw_get = original  # type: ignore[assignment]
        with open(os.path.join(tmp, "summary.txt"), encoding="utf-8") as f:
            summary = f.read()
        assert ATTRIBUTION in summary and "== spells/2651  # Elune" in summary and "ERROR: HTTP 404" in summary
        with open(os.path.join(tmp, "foreverdb-data.json"), encoding="utf-8") as f:
            assert set(json.load(f)) == {"spells/2651", "spells/9"}
    print("selftest passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
