# Changelog

<!--
Buffomat shows this file in the game, in the What's new window (wowaddon.py writes it into
Src/Changelog.lua). Start every point with a short title phrase in bold: the window shows it in red.
The window stops at the next top-level heading, so the legacy changelog below is not shown.
-->

## Buffomat Classic 2026.11.5

- **What's new window.** This list of changes is now in the game: the versions on the left, and the changes
  of the chosen version on the right. Open it with `/bom changes` or from the quick settings menu.
- **Welcome message.** When you log in, Buffomat says its version in chat, with a link which opens the
  What's new window. A new checkbox on the General options page turns the message off.

## Buffomat Classic 2026.11.4

- **Faster scanning.** The scanner was rewritten. Buffomat no longer rescans everything twice a second: it
  reacts to game events, reads only what changed (in a raid, only the members whose buffs changed), and
  redraws the task list only when it changed. A change shows up in the task list within a fraction of a
  second. Buff timers and cooldowns are checked exactly when they run out.
- **Items on cooldown.** Fixed: an item on cooldown (for example a Soulstone) made Buffomat rescan
  constantly.
- **Greater Blessings.** Fixed: a Greater Blessing for a class raised an error instead of adding a task.
- **Out of range in a raid.** Fixed: in a raid, raid-wide group buffs and class blessings showed a red
  "out of range" line.
- **Player counted twice.** Fixed: in a raid the player was counted twice, once in group 1.
- **Scan statistics.** `/bom scanstats` prints scan statistics while debug logging is on.
- **Choose the chat commands.** New options on the General page choose the chat commands: `/bom`, `/bfm`
  and `/buffomat`. The shortest one chosen is used in the Buffomat macro. A change takes effect after
  `/reload`.

## Buffomat Classic 2026.11.2

- **Reminders for levelling characters.** WoW: Forever reminders, hidden at level 60. Both are on by
  default; turn them off in the new Reminders section at the top of the Spells window, or under [Forever]
  on the Scan options page:
  - **Camp Benefits.** Near a campfire without Camp Benefits, or with them running out, a task says to sit
    by the fire.
  - **Experience.** A task when you are not Well Fed (+5% kill experience) or carry a sleeping bag without
    its bonus, with your rested experience.
- **Forever defaults.** WoW: Forever: Blessing of Kings is on by default for Mages, Priests and Warlocks
  (Might stays on for physical classes). Imbue scrolls are for mages only. The beta-only Endless elixirs
  and scroll are removed.
- **Corrected buffs.** Seal of Wisdom knows ranks 2 and 3; Elixir of the Sages shows on Classic Era and
  WoW: Forever again; Blessed Wizard Oil and Consecrated Sharpening Stone count as 1-hour enchantments.
- **Hidden buffs shown.** Buffs that were never listed in the Spells window now show: Elixir of Greater
  Intellect, Juju Ember, Juju Chill, Crystal Ward, Crystal Spire, Crystal Force, and paladin Seal of
  Justice.
- **New consumables.** Elixir of Brute Force, Elixir of Fire Power, Elixir of Minor Fortitude, Rumsey Rum
  Dark, Scrolls of Stamina I-IV. Lower ranks join existing groups: Elixir of Wisdom (Intellect), Minor,
  Lesser and regular Defense elixirs (Armor, with Superior Defense), Mighty Troll's Blood (health
  regeneration), Scrolls of Agility and Strength I-II. Existing settings for these buffs are kept.
- **Consumables by level.** Consumables are hidden until the player reaches the required level of at least
  one of their items (the check now takes the lowest item level and updates when item data loads or the
  player levels up).
- **Buff level limits.** Buff level limits work again: Aspect of the Monkey hides above level 74 in WotLK.
- **About page.** New About page in the options with usage notes and credits, including data from
  ForeverDB.net.
- **Numbered options tabs.** Options tabs are numbered 01, 02, ... so the About tab sorts last.
- **Top buttons on Forever.** The task list's top buttons line up on WoW: Forever, where the close button
  is smaller.

## Buffomat Classic 2026.11.1

- **Stones by weapon type.** Sharpening stones are suggested only for bladed weapons and weightstones only
  for blunt weapons (maces, staves, fist weapons); Elemental and Consecrated stones only for melee weapons,
  not fishing poles.
