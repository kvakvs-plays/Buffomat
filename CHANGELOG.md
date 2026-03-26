# Changelog

## Buffomat Classic 2026.3.0

- Fix for pets not being detected correctly in other languages than English (by jdelvare)

## Buffomat Classic 2025.5.5

- [Bug] Fixed issue with "Missing Buffs to use a group buff" setting where setting it to 2 (or higher) would cause buffs to not be detected or applied when only 1 party member was missing the buff. The logic now properly checks per-group requirements for pre-WotLK and total requirements for WotLK, ensuring single buffs are cast when group buffs don't meet the threshold.

## Buffomat Classic 2025.5.4

- Spell downranking: Restored the old broken feature, where a spell would automatically downrank if casted on a target too low level. As there isn't a way for addon to know it, it will learn from unsuccessful casts (you will need to cast the same buff again after it has learned). Requires enabled option for Downranking in 4.Convenience options tab.
- Reintroducing option "Autoshow" when disabled, the task list will not be auto-showing till user actually calls it with a hotkey or menu, regardless of whether there are tasks or not.
- Mage armor-type spells have now duration set to 30min, to allow better estimate of remaining duration for  rebuffing.

## Buffomat Classic 2025.5.3

- Option for drive-by buffing, your target is considered for a buff check, even if not part of the group.

## Buffomat Classic 2025.5.1

- Min fade opacity lowered to 0.1 (10%)
- An option was reintroduced: Auto close. When active, and the window would
  fade due to no tasks available, it will hide instead till the next scan.
  The window will be shown again if there's a buff to refresh.

## Buffomat Classic 2025.3.4 / 2025.5.0

- Big UI overhaul: New task list window, simpler and faster, new spell settings, easier access to main settings, multiple minor UI improvements, too.
- Window hide/fade/show behaviour has changed to be less annoying and more like the previous version.

## Buffomat Classic 2025.1.0, 2025.2.0

- Found possible reason for group buffs not working. Releasing a beta fix.
- Version bump with WoW classic updated to 1.15.6

## Buffomat Classic 2024.7.1

- When Macro edit frame is open, Buffomat will sleep
- Sorting the buffs inside each group alphabetically

## Buffomat Classic 2024.7.0

- [Paladin] In Cataclysm Crusader aura has changed its shapeshift-id from 7 to

5. This update will fix the crusader aura autobuff behaviour in Cataclysm.

## Buffomat Classic 2024.6.2

- [Mage] Mana gem fixed.
- [Cataclysm] Added Abyssal Clam and older clams to the openable containers list.
- [Cataclysm] Alchemist only Flask of Enhancement added.

## Buffomat Classic 2024.5.4

- [Cataclysm] Prepatch fix. Stay tuned for actual Cataclysm update.
- [Cataclysm] Elixirs, flasks, food buffs.
- [Cataclysm] Rogue poisons. Also see: Restocker Classic addon to auto-buy.
- [Cataclysm] Priest buffs fix
- [Bug] 'providesAuras' was working for consumables only, now also for buffs. Allows to account for fortitude and shadow
  protection being already on priest.
- Missing: Combo meals, alchemist flask.

## Buffomat Classic 2024.4.0

- [Druid] Do not /cancelform in moonkin form by adding `[noform:5]` to it.
- Minimap button is now using LibAce's standard library. Removed options for
  button rotation and distance, as they're now handled by the external library.
  Clicking the button toggles the window, right clicking shows quick menu.
- [Bug] Remaining reference in code to minimapButton is removed

## Buffomat Classic 2024.3.0

- [SoD] [Shaman] Dual wield enchantments work again. Known problem: You can't
  leave mainhand unenchanted, it always does mainhand first.

## Buffomat Classic 2023.12.1

- [SoD] [Hunter] Heart of the Lion 10% stats aura

## Buffomat Classic 2023.11.4

