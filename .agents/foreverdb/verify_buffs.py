#!/usr/bin/env python3
"""Check Buffomat's WoW: Forever buff database against ForeverDB (https://foreverdb.net).

Steps (run from the repository root):
  lua .agents/foreverdb/dump_buffs.lua > .agents/foreverdb/out/buffs-forever.json
  python .agents/foreverdb/verify_buffs.py            # writes .agents/foreverdb/out/verify-buffs.txt

Checks:
  1. Class buffs: every spell id in singleFamily/groupFamily is a rank of a ForeverDB class ability or
     talent of a class that gets the buff, and no ForeverDB rank of that ability is missing.
  2. Class abilities and new-in-Forever talents no buff uses, whose tooltip reads like a long buff.
  3. Consumable items: each exists on Forever, required level, use effects and their duration
     against singleDuration.
  4. Forever consumables Buffomat does not list whose effect lasts 10 minutes or more, or is Well Fed.

Requests go through foreverdb.Client (rate limits, 24 h cache), so a rerun is cheap.
Data from ForeverDB.net (https://foreverdb.net).
"""
from __future__ import annotations

import json
import os
import re
import sys
from typing import Any, Optional

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import foreverdb  # noqa: E402

CLASSES = ["Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid"]
# Consumable subclasses worth a detail lookup when Buffomat does not list the item
DETAIL_SUBCLASSES = {"Elixirs", "Flasks", "Food & Drink", "Scrolls", "Potions", "Temporary", "Other"}
OTHER_NAME = re.compile(r"Oil|Stone|Juju|Draught|Brew|Charm|Essence|Imbue|Mojo|Infusion|Tonic|Elixir|Flask|"
                        r"Scroll|Arcanum|Totem|Bait|Lure|Ward|Ration|Pie|Tart|Delight", re.I)
OTHER_SKIP = re.compile(r"Writ|Crate|Ensemble|Healthstone|Soulstone|Care Package|Firework|Rune of|Spell Notes|"
                        r"Prophecy|Epiphany|Treasure|Deathstone|Bloodstone", re.I)
DURATION = re.compile(r"(?:for|lasts?)\s+(?:up to\s+)?(\d+(?:\.\d+)?)\s*(sec|second|min|minute|hour|hr|h)\b", re.I)
UNIT = {"sec": 1, "second": 1, "min": 60, "minute": 60, "hour": 3600, "hr": 3600, "h": 3600}


def durations(text: str) -> list[int]:
    return [int(float(n) * UNIT[u.lower()]) for n, u in DURATION.findall(text or "")]


def fmt_s(seconds: Optional[int]) -> str:
    if not seconds:
        return "-"
    return f"{seconds // 3600}h" if seconds % 3600 == 0 else f"{seconds // 60}m" if seconds % 60 == 0 else f"{seconds}s"


