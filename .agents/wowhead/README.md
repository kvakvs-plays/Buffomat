# Wowhead lookup tool

> **DEPRECATED, marked for deletion (2026-11-08).** Wowhead answers this client with HTTP 403
> on content pages, even though robots.txt allows them, so the tool cannot fetch anything. Do not
> work around the block. Use [`../foreverdb/`](../foreverdb/README.md) instead. Delete this folder
> once nothing refers to it.

`wowhead.py` fetches a list of spells and items from Wowhead and writes the results to
`out/`, where an agent can read them. Python 3.9+ standard library only.

## Who runs it

**You run it, not an AI agent.** Wowhead's `robots.txt` disallows Anthropic's agents
(`ClaudeBot`, `anthropic-ai`, `Claude-Web`) for the whole site. The tool refuses network commands
when `CLAUDECODE` or `AI_AGENT` is set, which Claude Code sets in its shells. Run it in a normal
terminal. Read Wowhead's Terms of Use first; you are responsible for how you use it.

Agents: ask the user to run it, then read `out/summary.txt` (and `out/wowhead-data.json` for
details). Do not run it and do not work around the guard.

## What it does to be polite

- Sends an honest User-Agent: `BuffomatClassic-research/1.0 (+https://github.com/kvakvs-plays/Buffomat)`.
  Add your contact with `--contact you@example.com`.
- Reads `robots.txt` of each host and skips disallowed URLs, using the rules for its own
  User-Agent (wildcards and `$` supported). Honours `Crawl-delay`.
- Waits at least 2 seconds between requests (default 3), and stops after 300 requests (`--max-requests`).
- Caches every response in `.cache/` for 7 days, so re-running a batch costs nothing.
  `--refresh` ignores the cache.
- Stops the whole run on HTTP 403 and after repeated 429/503 (it honours `Retry-After`).

## Commands

Global options go **before** the command.

```sh
# The open questions from ../wowf-plan.md (about 22 requests)
python .agents/wowhead/wowhead.py batch .agents/wowhead/verify-forever.txt

# Single lookups
python .agents/wowhead/wowhead.py page spell 2651 1328548   # page: tooltip, dataEnv, Listview tables
python .agents/wowhead/wowhead.py xml 274273 250337         # item XML feed (items only)
python .agents/wowhead/wowhead.py --data-env 18 tooltip spell 2651   # tooltip JSON from nether.wowhead.com

# Another game version
python .agents/wowhead/wowhead.py --flavor classic page spell 2651

# Offline self-test (no network; allowed for agents)
python .agents/wowhead/wowhead.py selftest
```

| Command | URL | Gives |
|---------|-----|-------|
| `page TYPE ID...` | `www.wowhead.com/<flavor>/<type>=<id>` | Title, tooltip text, the `dataEnv` number, and every Listview table (taught by, sold by, created by, reagent for, ...) |
| `xml ID...` | `www.wowhead.com/<flavor>/item=<id>&xml` | Name, level, quality, class/subclass, tooltip text, recipe and reagents |
| `tooltip TYPE ID...` | `nether.wowhead.com/tooltip/<type>/<id>?dataEnv=N` | Name, quality, icon, tooltip text. Needs `--data-env` |
| `batch FILE` | any of the above | One job per line: `<tooltip\|xml\|page> <type> <id>  # note` |

`TYPE` is one of `spell`, `item`, `npc`, `object`, `quest`, `faction`, `zone`.

The Forever `dataEnv` number is not known in advance. Run one `page` command and read `dataEnv`
in the summary, then pass it to `tooltip`. `page` already includes the tooltip text, so `tooltip`
is rarely needed.

## Output

Default folder `.agents/wowhead/out/` (`--out-dir` to change). It is git-ignored.

| File | Content |
|------|---------|
| `runs/<timestamp>-<command>.jsonl` | Raw records of one run, one JSON object per line |
| `wowhead-data.json` | Newest record for each `(command, type, id)` across all runs, keyed `"page spell 2651"` |
| `summary.txt` | Short text for every record: tooltip lines, Listview names, recipe, errors |

Each record has `cmd`, `type`, `id`, `note`, `url`, `status`, `cached`, `fetched`, and `data` or `error`.

## Limits

- The page and XML parsers were tested only against sample data written from the known Wowhead
  format, not against live pages. If Wowhead changes its markup, a Listview may show
  `unparsed data` (the raw text is kept in `data_raw`), or the tooltip may be missing. Send the
  `runs/*.jsonl` file and the parser can be fixed offline.
- The XML feed exists for items only. Use `page` for spells and NPCs.
