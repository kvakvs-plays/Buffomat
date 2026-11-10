# Scan rewrite plan: scanning loop, readers and timers

Written 2026-11-10 against `master` at `ff28161` (version 2026.11.2). Status: **steps 0 to 9 are
implemented on branch `feature/scan-rewrite`; nothing has been run in a game client yet.** See the next
section before relying on anything below.

This plan replaces how Buffomat reads the game state (group roster, unit auras, bags, player state)
and when it decides to scan. The old code is replaced, not wrapped. Supported clients stay the same:
Classic Era / Anniversary, TBC Classic, WotLK Classic, Cataclysm Classic and WoW: Forever. Retail is
not a target; section 9 lists what would have to be researched first.

Terms used below:

- **Reader**: a module that calls WoW APIs and stores the result in a snapshot table.
- **Snapshot**: plain Lua tables holding the last read state. Evaluation reads only snapshots.
- **Domain**: one independently invalidated piece of state (`roster`, `auras`, `bags`, ...).
- **Pass**: one run of the scan pipeline: read dirty domains, evaluate, build tasks, present.
- **Aura-free mode**: the existing PvP-match mode where auras are secret but bags, weapon enchants
  and tracking are readable (`TaskScan:DoAuraFreeScan`).

## Status (2026-11-10)

Steps 0 to 9 are implemented, one commit per step ("Scan step N"). Step 10 is not: it depends on
measurements. Everything was checked with luacheck (0 warnings) and the tests in `Tests/`, which run
the real modules on a fake client (`Tests/ScanFixture.lua`). **None of it has been run in WoW.**

Still to do, all of it in game:

- Step 0.2 and 9.4: the measurements. Turn on `BuffomatShared.DebugLogging`, run `/bom scanstats`
  twice a minute apart, and record passes per minute, ms per pass, aura reads and evaluations for:
  solo idle, 5-man idle, 40-man idle, 40-man during buffing. There is no baseline of the old code;
  to take one, check out the "Scan step 0" commit, which has the counters on the old loop.
- The per-client checks at the end of section 7.
- A smoke test on each client: solo, 5-man, raid; a paladin with class blessings; a PvP match and a
  dungeon boss on Forever.

Where the implementation differs from the plan below, this list is right:

- **KvLib.** Every release-dependent API the scan uses is wrapped in `Src/KvLib/`: `KvUnit.lua`
  (units, group, auras, distance), `KvPlayer.lua` (player state and the few actions), `KvEvents.lua`
  (event registration), and additions to `KvEnv.lua`. `ReadAura` is in `KvUnit`, not `KvEnv`.
  luacheck gives `Src/Scan/`, `Src/Task/`, `BuffChecks.lua` and the unit and target classes a
  restricted standard (`stds.scan` in `.luacheckrc`), so a raw WoW API call there is a lint warning.
- **No Throttle shim.** The call sites were converted to `MarkAllDirty` / `Request` in step 1.
- **Events.** All scan events go through one `KvEventDispatcher` frame, not AceEvent, so that an
  event name a client does not have is refused in one place. `BAG_UPDATE` and `BAG_UPDATE_DELAYED`
  are both taken where valid; a burst still makes one pass. `MODIFIER_STATE_CHANGED` is always
  registered, because Alt also means "try again". `UNIT_AURA` is unregistered during combat.
  Added: `UNIT_FACTION` (PvP flag), `UPDATE_STEALTH`, `PLAYER_CONTROL_LOST` / `GAINED` (taxi),
  `ZONE_CHANGED_INDOORS`, `PLAYER_MOUNT_DISPLAY_CHANGED`.
- **`updateInfo`.** Aura instance ids are not tracked, so the only update that can be skipped is one
  which added harmful auras and nothing else (`KvUnit.AuraUpdateTouchesBuffs`).
- **Range.** `RangeScan:Distance(unit)` measures on demand, once per pass. There is no "distance
  bucket" check; instead the task list window is redrawn only when its lines changed
  (`TaskList:Display`), which was the expensive part. The range tick does not stop when the window is
  hidden, because the macro and its key binding work without the window.
- **Evaluation waits for the read queue.** While units are still queued for an aura read, the pass
  returns "continue" and does not evaluate: a half-read raid would show tasks for buffs which are
  only unread.