class Verifier:
    def __init__(self, client: foreverdb.Client):
        self.client = client
        self.lines: list[str] = []
        self.requests_before = client.requests

    def get(self, path: str) -> Optional[dict]:
        """Response data or None for 404 and errors."""
        result = self.client.api(path)
        body = result["body"]
        if result["status"] != 200 or not isinstance(body, dict):
            return None
        return body.get("data")

    def out(self, line: str = "") -> None:
        self.lines.append(line)

    # --- class data -------------------------------------------------------------------------------
    def class_index(self) -> tuple[dict[int, list[dict]], list[dict]]:
        """spellId -> [{class, name, kind, learned, rank, level, ranks}], and all abilities/talents."""
        index: dict[int, list[dict]] = {}
        entries: list[dict] = []
        for cls in CLASSES:
            data = self.get(f"classes/{cls}") or {}
            for ab in data.get("abilities", []):
                entry = {"class": cls.upper(), "name": ab["name"], "kind": "ability", "learned": ab.get("learned"),
                         "new": ab.get("newInForever"), "ranks": [r["spellId"] for r in ab.get("ranks", [])],
                         "levels": [r.get("level") for r in ab.get("ranks", [])]}
                entries.append(entry)
            for tree in data.get("talentTrees", []):
                for tal in tree.get("talents", []):
                    ranks = sorted({r["spellId"] for r in tal.get("ranks", []) if r.get("spellId")})
                    entry = {"class": cls.upper(), "name": tal["name"], "kind": "talent", "learned": "talent",
                             "new": tal.get("newInForever"), "ranks": ranks, "levels": [tal.get("level")],
                             "description": (tal.get("ranks") or [{}])[-1].get("description", "")}
                    entries.append(entry)
        for entry in entries:
            for spell_id in entry["ranks"]:
                index.setdefault(spell_id, []).append(entry)
        return index, entries

    def check_class_buffs(self, buffs: list[dict], index: dict[int, list[dict]]) -> set[int]:
        self.out("== 1. Class buffs against ForeverDB class abilities and talents")
        used: set[int] = set()
        problems = 0
        for buff in buffs:
            if buff["isConsumable"]:
                continue
            ids = (buff.get("singleFamily") or []) + (buff.get("groupFamily") or [])
            used.update(ids)
            classes = set(buff.get("classes") or [])
            notes: list[str] = []
            seen_entries: dict[str, dict] = {}
            for spell_id in ids:
                found = [e for e in index.get(spell_id, []) if e["class"] in classes]
                if not found:
                    other = index.get(spell_id, [])
                    if other:
                        notes.append(f"{spell_id} belongs to {other[0]['class']} {other[0]['name']}, "
                                     f"buff is for {','.join(sorted(classes))}")
                    else:
                        spell = self.get(f"spells/{spell_id}")
                        notes.append(f"{spell_id} not in any class list; spells/{spell_id}: "
                                     + (f"{spell['name']} {spell.get('rank') or ''} level {spell.get('requiredLevel')}"
                                        if spell else "not found (removed on Forever?)"))
                for e in found:
                    seen_entries[e["class"] + e["name"]] = e
            for e in seen_entries.values():
                missing = [s for s in e["ranks"] if s not in ids]
                if missing:
                    notes.append(f"{e['class']} {e['name']} ({e['kind']}) ranks not in buff: {missing}")
            if notes:
                problems += 1
                self.out(f"- buff {buff['buffId']} ({buff.get('type') or 'buff'}, {','.join(sorted(classes))}):")
                for n in notes:
                    self.out(f"    {n}")
        self.out(f"   {problems} buffs with notes")
        self.out()
        return used

    def check_unused_abilities(self, entries: list[dict], used: set[int]) -> None:
        self.out("== 2. ForeverDB abilities/talents no Buffomat buff uses that read like long buffs (>= 10 min)")
        self.out("   (party/raid wide, self buff or weapon imbue; review by hand)")
        for e in entries:
            if any(s in used for s in e["ranks"]) or not e["ranks"]:
                continue
            if e["kind"] == "talent":
                if not e["new"]:
                    continue
                text = e.get("description", "")
                top = e["ranks"][-1]
                spell = self.get(f"spells/{top}") if top else None
                text = (spell or {}).get("description") or text
            else:
                top = e["ranks"][-1]
                spell = self.get(f"spells/{top}")
                text = (spell or {}).get("description", "")
            longest = max(durations(text), default=0)
            if longest >= 600 or re.search(r"party or raid|all party|raid members", text, re.I) and longest >= 60:
                self.out(f"- {e['class']} {e['name']} ({e['kind']}, {e['learned']}{', new' if e['new'] else ''}) "
                         f"ranks {e['ranks']} {fmt_s(longest)}: {text[:220]}")
        self.out()

    # --- consumables ------------------------------------------------------------------------------
    def check_consumables(self, buffs: list[dict]) -> set[int]:
        self.out("== 3. Buffomat consumable items on Forever")
        listed: set[int] = set()
        for buff in buffs:
            if not buff["isConsumable"]:
                continue
            family = set((buff.get("singleFamily") or []) + (buff.get("providesAuras") or []))
            notes: list[str] = []
            summary: list[str] = []
            for item_id in buff.get("items") or []:
                listed.add(item_id)
                item = self.get(f"items/{item_id}")
                if not item:
                    notes.append(f"item {item_id} not on Forever")
                    continue
                effects = item.get("effects") or []
                use = [e for e in effects if e.get("trigger") == "use"] or effects
                spell_ids = [e.get("spellId") for e in use]
                text = " ".join(e.get("text") or "" for e in use)
                secs = durations(text)
                summary.append(f"{item_id} {item['name']} L{item.get('requiredLevel')}"
                               f" spell {spell_ids} {fmt_s(max(secs, default=0))}")
                if item.get("speculation"):
                    notes.append(f"item {item_id} {item['name']}: ForeverDB marks it speculation "
                                 f"{item.get('speculationReasons')}")
                if item.get("betaEvent"):
                    notes.append(f"item {item_id} {item['name']}: beta event item")
                food = "Well Fed" in text or "eat" in text.lower()
                if not food and spell_ids and not family.intersection(spell_ids) and buff.get("type") != "weapon":
                    notes.append(f"item {item_id} {item['name']}: use spell {spell_ids} not in buff family "
                                 f"{sorted(family)}")
                want = buff.get("singleDuration")
                if want and secs and not food and want not in secs and max(secs) >= 60:
                    notes.append(f"item {item_id} {item['name']}: tooltip lasts {fmt_s(max(secs))}, "
                                 f"buff singleDuration {fmt_s(want)}")
            if notes:
                self.out(f"- buff {buff['buffId']} ({buff.get('category')}, {buff.get('type') or 'buff'}):")
                for n in notes:
                    self.out(f"    {n}")
                for s in summary:
                    self.out(f"      . {s}")
        self.out()
        return listed

    def check_unlisted_consumables(self, listed: set[int]) -> None:
        self.out("== 4. Forever consumables Buffomat does not list, effect >= 10 min or Well Fed")
        items: list[dict] = []
        offset = 0
        while True:
            result = self.client.api(f"items?class=0&limit=100&offset={offset}" if offset
                                     else "items?class=0&limit=100")
            body = result["body"] if isinstance(result["body"], dict) else {}
            items += body.get("data") or []
            nxt = (body.get("meta") or {}).get("next")
            if not nxt:
                break
            offset += 100
        rows: list[str] = []
        for item in items:
            sub = item.get("subclass")
            if item["id"] in listed or sub not in DETAIL_SUBCLASSES:
                continue
            if sub == "Other" and (OTHER_SKIP.search(item["name"]) or not (
                    item["id"] >= 240000 or (item["id"] < 200000 and OTHER_NAME.search(item["name"])))):
                continue
            if 200000 <= item["id"] < 240000:
                continue   # Season of Discovery leftovers in the client
            detail = self.get(f"items/{item['id']}")
            if not detail:
                continue
            text = " ".join(e.get("text") or "" for e in detail.get("effects") or [])
            secs = max(durations(text), default=0)
            if secs >= 600 or "Well Fed" in text:
                flags = " speculation" if detail.get("speculation") else ""
                flags += " beta-event" if detail.get("betaEvent") else ""
                rows.append(f"- {item['id']} {item['name']} [{sub}] L{detail.get('requiredLevel')} {fmt_s(secs)}"
                            f"{flags}: spells {[e.get('spellId') for e in detail.get('effects') or []]} "
                            f"{text[:200]}")
        self.lines += rows
        self.out(f"   {len(rows)} items")
        self.out()


