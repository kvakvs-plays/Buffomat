-- What is left of the old party cache: a few values the task builders share.
-- The group itself is read by Src/Scan/RosterScan.lua.

---@class PartyModule
---@field itemListTarget table<number, string> Name of the member who has a usable item's buff from the player
---@field playerManaLimit number Lowest mana cost the player could not afford in the last scan
---@field playerMana number Player current mana
local module = LibStub("Buffomat-Party") --[[@as PartyModule]]

module.itemListTarget = {}
module.playerMana = 0
module.playerManaLimit = 0

---The group as last read by the roster scan.
---@alias BomParty BomRoster
