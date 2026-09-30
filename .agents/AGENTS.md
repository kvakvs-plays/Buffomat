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