- Single rows for each food buff are now grouped per stat they provide, including all levels (helps while leveling).
  Highest
  available in your bag will be eaten first (and a setting to choose lowest first).
  - New grouped buffs are marked with green text
  - New option (last in the "Scan Options") to prefer either highest available
    item, or lowest. Lowest is useful when leveling, to consume your lowest level consumables first.
  - Clicking the icon in the buff list to print all items, which can provide this buff, from lowest to highest.
  - Added food eating auras to ignore list to hide the food buff task while eating, so it doesn't get eaten multiple
    times.
- [Known Bug] Soon after resurrecting under the flask effect, Buffomat can show a task for reflasking. It disappears a
  second or two later.
- In raid, staggered per-group updates now will skip empty 5man groups, which will result in faster updates overall.

## Buffomat Classic 2023.11.1

- Hide consumables which have required level above player. If multiple items provide the buff, choose the lowest level
  requirement.

## Buffomat Classic 2023.11.0

- Updated the copy of KvLib for classic compatibility. Was using Windows directory Junctions before and that didn't go
  well.
- [Bug] Now updating player weapon enchantments on unit buff rescan. This helped solve the long standing Rockbiter bug.

## Buffomat Classic 2023.9.0

- 10min rebuff time was not working with druid thorns.

## Buffomat Classic 2023.8.0-1

- Fixing bugs related to Classic Hardcode, item ids from future expansions leaking into classic don't work well.
- Fixing API incompatibility for bag access, which changed somewhere later in a future expansion, causing errors in
  Classic.

## Buffomat Classic 2023.5.0

- [Bug] Mainhand enchantment for rogue failed on non-English clients. Thanks to @jdelvare for the suggested fix.

## Buffomat Classic 2023.4.1

- [Bug] Should not suggest enchanting fishing poles or if a weapon is not equipped

## Buffomat Classic 2023.4.0

- [Bug] On login with missing offhand weapon buff, an error was popping up

## Buffomat Classic 2023.2.0

- New bag event added for more consistent bag updates (thanks to jdelvare at Github)

## Buffomat Classic 2023.1.5

- [Bug] Throwing away/removing consumable from your bag, while a consumable task for that consumable was active, caused
  an error.

## Buffomat Classic 2023.1.5

- [Bug] Throwing away/removing consumable from your bag, while a consumable task for that consumable was active, caused
  an error.

## Buffomat Classic 2023.1.4

- Fix for Ulduar patch: Lua API for containers and tracking changed to Dragonflight API version

## Buffomat Classic 2023.1.1

- 3.4.1: Version increase for Ulduar patch
- Flask of the North support
- 2 elixirs changed item ID from TBC into WotLK, now changed.

## Buffomat Classic 2022.12.2

- Added no sound option in the play sound dropdown in the settings.
- Prayer of Spirit, Fortitude and Intellect buffs skip lists cleared (previously
  would skip these buffs if Sunwell aura is up or if fel intelligence from a warlock is present)

## Buffomat Classic 2022.12.1

- [Fix] Locales other than English fixed
- [Fix] Some sneaky bugs where buffs introduced in TBC were only allowed in TBC and not in WotLK
- German language updated a bit

## Buffomat Classic 2022.12.0

- Large refactor and type specs for most fields and functions, using Luanalysis
- Some bugs might have just disappeared
- Some new bugs possibly added, but should be minor and short lasting while i'm
  finding and fixing them.
- Crusader aura prompt will not pop up on the taxi or in a vehicle.
- Alchemist-only Flask of the North added
- Visual fixes to the task list
- Won't be tagging releases for TBC and classic anymore. They are not tested
  for that but might still work.

## Buffomat Classic 2022.11.0.2

- Ignore Priest Spirit buff and Mage Intellect buff, when Warlock Fel Intelligence is active
- [Bug] Respect MinBuff option (amount of missing buffs in party or on player
  to choose group buff)
- [Bug] Script error if MinBuff option is not set

## Buffomat Classic 2022.11.0

- In WotLK group buffs lost the ability to check whether an unit is within spell range. I am using single buff spell
  name for testing range which results in much shorter but still reliable range checks (30 yd instead of 100+). Keep in
  mind group buffs also check line of sight.

