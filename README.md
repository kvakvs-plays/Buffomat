# Buffomat Classic

Based on Buff'o'mat by GPI.

Maintained by @kvakvs at Github. https://github.com/kvakvs-plays/Buffomat

Compatible with WoW Classic and will be rolled into Classic Burning Crusade. As
I only play Classic and have no idea about retail spells and playstyles, I won't
be paying much attention to it being Retail-compatible.

## About

Buff'o'mat is a semi automatic buff and resurrection system.

Stamina! Int! Spirit! - Does that sound familiar? Buff'o'mat scan the
party/raid-member for missing buffs and with a click it is casted. When three or
more members are missing one buff the group-version is used. It also remembers
you to activate a tracking like "Find Herbs".

Also it will help you to resurrect players by choosing paladins, priests and
shamans first.

## Usage

You need a free macro-slot to use this addon. The main-window has two tabs "
Buff" and "Spells". Under "Buff" you find all missing buffs and a cast button.

Under "Spells" you can configure which spells should be monitored, if it should
use the group version. Select if it should only cast an you or on all party
members. Choose which buff should be active on which class. You can also ignore
complete groups (for example in raid, when you should only cast int on group
7&8). You can also select here, that one buff should be active on the current
target. For example as druid click on the main tank and in the "thorns"
-Section on the "-" (last symbol) - it will changed to a crosshair and now
buff'o'mat remember you to keep the buff on the main tank.

You have two options to Cast a buff from the missing-buff-list. The spell-button
in the window or the "Buff'o'mat"-macro. You find it with the "M"-Button in
the "titelbar" of the main window.

IMPORTANT: Buff'o'mat works only out of combat because Blizzard don't allow to
change macros during combat. Additional you can't open or close the main window
during combat!

## Slash commands

* `/bom spellbook` - Rescan spellbook
* `/bom update` - Update macro / list
* `/bom close` - Close BOM window
* `/bom reset` - Reset BOM window
* `/bom` - Open BOM window

## Supported spells

* PRIEST Power Word: Fortitude / Prayer of Fortitude, Divine Spirit / Prayer of
  Spirit, Shadow Protection / Prayer of Shadow Protection, Fear Ward, Touch of
  Weakness, Inner Fire, Resurrection
* DRUID Mark of the Wild / Gift of the Wild, Thorns, Omen of Clarity, Track
  Humanoids
* MAGE Arcane Intellect / Arcane Brilliance, Ice Armor, Frost Armor, Mage Armor
* SHAMAN Ancestral Spirit, Weapon Enchants, Lightning Shield
* WARLOCK Unending Breath, Detect Greater Invisibility, Shadow Ward, Demon
  Armor, Demon Skin, Sense Demons
* HUNTER Trueshot Aura, Aspect of the Beast, Aspect of the Hawk, Aspect of the
  Monkey, Aspect of the Wild, Aspect of the Cheetah, Aspect of the Pack, Track
  Beasts, Track Demons, Track Dragonkin, Track Elementals, Track Humanoids,
  Track Giants, Track Undead, Track Hidden
* PALADIN Righteous Fury, Blessing of Kings, Blessing of Might, Blessing of
  Sanctuary, Blessing of Wisdom, Seal of Justice, Seal of Light, Seal of
  Righteousness, Seal of Wisdom, Devotion Aura, Retribution Aura, Concentration
  Aura, Shadow Resistance Aura, Frost Resistance Aura, Fire Resistance Aura,
  Sanctity Aura, Redemption, Sense Undead
* TRACKING Find Herbs, Find Minerals, Find Treasure

## Building and installing

Run the build tool from the repository root. Existing commands, including
`--version classic`, `tbc`, `wotlk`, and `cata`, produce the combined Classic,
TBC, Wrath, and Cataclysm package:

```sh
python wowaddon.py --dst="../_Releases" zip
```

The destination directory for ZIP files must already exist. Supported client TOCs
use `_Vanilla`, `_TBC`, `_Wrath`, and `_Cata`, alongside the unsuffixed fallback.

WoW: Forever has an explicit experimental build target using beta interface
`16001`, as specified in the project compatibility notes. Its level-60 content
uses Mainline/Midnight UI architecture. Build or install it with:

```sh
python wowaddon.py --version forever --dst="../_Releases" zip
python wowaddon.py --version forever --dst="C:/Games/World of Warcraft/_classic_beta_/Interface/AddOns" install
```

The archive is named `BuffomatClassic_Camelot-<version>.zip`. It retains the
`BuffomatClassic` addon folder, asset paths, and saved-variable names, and contains
the Forever `BuffomatClassic_Camelot.toc` and an identical `BuffomatClassic.toc`
fallback. Existing generated Classic TOCs are preserved.
Restart the client if a newly installed addon folder does not appear.

Forever runtime adaptations are integrated into the shared `KvEnv` compatibility
layer and selected by client version and API availability. They include modern
weapon imbues, tracking, inventory slots, class options, and public mana/range
data. Buffomat skips combat-log registration on Forever, uses `UNIT_AURA` for
buff updates, and pauses aura scanning during combat, encounters, challenge
modes, and PvP restrictions. Unit-link clicks display `/who` or `/w` commands
on Forever so the player can enter them without restricted chat activation.

This remains experimental: automated tests cover mocked Classic and Forever
APIs, not an actual Forever beta session. Verify loading, buff scans, both weapon
imbues, restriction entry/exit, and buff-button/macro behavior in the client.
The adaptations were ported from
[yannlugrin/Buffomat's forever branch](https://github.com/yannlugrin/Buffomat/tree/69564aa)
through commit `69564aa`, retaining this repository's aura and macro safeguards.
The reference checkout in `references/forever-branch` is ignored and not packaged.

## Credits

* wellcat for the Chinese translation
* OlivBEL for the french translation
* Arrogant_Dreamer & kvakvs for the russian translation
* Free icons
  * Main Icon (Wizard): https://www.flaticon.com/free-icons/wizard, created by max.icons
* Yann Lugrin github @yannlugrin - thanks for initial push for the WoW: Forever port.
