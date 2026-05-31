---@class BomLanguageGermanModule

local germanModule = LibStub("Buffomat-LanguageGerman") --[[@as BomLanguageGermanModule]]

---@return BomLocaleDict
function germanModule:Translations()
  return {
    ["shaman.flametongueDownranked"] = "Ein Rang niedriger",

    ["Category_class"] = "Klasse Buffs",
    ["Category_blessing"] = "Segen",
    ["Category_pet"] = "Begleiter",
    ["Category_tracking"] = "Aufspüren",
    ["Category_aura"] = "Auren",
    ["Category_seal"] = "Siegelen",
    ["Category_classicPhysFood"] = "Physische Essen (Classic)",
    ["Category_classicSpellFood"] = "Zauber Essen (Classic)",
    ["Category_classicFood"] = "Anderes Essen (Classic)",
    ["Category_classicPhysElixir"] = "Physische Elixiere (Classic)",
    ["Category_classicPhysBuff"] = "Physische Buffs (Classic)",
    ["Category_classicSpellElixir"] = "Zauber Elixirs (Classic)",
    ["Category_classicBuff"] = "Buffs (Classic)",
    ["Category_classicElixir"] = "Elixiere (Classic)",
    ["Category_classicFlask"] = "Fläschchen (Classic)",
    ["Category_tbcPhysFood"] = "Physische Essen (TBC)",
    ["Category_tbcSpellFood"] = "Zauber Essen (TBC)",
    ["Category_tbcFood"] = "Anderes Essen (TBC)",
    ["Category_tbcPhysElixir"] = "Physische Elixiere (TBC)",
    ["Category_tbcSpellElixir"] = "Zauber Elixiere (TBC)",
    ["Category_tbcElixir"] = "Anderes Elixiere (TBC)",
    ["Category_tbcFlask"] = "Fläschchen (TBC)",
    ["Category_wotlkPhysFood"] = "Physische Essen (WotLK)",
    ["Category_wotlkSpellFood"] = "Zauber Essen (WotLK)",
    ["Category_wotlkFood"] = "Anderes Essen (WotLK)",
    ["Category_wotlkPhysElixir"] = "Physische Elixiere (WotLK)",
    ["Category_wotlkSpellElixir"] = "Zauber Elixiere (WotLK)",
    ["Category_wotlkElixir"] = "Anderes Elixiere (WotLK)",
    ["Category_wotlkFlask"] = "Fläschchen (WotLK)",
    ["Category_cataFood"] = "Food (Cataclysm)",
    ["Category_cataElixir"] = "Elixirs (Cataclysm)",
    ["Category_cataFlask"] = "Flasks (Cataclysm)",
    ["Category_scroll"] = "Rollen",
    ["Category_weaponEnchantment"] = "Waffenverzauberung",
    ["Category_classWeaponEnchantment"] = "Klassenwaffenverzauberungen",
    ["Category_none"] = "Nicht kategorisiert",

    ["options.OptionsTitle"] = "Buffomat",
    ["options.general.group.AutoActions"] = "Reaktive Aktionen",
    ["options.general.group.Convenience"] = "Bequemlichkeit",
    ["options.general.group.General"] = "Allgemeine",
    ["options.general.group.Scan"] = "Scannen",
    ["options.general.group.Buffing"] = "Buff-Timer",
    ["options.general.group.Visibility"] = "Kategorien anzeigen",
    ["options.general.group.Class"] = "Klassenoptionen",
    ["options.convenience.SomeoneIsDrinking.Hide"] = "Ignorieren",
    ["options.convenience.SomeoneIsDrinking.LowPrio"] = "Hinweis in Aufgaben anzeigen",
    ["options.convenience.SomeoneIsDrinking.Show"] = "Hinweis anzeigen und Buffomat öffnen",
    ["options.short.ActivateBomOnSpiritTap"] = "Bei Willensentzug unter Mana-% aktivieren",
    ["options.short.AutoClose"] = "Automatisches schließen",
    ["options.short.HideWhenScanBlocked"] = "Buffomat ausblenden, wenn Scannen blockiert ist",
    ["options.short.AutoCrusaderAura"] = "Kreuzfahreraura vorschlagen",
    ["options.short.AutoDismount"] = "Automatisches Absitzen beim Zaubern",
    ["options.short.AutoDismountFlying"] = "Automatisch im Flug absitzen",
    ["options.short.AutoDisTravel"] = "Automatisch  Reiseform abbrechen beim Zaubern",
    ["options.short.AutoOpen"] = "Buffomat bei Aufgaben automatisch anzeigen",
    ["options.short.AutoStand"] = "Automatisches Aufstehen beim Zaubern",
    ["options.short.BestAvailableConsume"] = "Bestes verfügbares Verbrauchsmaterial wählen",
    ["options.short.BuffTarget"] = "Aktuelles Ziel mit aufnehmen",
    ["options.short.Carrot"] = "Erinnere an die \"Karotte am Stiel\"",
    ["options.short.CustomBuffSorting"] = "Sortierfelder in der Buffliste anzeigen",
    ["options.short.DeathBlock"] = "Kein Gruppenbuff, wenn jemand tot ist",
    ["options.short.DontUseConsumables"] = "Verbrauchbares nur mit shift, strg oder alt benutzen.",
    ["options.short.FadeWhenNothingToDo"] = "Buffomat-Fenster ohne Aufgaben ausblenden",
    ["options.short.InInstance"] = "In Instanzen aktiv",
    ["options.short.InPVP"] = "In Schlachtfelder aktiv",
    ["options.short.InWorld"] = "Auf der Welt aktiv",
    ["options.short.MainHand"] = "Warne bei fehlender Haupthand-Waffenverzauberung",
    ["options.short.NoGroupBuff"] = "Kein Gruppenbuff benutzen",
    ["options.short.OpenLootable"] = "Öffne plünderbare Gegenstände",
    ["options.short.PreventPVPTag"] = "PvP-Markierung verhindern",
    ["options.short.ReplaceSingle"] = "Ersetze Einzelbuffs mit Gruppenbuffs",
    ["options.short.ReputationTrinket"] = "Erinnere an die Anstecknadel der Argentumdämmerung",
    ["options.short.ResGhost"] = "Freigelassene wiederbeleben",
    ["options.short.SameZone"] = "Überwache nur wenn in der gleicher Zone",
    ["options.short.ScanInRestArea"] = "In Rastgebieten scannen",
    ["options.short.ScanInStealth"] = "In Verstohlenheit scannen",
    ["options.short.ScanWhileMounted"] = "Beim Reiten scannen",
    ["options.short.SecondaryHand"] = "Warne bei fehlender Nebenhand-Waffenverzauberung",
    ["options.short.SelfFirst"] = "Immer zuerst sich selbst buffen",
    ["options.short.ShamanFlametongueRanked"] = "Schamane: Heruntergestufte Flammenzunge auf Haupthand",
    ["options.short.ShowMinimapButton"] = "Minimap-Icon anzeigen",
    ["options.short.SlowerHardware"] = "Buffs seltener scannen",
    ["options.short.SomeoneIsDrinking"] = "Wenn jemand trinkt...",
    ["options.short.UseProfiles"] = "Profile benutzen",
    ["options.short.UseRank"] = "Benutze Zauber mit Rang",
    ["options.short.VisibleCategories"] = "Buffs anzeigen (Charaktereinstellung)",
    ["options.long.ActivateBomOnSpiritTap"] = "Buffomat deaktivieren, wenn Priester-Willensentzug aktiv ist und Mana unter Prozentwert liegt",
    ["options.long.AutoClose"] = "Automatisches schließen, wenn alle Aufgaben erledigt sind",
    ["options.long.HideWhenScanBlocked"] = "Blendet das Buffomat-Fenster aus, wenn das Scannen durch inaktive Bedingungen gestoppt wird, z. B. Reiten, Rastgebiet, Verstohlenheit, Taxi, Fahrzeug, Tod, deaktivierte Zone oder Willensentzug.",
    ["options.long.AutoCrusaderAura"] = "Paladin: Automatische Kreuzfahreraura beim Reiten",
    ["options.long.AutoDismount"] = "Beim Zaubern automatisch vom Bodenreittier absitzen",
    ["options.long.AutoDismountFlying"] = "Beim Zaubern automatisch vom Flugreittier absitzen (Vorsicht)",
    ["options.long.AutoDisTravel"] = "Reisegestalt automatisch entfernen (funktioniert nicht in Classic)",
    ["options.long.AutoOpen"] = "Wenn aktiviert, erscheint die Aufgabenliste sobald Aufgaben verfügbar sind; sonst nur per Tastenkürzel.",
    ["options.long.AutoStand"] = "Wenn der Charakter sitzt, lässt Buffomat ihn aufstehen",
    ["options.long.BestAvailableConsume"] = "Wenn aktiviert, wird das beste verfügbare Verbrauchsmaterial gewählt. Deaktiviert wird das schwächste gewählt, nützlich beim Leveln zum Aufbrauchen alter Vorräte",
    ["options.long.BuffTarget"] = "Auch das aktuelle Ziel buffen",
    ["options.long.Carrot"] = "An Reit-/Flugschmuckstücke erinnern",
    ["options.long.CustomBuffSorting"] = "Zusätzliches Textfeld in der Buffliste anzeigen. Der eingegebene Wert wird zum Sortieren der Buff-Aufgaben verwendet.",
    ["options.long.DeathBlock"] = "Keine Gruppenbuffs wirken, wenn jemand tot ist",
    ["options.long.DontUseConsumables"] = "Verbrauchsmaterialien nur mit Umschalt, Strg oder Alt benutzen",
    ["options.long.FadeWhenNothingToDo"] = "Alpha-Transparenz des Buffomat-Fensters einstellen, wenn nichts zu tun ist",
    ["options.long.GroupBuff"] = "Gruppenbuffs bei Bedarf wirken (zusätzliche Reagenzkosten)",
    ["options.long.InInstance"] = "Buffs in Dungeons und Raids scannen",
    ["options.long.InPVP"] = "Buffs in Schlachtfeldern scannen",
    ["options.long.InWorld"] = "Buffs in Welt und Städten scannen",
    ["options.long.MainHand"] = "Warnen, wenn Haupthand-Verzauberung fehlt",
    ["options.long.NoGroupBuff"] = "Immer Einzelbuff",
    ["options.long.OpenLootable"] = "Plünderbare Gegenstände in den Taschen öffnen",
    ["options.long.PreventPVPTag"] = "PvP-Ziele überspringen, wenn dein PvP aus ist",
    ["options.long.ReplaceSingle"] = "Einzelbuff durch Gruppenbuff ersetzen",
    ["options.long.ReputationTrinket"] = "An Ruf-Schmuckstück erinnern",
    ["options.long.ResGhost"] = "Versuchen, Geister wiederzubeleben, in der Hoffnung, dass der Körper erreichbar ist (keine Distanzprüfung)",
    ["options.long.SameZone"] = "Nur in gleicher Zone überwachen",
    ["options.long.ScanInRestArea"] = "Buffs in Rastgebieten scannen (Stadt und Gasthaus)",
    ["options.long.ScanInStealth"] = "Buffs in Verstohlenheit scannen",
    ["options.long.ScanWhileMounted"] = "Scannen, wenn der Spieler beritten ist",
    ["options.long.SecondaryHand"] = "Warnen, wenn Nebenhand-Verzauberung fehlt",
    ["options.long.SelfFirst"] = "Immer zuerst sich selbst buffen",
    ["options.long.ShamanFlametongueRanked"] = "Schamane: Für Spellhancement-Schamanen heruntergestufte Flammenzunge auf der Haupthand und Maximalrang auf der Nebenhand verwenden.",
    ["options.long.ShowClassicConsumables"] = "Classic-Verbrauchsmaterialien anzeigen",
    ["options.long.ShowMinimapButton"] = "Minimap-Button anzeigen",
    ["options.long.ShowTBCConsumables"] = "TBC-Verbrauchsmaterialien anzeigen",
    ["options.long.SlowerHardware"] = "Weniger häufige Buff-Prüfungen (langsamer Rechner/Raid)",
    ["options.long.SomeoneIsDrinking"] = "Wenn jemand trinkt, kann eine Meldung angezeigt oder verborgen werden",
    ["options.long.UseProfiles"] = "Profile je nach Solo, Gruppe, Raid oder Schlachtfeld verwenden",
    ["options.long.UseRank"] = "Zauber mit Rängen verwenden; ist die Zielstufe zu niedrig, wird nächstes Mal ein niedrigerer Rang benutzt",
    ["options.long.VisibleCategories"] = "Eine Buff-Kategorie in der Zauberliste anzeigen (Charaktereinstellung)",

    ["tasklist.IgnoredBuffOn"] = "Ignoriert %s: %s",

    ["task.target.Self"] = "Auf selbst",
    ["task.target.SelfOnly"] = "Eigener Buff",
    ["task.type.Enchantment"] = "Waffenverzaub.",
    ["task.type.RegularBuff"] = "Buff",
    ["task.type.GroupBuff"] = "Gruppe",
    ["task.type.GroupBuff.Self"] = "Ziel selbst",
    ["task.type.Tracking"] = "Aufspüren",
    ["task.type.Reminder"] = "Erinnerung",
    ["task.type.Resurrect"] = "Auferstehen",
    ["task.type.MissingConsumable"] = "Fehlendes Verbrauchsmaterial",
    ["task.type.Consumable"] = "Verbrauchsmaterial",
    ["task.hint.HoldShiftConsumable"] = "Halten Sie Umschalt, Strg oder Alt gedrückt",

    TASK_BLESS_GROUP = "Gruppe segnen",
    TASK_BLESS = "Segnen",
    TASK_SUMMON = "Beschwörung",
    TASK_CAST = "Zauber wirken",

    ["task.type.Use"] = "Verwenden",
    ["task.type.Consume"] = "Konsumieren",
    ["task.type.tbcHunterPetBuff"] = "Gebrauch auf Begleiter",

    TASK_ACTIVATE = "Aktivieren",

    ["task.type.Unequip"] = "Ausrüsten",
    ["task.error.range"] = "Außer Reichweite",

    ["reminder.reputationTrinket"] = "Ruf Schmuckstück",
    ["reminder.ridingSpeedTrinket"] = "Reitgeschwindigkeit Schmuckstück",

    ["task.hint.DontHaveItem"] = "Nicht in Taschen",
    ["task.notifications.no-sound"] = "Kein Ton",
    ["task.error.missingMainhandWeapon"] = "Haupthand kann nicht verzaubert werden",
    ["task.error.missingOffhandWeapon"] = "Nebenhand kann nicht verzaubert werden (keine Waffe)",

    CHAT_MSG_PREFIX = "Buffomat: ",

    Buffomat = "Buffomat",

    ResetWatchGroups = "Buffgruppen auf 1-8 zurücksetzen",

    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s auf dich",
    FORMAT_BUFF_GROUP = "Gruppe %s %s",
    FORMAT_GROUP_NUM = "G%s",

    ["castButton.Next"] = "%s @ %s",
    ["castButton.InCombat"] = "Im Kampf",
    ["castButton.Busy"] = "Beschäftigt",
    ["castButton.BusyChanneling"] = "Beschäftigt / Kanalisieren",
    ["castButton.NothingToDo"] = "Nichts zu tun",
    ["castButton.NoMacroSlots"] = "Brauche Platz für ein Macro!",
    ["castButton.CantCastMaybeOOM"] = "Kann nicht buffen, kein Mana oder anderer Grund",

    ["message.CancelBuff"] = "Beende Buff %s von %s",
    ["message.BuffExpired"] = "%s ist abgelaufen.",

    ["task.UseOrOpen"] = "Öffnen",

    MSG_MAINHAND_ENCHANT_MISSING = "Haupthand-Verzauberung fehlt",
    MSG_OFFHAND_ENCHANT_MISSING = "Nebenhand-Verzauberung fehlt",

    InfoSomeoneIsDrinking = "1 Person trinkt",

    InfoMultipleDrinking = "%d Personen trinken",

    ["castButton.inactive.DeadMember"] = "Ein Gruppenmitglied ist tot",
    ["castButton.inactive.Flying"] = "Fliegen; Absteigen deaktiviert",
    ["castButton.inactive.InCombat"] = "Kampf",
    ["castButton.inactive.Instance"] = "Buff in Dungeons deaktiviert",
    ["castButton.inactive.IsDead"] = "Gestorben",
    ["castButton.inactive.IsStealth"] = "Buff im Stealth deaktiviert",
    ["castButton.inactive.MacroFrameShown"] = "Makros-Rahmen wird angezeigt",
    ["castButton.inactive.Mounted"] = "Buffen auf Reittier deaktiviert",
    ["castButton.inactive.OpenWorld"] = "Buff in der Welt deaktiviert",
    ["castButton.inactive.PriestSpiritTap"] = "Der <Willensentzug> des Priesters ist aktiv",
    ["castButton.inactive.PvpZone"] = "Buff im PvP deaktiviert",
    ["castButton.inactive.RestArea"] = "Buff in Rastplätzen deaktiviert",
    ["castButton.inactive.Taxi"] = "Kein Buff am Taxi",
    ["castButton.inactive.Vehicle"] = "Kein Polieren am Fahrzeug",

    ["castbutton.inactive.GCD"] = "Globale Abklingzeit",
    ["castButton.inactive.GlobalCooldown"] = "Globale Abklingzeit",

    ["error.castFailed.tooLowLevel"] = "Erniedrige den Rang für %s auf %s. Bitte neu zaubern.",

    CRUSADER_AURA_COMMENT = "Kann je nach Einstellungen automatisch gewirkt werden",

    HeaderRenew = "Vor dem auslaufen erneuern (in Sekunden)",

    ["options.short.Time60"] = "Dauer <=60 Sek:",
    ["options.short.Time300"] = "Dauer <=5 Min:",
    ["options.short.Time600"] = "Dauer <=10 Min:",
    ["options.short.Time1800"] = "Dauer <=30 Min:",
    ["options.short.Time3600"] = "Dauer <=60 Min:",
    ["options.short.UIWindowScale"] = "UI-Skalierung",
    ["options.short.MinBuff"] = "Anzahl der fehldenen Buffs für einen Gruppenbuff",
    ["options.short.MinBlessing"] = "Anzahl der fehlenden Segen für einen Großen Segen",
    ["options.short.PlaySoundWhenTask"] = "Ton abspielen, wenn Buff-Aufgaben vorhanden sind",
    ["options.short.PlaySoundWhenTask.test"] = "Abspielen",
    ["options.short.DebugLogging"] = "[Entwickler] Zusätzliche Debugmeldungen ausgeben (viel!)",
    ["options.general.sound.None"] = "- kein Soundeffekt -",
    ["options.long.Time60"] = "Buffs mit Gesamtdauer <=60 Sek. erneuern, wenn weniger verbleibt als",
    ["options.long.Time300"] = "Buffs mit Gesamtdauer <=5 Min. erneuern, wenn weniger verbleibt als",
    ["options.long.Time600"] = "Buffs mit Gesamtdauer <=10 Min. erneuern, wenn weniger verbleibt als",
    ["options.long.Time1800"] = "Buffs mit Gesamtdauer <=30 Min. erneuern, wenn weniger verbleibt als",
    ["options.long.Time3600"] = "Buffs mit Gesamtdauer <=60 Min. erneuern, wenn weniger verbleibt als",
    ["options.long.UIWindowScale"] = "Skalierung der Benutzeroberfläche, Buffomat größer oder kleiner machen (Standard 1.0)",
    ["options.long.MinBuff"] = "Anzahl fehlender Buffs, die für einen Gruppenbuff nötig ist",
    ["options.long.MinBlessing"] = "Anzahl fehlender Segen, die für einen Großen Segen nötig ist",
    ["options.long.PlaySoundWhenTask"] = "Ton abspielen, wenn die Aufgabenliste nicht leer ist",
    ["options.long.PlaySoundWhenTask.test"] = "Klicken, um den gewählten Ton zu testen",
    ["options.long.DebugLogging"] = "Nur für Entwicklung: Zusätzliche Meldungen zur Fehlersuche ausgeben, nicht benutzen!",

    TooltipCustomSorting = "Der hier eingegebene Text wird zum Sortieren der Buffs verwendet. Enter drücken, um zu speichern.",

    TooltipSelfCastCheckbox_Self = "Nur auf sich selbst wirken",
    TooltipSelfCastCheckbox_Party = "Gruppe und Raidgruppen buffen",

    TooltipEnableSpell = "Buffüberwachung ein-/ausschalten",

    TooltipEnableBuffCancel = "Automatisches beenden des Buff ein-/ausschalten",

    FormatToggleTarget = "Klicken, um Spieler umzuschalten: %s",

    FormatAllForceCastTargets = "Erzwingen auf: ",

    FormatForceCastNone = "Liste erzwungener Ziele ist leer",

    FormatAllExcludeTargets = "Ignoriert: ",

    FormatExcludeNone = "Ignorierliste ist leer",

    TooltipForceCastOnTarget = "Buff dauerhaft auf Ziel halten",

    TooltipExcludeTarget = "Aktuelles Raid- oder Gruppenziel zur Ausschlussliste hinzufügen",

    TooltipSelectTarget = "Wähle ein Gruppenmitglied um diese Option zu aktivieren.",

    ["tooltip.SpellsDialog.watchGroup"] = "Gruppe %d",

    TooltipRaidGroupsSettings = "Einstellungen für Raidgruppen-Überwachung",

    MessageAddedForced = "Buff wird erzwungen ",

    MessageClearedForced = "Erzwungenen Buff entfernt für",

    MessageAddedExcluded = "Wird nie gebufft ",

    MessageClearedExcluded = "Ausschluss entfernt für",

    HintCancelThisBuff = "Brich diesen Buff",
    HintCancelThisBuff_Combat = "vor dem Kampf",
    HintCancelThisBuff_Always = "immer ab",

    TooltipWhisperWhenExpired = "Quelle anflüstern, wenn abgelaufen.",

    ["tooltip.mainhand"] = "Waffenhand",
    ["tooltip.offhand"] = "Schildhand",

    ShamanEnchantBlocked = "Warten auf Haupthand",

    PreventPVPTagBlocked = "Ziel ist PvP",

    TooltipIncludesAllRanks = "Alle Varianten",

    TooltipSimilar = "Alle ähnlichen",

    TooltipSimilarFoods = "Alle ähnlichen Essen",

    ["tooltip.buff.conjure"] = "Herstellen",
    ["tooltip.buff.agility"] = "+Bew",
    ["tooltip.buff.allResist"] = "+Alle Res",
    ["tooltip.buff.attackPower"] = "+Angriff",
    ["tooltip.buff.crit"] = "+Krit",
    ["tooltip.buff.fireResist"] = "+Feuerres",
    ["tooltip.buff.frostResist"] = "+Frostres",
    ["tooltip.buff.haste"] = "+Tempo",
    ["tooltip.buff.healing"] = "+Heilung",
    ["tooltip.buff.hit"] = "+Treffer",
    ["tooltip.buff.intellect"] = "+Int",
    ["tooltip.buff.maxHealth"] = "+Max. LP",
    ["tooltip.buff.mp5"] = "+Mana/5",
    ["tooltip.buff.resilience"] = "+Abhärtung",
    ["tooltip.buff.spellPower"] = "+Zauber",
    ["tooltip.buff.spellCrit"] = "+Zauberkrit",
    ["tooltip.buff.spirit"] = "+Willenskraft",
    ["tooltip.buff.stamina"] = "+Ausdauer",
    ["tooltip.buff.strength"] = "+Stärke",
    ["tooltip.buff.comboMealWotlk"] = "+Angriff/+Zauber",
    ["tooltip.buff.armorPenetration"] = "+Rüstungsdurchdr.",
    ["tooltip.buff.petStrength"] = "Begleiter +Stärke",
    ["tooltip.buff.petStamina"] = "Begleiter +Ausdauer",
    ["tooltip.buff.alchemistOnly"] = "Nur Alchemisten",
    ["tooltip.consumable.bestInBag"] = " (bestes in der Tasche)",
    ["tooltip.elixir.bestInBag"] = " (bestes Elixier in der Tasche)",
    ["tooltip.food.bestInBag"] = " (bestes Essen in der Tasche)",
    ["tooltip.scroll.bestInBag"] = " (beste Rolle in der Tasche)",

    ["consumeType.food"] = "Essen",
    ["consumeType.elixir"] = "Elixier",
    ["consumeType.scroll"] = "Rolle",

    ["Items, which provide buff for %s:"] = "Gegenstände, die Buff %s gewähren:",

    ["Click to print all items which provide this buff"] = "Dies ist eine Gruppe von Gegenständen mit demselben Bufftyp\nKlicken, um alle Gegenstände auszugeben, die diesen Buff gewähren",

    ["tooltip.alcohol.stamina"] = "Alkohol +Ausdauer",
    ["tooltip.alcohol.spirit"] = "Alkohol +Willenskraft",

    ["Healing Power"] = "Heilkraft",

    TabBuff = "Buff",

    TabDoNotBuff = "Nicht buffen",

    TabBuffOnlySelf = "Nur selbst buffen",

    TabSpells = "Zauber",

    ["popup.OpenBuffomat"] = "Öffnen",

    BtnCancel = "Abbruch",

    ["popup.QuickSettings"] = "Schnelleinstellungen",

    ["optionsMenu.Settings"] = "Einstellungen",

    BtnSettingsSpells = "Einstellungen Zauber",

    BtnBuffs = "Verbrauchbares",

    ButtonCastBuff = "Zaubere Buff",

    ButtonBuffomatWindow = "Buffomat-Fenster anzeigen/verbergen",

    Header_TRACKING = "Suche",
    Header_INFO = "Informationen",
    Header_CANCELBUFF = "Buffs Abbrechen",
    Header_item = "Verbrauchbares",

    HeaderSupportedSpells = "Unterstützte Zauber",

    HeaderWatchGroup = "Im Raid Gruppe überwachen",

    PanelAbout = "Über",

    HeaderInfo = "Information",

    HeaderUsage = "Benutzung",

    HeaderSlashCommand = "Befehle",

    HeaderCredits = "Credits",

    HeaderCustomLocales = "Lokalisierung",

    ["header.Profiles"] = "Profile",

    SlashSpellBook = "Zauberbuch neu einlesen",

    SlashUpdate = "Update Macro / Liste",

    SlashClose = "BOM-Fenster schließen",

    SlashReset = "BOM-Fenster zurücksetzen",

    SlashOpen = "BOM-Fenster öffnen",

    SlashProfile = "Das aktuelle Profil zu solo/group/raid/battleground/auto wechseln",

    Tank = "Tank",

    Pet = "Tier",

    TooltipCastOnClass = "Auf Klasse wirken",

    TooltipCastOnTank = "Auf Tanks wirken",

    TooltipCastOnPet = "Auf Begleiter wirken",

    ["profile.activeProfileMenuTag"] = "[aktiv]",

    ["profileName.solo"] = "Allein",
    ["profileName.solo_spec2"] = "Allein (Zweite Talente)",
    ["profileName.group"] = "Gruppe",
    ["profileName.group_spec2"] = "Gruppe (Zweite Talente)",
    ["profileName.raid"] = "Schlachtzug",
    ["profileName.raid_spec2"] = "Schlachtzug (Zweite Talente)",
    ["profileName.battleground"] = "Schlachtfeld",
    ["profileName.battleground_spec2"] = "Schlachtfeld (Zweite Talente)",
    ["profileName.auto"] = "Automatisch",

    AboutInfo = "Ausdauer! Int! Wille! - klingt das bekannt? Buffomat überprüft alle Gruppen/Raid-Mitglieder auf fehlende Buffs und ermöglicht diese dann mit einen klick zu verteilen. Wenn drei oder mehr den gleichen Buff brauchen, wird die Gruppenversion benutzt. Es erinnert dich auch die Suche wie Kräutersuche wieder zu aktivieren.|nAuch beim Wiederbeleben wird unterstützt, indem Paladine, Priester und Schamanen bevorzugt werden.",

    AboutUsage = "Es wird ein freier Makro-Platz benötigt. Das Hauptfenster hat zwei Reiter 'Buff' und 'Zauber'. Unter 'Buff' findet man die fehlenden buffs und ein 'Zaubern'-Button.|nUnter 'Zauber' findet man Einstellungen z.B.: Welche Zauber überwacht werden sollen, ob die Gruppen-Varianten erlaubt sind, ob der Zauber nur auf den Spieler oder alle erfolgen soll, welche Klassen diesen Zauber bekommen sollen. Zudem lassen sich die Gruppen einschränken, bspw. im Raid, wenn man nur Gruppe 7&8 mit Int buffen soll. Auch kann man hier Einstellen, dass das aktuelle Ziel immer einen bestimmten Buff bekommen soll. Bspw. kann ein Druide den Haupttank auswählen und in der Zeile von 'Dornen' auf das '-' klicken. Es sollte sich dann in ein Zielkreuz änden. Von nun an wird immer Dornen auf den Tank aufrecht gehalten.|nMan hat zwei Möglichkeiten, einen Buff zu zaubern: Einmal der 'Zaubern'-Button in Hauptfenster oder das Buff'o'mat-Makro. Man findet es unter dem 'M'-Button in der Titelzeile des Fensters.|nACHTUNG: Aufgrund von Einschränkungen von Blizzard funktioniert Buffomat nur außerhalb des Kampfes. Es kann auch bspw. das Hauptfenster nur außerhalb geöffnet und geschlossen werden!",

    AboutSlashCommand = "",

    TooltipMacroButton = "Ziehe dieses Makro in deine Aktionsleiste, um die Buffs zu wirken|nDu kannst dem Makro unter Tastenbelegungen => Andere eine Tastenkombination hinzufügen",

    ["tooltip.button.AllSettings"] = "Alle Einstellungen",
    ["tooltip.button.QuickSettingsPopup"] = "Schnelleinstellungen und Profile",
    ["tooltip.button.AllBuffs"] = "Alle Buffs",
    ["tooltip.button.HideBuffomat"] = "Verstecken. Um wieder anzuzeigen, tippe /bom, klicke auf den Minimap-Button oder drücke %s",
    ["tooltip.TaskList.CastButton"] = "Wirke den Zauber aus der Liste.|nNicht im Kampf verfügbar.|nKann auch über das Makro (in der obersten Reihe) aktiviert werden|nNoch eine Tastenkombination in Tastenkombinationen => Andere binden",

    SpellLabel_TrackHumanoids = "Nur Katze - überschreibt Kräuter- und Erzsuche",

    ["title.SpellsWindow"] = "Zauber und Buffs auswählen (%s)",

    SpellsWindow_ShowCategory = "Aktivieren, um diese Kategorie anzuzeigen",

    ["title.ForceTarget"] = "Buff erzwingen auf",
    ["title.ExcludeTarget"] = "Beim Buffen ausschließen",

    ["button.ForceCast.AddTarget"] = "Ziel hinzufügen",

    ["buttonTooltip.ForceCast.AddTarget"] = "Spieler oder Begleiter anvisieren und zur Erzwingen-/Ignorierliste hinzufügen",

    ["button.ForceCast.RemoveTarget"] = "Ziel entfernen",

    ["buttonTooltip.ForceCast.RemoveTarget"] = "Spieler oder Begleiter anvisieren und aus der Erzwingen-/Ignorierliste entfernen",

    ["label.ForceCast.TargetList"] = "Zielliste",
    ["label.SpellsDialog.ProfileSelector"] = "Buff-Auswahl für Profil",
    ["label.SpellsDialog.GroupScanSelector"] = "Raidgruppen überwachen",

    ["binding.notSet"] = "[nicht gesetzt]",
  }
end