## Buffomat Classic 2022.10.4, 10.5

- Spell tab update is now hard limited in frequency to combat the raid lag.
- Buff scan update is also hard limited in frequency for the same reason.
- Horn of Winter rank 2 added
- Option to play sound when Buffomat has something to do
- Unit cache is less aggressive, this should help buffs to update faster

## Buffomat Classic 2022.10.1, -10.2

- Group buffs will now apply to self, if no group member in range. This needs
  to be tested in real raid so will give it some time before promoting to
  release.
- Fixes for group buff range check.
- Intellect scrolls?

## Buffomat Classic 2022.9.6

- [Pet] Pet food is now available for all classes not just hunters

## Buffomat Classic 2022.9.5.1

- [Shaman] Water Walking, Water Breath now in Buffomat, require no reagent with Wotlk Glyphs
- [Shaman] Spellhance weapon enchants option (on by default) to enchant main hand with 1 rank lower flametongue.
- [Priest] Vampiric Embrace is now a buff.

## Buffomat Classic 2022.9.4, 4.1

- [Death Knight] Horn of Winter; Bone Shield
- [Bug] Crash on group buffs distance check fixed

## Buffomat Classic 2022.9.3

- [Bug] K'iru's song of victory correctly works for priests

## Buffomat Classic 2022.9.2.2

- [Fix] Classic compatibility fix

## Buffomat Classic 2022.9.2.1

- [bug] Performance improvements; Fix to raid lag bug is in the testing before
  this file is promoted from beta to release
- [Feature] For WotLK with dual specialization, auto-profiles and profile
  selector now recognize second set of talents

## Buffomat Classic 2022.9.1

- [Shaman] Earthliving Weapon self-enchantment added
- [Paladin] Seal of command was missing, now added

## Buffomat Classic 2022.9.0

- [WotLK] Tracking herbs/ore feature restored
- [WotLK] Crippling poison was disabled in WotLK incorrectly
- [bug] Golden fish sticks had same buff id as (mistakenly) skullfish soup
- [bug] Script error when choosing a profile

## Buffomat Classic 2022.7.5

- Throttled rebuild frequency of abilities/buffs tab to max 1 per second. This
  seems to have triggered lags in battlegrounds and raids. Being throttled at a
  wrong time means that we must update as soon as the throttle allows, so the update
  is performed asap after the cooldown window.

## Buffomat Classic 2022.7.4

- [WotLK] Rogue poison ranks updated
- Installing 7.2 or newer addon will also install a dummy addon named "BuffomatClassicTBC" which deactivates the old TBC
  version of the addon and allows reimporting of the old settings.

## Buffomat Classic 2022.7.1

- All versions of addon are now merged into one, and you should delete (either automatically or manually the old "
  Buffomat Classic TBC")
- A big new wave of updates for Wrath of the Lich King:
  - New class spell ranks
  - New elixirs
  - New food
  - New weapon enchantments
- A new page in Options which allows Visibility selection for buff categories. Invisible categories are not scanned,
  even if they're checked.
- Skip mage Intellect buff if K'iru's Song of Victory is up in SWP or the island. Same for group buffs (Arcane
  Brilliance)
- Hunter pet food buff was broken and fixed.
- (Known problem) on First start spell tab can look empty, do a `/reload` one time.

## Buffomat Classic and TBC 2022.5.5

- Fix for classic version (script error)

## Buffomat Classic and TBC 2022.5.1

- Grouped buffs by categories
- [Bug] Try cache items and spells and update all spells list icons and text
- Added riding trinket reminder in Arena zones, do not forget your trinkets!
- [Bug] Allow crusader aura suggestion even if mounted buffing is disabled.
- Chinese language update (contributed by nanjuekaien1 @github)

## Buffomat Classic and TBC 2022.4.1

- Pet zone is now bound to player zone and buffing pets should work again (
  Contributed by @Anonomit on github)

## Buffomat Classic and TBC 2022.3.4, 3.5

- [Bug] Added AceGUI to embeds.xml, this seems to be required by the options
  page.
- [Bug] Order of lines in embeds.xml
- Updated build number for Classic Era (11402)

## Buffomat Classic and TBC 2022.3.2

- Script error fixed for uninitialized values of remaining durations settings.

## Buffomat Classic and TBC 2022.3.1

- Shattrath Flasks added.
- Item/spell info queries refresh spell tabs when they succeed, to fix the old
  problem with missing spell/item names.

## Buffomat Classic and TBC 2022.2.5, .6

- Added Find Fish tracking.
- Packaging error: library CallbackHandler was included but not embedded
  properly, so on systems without other Ace3 addons it would blow up with a
  script error.

## Buffomat Classic and TBC 2022.2.4

- Using new tech now: AceAddon, AceConfig, and event handlers from Ace.
- Changed Spirit Tap setting to a slider, the previously set boolean value is
  now lost as the variable was renamed and became a percentage.

## Buffomat Classic and TBC 2022.2.1, and .2

- Option to hide "Someone is drinking message", off by default, enable to hide.
- Option to disable Buffomat if priest's Spirit Tap talent is active (to
  maximize mana regen by preventing priest self-buffing after the combat). Off
  by default, click to enable (also please be a priest!).
