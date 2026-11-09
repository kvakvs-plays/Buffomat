# ForeverDB client

`foreverdb.py` reads WoW: Forever data from [ForeverDB](https://foreverdb.net) and writes it to
`out/`, where agents read it. Python 3.9+ standard library only.

## Permission and terms

- ForeverDB's `robots.txt` welcomes AI assistants (`ClaudeBot`, `Claude-User`, ...) and says its
  crawler rules do not restrict apps and tools. Agents may run this tool.
- The API (`https://foreverdb.net/api/v1`) needs a key. Request one on
  https://foreverdb.net/developers (Battle.net login; say what you build, give an email, agree to
  credit ForeverDB). The project key is `FOREVERDB_API_KEY=...` in the repository root `.env`
  (git-ignored, added 2026-11-09). The client looks in the environment variable, then `.env`, then
  `.agents/foreverdb/.apikey`. Never print, log or commit the key.
- Auth header `X-API-Key: <key>` (or `Authorization: Bearer <key>`); no query-string auth.
- Usage log for rate-limit counting: `.agents/foreverdb/usage-24h.log` (git-ignored) holds one line
  per minute with requests, `YYYY-MM-DD HH:MM<TAB>count` in local time, counting every HTTP request
  (API and addon-data downloads). Minutes older than 24 hours are dropped on each write. Nothing
  else is stored: no paths, statuses or keys. All runs share it, so the client stops 100 requests short
  of 10,000 in any 24 hours even across separate runs. Check before a large run:
  `python .agents/foreverdb/foreverdb.py usage`. When the log is missing or empty, that command starts
  it from the fetch times in `.cache/`. Every `get`/`batch`/... run prints the same summary at the end.
- Limits: 60 requests a minute and 10,000 a day per key. The tool spaces requests about 1.05 s
  apart, slows down when `X-RateLimit-Remaining` is low, waits on `429` + `Retry-After`, stops when
  the daily allowance is nearly used up, and stops after 2,000 requests per run (`--max-requests`).
- Credit "Data from ForeverDB.net" with a link to https://foreverdb.net wherever the data is shown.
  Do not resell it or present it as our own.
- The addon data files are GPL-3.0 with an attribution term. Buffomat is not GPL: use them for
  research and to check facts; do not copy them into `Src/`.

## Commands

Global options go **before** the command.

```sh
python .agents/foreverdb/foreverdb.py meta                          # check the key; build and counts
python .agents/foreverdb/foreverdb.py batch .agents/foreverdb/verify-forever.txt
python .agents/foreverdb/foreverdb.py spell 1225502 1328548
python .agents/foreverdb/foreverdb.py item 274273
python .agents/foreverdb/foreverdb.py class Paladin Priest
python .agents/foreverdb/foreverdb.py get "builds/latest?type=ability&class=Priest" "items?q=elixir&limit=100"
python .agents/foreverdb/foreverdb.py addon-data Consumables Spells Talents   # no key needed
python .agents/foreverdb/foreverdb.py selftest                      # offline
```