- **Timers.** The resync also marks `status` (a member's zone has no event). The dead watch, resync
  and range timers are cancelled while Buffomat is paused (resting, mounted, casting and so on).
- **Weapon enchants** are no longer copied into the player's `knownBuffs`; nothing read them there.
  `player.mainhandEnchantment` / `offhandEnchantment` remain, filled by `PlayerStateScan`.
- **Bag cooldowns** are read lazily, when a check asks about an item, once per cooldown change.
  No registry of "tracked" items is needed.
- **Roster.** Raid pets are not scanned, as before. The target outside the group keeps group 1.
  Toggling the BuffTarget option rebuilds the roster.
- **Modules.** Step 8 added `ScanResult.lua`, `ScanEvaluate.lua` and `ScanEffects.lua`.
  `TaskScan.lua` became `Src/Task/TaskBuilder.lua`; `Core/Party.lua` is gone.
- **Removed as dead code:** `WhisperExpired` (the flag it tested was never set) and
  `BuffomatAddon.lastAura`. `SomeoneIsDrinking` is kept but, as before, nothing calls it.

After step 9 the new code was reviewed against the Blizzard UI source and Ace3. What that changed:

- **An error in a pass** is caught (`envModule.SafeCall`), reported to the client's error handler,
  and the pass is run again after `ERROR_RETRY` (5 s). Before, it left `inPass` set and scanning
  stopped until a reload.
- **Mana** is read at the start of every evaluation (`PlayerStateScan:ReadMana`), not only when the
  `player` domain is dirty: it regenerates without an event the scan listens to.
- **Settings.** Every option (`Options.lua` templates) and every choice in the spells dialog calls
  `Request`. The old loop picked such changes up by rescanning all the time.
- **State without an event.** The macro frame's `OnShow` / `OnHide` are hooked (`Src/Events.lua`).
  `MINIMAP_UPDATE_ZOOM` marks `player` (walking indoors or outdoors). Where flying exists, a
  mounted player or a druid in flight form is read again every `FLIGHT_WATCH` (2 s), also while
  paused, because taking off and landing send nothing.
- **Roster.** A member whose class the GUID lookup does not know yet gets it from `UnitClass`
  (`KvUnit.GetClass`); `UNIT_NAME_UPDATE` of a member rebuilds the roster.
- **Window.** "Open" is `IsShown`, not `IsVisible`: with the whole interface hidden the window was
  re-opened, and a pass requested, five times a second.
- `UNIT_AURA` is no longer registered again by a roster event during combat.

Defects of the old code fixed on the way:

- An item on cooldown made a full scan run twice a second (relative time in `nextCooldownDue`).
- Rescan requests raised during a scan were lost.
- Showing the window rescanned on every tick while tasks existed; with AutoClose, hiding it did too.
- In a raid the player was listed twice: as `raidN`, and as `player` in subgroup 1.
- A class blessing with enough members to bless looked for its target with `pairs(list.byUnitId)`
  on a plain list, which raises an error.
- A raid-wide group buff, and a class blessing, reported "out of range" in a raid, because the
  target was looked up as raid subgroup 0 or as a subgroup named like the class.

## 1. What is wrong today

All of this was read from the code, not measured in game. Phase 0 adds the counters to measure it.

### Loop and timers

- [Src/Throttle.lua](../Src/Throttle.lua) `UpdateTimer` is an AceTimer repeating every 0.5 s (1.5 s
  with `SlowerHardware`), started in `buffomatModule:ScheduleUpdateTimer`. It polls four things on
  every tick: the profile (every 2 s), `nextCooldownDue`, `checkCooldown`, and the modifier key.
- There is one dirty flag (`taskRescanRequestedBy`). Any reason triggers a full pass: roster rebuild,
  aura reads, bag cooldowns, every buff definition, task list, UI and macro.
- Requests made during a pass are lost. `Throttle:Update` wipes the reasons before the pass, and
  `TaskScan:Finalize` / `ShowInactive` wipe them again after it. So `"mainHandBuffChanged"`,
  `"weaponConsumableBuff"` and `"profileChanged"`, which are raised inside the pass, do nothing.
- `TaskScan:DoScan` only recomputes missing buffs when the reasons table is non-empty. It is
  non-empty only because `Party:RefreshParty` adds `"reloadParty"` on every pass.
- `BuffomatAddon.repeatUpdate` makes a full pass run on every tick while any target is out of range
  or dead. This is the range polling.
- `TaskScan:CheckItemsAndContainers` stores a *relative* time (seconds remaining) into
  `nextCooldownDue`, which is compared as an absolute `GetTime()` value. While any tracked item is
  on cooldown, `"cdDue"` fires on every tick and a full pass runs twice a second.
- `Throttle:FastUpdateTimer` writes a timestamp nobody reads. The slow-hardware auto-throttle is
  commented out.
- Six call sites call `TaskScan:ScanTasks` directly from an event or UI handler (target change,
  options, profile, window show, `/bom update`), bypassing the timer.
- The profile is chosen in three places: `UpdateTimer`, `ScanTasks`, `Precheck`.

### Events

- [Src/Events.lua](../Src/Events.lua) registers `UNIT_AURA`, `UNIT_INVENTORY_CHANGED`,
  `UNIT_POWER_UPDATE` and all `UNIT_SPELLCAST_*` for every unit in the world. `UNIT_AURA` for a
  nameplate or a stranger requests a full pass.
- The Classic combat log handler runs for every raid combat event. Its only effect besides
  `UNIT_DIED` is to stamp `partyModule.unitAurasLastUpdated[name] = GetTime()`. `Unit:UnitAura`
  expects that entry to be a table, so the expiration fallback it feeds never runs. The whole
  combat-log path is dead weight, and Forever has no combat log at all.
- Loading screens are handled by pretending combat started and polling a timeout in the timer.

### Roster

- [Src/Core/Party.lua](../Src/Core/Party.lua) `GetParty` runs every pass: `UnitFullName` for every
  member to validate, then `RefreshParty`.
- `GetRaidMembers` re-reads "invalid group g" as raid indexes `(g-1)*5 .. (g-1)*5+5`. Raid indexes
  are not ordered by subgroup, and the window includes index 0 and overlaps its neighbour. Then
  `GetParty` refreshes auras for members whose real subgroup is `g`. The set of units re-registered
  and the set whose auras are re-read are different sets.
- In a raid only one rotating group has its auras re-read per pass, and a pass only happens on an
  event. A buff that fell off a member of group 5 is seen when the rotation next reaches group 5.
- [Src/Cache/UnitCache.lua](../Src/Cache/UnitCache.lua) `GetUnit` rebuilds the coloured link string
  for every unit on every pass, and allocates a new table for every pet.
- The roster is keyed by name. Names can be secret on Forever, and two cross-realm players can share
  a name once the realm is stripped.

### Auras

- [Src/Core/Unit.lua](../Src/Core/Unit.lua) reads auras through `envModule.GetUnitAura`, which for
  every aura index checks up to four addon restrictions, allocates a 15-field table, and loops over
  it for secret values.
- Per aura it then runs `tContains(allBuffsModule.allSpellIds, spellId)` (linear over every known
  spell id), `tContains(AllDrink, ...)` and `tContains(buffIgnoreAll, ...)`, and allocates a
  `BomUnitBuff`.
- `UpdateBuffs` also computes the distance for every member (up to eight API calls each), whether or
  not anyone needs the distance.

### Bags

- Two independent scanners walk all bags: `ItemListCache:GetItemList` and `BuffChecks:HasOneItem`.
  `HasOneItem` walks every bag slot once per item id per cache miss.
- `GetItemList` tooltip-scans every openable item on each rebuild, and allocates a cooldown table per
  item on every pass.
- On Era and TBC both `BAG_UPDATE` (once per bag) and `BAG_UPDATE_DELAYED` invalidate everything.

### Structure

- Scan state lives in loose fields on `BuffomatAddon`: `nextCooldownDue`, `checkCooldown`,
  `repeatUpdate`, `scanModifierKeyDown`, `wipeCachedItems`, `cachedPlayerBag`, `drinkingPersonCount`,
  `somebodyIsGhost`, `declineHasResurrection`, `isPlayerCasting`, `inLoadingScreen`,
  `loadingScreenTimeOut`.
- Scan results are written onto the buff definitions (`unitsNeedBuff`, `groupsNeedBuff`,
  `groupsHaveDead`, `reminderText`), so the knowledge database is also the scratchpad.
- [Src/Task/TaskScan.lua](../Src/Task/TaskScan.lua) mixes reading, deciding and side effects:
  activating tracking, cancelling buffs, whispering, switching profiles and printing all happen
  inside the pass that is supposed to compute a task list.
- Combat and restriction checks are repeated at every layer (`ScanTasks`, `ForceUpdateBuffs`,
  `GetUnitAura`, `CancelBuff`, `IsActive`).

## 2. Design goals

1. Events mark a domain dirty; they never scan. One scheduler decides when a pass runs.
2. Each domain has one reader and one snapshot. A reader runs only when its domain is dirty.
3. No repeating timer while nothing is pending. Time-based work uses one one-shot deadline timer.
4. Evaluation (who needs what) makes no WoW API calls except a short documented list, so it can be
   unit-tested against fixtures.
5. A raid aura event costs one unit's aura read, not a roster rebuild.
6. Capabilities, not flavors: readers probe for the API they need. `envModule.isForever` is used
   only where content differs.
7. Combat, loading screen and addon restrictions are checked once per pass, in the scheduler gate.
8. No table allocation per aura, per bag slot or per pass in steady state.

Non-goals: changing what Buffomat buffs, the task list UI, the macro or the knowledge database.
Re-evaluating only the buffs affected by a change is also a non-goal: evaluation is table lookups
over at most 40 units and is re-run in full whenever any snapshot changed.

## 3. Architecture

```
 game events ──► ScanEvents ──► ScanScheduler.MarkDirty(domain, key)
 UI / slash  ──► ScanScheduler.Request(reason)
                      │  one-shot timers (section 5)
                      ▼
                 ScanPass.Run()
   gate ─► read dirty domains ─► evaluate ─► build tasks ─► side effects ─► present
              │                     ▲
              ▼                     │
   RosterScan  AuraScan  BagScan  PlayerStateScan  RangeScan     (snapshots)
```

New files, all under `Src/Scan/`. Each needs a `LibStub:NewLibrary` line in
[Src/EarlyBoot.lua](../Src/EarlyBoot.lua) and a `Src/Scan/` block in
[toc_template.toc](../toc_template.toc) after `Src/Cache/`.

| File | LibStub name | Replaces |
|---|---|---|
| `ScanScheduler.lua` | `Buffomat-ScanScheduler` | `Src/Throttle.lua` |
| `ScanEvents.lua` | `Buffomat-ScanEvents` | the scan-related half of `Src/Events.lua` |
| `ScanPass.lua` | `Buffomat-ScanPass` | `TaskScan:ScanTasks`, `Precheck`, `Finalize`, `ShowInactive` |
| `RosterScan.lua` | `Buffomat-RosterScan` | roster code in `Core/Party.lua`, `Cache/UnitCache.lua` |
| `AuraScan.lua` | `Buffomat-AuraScan` | `Unit:UnitAura`, `Unit:ForceUpdateBuffs` |
| `BagScan.lua` | `Buffomat-BagScan` | `Cache/ItemListCache.lua`, `BuffChecks:HasOneItem` / `HasItem` |
| `PlayerStateScan.lua` | `Buffomat-PlayerStateScan` | weapon enchant, mana, form, mount, tracking reads spread over `Unit.lua`, `TaskScan.lua`, `BuffChecks.lua` |
| `RangeScan.lua` | `Buffomat-RangeScan` | distance in `Unit:UpdateBuffs`, `repeatUpdate` |
| `ScanResult.lua` | `Buffomat-ScanResult` | `unitsNeedBuff` and the other scan results on `BomBuffDefinition` |
| `ScanEvaluate.lua` | `Buffomat-ScanEvaluate` | `TaskScan:IsActive`, `Check*`, `UpdateMissingBuffs*`, aura / seal / tracking selection |
| `ScanEffects.lua` | `Buffomat-ScanEffects` | `TaskScan:CancelBuff*`, `SetTracking`, skip list, watch-group reset |
| `ScanStats.lua` | `Buffomat-ScanStats` | new: counters for `/bom scanstats` |

The task builders of `TaskScan.lua` are now `Src/Task/TaskBuilder.lua` (`Buffomat-TaskBuilder`).

`Src/Events.lua` keeps the handlers that are not scanning: taxi, UI error auto-stand / dismount,
downrank learning, skip list.

### Domains

| Domain | Key | Snapshot owner | Read cost |
|---|---|---|---|
| `roster` | none | RosterScan | up to 40 `GetRaidRosterInfo` + per-unit identity |
| `status` | unitId | RosterScan | dead / ghost / connected / incoming res / zone for one unit |
| `auras` | unitId | AuraScan | up to 40 aura reads for one unit |
| `bags` | none | BagScan | every bag slot once |
| `bagCooldowns` | none | BagScan | one cooldown call per *tracked* item |
| `weapon` | none | PlayerStateScan | `GetWeaponEnchantInfo` + two inventory item ids |
| `player` | none | PlayerStateScan | form, mounted, resting, taxi, vehicle, stealth, instance, tracking, mana |
| `range` | none | RangeScan | distance for units that have a pending task only |
| `settings` | none | none | no read; forces evaluate (options, profile, spell setup, modifier key, skip list) |

A domain is dirty or clean. `auras` and `status` carry a set of dirty unit ids plus an "all" flag.
Every snapshot has a `version` number that the reader increments only when the data really changed.
The pass skips evaluate when no version moved and `settings` is clean.

### Snapshot shapes

`BomUnit` keeps the field names that `BuffChecks.lua` and `TaskScan.lua` read today (`unitId`,
`name`, `class`, `group`, `isTank`, `link`, `owner`, `isDead`, `isGhost`, `isConnected`,
`isSameZone`, `hasResurrection`, `knownBuffs`, `allBuffs`, `NeedBuff`, `auraDataUnavailable`,
`weaponDataUnavailable`, `mainhandEnchantment`, `offhandEnchantment`, `distance`, `isPlayer`). This
is what lets the readers be replaced before the evaluation code is touched. New fields: `guid`,
`auraVersion`.

```lua
---@class BomRoster
---@field version number
---@field isRaid boolean
---@field units BomUnit[]            Array, for allocation-free ipairs in hot loops
---@field byUnitId table<string, BomUnit>
---@field byName table<string, BomUnit>   Display and per-name settings only; never the identity
---@field groups table<number, BomUnit[]> Raid subgroup 1..8; party and solo use group 1
---@field player BomUnit
---@field playerPet BomUnit?
---@field target BomUnit?            Drive-by buff target (BuffomatShared.BuffTarget), not in a group
```

Rules:

- One `BomUnit` object per unit id, created once and reused. A roster rebuild re-fills identity
  fields; it does not allocate. Pets are cached like players.
- Identity is the GUID. When the GUID behind a unit id changes, the unit's aura snapshot is wiped,
  its link is rebuilt and it is marked aura-dirty. The link is not rebuilt otherwise.
- `byName` keeps the realm suffix for cross-realm players if stripping it would collide. Per-name
  settings (`ForcedTarget`, `ExcludedTarget`, blessing assignments, skip lists) are looked up by the
  short name first, as today.
- A secret name or GUID (Forever) makes the unit unusable: it is left out of the roster and the
  roster is flagged `incomplete`, which the gate turns into the existing "aura data unavailable"
  inactive state. In aura-free mode the roster is the player only.

`BagScan` snapshot: one walk over `envModule.playerBagIds` fills
`byItemId[itemId] = { count, bag, slot }` (first slot found, total count) for every item, plus an
array of openable items. Lookups are O(1). The lockbox tooltip scan runs only for openable items and
only when `BuffomatShared.OpenLootable` is on. Cooldowns are read only for item ids the knowledge
database registered (`BuffomatAddon.itemList`, `lockIfHaveItem`, consumables) and stored as two
numbers on the reused record.

### Aura reading

- `kvUnitModule.ReadAura(unit, index, filter)` in [Src/KvLib/KvUnit.lua](../Src/KvLib/KvUnit.lua)
  returns `spellId, name, duration, expirationTime, sourceUnit, readable` as plain values with no
  table. It checks only those values for secrets and does **not** check combat or restrictions; the
  gate did. `envModule.GetUnitAura` stays for the existing tests.
- Replace the three `tContains` calls with set lookups built once in `SpellSetup`:
  `allBuffsModule.drinkSpellIdSet`, `ignoreAllSpellIdSet`, and the existing
  `selectedBuffsSpellIds` / `spellIdIsSingleLookup`.
- `BomUnitBuff` records are reused per unit (a small free list), not allocated per aura.
- Duration learning stays: `BuffomatShared.Duration[name]` is written when the player's own buff
  reports a duration and used when a later read reports none. The `unitAurasLastUpdated` fallback is
  deleted; when the client reports no expiration, `BuffChecks:TimeCheck` already treats the buff as
  present.
- First version re-reads the whole unit when it is dirty. That is at most 40 calls for one unit and
  works on every client. The `UNIT_AURA` `updateInfo` payload (present in the Classic UI source under
  `F:\Projects\WowAddons\BlizzardInterfaceCode\`, `UnitAuraDocumentation.lua`) is used only as a
  filter: skip the unit when `updateInfo` is a table, `isFullUpdate` is false, and none of the added
  aura spell ids or changed instance ids are in the watched sets. Any nil, secret or missing field
  means "re-read". Incremental reading by aura instance id is step 10, and only if the phase 0
  counters say it is needed.
- Reading is budgeted: at most 10 units per pass (5 with `SlowerHardware`). Order: player, player
  pet, the player's own subgroup, then the rest in unit order. Units left over stay dirty and the
  scheduler runs a continuation pass. This replaces the raid round-robin.
- A unit whose aura read hits a secret value keeps `auraDataUnavailable = true` and empty buff
  tables, as today.

### The pass

`ScanPass:Run()`, in order:

1. **Gate.** Stop if the knowledge database is not set up or a loading screen is active. Stop if
   `InCombatLockdown()`. Read `envModule.GetAuraRestriction()` once: `nil` gives mode `full`,
   `"PvPMatch"` gives mode `auraFree`, anything else shows the inactive text and stops. No timer is
   left running after a gate stop; the event that lifts the gate marks everything dirty.
2. **Profile.** Choose the profile here and only here, when `roster`, `player` or `settings` is
   dirty.
3. **Read**, each only when dirty, in this order: `roster`, `status`, `auras` (budgeted), `bags`,
   `bagCooldowns`, `weapon`, `player`, `range`.
4. **Early out.** If no snapshot version changed and `settings` is clean, schedule and return.
5. **Activity checks** (`IsActive`, casting, global cooldown, incomplete roster) on the snapshots.
6. **Evaluate.** For every selected buff compute who needs it, from snapshots only.
7. **Build tasks**, sort, pick the first castable.
8. **Side effects**, as an explicit list produced by evaluate and run here: activate tracking,
   cancel buffs, whisper expired. Never from inside evaluate.
9. **Present.** Task list, cast button, macro, auto show / hide, sound.
10. **Schedule.** Leftover dirty units give a continuation pass. Otherwise arm the deadline timer for
    the earliest wake time collected during the pass.

API calls still allowed in evaluate and task building, because they are cheap, per-candidate and
have no event: `IsSpellInRange` for a unit that needs a buff, `UnitIsPVP` for the PvP-tag guard,
`GetSpellCooldown` for a buff with `hasCD`. Everything else comes from a snapshot.

A request that arrives while a pass runs sets the dirty flag for the *next* pass. The pass clears a
domain's flag immediately before reading that domain, never at the end.

## 4. Events

`ScanEvents` owns one `KvEventDispatcher` (`Src/KvLib/KvEvents.lua`) for all of these. The dispatcher
refuses an event name the client does not have, so every row is "if valid". "player only" means
`RegisterUnitEvent` with a fallback filter. Handlers outside scanning stay on AceEvent in `Src/Events.lua`.

| Event | Registration | Effect |
|---|---|---|
| `GROUP_ROSTER_UPDATE`, `GROUP_JOINED`, `GROUP_LEFT`, `RAID_ROSTER_UPDATE`, `PLAYER_ROLES_ASSIGNED` | all units | `roster` |
| `UNIT_NAME_UPDATE` | all units | `roster`, for a member: the name or class arrived after the member did |
| `UNIT_PET` | all units | `roster` for the player's pet and, outside a raid, a member's pet; for the player also `player` |
| `UNIT_AURA` | player and pet only when alone; all units in a group or with BuffTarget, then filtered by `roster.byUnitId[unit]`; not registered in combat | `auras[unit]`, `status[unit]`; for `player` also `player` (mount, stealth and form are auras). Skipped when the payload says only harmful auras were added |
| `UNIT_CONNECTION`, `INCOMING_RESURRECT_CHANGED` | all units, roster filter | `status[unit]` |
| `PLAYER_DEAD`, `PLAYER_ALIVE`, `PLAYER_UNGHOST` | | `status[player]`, `auras[player]`, `player` |
| `READY_CHECK` | | `auras` all, `status` all |
| `BAG_UPDATE_DELAYED`, `BAG_UPDATE`, `TRADE_CLOSED` | | `bags`, `bagCooldowns` |
| `BAG_UPDATE_COOLDOWN` | | `bagCooldowns` |
| `UNIT_INVENTORY_CHANGED` | player only | `weapon` |
| `PLAYER_EQUIPMENT_CHANGED`, `WEAPON_ENCHANT_CHANGED` | | `weapon` |
| `UPDATE_SHAPESHIFT_FORM`, `PLAYER_UPDATE_RESTING`, `ZONE_CHANGED_INDOORS`, `MINIMAP_UPDATE_TRACKING`, `PLAYER_MOUNT_DISPLAY_CHANGED`, `UPDATE_STEALTH`, `MINIMAP_UPDATE_ZOOM` (indoors / outdoors), `PLAYER_CONTROL_LOST` / `GAINED` | | `player` |
| `UNIT_ENTERED_VEHICLE` / `UNIT_EXITED_VEHICLE`, `UNIT_FACTION` | player only | `player` |
| `ZONE_CHANGED`, `ZONE_CHANGED_NEW_AREA` | | `player`, `status` all (members are compared with the player's zone) |
| `UNIT_POWER_UPDATE` | player only, registered only while a task waits for mana (`ScanEvents:SetManaWatch`) | `player`, once mana reaches `PlayerStateScan.manaWakeLimit` |
| `UNIT_SPELLCAST_START` / `STOP` / `SUCCEEDED` / `FAILED` / `INTERRUPTED`, `UNIT_SPELLCAST_CHANNEL_START` / `STOP` | player only | `PlayerStateScan.casting`, then `settings`; stop and result also `player` (mana) |
| `PLAYER_TARGET_CHANGED` | | only with `BuffTarget` on and a different buffable outsider: `roster` and `auras["target"]` |
| `MODIFIER_STATE_CHANGED` | | Alt down: forget skip list and resurrections, everything dirty. Otherwise `settings` while a task waits for a modifier |
| `PLAYER_REGEN_DISABLED` | | cancel the pass timer, unregister `UNIT_AURA` |
| `PLAYER_REGEN_ENABLED` | | register `UNIT_AURA`, everything dirty |
| `LOADING_SCREEN_ENABLED`, `PLAYER_LEAVING_WORLD` | | gate closed, timers cancelled |
| `LOADING_SCREEN_DISABLED`, `PLAYER_ENTERING_WORLD` | | gate opens after the grace timer; everything dirty |
| `ADDON_RESTRICTION_STATE_CHANGED` (where restrictions exist) | | everything dirty; pass runs from the timer, never inside the event (the state is not final yet) |

In `Src/Events.lua` (AceEvent): `SPELLS_CHANGED`, `PLAYER_LEVEL_UP`, `TRAIT_CONFIG_UPDATED` and
`ACTIVE_TALENT_GROUP_CHANGED` run the spell setup or profile choice and then call `Request`.

Removed: `COMBAT_LOG_EVENT_UNFILTERED` on every client, and the unfiltered generic update events.

Deaths of other members have no cheap event without the combat log. A death removes auras, so
`UNIT_AURA` marks the unit and its `status` is re-read with it. Resurrection is covered by the dead
watch timer below. **Verify in game** on Era and Forever that a party member dying produces
`UNIT_AURA`; if it does not, add `UNIT_HEALTH` registered only for units that currently have a
pending task, never for the whole raid.

## 5. Timers

All are AceTimer one-shots owned by `ScanScheduler`. `SlowerHardware` doubles every interval. No
timer runs in combat, behind a loading screen, or when nothing is pending.

| Timer | Interval | Armed when | Purpose |
|---|---|---|---|
| Coalesce | 0.1 s after the *first* mark (not sliding) | a domain becomes dirty and no pass is scheduled | Folds an event burst into one pass. A raid buff produces up to 40 `UNIT_AURA` in one frame. |
| Minimum gap | 0.2 s between pass starts | always enforced | Caps the cost of a continuous event stream at 5 passes a second. |
| Continuation | 0.05 s | the aura budget left dirty units | Finishes a full-raid read in about four passes without a frame spike. |
| Deadline | at `nextWakeAt` | a pass collected a future wake time | Replaces `nextCooldownDue`, `checkCooldown` and the cooldown polling. |
| Range tick | 1.0 s, re-armed by the pass | a task builder made a task for another member, a group or a resurrection | Replaces `repeatUpdate`. Marks `range`, which forces an evaluation with fresh distances. Stops when no such task is left or Buffomat is paused. |
| Dead watch | 2.0 s, re-armed by the pass | the roster has a dead member and Buffomat is active | Marks `deadWatch`: the status of the dead members only. |
| Resync | 30 s, re-armed by the pass | more than one unit in the roster and Buffomat is active | Marks `auras` and `status` all. Insurance against a missed `UNIT_AURA` or a zone change of a far-away member. Remove it if in-game testing shows it never changes a snapshot version. |
| Flight watch | 2.0 s, re-armed by the pass | flying exists on the client and the player is mounted or in a flight form; also while paused | Marks `player`. Taking off and landing send no event. |
| Error retry | 5.0 s | a pass raised an error | Runs the failed pass again with the same input. An event may bring the next pass sooner. |
| Loading grace | `constModule.LOADING_SCREEN_TIMEOUT` | loading screen ended | Opens the gate. Replaces the timeout polling. |

`nextWakeAt` is the minimum, always as an absolute `GetTime()` value, of:

- the moment a watched buff reaches its rebuff threshold (`BuffChecks:TimeCheck`);
- the end of a spell cooldown for a buff with `hasCD`, and of the global cooldown;
- the end of a tracked item's cooldown (this fixes the relative-time bug);
- the weapon enchant expiry minus its rebuff threshold.

Collectors call `scheduler:WakeAt(time)`; nothing writes a shared field directly.

`ScanScheduler` API:

```lua
---Mark a domain dirty and make sure a pass is scheduled.
---@param domain BomScanDomain
---@param key string? Unit id for "auras" and "status"; nil marks the whole domain
function module:MarkDirty(domain, key) end

---Mark everything dirty: combat end, loading end, restriction change, full resync.
---@param reason string Shown by /bom scanstats
function module:MarkAllDirty(reason) end

---Settings or UI changed: forces evaluate without re-reading anything.
---@param reason string
function module:Request(reason) end

---Make a domain dirty at an absolute time; an earlier request for the same domain wins.
---@param time number GetTime() based
---@param domain BomScanDomain? Defaults to "settings", which only evaluates again
function module:WakeAt(time, domain) end
```

Also `MarkUnit(unitId)` (auras and status of one unit), `WakeAfter(seconds, domain)` and
`CancelWake(domain)`. The pass reads its input from `pending` / `pendingUnits`; marks made while a
pass runs go to the next pass.

Timers are restarted, not accumulated: arming a timer that is already armed for an earlier time is a
no-op, and for a later time is ignored.

## 6. Step-by-step plan

Each step ends with `luacheck Src Tests` at 0 warnings, all `Tests/*.lua` passing, and an in-game
smoke test on Era and Forever (solo, 5-man, raid if available). Each step is one commit and leaves
the addon working. Update [code-index.md](code-index.md) in the same commit whenever a file or
function listed there moves.

### Step 0. Measure and build the test fixture

1. Add scan counters behind `BuffomatShared.DebugLogging`: passes per minute, reasons, milliseconds
   per pass (`debugprofilestop`), aura API calls, bag slot reads. Print with `/bom scanstats`.
2. Record a baseline in this file: solo idle, 5-man idle, 40-man idle, 40-man during buffing, and
   solo with one tracked item on cooldown (expect 2 passes a second from the `cdDue` bug).
3. Add `Tests/ScanFixture.lua`: a fake client with settable units, auras, raid roster, bags, a
   manual clock, a capturing `C_Timer` / AceTimer, and an event pump. Model it on the loader in
   `Tests/AuraCompatibilityTest.lua`. It needs a legacy mode (`UnitAura` tuples, no `issecretvalue`)
   and a modern mode (`C_UnitAuras`, secret values, restrictions).

### Step 1. ScanScheduler replaces Throttle

1. Create `ScanScheduler.lua` with the dirty set, the four API functions and the coalesce, minimum
   gap and deadline timers. For now a pass calls the existing `TaskScan:ScanTasks`.
2. Keep `throttleModule:RequestTaskRescan(reason)` as a one-line shim to `MarkAllDirty(reason)` so
   the 30-odd call sites keep working; they are converted as their domain gets a reader.
3. Replace the six direct `ScanTasks` calls with `scheduler:Request`.
4. Move `nextCooldownDue`, `checkCooldown` and the modifier-key poll to `WakeAt` and
   `MODIFIER_STATE_CHANGED`. Fix the relative-time item cooldown value here.
5. Delete `repeatUpdate`; add the range tick timer in its place (it marks everything dirty until
   step 7).
6. Delete the repeating AceTimer and `ScheduleUpdateTimer`. `TaskListPanel:WindowCommand` is called
   from the pass and from `PLAYER_REGEN_ENABLED` instead of every tick.
7. Make the dirty flags survive a pass: clear before reading, never in `Finalize` / `ShowInactive`.
8. Tests: burst of 40 marks gives one pass; a mark during a pass gives a second pass; deadline fires
   at the right clock value; no timer is armed in combat or when clean.

### Step 2. ScanEvents and the gate

1. Create `ScanEvents.lua` with the plain unit-event frame and the table from section 4. At this
   step every event still ends in a full pass, but through the right domain name.
2. Filter `UNIT_AURA` by roster membership. Register the player-only unit events with
   `RegisterUnitEvent`.
3. Remove the combat log registration and `Party:OnBuffsChangedEvent`, `unitAurasLastUpdated`,
   `CleanUpBuffs`.
4. Move the combat, loading-screen and restriction checks into the scheduler gate. Loading no longer
   calls `Event_CombatStart`.
5. Tests: `UNIT_AURA` for a nameplate schedules nothing; combat start cancels timers; combat end
   schedules exactly one pass.

### Step 3. BagScan

1. Create `BagScan.lua` with the `byItemId` index, the openable list and tracked-item cooldowns.
2. Port `BuffChecks:HasOneItem` / `HasItem` and `TaskScan:CheckItemsAndContainers` to it. Keep the
   return shapes so callers do not change.
3. Delete `Cache/ItemListCache.lua`, `BuffomatAddon.wipeCachedItems`, `cachedPlayerBag`.
4. `Event_Bag` becomes `MarkDirty("bags")`.
5. Tests: reagent bag on Forever is included; a stack split across two bags sums; an item on
   cooldown yields the right `WakeAt`; a bag event with unchanged contents does not bump the version.

### Step 4. RosterScan

1. Create `RosterScan.lua` with the `BomRoster` shape. Rebuild only when `roster` is dirty: one loop
   over `GetRaidRosterInfo(1..GetNumGroupMembers())` in a raid (subgroup and role come from that
   call), `party1..4` otherwise, plus pets and the optional target.
2. Keep `partyModule:GetParty()` as a thin accessor returning the roster, so `BuffChecks.lua` and
   `TaskScan.lua` keep reading `party.byUnitId`, `party.player`, `party.playerPet`.
3. Move `detectIsTank` and the link builder from `UnitCache.lua`; delete `UnitCache.lua`,
   `partyCacheInvalidation`, `ALL_INVALID_GROUPS`, `validatePartyMembers`, `emptyGroups` and the
   round-robin in `TaskScan:RotateInvalidatedGroup_GetGroup`.
4. Move the Alt-key "clear skip list, forget declined resurrections" side effect out of `GetParty`
   into the `MODIFIER_STATE_CHANGED` handler.
5. Until step 5, a dirty roster still re-reads every unit's auras through the old `UpdateBuffs`.
6. Tests: raid indexes in shuffled subgroup order land in the right `groups[g]`; a member swap keeps
   the unit object and wipes its auras; leaving a group empties the roster to player and pet; a
   secret name flags the roster incomplete.

### Step 5. AuraScan and unit status

1. Add `envModule.ReadAura` and the spell id sets.
2. Create `AuraScan.lua`: per-unit read into the reused `knownBuffs` / `allBuffs`, version bump only
   on change, budget and priority order, `updateInfo` filter.
3. Move the status read (dead, ghost, connected, zone, incoming resurrection) to
   `RosterScan:ReadStatus(unit)`.
4. Counters such as the number of drinking members become fields of the aura snapshot, recomputed
   from per-unit flags, not globals reset at the top of a pass.
5. Delete `Unit:UnitAura`, `Unit:ForceUpdateBuffs`, `Unit:UpdateBuffs`. `BuffChecks:HunterPetNeedsBuff`
   reads the pet's snapshot instead of forcing an aura read.
6. Add the continuation, dead watch and resync timers.
7. Tests: one dirty unit reads one unit; 40 dirty units take four passes and the player is in the
   first; an unreadable aura marks only that unit; an irrelevant `updateInfo` is skipped; a malformed
   `updateInfo` falls back to a full read; no table is created in a steady-state read (count
   allocations through the fixture).

### Step 6. PlayerStateScan

1. Create `PlayerStateScan.lua` holding: weapon enchants, mana and max mana, shapeshift form id,
   mounted, flying, taxi, vehicle, resting, stealth, instance type, active tracking, casting state.
2. Port `TaskScan:IsActive`, `UpdatePlayerMana`, `IsMountedAndCrusaderAuraRequired`,
   `BuffChecks:IsTrackingActive`, `WeaponHandsNeedingBuff` and `Unit:UpdatePlayerWeaponEnchantments`
   to read it. `partyModule.playerMana` / `playerManaLimit` move here.
3. Weapon enchant expiry feeds `WakeAt`.
4. Aura-free mode becomes: roster of the player only, `auras` skipped, everything else read
   normally. `TaskScan:GetPlayerOnlyParty` is deleted.

### Step 7. RangeScan

1. Create `RangeScan.lua`. `unit.distance` is computed only for units named by the previous pass's
   pending tasks, and only when `range` is dirty. Other units keep a "not measured" value.
2. The task builders (`GetGroupInRange`, `GetClassInRange`, `GetAnyPartyMemberInRange`) keep calling
   `IsSpellInRange` for candidates; they register the units they looked at with RangeScan.
3. The range tick marks `range` only. Evaluate is skipped when the measured distances did not change
   bucket.
4. `PLAYER_STARTED_MOVING` / `PLAYER_STOPPED_MOVING` pause the tick while the player stands still and
   no group member moved into range on the last tick. Skip this refinement if it costs more than a
   few lines.

### Step 8. Split TaskScan into evaluate, tasks, side effects, present

1. Create `ScanPass.lua` with the ten stages of section 3. `TaskScan:ScanTasks` is deleted.
2. Introduce `BomScanResult`, owned by the pass and reused between passes:
   `needs[buffId] = { units = {}, groups = {}, groupsHaveDead = {}, betterBuff = {}, reminderText }`.
   Move `unitsNeedBuff`, `groupsNeedBuff`, `groupsHaveDead`, `unitsHaveBetterBuff`, `reminderText`
   and `ResetBuffTargets` off `BomBuffDefinition`. `skipList` stays on the definition; it is user
   feedback, not a scan result.
3. Collect side effects into `result.effects` during evaluate; run them in stage 8. This covers
   `SetTracking`, `CancelBuffs`, `WhisperExpired`.
4. Move the remaining loose `BuffomatAddon` scan fields (section 1, Structure) into the module that
   owns them. Update the `BomAddon` type spec in `Src/Buffomat.lua`.
5. `TaskScan.lua` keeps only task builders (`Add*`). Consider renaming it `TaskBuilder.lua`.
6. Tests: evaluate against fixture snapshots for a priest in a 40-man raid, a paladin with class
   blessings, and a solo warrior with a weapon stone; assert the needs table and the task texts.

### Step 9. Remove the old code and update documents

1. Delete `Src/Throttle.lua`, the `RequestTaskRescan` shim, `Cache/ItemListCache.lua`,
   `Cache/UnitCache.lua`, and what is left of the roster code in `Core/Party.lua`. Remove their
   `EarlyBoot.lua` and TOC entries.
2. Rewrite the Throttle, Events, Party, Unit, Caches and TaskScan entries of
   [code-index.md](code-index.md) and add a "Scan" section.
3. Add to the root `AGENTS.md`: events mark domains and never scan; readers are the only code that
   calls the listed WoW APIs; new time-based conditions use `scheduler:WakeAt`.
4. Re-run the step 0 measurements and record them here next to the baseline.

### Step 10 (optional). Incremental aura updates

Only if step 9 measurements show aura reading still dominates in a 40-man raid. Use
`updateInfo.addedAuras`, `updatedAuraInstanceIDs`, `removedAuraInstanceIDs` with
`C_UnitAuras.GetAuraDataByAuraInstanceID` to patch a unit's snapshot, keyed by aura instance id.
Capability-gated; the full re-read stays as the fallback and as the path for `isFullUpdate`.

## 7. Per-client notes

| Topic | Era / TBC / WotLK / Cata Classic | Forever |
|---|---|---|
| Aura API | `C_UnitAuras.GetAuraDataByIndex` where present, else `UnitAura` tuples | `C_UnitAuras` only |
| Secret values | none | names, auras, power, cooldowns, weapon enchants can be secret; every reader guards with `envModule.IsSecretValue` |
| Restrictions | none (`supportsAuraRestrictions` false) | gate reads `GetAuraRestriction()` once per pass; PvP match gives aura-free mode |
| Combat log | removed by this plan | does not exist |
| Bags | bags 0-4; `BAG_UPDATE_DELAYED` validity differs by client | bags 0-5 through `envModule.playerBagIds` |
| Group buffs | party-wide before WotLK, so `groups[g]` matters | raid-wide (`envModule.groupBuffsRaidWide`) |
| `UNIT_AURA` `updateInfo` | documented in the Classic UI source; not confirmed per flavor | present; fields may be secret in restricted states |
| Tracking | texture or tracking-settings API (`envModule.usesTrackingSettings`) | tracking-settings API |

To verify in game, per client, and record in this table:

- `UNIT_AURA` fires for out-of-range raid members, and on a member's death (the dead member's
  status is read with the aura event; without it a death is noticed only by the 30 s resync).
- A resurrected member is noticed within the 2 s dead watch.
- `RegisterUnitEvent` accepts `"player", "pet"`, and one unit without a second argument.
- Which of `WEAPON_ENCHANT_CHANGED`, `PLAYER_ROLES_ASSIGNED`, `UPDATE_STEALTH`,
  `PLAYER_MOUNT_DISPLAY_CHANGED`, `PLAYER_CONTROL_LOST` exist (`/dump C_EventUtils.IsEventValid(...)`).
  On a client without `C_EventUtils` an unknown name is caught by the protected registration.
- The end of a temporary weapon enchant is noticed (event or the deadline timer).
- Mounting, taking a taxi, entering stealth and changing form each update the cast button.
- On Era: activating a tracking spell through `CastSpellByID` still works out of combat.

## 8. Risks

- **Missed updates.** Moving from "rescan everything often" to "read what an event named" can leave
  a snapshot stale when an event is missing. The resync and dead watch timers bound the staleness;
  `/bom update` and showing the window call `MarkAllDirty`.
- **Behaviour drift in evaluation.** Steps 3 to 7 keep the `BomUnit` and `party` shapes so
  `BuffChecks.lua` is untouched until step 8. Step 8 is the risky one and gets fixture tests first.
- **Taint and combat.** The pass still never runs in combat. Timers are cancelled on
  `PLAYER_REGEN_DISABLED`, so no pass can start between that event and lockdown.
- **AceTimer resolution.** AceTimer one-shots are fine for 0.05 s and up. If the continuation timer
  proves too coarse, use `C_Timer.After`, which every supported client has.

## 9. Retail: research first, no work planned

Retail is out of scope. The design avoids choices that would block it: capability probes instead of
flavor checks, unit-id identity, no combat log, a single restriction gate, and an aura-free mode.

The items below are from memory of the Midnight (12.x) addon changes and are **not verified**. Each
needs a check against a live Retail client or current documentation before any work is planned.

1. Are other group members' auras readable out of combat in the open world, in a dungeon between
   pulls, and in a raid between encounters? The gate assumes the answer is the same as on Forever.
2. Is the `UNIT_AURA` `updateInfo` payload secret or absent in restricted states, and is
   `GetAuraDataByAuraInstanceID` usable out of combat?
3. Which restriction types exist in `Enum.AddOnRestrictionType` on Retail beyond the four that
   `KvEnv.lua` knows, and do any hide bags, weapon enchants or cooldowns?
4. Follower dungeons and delves put NPCs in party unit slots. `GetPlayerInfoByGUID` returns no class
   for them, and today that classifies them as pets.
5. Cross-realm and cross-faction groups: name collisions after stripping the realm (the roster rule
   in section 3 is meant to cover this).
6. `envModule.isClassic` is false and `isForever` deliberately excludes Retail, so no buff
   definitions load. A Retail knowledge database (few raid buffs, no ranks, no reagents, raid-wide
   only) is the larger job and is unrelated to scanning.
7. A Mainline TOC and `wowaddon.py` flavor, and whether `UnitDistanceSquared` and the item-range
   fallbacks in `LegacyToolbox:UnitDistanceSquared` are restricted there.

## 10. Decisions taken in this plan

Change these here if you disagree; the steps follow from them.

- Evaluation is re-run in full when anything changed; only reading is incremental.
- A dirty unit is re-read in full; incremental aura patches are deferred to step 10.
- The combat log is dropped on every client, not only Forever.
- A 30 s resync and a 2 s dead watch are kept as safety nets until in-game testing justifies
  removing them.
- `SlowerHardware` stays as one option that doubles every interval and halves the aura budget.