- **WoW: Forever update.** Buffs and consumables for client build 1.60.1.70862:
  - **Raid-wide group buffs.** Group buffs cover the whole raid, like WotLK; dual specialization profiles
    work.
  - **Durations.** Blessings last 60 minutes; Fortitude, Mark of the Wild, Arcane Intellect and Divine
    Spirit 60 minutes; Fear Ward 3 minutes.
  - **Removed spells.** Removed spells are hidden: Blessing of Light, Salvation and Sanctuary (and
    Greater), Sanctity Aura, Omen of Clarity (now passive), Elune's Grace ranks 2-5 (rank 1 stays for
    Night Elf priests).
  - **New spells.** Druid Revive, paladin Seal of Fury and Oath of Light, new ranks of Trueshot Aura and
    Aspect of the Beast.
  - **Warlock stones.** Firestone and Spellstone are tracked as 2-hour weapon enchantments.
  - **Consumables.** Food is grouped by the single stat its Well Fed buff gives; new elixirs, Natural
    flasks, Familiar and Imbue scrolls; Elixir of Greater Firepower became Elixir of Holy Power; Greater
    Protection Potions are no longer treated as long buffs.
  - **Reagent Economy.** With the Legacy talent Reagent Economy the reagent count is hidden for vendor
    reagents.
  - **Imbue scrolls.** Imbue scrolls are suggested only for a weapon they fit (staff, dagger or one-handed
    sword), and the spells dialog shows the weapon type.

## Buffomat Classic 2026.11.0

- **Hunter tracking in TBC.** Hunter tracking is using the correct API in TBC.

## Buffomat Classic 2026.10.5

- **PvP matches.** Restrict aura scanning while a PvP match is active. Checks of the items in the bags
  (conjured items) and of weapon enchantments still should operate normally.
- **Travel form.** Fixed: "Auto cancel travel form" never cancelled Ghost Wolf or Travel Form (broken
  since 2022).
- **Popup menu error.** Fixed: Lua error from the options popup menu callback (removed call into deleted
  UI code).
- **WotLK hit food.** Fixed: the WotLK hit food group offered haste food instead of Worg Tartare/Snapper
  Extreme.
- **Reagent count.** Group buff tasks show the reagent count again (for example Arcane Powder x12).
- **Crosshair icon.** Single buff and blessing tasks show the crosshair icon again for players with a
  forced or assigned target.

## Buffomat Classic 2026.10.4

- **Error inside Forever instances.** On Forever, inside instances, UnitIsUnit("targettarget", "player")
  returns a secret boolean. UNIT_POWER_UPDATE fires for every unit token, and the event handler used that
  result in an `if`, which threw the error.
- **Forever compatibility.** Port Forever compatibility from yannlugrin/Buffomat through `69564aa`: weapon
  imbues, restriction-aware scans, class options, and moved client APIs.
- **Classic fallbacks.** Keep Classic client fallbacks and pause scans when aura or enchant data cannot
  be read. Fix the legacy spell cooldown fallback and secret cooldown handling.

## Buffomat Classic 2026.5.2

- **Hide when scanning is off.** A new convenience option for hiding the window if scanning is disabled,
  for whatever reason.
- **Translations.** Translations updated.

## Buffomat Classic 2026.3.0

- **Pets in other languages.** Fix for pets not being detected correctly in other languages than English
  (by jdelvare).

## Buffomat Classic 2025.5.5

- **Missing buffs for a group buff.** Fixed an issue with the "Missing Buffs to use a group buff" setting,
  where setting it to 2 (or higher) would cause buffs to not be detected or applied when only 1 party
  member was missing the buff. The logic now properly checks per-group requirements for pre-WotLK and
  total requirements for WotLK, ensuring single buffs are cast when group buffs don't meet the threshold.

## Buffomat Classic 2025.5.4

- **Spell downranking.** Restored the old broken feature, where a spell would automatically downrank if
  casted on a target too low level. As there isn't a way for addon to know it, it will learn from
  unsuccessful casts (you will need to cast the same buff again after it has learned). Requires enabled
  option for Downranking in 4.Convenience options tab.
- **Autoshow.** Reintroducing the option "Autoshow": when disabled, the task list will not be auto-showing
  till user actually calls it with a hotkey or menu, regardless of whether there are tasks or not.