Useful API paths (see https://foreverdb.net/developers for all): `spells/{id}`, `items/{id}`,
`items?q=&class=&minLevel=&limit=&offset=`, `classes/{name}`, `professions/{slug}`, `poisons`,
`builds/{build|latest}?type=ability|talent|spell|item&class=&change=added|removed|changed`,
`buffs-nerfs?class=&direction=buff|nerf|changed|new|removed`, `vendors?q=&seen=true`.

## Output

Default folder `.agents/foreverdb/out/` (git-ignored, `--out-dir` to change).

| File | Content |
|------|---------|
| `summary.txt` | Short text per API path: build, names, ranks, descriptions, list sizes, errors. Read this first |
| `foreverdb-data.json` | Newest full response per API path across all runs |
| `runs/<timestamp>-<command>.jsonl` | Raw records of one run |
| `addon-data/<version>/Data/*.lua` | ForeverDB addon data files, SHA-256 checked against the manifest |

Responses are cached for 24 hours in `.cache/`; `--refresh` ignores the cache.

## Addon data files worth reading

Downloaded 2026-11-08, data version `2026-11-08.f0054e58`, build 1.60.1.70862:

| File | Content |
|------|---------|
| `Spells.lua` | Class spells by level: `{level, name, rank, spell, races, faction, quest, questId, classicQuest}`. The trainer list |
| `Talents.lua` | Talent trees with trait node and entry IDs |
| `Consumables.lua` | `{item, name, kind, effect, level, strength, madeBy, soldByVendor, sodLeftover}` |
| `Supplies.lua` | Class reagents, pet food, ammunition and their vendors |
| `Assist.lua` | Rotation spells with kind (`buff`, `imbue`, `toggle`, ...), cooldown and duration |
| `Camp.lua`, `NewData.lua`, `Enhance.lua` | Camp features, new-in-update data, enchant choices |

## Response shapes (live API, build 1.60.1.70862, checked 2026-11-09)

Every answer is `{"data": ..., "meta": {"build", "attribution", "total", "limit", "offset", "next"}}`;
errors are `{"error": {"code", "message"}}` (`not_found` is HTTP 404, `bad_parameter` 400).

- `classes/{Name}` → `abilities[]`: `{name, line, learned, newInForever, ranks[{level, rank, spellId}]}`.
  `learned` is `trainer`, `quest`, `sod` (Season of Discovery rune spell) or `other` (book, item,
  talent). `talentTrees[]`: `{name, talents[{id, name, tier, column, level, maxRanks, newInForever,
  prerequisites, ranks[{rank, spellId, description}]}]}`. This is the Forever trainer list with spell
  IDs per rank; buff talents (Trueshot Aura, Oath of Light) are under talents, not abilities.
- `spells/{id}` → `{id, name, rank, requiredLevel, school, costs[], description, castTimeMs,
  cooldownMs, rangeYards, icon, liveClient?}`. No duration field: read it from `description`.
  Numbers in descriptions are for level 60. `liveClient.changes[]` lists beta→live tooltip and effect
  differences. Spells removed on Forever (e.g. Blessing of Salvation 1038) return 404.
- `items/{id}` → `{id, name, class, classId, subclass, subclassId, quality, itemLevel, requiredLevel,
  effects[{spellId, text, trigger}], speculation, speculationReasons, betaEvent, ...}`. Use the effect
  `text` for durations.
- `items?class=` takes the numeric item class: `class=0` is Consumable (1,929 items; subclasses
  Food & Drink, Elixirs, Flasks, Potions, Scrolls, Other, ...). List rows have no `effects`.
  Items 210000–239999 are Season of Discovery leftovers in the client.
- `buffs-nerfs?class=&direction=` → per-build changes `{id, name, type, direction, build, about,
  changes[{field, before, after}]}`. An ability can be renamed in one build and removed later
  (Salvation: renamed in 70425, removed in 70707), so read every entry, not only the newest one.
- Headers: `X-RateLimit-Limit/Remaining/Reset`, `X-Daily-Limit/Remaining`.

## Checking the buff database

```sh
lua .agents/foreverdb/dump_buffs.lua > .agents/foreverdb/out/buffs-forever.json
python .agents/foreverdb/verify_buffs.py     # ~1,000 requests on a cold cache, ~17 min
```

`dump_buffs.lua` loads `Src/Knowledge` on a Forever fixture for every class and race (as
`Tests/ForeverKnowledgeTest.lua` does) and prints each buff's spell and item IDs, durations and
classes. `verify_buffs.py` writes `out/verify-buffs.txt`: class buff ranks against ForeverDB class
lists, unused abilities that read like long buffs, each consumable item's existence, level, use spell
and duration, and Forever consumables Buffomat does not list. The report needs a human read: the
duration parser works on tooltip text.

## Limits

- The API response shapes are not fully documented; see above and `foreverdb-data.json`.
- The offline `selftest` covers rate limiting, caching, missing keys and the output files.
