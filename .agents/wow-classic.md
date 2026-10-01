# WoW Addon & WeakAuras Project Rules

Target clients: **WoW Classic Anniversary** (1.15.x) and **The Burning Crusade Classic** (2.5.x).
Lua runtime: **Lua 5.1** + WoW additions (`bit` library, no `goto`, no `bit32`, no integer division `//`).

---

## Client / API Versioning

- TOC interface numbers:
  - Classic Era / Anniversary 1.15.x → `11506` (bump per patch).
  - TBC Classic 2.5.x → `20504`.
- Use **separate TOC files** for each flavor when supporting both:
  - `MyAddon.toc` (mainline / fallback)
  - `MyAddon-Classic.toc` (Anniversary / Era)
  - `MyAddon-BCC.toc` (TBC Classic)
- Detect flavor at runtime with `WOW_PROJECT_ID`:
  ```lua
  local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
  local isBCC     = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
  ```
- **Never** assume retail APIs exist. Check `_G["C_Spell"]`, `C_Timer`, `GetSpellInfo`, etc. before use. TBC 2.5.x has `C_Timer.After`; Era usually does too — but old Era builds did not.
- Spell IDs differ between Era and TBC; never hardcode an ID without verifying for the target flavor. Prefer name-based lookup via `GetSpellInfo(spellID)` then compare.

---

## Forbidden / Risky APIs in Combat

The "combat lockdown" rule: protected functions cannot be called while `InCombatLockdown()` is true.

- Do **not** call in combat: `frame:Show/Hide` on protected frames, `SetAttribute`, `:RegisterUnitWatch`, action button reassignment, macro edits, frame parent changes on secure frames.
- Wrap risky setup in `PLAYER_REGEN_ENABLED` deferral:
  ```lua
  if InCombatLockdown() then
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(self) self:UnregisterEvent("PLAYER_REGEN_ENABLED"); doSetup() end)
  else
    doSetup()
  end
  ```
- Never taint Blizzard frames. Avoid hooking `UIParent`, action bars, or unit frames with non-secure code that later gets called from a protected path. If you must hook, use `hooksecurefunc` (post-hook, never modifies return).

---

## Event Handling

- Prefer one frame per addon for events; dispatch by event name:
  ```lua
  local f = CreateFrame("Frame")
  f:SetScript("OnEvent", function(self, event, ...) ns[event](ns, ...) end)
  f:RegisterEvent("PLAYER_LOGIN")
  ```
- Combat log: use `COMBAT_LOG_EVENT_UNFILTERED` + `CombatLogGetCurrentEventInfo()` (no payload args — exists in both 1.15 and 2.5).
- Unit events: register with `RegisterUnitEvent("UNIT_AURA", "player", "target")` to skip irrelevant unit firings.
- Unregister events you no longer need. `OnUpdate` is the most expensive script — avoid unless throttled.

---

## Performance Rules

- **Throttle `OnUpdate`** with an accumulator:
  ```lua
  local acc = 0
  frame:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.1 then return end
    acc = 0
    -- work
  end)
  ```
- No table allocation in hot paths (combat log, OnUpdate). Reuse tables, `wipe(t)` instead of `t = {}`.
- Cache global lookups as locals at chunk top: `local UnitAura, GetTime = UnitAura, GetTime`.
- String concatenation with `..` in hot loops → use `table.concat` or pre-format.
- Avoid `pairs` over large tables every frame; index by integer when possible.

---

## Saved Variables

- Declare in TOC: `## SavedVariables: MyAddonDB` (account) / `## SavedVariablesPerCharacter: MyAddonCharDB`.
- Globals only become populated **after `ADDON_LOADED`** for your addon. Do not read them at file-scope:
  ```lua
  if event == "ADDON_LOADED" and arg1 == addonName then
    MyAddonDB = MyAddonDB or { version = 1 }
  end
  ```
- Migrate schema by version field; never silently overwrite user data.

---

## Frame & XML Conventions

- Name frames only when external code needs `_G["FrameName"]` access. Anonymous frames are cheaper and safer.
- Inheritance: use templates (`UIPanelButtonTemplate`, `BackdropTemplate` — TBC 2.5.x **requires** explicit `BackdropTemplate` mixin since Shadowlands-era backdrop changes were backported).
- Strata: `BACKGROUND < LOW < MEDIUM < HIGH < DIALOG < FULLSCREEN < FULLSCREEN_DIALOG < TOOLTIP`. Don't use TOOLTIP for normal UI.

---

## WeakAuras 2 Custom Code Rules

WeakAuras runs custom Lua inside `aura_env`, a per-aura sandbox.

- **Always use `aura_env`** for state, not globals. Persistent across loads of the same aura:
  ```lua
  aura_env.cache = aura_env.cache or {}
  ```
- Custom triggers come in two flavors:
  - **Event-based**: return `true` to show, `false` to hide. Fast, simple.
  - **Trigger State Updater (TSU)**: receives `allstates`; mutate it and return `true`. Required for multi-instance auras (one per enemy, one per buff stack).
- TSU minimal pattern:
  ```lua
  function(allstates, event, ...)
    allstates[""] = allstates[""] or { show = true, changed = true }
    local s = allstates[""]
    s.changed = true
    s.progressType = "timed"
    s.duration = 10
    s.expirationTime = GetTime() + 10
    return true
  end
  ```
- Custom variables: declare them in the trigger's "Custom Variables" section so conditions/actions can read them. Untyped vars silently fail in conditions.
- Subscribe to the **minimum** event set. `COMBAT_LOG_EVENT_UNFILTERED` fires constantly — filter by `subevent` and `sourceGUID == UnitGUID("player")` early.
- Custom Init: runs once on load, ideal for setting up `aura_env.cache`, precompiled spell lists, etc.
- Don't `print()` in shipped auras. Use `WeakAuras.prettyPrint` or remove debug output.
- Animations and sounds in actions, not triggers — keep trigger code pure.

---

## Library Usage

- Libraries via **LibStub**: `local AceGUI = LibStub("AceGUI-3.0")`.
- For Era + TBC compat, prefer libraries known to support both: Ace3, LibSharedMedia-3.0, LibDataBroker-1.1, LibDBIcon-1.0, CallbackHandler-1.0.
- Embed libraries; never assume the user has them as standalone addons unless declaring `## Dependencies:` or `## OptionalDeps:` in TOC.

---

## Style

- Local-by-default. File-scope `local addonName, ns = ...` at top of every Lua file; export via `ns`, never via globals unless an external addon must consume.
- 2-space indent. No tabs in Lua (mismatched tab/space breaks WoW's error display column numbers).
- Function signatures: comma-space, no padding parens. `function foo(a, b, c)` not `function foo( a,b,c )`.
- Comments only where the *why* is non-obvious (combat lockdown workaround, version-specific quirk, taint avoidance). Don't restate code.