- **Mage armor duration.** Mage armor-type spells have now duration set to 30min, to allow better estimate
  of remaining duration for rebuffing.

## Buffomat Classic 2025.5.3

- **Drive-by buffing.** Option for drive-by buffing: your target is considered for a buff check, even if
  not part of the group.

## Buffomat Classic 2025.5.1

- **Fade opacity.** Min fade opacity lowered to 0.1 (10%).
- **Auto close.** An option was reintroduced: Auto close. When active, and the window would fade due to no
  tasks available, it will hide instead till the next scan. The window will be shown again if there's a
  buff to refresh.

## Buffomat Classic 2025.3.4 / 2025.5.0

- **New user interface.** Big UI overhaul: new task list window, simpler and faster, new spell settings,
  easier access to main settings, multiple minor UI improvements, too.
- **Window behaviour.** Window hide/fade/show behaviour has changed to be less annoying and more like the
  previous version.

## Buffomat Classic 2025.1.0, 2025.2.0

- **Group buffs.** Found a possible reason for group buffs not working. Releasing a beta fix.
- **Classic 1.15.6.** Version bump with WoW Classic updated to 1.15.6.

## Buffomat Classic 2024.7.1

- **Macro window.** When the Macro edit frame is open, Buffomat will sleep.
- **Alphabetical buffs.** Sorting the buffs inside each group alphabetically.

## Buffomat Classic 2024.7.0

- **Paladin: Crusader Aura.** In Cataclysm Crusader Aura has changed its shapeshift id from 7 to 5. This
  update will fix the Crusader Aura autobuff behaviour in Cataclysm.

## Buffomat Classic 2024.6.2

- **Mage: mana gem.** Mana gem fixed.
- **Cataclysm clams.** Added Abyssal Clam and older clams to the openable containers list.
- **Flask of Enhancement.** Cataclysm: the alchemist-only Flask of Enhancement added.

## Buffomat Classic 2024.5.4

- **Cataclysm prepatch.** Prepatch fix. Stay tuned for the actual Cataclysm update.
- **Cataclysm consumables.** Elixirs, flasks, food buffs.
- **Rogue poisons.** Cataclysm rogue poisons. Also see: Restocker Classic addon to auto-buy.
- **Priest buffs.** Cataclysm priest buffs fix.
- **Buffs providing auras.** Bug: 'providesAuras' was working for consumables only, now also for buffs.
  Allows to account for fortitude and shadow protection being already on priest.
- **Still missing.** Combo meals, alchemist flask.

## Buffomat Classic 2024.4.0

- **Druid: Moonkin form.** Do not /cancelform in moonkin form, by adding `[noform:5]` to it.
- **Minimap button.** Minimap button is now using LibAce's standard library. Removed options for button
  rotation and distance, as they're now handled by the external library. Clicking the button toggles the
  window, right clicking shows quick menu.
- **Minimap button cleanup.** Bug: a remaining reference in code to minimapButton is removed.

## Buffomat Classic 2024.3.0

- **Shaman: dual wield.** Season of Discovery: dual wield enchantments work again. Known problem: you
  can't leave mainhand unenchanted, it always does mainhand first.

## Buffomat Classic 2023.12.1

- **Hunter: Heart of the Lion.** Season of Discovery: the Heart of the Lion 10% stats aura.

## Buffomat Classic 2023.11.4

- **Food grouped by stat.** Single rows for each food buff are now grouped per stat they provide, including
  all levels (helps while leveling). The highest available in your bag will be eaten first (and a setting
  to choose lowest first).
  - **Green text.** New grouped buffs are marked with green text.
  - **Highest or lowest first.** New option (last in the "Scan Options") to prefer either highest available
    item, or lowest. Lowest is useful when leveling, to consume your lowest level consumables first.
  - **Items for a buff.** Clicking the icon in the buff list prints all items which can provide this buff,
    from lowest to highest.
  - **While eating.** Added food eating auras to the ignore list to hide the food buff task while eating,
    so it doesn't get eaten multiple times.
- **Known bug: flask after resurrection.** Soon after resurrecting under the flask effect, Buffomat can
  show a task for reflasking. It disappears a second or two later.
- **Empty raid groups.** In raid, staggered per-group updates now will skip empty 5man groups, which will
  result in faster updates overall.

## Buffomat Classic 2023.11.1

