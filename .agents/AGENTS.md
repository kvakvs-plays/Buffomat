# Buffomat Lua addon for World of Warcraft

- The addon is written in Lua with type specs.
- Always specify types where types can be known.
- Suggest documentation comments for functions and parameters with summary for that function.
- The group in World of Warcraft consists of parties, each party fits max 5 players or fewer. A raid contains multiple parties up to 8 5man groups, or 40 players.
- Important distinction:

  - "Group Buffs" are mass buffs, a special type of regular single-target buffs, they apply to a party of players. Mass buffing a person in a party will buff all players in that party.
  - On the contrary: Paladin mass buffs apply to all players of targeted class (for example mass buffing a warrior will bless all warriors).

- This addon supports Classic World of Warcraft from the vanilla up to Wrath of the Lich King. The code uses Ace3 libraries where possible: For user interface, for addon state management, for option windows, game event management, timer management and minimap icon.

# Important

* The source for WoW UI is conveniently downloaded from the game files and is located at     `F:\Projects\WowAddons\BlizzardInterfaceCode\`
* Use skill `s-research` on questions related to wow and Lua programming topics.

Always read `.agents/addon-dev.md`
When need to search for code locations, consult with `.agents/code-index.md`

# Game data sources

* Do not fetch Wowhead; its robots.txt disallows Anthropic agents and it answers scripts with 403.
  `.agents/wowhead/` is deprecated and marked for deletion.
* For Forever trainer lists, talents, consumables and spell details use ForeverDB, which welcomes
  AI assistants: `.agents/foreverdb/foreverdb.py`, then read `.agents/foreverdb/out/summary.txt`.
  The API key is `FOREVERDB_API_KEY` in the git-ignored repository `.env`; the client reads it from
  there. Never print or commit the key. Limits: 60 requests a minute, 10,000 a day.
  Request counts per minute for the last 24 hours are kept in the git-ignored
  `.agents/foreverdb/usage-24h.log` (`YYYY-MM-DD HH:MM<TAB>count`); run
  `python .agents/foreverdb/foreverdb.py usage` before a large query to see how many are left.
  To check the Forever buff database, run `.agents/foreverdb/dump_buffs.lua` and
  `.agents/foreverdb/verify_buffs.py` (see `.agents/foreverdb/README.md`).
  Credit "Data from ForeverDB.net" with a link to https://foreverdb.net (README credits and the
  options About box already do); its addon data is GPL-3.0, so never copy it into `Src/`.
* For raw game data (spells, items, talents) use wago.tools DB2 CSV exports through
  `.agents/wowf-scan/scripts/fetch.py`; see `.agents/wowf-scan/README.md`.