- Incubus pet creature family was set incorrectly to "Succubus" and this did not
  really work well.

## Buffomat Classic and TBC 2022.1.2

- Show a comment when someone in party or raid is drinking
- Added Summon Incubus spell, sacrificeable just like succubus.

## Buffomat Classic and TBC 2022.1.1

- Chinese language updated
- Buffomat window now clips to screen (never goes off-screen)
- Icon for macro is changed to INV_MISC_QUESTIONMARK which instructs the game to
  change the macro icon dynamically to the first spell in the macro.

## Buffomat Classic and TBC 2022.1.0

- Fix for raid pets/party pets buffing
- Fix for "unknown unit id" error, thanks to Anonomit @github for reporting and
  explaining the cause
- UI scale option (default to 1.0) allows you to shrink or expand the window (
  for example when you are running on 4k resolution). Hide and show Buffomat to
  apply the new value.

## Buffomat Classic and TBC 2021.10.1-3

- Support for scrolls of strength, agility, spirit, protection, casted on self.
- Support for Greater Rune of Warding, casted on self.
- Experimental: Fix for raid pets targeting when scanning buffs.

## Buffomat Classic and TBC 2021.8.1

- Typo for shaman weapon enchantments main hand was showing as off-hand in tasks

## Buffomat Classic and TBC 2021.7.5

- Druid: Removed "cancelForm" flag from thorns, now should be castable in
  Moonkin form.
- Paladin: Blessing of Sanctuary is now split into normal and Greater, like the
  other blessings, to show in spell list twice.

## Buffomat Classic and TBC 2021.7.4

- Added classic consumables: Greater Intellect elixir +25, and Sages elixir +18
  Int/18 Spi.

## Buffomat Classic and TBC 2021.7.3

- New option: Scan buffs while mounted (default on) - disables annoying Buffomat
  buffs popup while you're traveling to the quest area.

## Buffomat Classic and TBC 2021.7.1-2

- Paladin: Fixed ignore and force cast on blessings. Now you can exclude and
  include targets for more intricate blessing setups.
- TBC: Crusader aura reminder will pop up when you're on a mount.
- TBC: For new Buffomat install all paladin blessings are off by default except
  Might.

## Buffomat Classic and TBC 2021.6.7

- Bug: Physical classes restriction on some consumables did not include
  Paladins. Now this is fixed.
- TBC: Marked consumables from Classic Era as "Classic"

## Buffomat Classic and TBC 2021.6.6

- Changed task wording in the task list and how tasks are sorted and displayed
- Distance calculations code improved, out of range tasks are shown in red
- Group distance calculations code improved
- Do not scan buffs while on a taxi flight
- TBC: Prevent dismount in flight when attempting to cast, OUCH! There is an
  option to enable this behaviour like before.
- TBC: Reminder to unequip carrot now works for riding crop and (not in the game
  yet) druid flight speed trinket.