- **Consumables above your level.** Hide consumables which have required level above player. If multiple
  items provide the buff, choose the lowest level requirement.

## Buffomat Classic 2023.11.0

- **KvLib copy.** Updated the copy of KvLib for classic compatibility. Was using Windows directory
  Junctions before and that didn't go well.
- **Weapon enchantments.** Bug: now updating player weapon enchantments on unit buff rescan. This helped
  solve the long standing Rockbiter bug.

## Buffomat Classic 2023.9.0

- **Druid: Thorns.** 10min rebuff time was not working with druid Thorns.

## Buffomat Classic 2023.8.0-1

- **Classic Hardcore.** Fixing bugs related to Classic Hardcore: item ids from future expansions leaking
  into Classic don't work well.
- **Bag access.** Fixing API incompatibility for bag access, which changed somewhere later in a future
  expansion, causing errors in Classic.

## Buffomat Classic 2023.5.0

- **Rogue: mainhand enchantment.** Bug: mainhand enchantment for rogue failed on non-English clients.
  Thanks to @jdelvare for the suggested fix.

## Buffomat Classic 2023.4.1

- **Fishing poles.** Bug: should not suggest enchanting fishing poles, or if a weapon is not equipped.

## Buffomat Classic 2023.4.0

- **Offhand error at login.** Bug: on login with a missing offhand weapon buff, an error was popping up.

## Buffomat Classic 2023.2.0

- **Bag updates.** New bag event added for more consistent bag updates (thanks to jdelvare at Github).

## Buffomat Classic 2023.1.5

- **Removed consumable.** Bug: throwing away/removing a consumable from your bag, while a consumable task
  for that consumable was active, caused an error.

## Buffomat Classic 2023.1.4

- **Ulduar patch API.** Fix for the Ulduar patch: Lua API for containers and tracking changed to the
  Dragonflight API version.

## Buffomat Classic 2023.1.1

- **WotLK 3.4.1.** Version increase for the Ulduar patch.
- **Flask of the North.** Flask of the North support.
- **Elixir item ids.** 2 elixirs changed item ID from TBC into WotLK, now changed.

## Buffomat Classic 2022.12.2

- **No sound.** Added a no sound option in the play sound dropdown in the settings.
- **Prayer skip lists.** Prayer of Spirit, Fortitude and Intellect buffs skip lists cleared (previously
  would skip these buffs if Sunwell aura is up or if fel intelligence from a warlock is present).

## Buffomat Classic 2022.12.1

- **Other languages.** Fix: locales other than English fixed.
- **TBC buffs in WotLK.** Fix: some sneaky bugs where buffs introduced in TBC were only allowed in TBC and
  not in WotLK.
- **German.** German language updated a bit.

## Buffomat Classic 2022.12.0

- **Type specs.** Large refactor and type specs for most fields and functions, using Luanalysis.
- **Old bugs.** Some bugs might have just disappeared.
- **New bugs.** Some new bugs possibly added, but should be minor and short lasting while i'm finding and
  fixing them.
- **Crusader Aura prompt.** Crusader aura prompt will not pop up on the taxi or in a vehicle.
- **Flask of the North.** Alchemist-only Flask of the North added.
- **Task list.** Visual fixes to the task list.
- **TBC and Classic releases.** Won't be tagging releases for TBC and classic anymore. They are not tested
  for that but might still work.

## Buffomat Classic 2022.11.0.2

- **Fel Intelligence.** Ignore Priest Spirit buff and Mage Intellect buff, when Warlock Fel Intelligence
  is active.
- **MinBuff respected.** Bug: respect the MinBuff option (amount of missing buffs in party or on player to
  choose group buff).
- **MinBuff not set.** Bug: script error if the MinBuff option is not set.

## Buffomat Classic 2022.11.0

- **Group buff range.** In WotLK group buffs lost the ability to check whether an unit is within spell
  range. I am using single buff spell name for testing range which results in much shorter but still
  reliable range checks (30 yd instead of 100+). Keep in mind group buffs also check line of sight.

## Buffomat Classic 2022.10.4, 10.5

- **Spell tab updates.** Spell tab update is now hard limited in frequency to combat the raid lag.
- **Buff scan updates.** Buff scan update is also hard limited in frequency for the same reason.
- **Horn of Winter.** Horn of Winter rank 2 added.
- **Task sound.** Option to play sound when Buffomat has something to do.
- **Unit cache.** Unit cache is less aggressive, this should help buffs to update faster.

