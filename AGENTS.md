# Codex Instructions for BuffomatClassic

## Project Context

- This repository contains Buffomat, a Lua addon for World of Warcraft Classic.
- The addon is written in Lua with type specs. Specify types wherever they can be known.
- Suggest documentation comments for functions and parameters when adding or changing public or non-obvious functions.
- Use Ace3 libraries where possible for user interface, addon state, options windows, game events, timers, console integration, and the minimap icon.
- Supported clients include Classic Era / Anniversary, The Burning Crusade Classic, Wrath of the Lich King Classic, and Cataclysm Classic. Do not assume Retail-only APIs exist.

## Required Reference Files

- Read `.claude/addon-dev.md` before making non-trivial Lua addon changes.
- Use `.claude/code-index.md` to find relevant modules and functions before broad code searches.
- The downloaded Blizzard UI source is available at `F:\Projects\WowAddons\BlizzardInterfaceCode\` and should be used when checking WoW UI behavior or API details.

## WoW Group And Buff Semantics

- A World of Warcraft party has up to 5 players.
- A raid contains up to 8 parties, for a maximum of 40 players.
- "Group Buffs" are mass versions of regular single-target buffs. They apply to the target player's party.
- Paladin mass buffs are different: they apply to all players of the targeted class. For example, mass buffing a warrior blesses all warriors.

## Target Runtime

- Target clients: WoW Classic Anniversary / Era 1.15.x and The Burning Crusade Classic 2.5.x, with existing support for WotLK and Cataclysm Classic flavors.
- Lua runtime: Lua 5.1 plus WoW additions.
- Do not use `goto`, `bit32`, or integer division `//`.
- The WoW `bit` library is available.

## Client And API Versioning

- Use separate TOC files for flavors:
  - `BuffomatClassic.toc`
  - `BuffomatClassic-Classic.toc`
  - `BuffomatClassic-BCC.toc`
  - `BuffomatClassic-WOTLKC.toc`
  - `BuffomatClassic-Cata.toc`
- Detect flavor at runtime with `WOW_PROJECT_ID` and the project constants.
- Never assume Retail APIs exist. Check for globals or namespaces such as `_G["C_Spell"]`, `C_Timer`, and `GetSpellInfo` before use.
- Spell IDs can differ by flavor. Do not hardcode spell IDs without verifying them for the target flavor.

## Combat Lockdown And Taint

- Protected functions cannot be called while `InCombatLockdown()` is true.
- Do not call protected frame show/hide, `SetAttribute`, `RegisterUnitWatch`, action button reassignment, macro edits, or secure frame parent changes in combat.
- Defer risky setup to `PLAYER_REGEN_ENABLED` when needed.
- Avoid tainting Blizzard frames. Prefer `hooksecurefunc` for post-hooks when hooking is necessary.

## Event Handling

- Prefer one frame per addon for events and dispatch by event name.
- Use `COMBAT_LOG_EVENT_UNFILTERED` with `CombatLogGetCurrentEventInfo()`.
- Prefer `RegisterUnitEvent` for unit events when the relevant unit set is known.
- Unregister events that are no longer needed.
- Avoid `OnUpdate` unless throttled.

## Performance Rules

- Throttle `OnUpdate` work with an accumulator.
- Avoid table allocation in hot paths such as combat log handlers and `OnUpdate`; reuse tables and `wipe(t)`.
- Cache frequently used globals as locals at chunk top.
- Avoid string concatenation in hot loops; prefer prebuilt strings or `table.concat`.
- Avoid `pairs` over large tables every frame.

## Saved Variables

- Declare saved variables in TOC metadata.
- Saved variable globals are populated after `ADDON_LOADED`; do not read them at file scope.
- Migrate saved variable schemas by version field. Do not silently overwrite user data.

## Frame And XML Conventions

- Name frames only when external code needs `_G["FrameName"]` access.
- Use templates such as `UIPanelButtonTemplate` and `BackdropTemplate` as appropriate. TBC 2.5.x requires explicit `BackdropTemplate` for backdrop support.
- Do not use `TOOLTIP` strata for normal UI.

## Library Usage

- Access libraries through LibStub, for example `local AceGUI = LibStub("AceGUI-3.0")`.
- Prefer libraries known to support Classic Era and TBC Classic, including Ace3, LibSharedMedia-3.0, LibDataBroker-1.1, LibDBIcon-1.0, and CallbackHandler-1.0.
- Embed libraries unless the TOC explicitly declares dependencies or optional dependencies.

## Lua Style

- Local by default.
- Start Lua files with `local addonName, ns = ...` when adding new files that follow the addon pattern.
- Export through `ns`; avoid globals unless required for external addon integration.
- Use 2-space indentation and no tabs in Lua.
- Use standard function signature spacing: `function foo(a, b, c)`.
- Comments should explain non-obvious why: combat lockdown workarounds, version quirks, taint avoidance, or tricky compatibility behavior.

## Build And Repo Notes

- `wowaddon.py` is the Python build/install tool. It writes flavor TOCs, installs addon files, and builds release zips.
- `toc_template.toc` is the authoritative load-order template for generated TOC files.
- When adding a module, update `Src/EarlyBoot.lua` and ensure the module is included in the TOC load order.
