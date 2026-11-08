# ForeverDB client

`foreverdb.py` reads WoW: Forever data from [ForeverDB](https://foreverdb.net) and writes it to
`out/`, where agents read it. Python 3.9+ standard library only.

## Permission and terms

- ForeverDB's `robots.txt` welcomes AI assistants (`ClaudeBot`, `Claude-User`, ...) and says its
  crawler rules do not restrict apps and tools. Agents may run this tool.
- The API (`https://foreverdb.net/api/v1`) needs a key. Request one on
  https://foreverdb.net/developers (Battle.net login; say what you build, give an email, agree to
  credit ForeverDB). Then either set `FOREVERDB_API_KEY` or write the key into
  `.agents/foreverdb/.apikey` (git-ignored).
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

## Limits

- The API response shapes are not fully documented. `summary.txt` prints any shape generically;
  read `foreverdb-data.json` for the full response.
- Not yet tested against the live API: there was no key when this was written. The offline
  `selftest` covers rate limiting, caching, missing keys and the output files.