- TBC: Fixed reminders to unequip AD trinket, added new Naxx trinket versions,
  added new zones: Auchenai and Karazhan to the list of places where undead can
  be found.
- TBC: Hunter pet snacks added (two types for +strength and +stamina)
- TBC: Added Bloodthistle to spell power buffs (Blood elf only)
- TBC: Added Warp Burger, Grilled Mudfish to the 20 AGI/20 SPI buff food
- Warlock: Added Soul Link and Demonic Sacrifice (require pet to be present)
- Warlock: Added pet summon checkboxes. Summon will be inactive if pet of the
  correct family is present, or if demonic sacrifice for that pet is active.
- Localization: Chinese translations updated.

## Buffomat Classic and TBC 2021.6.3

- Reverted change: Hiding window if no cast messages were added by the scan
- Removed addon start message

## Buffomat Classic and TBC 2021.6.1-2

- Fix for script error when combat is restarted due to Mind Control ending
- Fix for open containers feature; New message why contaners won't open because
  player must hold a modifier key - disable in the options.
- Added Soul Link for Demonology Warlocks

## Buffomat Classic and TBC 2021.5.12-DEBUG

- Fel Armor rank 1 and 2 added for warlocks
- BUG: Swapped Sunfruit and Sunfruit Juice (wrong class limits)
- Less aggressive Buffomat window show behaviour, it will not show if there are
  tasks which cannot be completed (like players unbuffed but out of range)
- Rockbiter ranks were all changed for TBC, added new ranks too
- Massive code refactoring

## Buffomat Classic and TBC 2021.5.10

- Renamed option: Scan in rest areas (off by default), before: disable in rest
  areas (on by default)
- New option: Scan in stealth (off by default)
- New classic consumable: Crystal Force +30 SPI
- Some TBC food has new limitations for mana classes only or for physical/melee
  classes only, to reduce the clutter
- Known problem: Tracking is checked periodically and is casted without the need
  to press a button: this sometimes can produce error message "Ability is not
  ready yet"

## Buffomat Classic and TBC 2021.5.8

- Key binding: show/hide Buffomat window, does same as /bom, which you can also
  macro
- Paladin blessings now split into single and greater, TBC allows buffing
  shamans and paladins in the same group
- Option: Disable Buffomat in resting areas (on by default)
- Option: Slower hardware, will use 1.5 sec update instead of 0.5 sec
- Fix: Include and Exclude buttons now work again
- Fix: Spell and item scanning code had a typo
- Fix: Cache for items is now fixed and it should not print item not found
  errors anymore (or do /reload once)

## Buffomat Classic and TBC 2021.5.1-3

- Warlock summoning fix (all channeled spells) - do not get stuck in Busy state
- Enhancement shaman TBC weapons enchant fix (wait for mainhand enchant first)
- Prevent buffing a PVP person if player is not PVP, and is in the open world (
  also an option for it)
- TBC food buffs added
- Option to skip buffing PvP targets if you are not PvP - to prevent PVP
  poisoning of open world raids
- Bug where checking intellect buff or fortitude

## Buffomat Classic and TBC 2021.4.7

- Fixes shaman enchants in live classic; adds new main/offhand enchants for TBC
  shamans

## Buffomat Classic and TBC 2021.4.7

- Paladin blessings now split into single and greater
- Disable Buffomat in resting areas (toggle option, on by default)
- Slower hardware option (toggle option) will use 1.5 sec update instead of 0.5
  sec
- Fix: Include and Exclude buttons now work again
- Fix: Spell and item scanning code had a typo
- Fix: Cache for items is now fixed and it should not print item not found
  errors anymore (or do /reload once)

## Buffomat Classic and TBC 2021.4.0-6

- TBC Classic: New class spells and new consumables
- BUG: TBC tracking (the addon did not know whether tracking was enabled and
  recasted it repeatedly)

## Buffomat Classic 1.9.6

- "Force cast" on target and "Exclude target". Target a member of your group and
  click Force or Exclude button. The setting is saved per character and is not
  reset when you leave raid. Force/exclude button tooltip shows current list of
  names.