def main() -> int:
    dump = os.path.join(HERE, "out", "buffs-forever.json")
    if not os.path.exists(dump):
        print("run first: lua .agents/foreverdb/dump_buffs.lua > .agents/foreverdb/out/buffs-forever.json")
        return 2
    with open(dump, encoding="utf-8") as f:
        buffs: list[dict[str, Any]] = json.load(f)
    client = foreverdb.Client(foreverdb.read_api_key(), os.path.join(HERE, ".cache"), 3000, refresh=False)
    v = Verifier(client)
    v.out(f"# Buffomat Forever buffs checked against ForeverDB. {foreverdb.ATTRIBUTION}")
    v.out(f"# {len(buffs)} buffs from {dump}")
    v.out()
    try:
        index, entries = v.class_index()
        used = v.check_class_buffs(buffs, index)
        v.check_unused_abilities(entries, used)
        listed = v.check_consumables(buffs)
        v.check_unlisted_consumables(listed)
    except foreverdb.StopRun as err:
        v.out(f"STOPPED: {err}")
    v.out(f"# {client.requests - v.requests_before} HTTP requests; limits {client.limits}")
    path = os.path.join(HERE, "out", "verify-buffs.txt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(v.lines) + "\n")
    print(f"Report: {path} ({client.requests} requests)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