## Buffomat Classic 2022.10.1, -10.2

- **Group buffs on self.** Group buffs will now apply to self, if no group member in range. This needs to
  be tested in real raid so will give it some time before promoting to release.
- **Group buff range.** Fixes for group buff range check.
- **Intellect scrolls.** Intellect scrolls?

## Buffomat Classic 2022.9.6

- **Pet food for all.** Pet food is now available for all classes, not just hunters.

## Buffomat Classic 2022.9.5.1

- **Shaman: water spells.** Water Walking, Water Breath now in Buffomat, require no reagent with WotLK
  Glyphs.
- **Shaman: spellhance weapons.** Spellhance weapon enchants option (on by default) to enchant main hand
  with 1 rank lower flametongue.
- **Priest: Vampiric Embrace.** Vampiric Embrace is now a buff.

## Buffomat Classic 2022.9.4, 4.1

- **Death Knight.** Horn of Winter; Bone Shield.
- **Group buff distance.** Bug: crash on group buffs distance check fixed.

## Buffomat Classic 2022.9.3

- **K'iru's Song of Victory.** Bug: K'iru's Song of Victory correctly works for priests.

## Buffomat Classic 2022.9.2.2

- **Classic.** Classic compatibility fix.

## Buffomat Classic 2022.9.2.1

- **Performance.** Performance improvements; a fix to the raid lag bug is in the testing before this file
  is promoted from beta to release.
- **Dual specialization.** For WotLK with dual specialization, auto-profiles and profile selector now
  recognize second set of talents.

## Buffomat Classic 2022.9.1

- **Shaman: Earthliving Weapon.** Earthliving Weapon self-enchantment added.
- **Paladin: Seal of Command.** Seal of Command was missing, now added.

## Buffomat Classic 2022.9.0

- **Tracking in WotLK.** Tracking herbs/ore feature restored.
- **Crippling Poison.** Crippling Poison was disabled in WotLK incorrectly.
- **Golden Fish Sticks.** Bug: Golden Fish Sticks had same buff id as (mistakenly) Skullfish Soup.
- **Choosing a profile.** Bug: script error when choosing a profile.

## Buffomat Classic 2022.7.5

- **Buffs tab rebuilds.** Throttled rebuild frequency of abilities/buffs tab to max 1 per second. This
  seems to have triggered lags in battlegrounds and raids. Being throttled at a wrong time means that we
  must update as soon as the throttle allows, so the update is performed asap after the cooldown window.

## Buffomat Classic 2022.7.4

- **Rogue poisons.** WotLK rogue poison ranks updated.
- **Old TBC addon.** Installing 7.2 or newer addon will also install a dummy addon named
  "BuffomatClassicTBC" which deactivates the old TBC version of the addon and allows reimporting of the
  old settings.

## Buffomat Classic 2022.7.1

- **One addon for all versions.** All versions of addon are now merged into one, and you should delete
  (either automatically or manually) the old "Buffomat Classic TBC".
- **Wrath of the Lich King.** A big new wave of updates for Wrath of the Lich King:
  - **Spells.** New class spell ranks.
  - **Elixirs.** New elixirs.
  - **Food.** New food.
  - **Weapon enchantments.** New weapon enchantments.
- **Buff category visibility.** A new page in Options which allows Visibility selection for buff
  categories. Invisible categories are not scanned, even if they're checked.
- **K'iru's Song of Victory.** Skip mage Intellect buff if K'iru's Song of Victory is up in SWP or the
  island. Same for group buffs (Arcane Brilliance).
- **Hunter pet food.** Hunter pet food buff was broken and fixed.
- **Known problem: empty spell tab.** On first start the spell tab can look empty, do a `/reload` one time.

## Buffomat Classic and TBC 2022.5.5

- **Classic.** Fix for classic version (script error).

## Buffomat Classic and TBC 2022.5.1

- **Buff categories.** Grouped buffs by categories.
- **Icons and names.** Bug: try cache items and spells and update all spells list icons and text.
- **Arena riding trinket.** Added riding trinket reminder in Arena zones, do not forget your trinkets!
- **Crusader Aura.** Bug: allow Crusader Aura suggestion even if mounted buffing is disabled.
- **Chinese.** Chinese language update (contributed by nanjuekaien1 @github).