- Added Argent Dawn strength food (Blessed Sunfruit)

## Buffomat Classic 1.9.3

- Improved tooltips on self/group buff switches. Inactive switches texture
  changed to gray circle "offline" texture.
- Added Naxxramas instance IDs from Lich King, for AD trinket reminders, seems
  to work in Classic too.
- Update timer is now 1.5 seconds instead of 0.1 seconds (might help Naxx lags)
- There is now group/single buff toggle conveniently placed next to the cast
  button, when you don't want to rebuff but just to refresh single buffs on
  people. This is the same option as in the quick settings menu and in the
  settings window.
- Internal code refactoring for the scan module.

## Buffomat Classic 1.9

- Internal code improvements, even though I constantly play with it and it shows
  no signs of problems, things will possibly be unstable for a moment.
- Menu popup is simpler now, options removed from the main Spells tab. Options
  submenu renamed to "Quick Options" and Options menu item renamed to "Options
  Window".
- Cancel auras now has text label and not just an empty row without any
  explanation. Can cancel int and spirit buffs.
- Added 2 more cancel buffs (int and spirit, useful for tanks in raids). Added
  agi elixir for cheapskates like me.
- Class-restrictions, limiting mana int and spirit buffs to mana classes,
  limiting agi, str and AP buffs to physical dmg classes - makes the list of
  consumables shorter.
- Resurrection targets are sorted to prefer priests, shamans and paladins first
- Multiple nice tooltips added reminding that keybind setting exists and that
  the macro button can be used.
- Buff tab now displays selected buff groups in tab text
- Watched groups are saved if the user is in raid (relogs and reloads do not
  lose the settings). Reset to watch all when user leaves the raid.
- Warriors can now have Battle Shout in watched buffs. Hunters now don't have
  all trackers enabled by default - choose yourself.
- Fonts made slightly bigger
- Green and red circles changed to more familiar checkboxes improving the UI
  overall feel.

## Buffomat Classic 1.83

- Forked and renamed abandoned addon to become "Buffomat Classic". Reuploading
  to Curse.

# Legacy Changelog from Buff'o'mat

## 1.83

- fix a bug with elixier count

## 1.82

- automatic cast tracking-spells

## 1.81

- add ranks for Touch of Weakness

## 1.80

