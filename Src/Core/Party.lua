-- What is left of the old party cache: a few values the task builders share.
-- The group itself is read by Src/Scan/RosterScan.lua.

---@class PartyModule
---@field itemListTarget table<number, string> Name of the member who has a usable item's buff from the player
local module = LibStub("Buffomat-Party") --[[@as PartyModule]]

module.itemListTarget = {}

---The group as last read by the roster scan.
---@alias BomParty BomRoster