## Buffomat Classic and TBC 2022.4.1

- **Pet zone.** Pet zone is now bound to player zone and buffing pets should work again (contributed by
  @Anonomit on github).

## Buffomat Classic and TBC 2022.3.4, 3.5

- **AceGUI.** Bug: added AceGUI to embeds.xml, this seems to be required by the options page.
- **Library order.** Bug: order of lines in embeds.xml.
- **Classic Era 1.14.2.** Updated build number for Classic Era (11402).

## Buffomat Classic and TBC 2022.3.2

- **Remaining durations.** Script error fixed for uninitialized values of remaining durations settings.

## Buffomat Classic and TBC 2022.3.1

- **Shattrath flasks.** Shattrath Flasks added.
- **Missing names.** Item/spell info queries refresh spell tabs when they succeed, to fix the old problem
  with missing spell/item names.

## Buffomat Classic and TBC 2022.2.5, .6

- **Find Fish.** Added Find Fish tracking.
- **CallbackHandler.** Packaging error: library CallbackHandler was included but not embedded properly, so
  on systems without other Ace3 addons it would blow up with a script error.

## Buffomat Classic and TBC 2022.2.4

- **Ace3.** Using new tech now: AceAddon, AceConfig, and event handlers from Ace.
- **Spirit Tap slider.** Changed Spirit Tap setting to a slider, the previously set boolean value is now
  lost as the variable was renamed and became a percentage.

## Buffomat Classic and TBC 2022.2.1, and .2

- **Someone is drinking.** Option to hide "Someone is drinking message", off by default, enable to hide.
- **Priest: Spirit Tap.** Option to disable Buffomat if priest's Spirit Tap talent is active (to maximize
  mana regen by preventing priest self-buffing after the combat). Off by default, click to enable (also
  please be a priest!).
- **Incubus.** Incubus pet creature family was set incorrectly to "Succubus" and this did not really work
  well.

## Buffomat Classic and TBC 2022.1.2

- **Drinking.** Show a comment when someone in party or raid is drinking.
- **Summon Incubus.** Added Summon Incubus spell, sacrificeable just like succubus.

## Buffomat Classic and TBC 2022.1.1

- **Chinese.** Chinese language updated.
- **Window on screen.** Buffomat window now clips to screen (never goes off-screen).
- **Macro icon.** Icon for macro is changed to INV_MISC_QUESTIONMARK which instructs the game to change
  the macro icon dynamically to the first spell in the macro.

## Buffomat Classic and TBC 2022.1.0

- **Pets.** Fix for raid pets/party pets buffing.
- **Unknown unit id.** Fix for "unknown unit id" error, thanks to Anonomit @github for reporting and
  explaining the cause.
- **UI scale.** UI scale option (default to 1.0) allows you to shrink or expand the window (for example
  when you are running on 4k resolution). Hide and show Buffomat to apply the new value.

## Buffomat Classic and TBC 2021.10.1-3

- **Scrolls.** Support for scrolls of strength, agility, spirit, protection, casted on self.
- **Greater Rune of Warding.** Support for Greater Rune of Warding, casted on self.
- **Raid pets.** Experimental: fix for raid pets targeting when scanning buffs.

## Buffomat Classic and TBC 2021.8.1

- **Shaman: main hand.** Typo: shaman main hand weapon enchantments were showing as off-hand in tasks.

## Buffomat Classic and TBC 2021.7.5

- **Druid: Thorns.** Removed "cancelForm" flag from thorns, now should be castable in Moonkin form.
- **Paladin: Blessing of Sanctuary.** Blessing of Sanctuary is now split into normal and Greater, like the
  other blessings, to show in spell list twice.

## Buffomat Classic and TBC 2021.7.4

- **Classic elixirs.** Added classic consumables: Greater Intellect elixir +25, and Sages elixir +18
  Int/18 Spi.

## Buffomat Classic and TBC 2021.7.3

- **Scan while mounted.** New option: Scan buffs while mounted (default on) - disables annoying Buffomat
  buffs popup while you're traveling to the quest area.

## Buffomat Classic and TBC 2021.7.1-2

- **Paladin: blessing targets.** Fixed ignore and force cast on blessings. Now you can exclude and include
  targets for more intricate blessing setups.