- show item count (note for group buffs, it will count all variants (e.g.
  candles) and don't care about the rank of the spell)
- fix itemcache

## 1.76

- fix weapon-buff

## 1.75

- Support for Crippling Poison, Wound Poison, Instant Toxin, Instant Poison,
  Mind-numbing Poison, Deadly Poison, Elemental Sharpening Stone, Consecrated
  Sharpening Stone, Sharpening Stone, Weightstone, Blessed Wizard Oil, Brilliant
  Wizard Oil, Brilliant Mana Oil
- "preload" item-information.
- repair Mageblood Potion

## 1.74

- Fix Bug with weapon-enchantments
- Add Brilliant Mana Oil & Brilliant Wizard Oil

## 1.73

- more optimizations

## 1.72

- redesign spell-tab (config-section)
- cached-item-scan - should be much faster
- "slow-mode" - reduce refresh-rate, when the update of the list is slow.

## 1.71

- Bugfixes

## 1.70

- "wispher source-warlock when soul stone buff expired" should work without
  activate the info "soul stone"
- add a short delay after a loading screen
- TOC-Update

## 1.63

- New: Keybinding for the macro
- Alt-Key reset skip- and is resurrected-list
- add optional wispher source-warlock when soul stone buff expired
- soul-stone should remember last person who got a soulstone from the player

## 1.62

- split Mage Conjure Mana Ruby
- minor changes for resurrection

## 1.61

- fix stupid bug

## 1.60

- change refresh rate

## 1.54

- correct Buff-Food - SpellIds - should work now
- Option "Don't use consumables. Just inform." - when you hold shift/ctrl/alt it
  will use the consumables

## 1.53

- remove consumables from popup-menu (to large list)
- improve list in the spell-tab
- add mage ice barrier
- add priest Shadowform

## 1.52

- consumables are now in a submenu

## 1.51

- Support for Consumables Elixir of the Mongoose, Mageblood Potion, Elixir of
  Fortitude, Elixir of Superior Defense, Major Troll's Blood Potion, Gift of
  Arthas, Juju Power, Elixir of Giants, Juju Might, Winterfall Firewater,
  Greater Arcane Elixir, Elixir of Shadow Power, Elixir of Greater Firepower,
  Elixir of Frost Power, Juju Ember, Juju Chill, Crystal Ward, Crystal Spire,
  Grilled Squid, Smoked Desert Dumplings, Nightfin Soup, Runn Tum Tuber
  Surprise, Dirge's Kickin' Chimaerok Chops, Blessed Sunfruit Juice, Blessed
  Sunfruit, Kreeg's Stout Beatdown, Gordok Green Grog, Rumsey Rum Black Label,
  Greater Arcane Protection Potion, Greater Fire Protection Potion, Greater
  Frost Protection Potion, Greater Nature Protection Potion, Greater Shadow
  Protection Potion, Noggenfogger Elixir, Savory Deviate Delight

## 1.50

- bugfixes / release

## 1.46

- bugfixes

## 1.45

- option: Always buff self first
- targets and pets are now buffed at last

## 1.44

- resurrection ignores pets.
- profile-system - default off. Automatic switch between
  solo,group,raid,battleground. You can temporary force a profile for
  configuration (pop-menu)
- clears skip-list after combat

## 1.43

- option for pets in spells. Pets in Phase Shift are ignored

## 1.42

- Option to automatic open lootable items, ignores locked (default on)

## 1.41

- add: Mage Amplify Magic
- fix: Single-Buff on spezific group member - option was missing
- New: Option to select a Buff for Tanks (only in Raid, when tanks are set)
- Automatic Cancelling of "Blessing of Salvation / Greater Blessing of
  Salvation" - hidden when player is horde
- Remove Aspect of the Cheetah/Aspect of the Pack direct before a combat (
  default on) - hidden when player is not a hunter

## 1.40

- clarified option "Watch only when in same zone"
- "Targets" are now always in the same zone

## 1.35

- optional: Remove Aspect of the Cheetah/Aspect of the Pack direct before a
  combat (default on)

## 1.34

- some bugfixes

## 1.33

- fix downgrade-system and reactivate "use rank"
- Add: Priest Elune's Grace & Power Word: Shield
- Add: Dampen Magic
- Optional: Automatic Cancelling of "Power Word: Shield" and "Blessing of
  Salvation / Greater Blessing of Salvation"

## 1.32

- optional: Add current Target in List.
- new downgrade system. When a spell is rejected with a "player is to low"
  -errormessage, the next time buff'o'mat try to cast a lower version of the
  spell.

## 1.31

- List sorted by name
- correct maximum macro limit
- Blessings - it was possible, that to many manual single-Target will trigger a
  group buff.
- rework skip mechanic - should not stuck anymore
- New: Check for "Carrot on Stick"-Buff in dungeons

## 1.30

- release
- Better detection of the Soulstone CD.

## 1.26

- hide window, when combat starts
- Warlock: Demonic Sacrifice, Firestone, Healthstone, Soulstone
- Mage: Manastone
- Items: Remember, when a Soulstone exist and has no CD.

## 1.25

- optional: automatic dismount/stand up/remove travel form after
  casting-errorType Ghost/Druid-Travel form is only out of combat automatic
  removeable

## 1.24

- Repair Group-Buff-Detection / Error-Message

## 1.23

- add event/detect for weapon-enchantments
- repair Flametongue detection

## 1.22

- Support for temporary weapon-enchantments
- optional: warn if main/secondry hand weapon echantment is missing (default
  off)
- Shaman: support for Flametongue, Frostbrand, Windfury Weapon

## 1.21

- Optional: Infos for Soulstones, who eats and drinks (default off)
- Optional: Add Rank on spell-cast in the macro (default on)
- New Skip-Mechanic. When a Spell can't be casted, it will be skiped until every
  other spell is casted.
- Add Rockbiter Weapon and Lightning Shield from Shaman

## 1.20 -Russian update by Arrogant_Dreamer

## 1.12

- Option: Remember to (un)equip Argent Dawn Commission
- Option: Disable in World/Battleground/Instance

## 1.11

- Option: Number of missing blessing required to use a Greater Blessing

## 1.10

- Update TOC
- Option: Number of missing buffs required to use a group buff

## 1.03

- Nature's Grasp - CD-Detection
- Nature's Grasp - when inside the buff is visible in the list, but buff'o'mat
  will not cast it

## 1.02

- new option: Replace single buff with group buff (when more than 3)
- magier spell: Mana Shield
- druid spell: Nature's Grasp
- Paladin: More blessing and greater blessing

## 1.01

- set minimum width to 256 pixels
- add Shadowguard (troll-priest)

## 1.00

- fix Hunter and Feign Death (buff-time-reset)
- update Chinese translation by wellcat
- Russian translation from Arrogant_Dreamer
- detection of minmap-shape

## 0.96

- new option: "resurrect ghosts"
- Thanks to OlivBEL for the french translation
- new Option-Tab Localization
- some code-optimizations
- improved auto open/close
- Additional CD-Check for Fear Ward

## 0.95

- Tracking is now prio (because it doesn't cost mana)
- Always prio resurrections
- Rename Option to "Don't cast group buffs, when somebody is dead"
- fix bug with druid human tracking

## 0.94

- Always resurrect, even when group in raid is disabled
- Normal-Settings also in "spells"-tab
- disable Tab-Switch during combat
- some cosmetic changes

## 0.93

- Add "Set"-Button for setting the activ seal/aura/tracking
- Tooltip for "Supported Spells"
- Menu optimizations
- improved detection of buff duration/expirationTime of group/raid-members

## 0.92

- bugfix

## 0.91

- Fix: "Blessing of Wisdom" was linked with Blessing of Might
- Option "Rebuff when expired in x seconds"
- rework buff finding
- Add on SpellsTab "Watch group in raid"

## 0.90

- new TABs on main window
- Tab Buff - old "Main"-window
- Tab Spells - configuration of every spell Icons from left to right: on/off,
  all/self, on classes, Always on Person X (current target!)
  This settings are stored per character!
  Simple click on a icon to toogle!
- repair /cancelform for druids

## 0.80

- fix bug in blessing
- druid-buffs include a "/cancelform"
- add fearward

## 0.71

- Mage Armor-Spells use now "Seals"-Mechanik, only one can be active
- Aura - track only casted by player
- Add Paladin-Seals - default off

## 0.70

- new Tracking-Detection. Always want to cast the last active tracking.
- Track Humanoids (as cat) -> more tests needed!
- Paladin/Hunter/Druid -> more tests needed!

## 0.60

- update-check-Optimizations
- Reset "HasResurrection"-Check after combat
- new Message "somebody is dead"
- Group buff only, when everybody is in range
- Error-Message, when macro can't created
- Option "Only in same zone" - for example when in raid are persons without the
  prequest.
- Add druid-buff "Omen of Clarity"

## 0.50

- Repair hasResurrection detection - should not resurrect somebody which has
  already resurrected
- Option "Only buff self"
- Option "Ignore in raid group x"

## 0.40

- Chinese translation by wellcat
- add "Find Treasure" tracking spell
- fallback resurrection, try to resurrect a "ghost"-player
- Use now Rank and better spell-detection

## 0.30

- resurrection optimizations
- buff handling optimizations
- fix bug with mages
- bug fixes

## 0.20

- repair distance-check (list) / Sort order List
- Wait for SPELLS_CHANGED Event before scanning for spells
- party update only on special events
- Option "Don't use group buff"
- minimap-button indicates now missing buffs
- better combat - detection / indicates
- disable button while global cool-down
- disable button while casting
- disable button while combat
- many small changes and bug fixes

## 0.10

- first release\_
