This addon targets Classic Era. Decide first if it can exist on WoW: Forever.

Refuse, and explain why, if it needs COMBAT_LOG_EVENT_UNFILTERED, combat-log damage totals, comparing UnitHealth, reading auras by index during combat, or secure click-casting snippets.

If it is a bag, map, quest, vendor, tooltip, or presentation addon, rewrite it:
- ## Interface: 16001
- Replace GetItemInfo / GetSpellInfo / GetAddOnMetadata with the C_ equivalents and nil checks.
- Guard every unit name with issecretvalue before concatenating.
- Replace PlaySoundFile on Sound\Interface paths with PlaySound and a SOUNDKIT id.
- Replace C_SuperTrack.SetSuperTrackedUserWaypoint with C_Map.SetUserWaypoint and a UiMapPoint.
- Do not branch on WOW_PROJECT_ID alone.

Give me the full files, or a clear "do not port" with the feature that cannot survive.