- **Crusader Aura reminder.** TBC: Crusader aura reminder will pop up when you're on a mount.
- **Paladin: default blessings.** TBC: for a new Buffomat install all paladin blessings are off by default
  except Might.

## Buffomat Classic and TBC 2021.6.7

- **Paladins as a physical class.** Bug: physical classes restriction on some consumables did not include
  Paladins. Now this is fixed.
- **Classic consumables.** TBC: marked consumables from Classic Era as "Classic".

## Buffomat Classic and TBC 2021.6.6

- **Task wording.** Changed task wording in the task list and how tasks are sorted and displayed.
- **Out of range tasks.** Distance calculations code improved, out of range tasks are shown in red.
- **Group distance.** Group distance calculations code improved.
- **Taxi flights.** Do not scan buffs while on a taxi flight.
- **Dismount in flight.** TBC: prevent dismount in flight when attempting to cast, OUCH! There is an
  option to enable this behaviour like before.
- **Riding trinkets.** TBC: reminder to unequip carrot now works for riding crop and (not in the game yet)
  druid flight speed trinket.
- **Argent Dawn trinket.** TBC: fixed reminders to unequip AD trinket, added new Naxx trinket versions,
  added new zones: Auchenai and Karazhan to the list of places where undead can be found.
- **Hunter pet snacks.** TBC: hunter pet snacks added (two types for +strength and +stamina).
- **Bloodthistle.** TBC: added Bloodthistle to spell power buffs (Blood elf only).
- **Agility and spirit food.** TBC: added Warp Burger, Grilled Mudfish to the 20 AGI/20 SPI buff food.
- **Warlock: Soul Link and Demonic Sacrifice.** Added Soul Link and Demonic Sacrifice (require pet to be
  present).
- **Warlock: pet summons.** Added pet summon checkboxes. Summon will be inactive if pet of the correct
  family is present, or if demonic sacrifice for that pet is active.
- **Chinese.** Localization: Chinese translations updated.

## Buffomat Classic and TBC 2021.6.3

- **Window hiding.** Reverted change: hiding window if no cast messages were added by the scan.
- **Start message.** Removed addon start message.

## Buffomat Classic and TBC 2021.6.1-2

- **Mind Control.** Fix for script error when combat is restarted due to Mind Control ending.
- **Open containers.** Fix for open containers feature; new message why containers won't open because
  player must hold a modifier key - disable in the options.
- **Soul Link.** Added Soul Link for Demonology Warlocks.

## Buffomat Classic and TBC 2021.5.12-DEBUG

- **Fel Armor.** Fel Armor rank 1 and 2 added for warlocks.
- **Sunfruit.** Bug: swapped Sunfruit and Sunfruit Juice (wrong class limits).
- **Window showing.** Less aggressive Buffomat window show behaviour, it will not show if there are tasks
  which cannot be completed (like players unbuffed but out of range).
- **Rockbiter.** Rockbiter ranks were all changed for TBC, added new ranks too.
- **Refactoring.** Massive code refactoring.

## Buffomat Classic and TBC 2021.5.10

- **Scan in rest areas.** Renamed option: Scan in rest areas (off by default), before: disable in rest
  areas (on by default).
- **Scan in stealth.** New option: Scan in stealth (off by default).
- **Crystal Force.** New classic consumable: Crystal Force +30 SPI.
- **TBC food by class.** Some TBC food has new limitations for mana classes only or for physical/melee
  classes only, to reduce the clutter.
- **Known problem: tracking.** Tracking is checked periodically and is casted without the need to press a
  button: this sometimes can produce error message "Ability is not ready yet".

## Buffomat Classic and TBC 2021.5.8

- **Key binding.** Key binding: show/hide Buffomat window, does same as /bom, which you can also macro.
- **Paladin: single and greater blessings.** Paladin blessings now split into single and greater, TBC
  allows buffing shamans and paladins in the same group.
- **Rest areas.** Option: Disable Buffomat in resting areas (on by default).
- **Slower hardware.** Option: Slower hardware, will use 1.5 sec update instead of 0.5 sec.
- **Include and Exclude.** Fix: Include and Exclude buttons now work again.
- **Scanning typo.** Fix: spell and item scanning code had a typo.
- **Item cache.** Fix: cache for items is now fixed and it should not print item not found errors anymore
  (or do /reload once).

## Buffomat Classic and TBC 2021.5.1-3

