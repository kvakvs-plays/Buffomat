# Luacheck fixing plan

Baseline taken 2026-10-19 on branch `feature/wowforever`, luacheck 1.2.0, run over `Src` and `Tests`
(74 files; `Ace3/`, `references/`, `codex-references/` are third-party and not linted).

**2546 warnings, 0 errors.** Most of the noise comes from `.luacheckrc`, not the code. After the
config fix (Phase 1) about 490 warnings remain. Among them are a handful of real bugs (Phase 0).

## Status (2026-10-19): done, 0 warnings in 71 files

All phases are complete and the tests pass. Item 8 is restored as well. What was done beyond the
plan below:

- Config: `ignore` covers `_`-prefixed unused values (the repo's existing convention), the
  `addonName, ns` file header, and W542 (commented empty branches in elseif chains are deliberate).
  `max_comment_line_length = false`: `---@alias` and `---@type` lines and aligned data comments
  cannot be wrapped usefully.
- Phase 2: deleted dead imports (`local BuffomatAddon = BuffomatAddon` in 17 files, unused
  `buffomatModule` in 5), the unused `bom_gpiprivat_event_handler`, and other dead locals. Remaining
  unused loop variables became `_`. Unused locals and arguments were prefixed with `_` by a script
  that renames at luacheck's exact columns and keeps `---@param` names in sync.
- Phase 3:
  - Removed the `else` branches that held only commented-out code (ItemCache, ActionCast).
  - Renamed the KvOptions `_t` parameter to `translate`.
  - Deleted the class tables in CharacterSettings and SharedSettings, which were never attached.
  - Fixed `not (x == 1)`.
  - The disabled TBC potion block in Elixirs is kept inside `-- luacheck: push ignore 511` / `pop`.
- Phase 4: the lint rule and the run command are in the root `AGENTS.md`. `CHECKLIST.md` is a
  feature TODO list, so the rule went to `AGENTS.md` instead.

## How to run

There is no Windows launcher; run the luarocks script through `lua` with the module path set:

```powershell
$env:LUA_PATH = "$env:APPDATA\luarocks\share\lua\5.4\?.lua;$env:APPDATA\luarocks\share\lua\5.4\?\init.lua;;"
$env:LUA_CPATH = "$env:APPDATA\luarocks\lib\lua\5.4\?.dll;;"
lua "$env:APPDATA\luarocks\bin\luacheck" Src Tests --codes
```

## Baseline breakdown

| Code | Count | Meaning | Main cause |
|---|---:|---|---|
| W113 | 1695 | undefined global | `.luacheckrc` sets `std = { globals = ... }`, which **replaces** the standard library, so `pairs`, `table`, `string` are "undefined" too. 221 distinct names, almost all WoW API. |
| W212 | 346 | unused argument | 233 are `self` in `function module:Method()`; 41 are `enchantments` in Knowledge setup functions; 12 `info` in option callbacks |
| W631 | 156 | line > 120 | Language files (66), `AllConsumesFood.lua` aligned trailing comments (44) |
| W211 | 115 | unused local | Mostly unpacked API returns (`GetInstanceInfo`, `GetWeaponEnchantInfo`...). TaskScan 34, Events 12, GroupBuffTarget 10, Party 8 |
| W213 | 88 | unused loop variable | `for i, x in ipairs` where `i` is unused; 35 already use `_name` style |
| W314 | 62 | field overwritten | **All in `LegacyToolbox.lua` — real bug, see Phase 0** |
| W112/W111 | 46 | setting/mutating globals | Saved variables, bindings, `SlashCmdList`; plus one leak `popupDepth` |
| other | 38 | W542 empty if (11), W231 (8), W214 (6), W511 (4), W311 (4), W241 (2), W581, W432, W411 | see Phase 3 |

Top files: `TaskScan.lua` 311, `LegacyToolbox.lua` 192, `AllConsumesFood.lua` 121, `Events.lua` 118,
`Buffomat.lua` 111, `KvEnv.lua` 96, `BuffDefinition.lua` 90.

## Phase 0 — real bugs (fix first, one commit each, in game or test-verified)

1. **`Src/Buffomat.lua:127`** — `buffomatModule.OptionsUpdate()` calls `managedUiModule:UpdateAll()`.
   `managedUiModule` is an undefined global (`Src/Deprecated/ManagedUi.lua` is not in the TOC), so
   this throws "attempt to index a nil value". It runs from the popup menu callback
   (`popupModule:CreatePopup(buffomatModule.OptionsUpdate)`, `Buffomat.lua:268`) and from
   `BuffomatAddon.MyButtonOnClick`. Fix: remove the call, or replace it with the current UI refresh.
2. **`Src/Task/TaskScan.lua:130`** — `BuffomatAddon.CancelShapeShift()` passes global
   `ShapeShiftTravel`, which is nil. The list `{2645, 783}` (Ghost Wolf, Travel Form) is a *local*
   in `Src/Knowledge/AllBuffs.lua:419` and unused there. Cancelling travel forms never works.
   Fix: move the list to `SpellIdsModule` (or export it on `allBuffsModule`) and use it in TaskScan.
3. **`Src/Task/TaskScan.lua:952`** — `AddResurrection` calls `:LinkToBuffDef(buffDef)`; the
   parameter is named `spell`, so `buffDef` is an undefined global and resurrection tasks are never
   linked to their buff definition. Fix: `:LinkToBuffDef(spell)`.
4. **`Src/Toolbox/LegacyToolbox.lua:27`** — every key of `bom_special_letter_to_ascii` is `"\239\191\189"`
   (U+FFFD replacement character). The file was mis-encoded before the earliest commit in history,
   so all 63 entries collapse into one and accent folding for sorting is broken. Fix: rebuild the
   keys from the Latin-1 letters. The value order (`A, A, A, A, Ae, ...`) shows which letter each
   line was (`À Á Â Ã Ä ...`). Add a small test for the sort helper.
5. **`Src/Toolbox/Popup.lua:74`** — `popupDepth = nil` writes a global. Make it a file-level local or
   a field on the popup.
6. **Investigate** `TaskScan.lua:619` (`AddBlessing`) and `:866` (`AddBuff`): `ok, bag, slot` from
   `HasItem(buffDef.reagentRequired)` are never read, and the formatted reagent `count` string is
   built and then discarded. Either the "missing reagent" handling and the reagent count text were
   lost in a refactor, or this is dead code. Decide which, then restore or delete it.
7. Cosmetic: `Src/Knowledge/AllConsumesFood.lua:413` redeclares `hasteFoodAuras` for the hit food
   group. Rename it to `hitFoodAuras` (no behavior change).

Outcome:
- 1 (removed the call), 2 (`spellIdsModule.TravelShapeshiftForms`), 3, and 5 (the global was never
  read, so the line was deleted) are fixed.
- 4: keys rebuilt from Latin-1 (`À`..`Þ`, `ß`, `à`..`ÿ`). The early `ß = "s"` entry was overridden
  by the later `"ss"` one, so only `ß = "ss"` is kept. `stripChars` has no callers, so users were
  never affected.
- 6: history shows `ok, bag, slot` were never used, even in 2021. The `" xN"` reagent count was
  appended to group buff texts until the 2025 task refactor. Restored as
  `taskScanModule:FormatReagentCount` in each group task's extra text; the dead locals are removed.
- 7: renaming exposed a **real bug**. The WotLK hit food group was built from `hasteFoodItemIds`
  and `hitFoodItemIds` was unused. Now fixed.
- **New item 8 (open):** `TaskScan.lua` `AddBlessing` (`local add`) and `AddBuff_SingleBuff` build a
  target icon (`ICON_TARGET_ON`) for players with a forced or blessing-assigned target, then never
  display it. This is the same refactor loss as item 6. Restore it as extra text on the single-buff
  tasks, or delete it.
- Left alone (unfinished data, not bugs): `AllConsumesElixirs.lua` `intItemIds`/`intAuras` (an
  intellect elixir group that was never created) and `AllConsumesFood.lua` `comboFoodItemIds` (TODO
  in the code: auras for Cata feasts unknown).

## Phase 1 — fix `.luacheckrc` (single commit, no code changes)

Draft (the global list is generated, see below):

```lua
std = "lua51"
max_line_length = 120
self = false -- `function module:Method()` without using self is normal here
exclude_files = { "Ace3/**", "references/**", "codex-references/**", "Src/Deprecated/**" }

-- Written by the addon: saved variables, key binding labels, slash commands
globals = {
  "BomModuleManager", "BUFFOMAT_ADDON", "BuffomatAddon", "BuffomatShared", "BuffomatCharacter",
  "BINDING_HEADER_BUFFOMATHEADER", "BINDING_NAME_BUFFOMAT_WINDOW", "SlashCmdList", "_G",
}

-- WoW API, FrameXML globals, and Lua extensions provided by the client
read_globals = { "bit", "wipe", "tContains", "tinsert", "LibStub", "CreateFrame", --[[ ... ]] }

files["Src/Languages/**"] = { max_line_length = false }
files["Src/Knowledge/**"] = { ignore = { "212/enchantments" } } -- shared setup signature
files["Tests/**"] = { read_globals = { "setfenv", "loadfile" } }
```

- Generate `read_globals` from the W113 names in the baseline. Do **not** whitelist
  `managedUiModule`, `uiButtonModule`, `ShapeShiftTravel`, `buffDef`, or `parent`; these are the bugs
  from Phase 0 (or Deprecated-only code).
- `Src/Deprecated/` is not in `toc_template.toc`; exclude it from lint (or delete the folder in a
  separate commit if it is no longer useful as reference).
- Option callbacks with an unused `info` argument: add `ignore = { "212/info" }` to the options files.
- A dry run of this config gives about 536 warnings (46 of them in `Src/Deprecated`, so about 490
  after the exclusion).

## Phase 2 — mechanical cleanup (per file or folder, no behavior change)

Do these one folder at a time so diffs stay reviewable. Run the tests (`lua Tests/*.lua`) after each.

- **W213 unused loop variables (88):** rename to `_` (`for _, member in pairs(...)`).
- **W211 unused locals (115):** for unpacked API returns, drop the trailing names or use `_`. For
  example, `local name, instanceType, ... = GetInstanceInfo()` becomes `local _, _, _, _, _, _, _, instanceID = ...`
  or `select(8, GetInstanceInfo())`. Delete truly dead locals. Start with `TaskScan.lua`, `Events.lua`,
  `GroupBuffTarget.lua`, `Party.lua`.
- **W212 remaining unused arguments (~70 after config):** `buffCtx` (8), `context` (4), `state`,
  `eventType`, `mouseButton`... Prefix with `_` only where the signature must stay (callbacks, shared
  dispatch); otherwise remove the parameter and update callers.
- **W631 long lines (90 after language exemption):** `AllConsumesFood.lua` (44) has aligned trailing
  comments; move each comment above its line. Fix the rest (`BuffDefinition.lua` 7, `SpellIds.lua` 4,
  `Buffomat.lua` 4, ...) by wrapping.

## Phase 3 — small logic warnings (review each)

- **W542 empty if branch (10 live):** `BuffChecks.lua:256`, `Cache/ItemCache.lua:120`, `Events.lua:218`,
  `Task/ActionCast.lua:50`, `TaskScan.lua:190`, `:707`, `:832`, `:1538`. Most are "do nothing" branches
  with a comment; invert the condition, or keep them and add `-- luacheck: ignore 542` with the reason.
- **W241** `CharacterSettings.lua:37` `characterStateClass`, `SharedSettings.lua:89` `sharedStateClass`:
  class tables filled in but never used (no `setmetatable`). Either attach them or delete them.
- **W214** `KvLib/KvOptions.lua` (6): parameter `_t` is used; rename it (e.g. `translate`) so the
  underscore does not claim it is unused.
- **W511** `Knowledge/AllConsumesElixirs.lua:397`: `if false then` block of TBC potions. Delete it or
  keep it with a comment and an inline ignore.
- **W581** `TaskScan.lua:314`: `not (x == y)` → `x ~= y`.

## Phase 4 — keep it clean

- Add the luacheck command to `CHECKLIST.md` (pre-release) next to the tests.
- Target: 0 warnings for `Src` and `Tests` with the committed `.luacheckrc`. Any remaining intentional
  case gets an inline `-- luacheck: ignore <code>` with a reason.
- New or edited files should lint clean before commit.

## Suggested order

Phase 0 bugs 1–3 and 5 are small, so do them first. Then Phase 1 (config) gives a readable warning list
for the rest. Bug 4 (accent table) and the investigation in 6 can go after that. Phases 2–3 are
opportunistic, one file group per commit.