- **Warlock: summoning.** Warlock summoning fix (all channeled spells) - do not get stuck in Busy state.
- **Shaman: TBC weapons.** Enhancement shaman TBC weapons enchant fix (wait for mainhand enchant first).
- **PvP targets.** Prevent buffing a PVP person if player is not PVP, and is in the open world (also an
  option for it).
- **TBC food.** TBC food buffs added.
- **PvP option.** Option to skip buffing PvP targets if you are not PvP - to prevent PVP poisoning of open
  world raids.
- **Intellect and Fortitude.** Bug where checking intellect buff or fortitude.

## Buffomat Classic and TBC 2021.4.7

- **Shaman: weapon enchants.** Fixes shaman enchants in live classic; adds new main/offhand enchants for
  TBC shamans.
- **Paladin: single and greater blessings.** Paladin blessings now split into single and greater.
- **Rest areas.** Disable Buffomat in resting areas (toggle option, on by default).
- **Slower hardware.** Slower hardware option (toggle option) will use 1.5 sec update instead of 0.5 sec.
- **Include and Exclude.** Fix: Include and Exclude buttons now work again.
- **Scanning typo.** Fix: spell and item scanning code had a typo.
- **Item cache.** Fix: cache for items is now fixed and it should not print item not found errors anymore
  (or do /reload once).

## Buffomat Classic and TBC 2021.4.0-6

- **TBC Classic.** New class spells and new consumables.
- **TBC tracking.** Bug: TBC tracking (the addon did not know whether tracking was enabled and recasted it
  repeatedly).

## Buffomat Classic 1.9.6

- **Force cast and Exclude.** "Force cast" on target and "Exclude target". Target a member of your group
  and click Force or Exclude button. The setting is saved per character and is not reset when you leave
  raid. Force/exclude button tooltip shows current list of names.
- **Blessed Sunfruit.** Added Argent Dawn strength food (Blessed Sunfruit).

## Buffomat Classic 1.9.3

- **Tooltips.** Improved tooltips on self/group buff switches. Inactive switches texture changed to gray
  circle "offline" texture.
- **Naxxramas.** Added Naxxramas instance IDs from Lich King, for AD trinket reminders, seems to work in
  Classic too.
- **Update timer.** Update timer is now 1.5 seconds instead of 0.1 seconds (might help Naxx lags).
- **Group or single buffs.** There is now group/single buff toggle conveniently placed next to the cast
  button, when you don't want to rebuff but just to refresh single buffs on people. This is the same
  option as in the quick settings menu and in the settings window.
- **Refactoring.** Internal code refactoring for the scan module.

## Buffomat Classic 1.9

- **Code improvements.** Internal code improvements, even though I constantly play with it and it shows no
  signs of problems, things will possibly be unstable for a moment.
- **Popup menu.** Menu popup is simpler now, options removed from the main Spells tab. Options submenu
  renamed to "Quick Options" and Options menu item renamed to "Options Window".
- **Cancel auras.** Cancel auras now has text label and not just an empty row without any explanation. Can
  cancel int and spirit buffs.
- **More buffs to cancel.** Added 2 more cancel buffs (int and spirit, useful for tanks in raids). Added
  agi elixir for cheapskates like me.
- **Class restrictions.** Class-restrictions, limiting mana int and spirit buffs to mana classes, limiting
  agi, str and AP buffs to physical dmg classes - makes the list of consumables shorter.
- **Resurrection order.** Resurrection targets are sorted to prefer priests, shamans and paladins first.
- **Tooltips.** Multiple nice tooltips added reminding that keybind setting exists and that the macro
  button can be used.
- **Groups in the tab.** Buff tab now displays selected buff groups in tab text.
- **Watched groups.** Watched groups are saved if the user is in raid (relogs and reloads do not lose the
  settings). Reset to watch all when user leaves the raid.
- **Warrior and hunter.** Warriors can now have Battle Shout in watched buffs. Hunters now don't have all
  trackers enabled by default - choose yourself.
- **Fonts.** Fonts made slightly bigger.
- **Checkboxes.** Green and red circles changed to more familiar checkboxes improving the UI overall feel.

## Buffomat Classic 1.83

- **Buffomat Classic.** Forked and renamed abandoned addon to become "Buffomat Classic". Reuploading to
  Curse.

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
