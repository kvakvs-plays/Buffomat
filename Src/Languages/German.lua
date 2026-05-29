---@class BomLanguageGermanModule

local germanModule = LibStub("Buffomat-LanguageGerman") --[[@as BomLanguageGermanModule]]

---@return BomLocaleDict
function germanModule:Translations()
  return {
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

    ["Category_scroll"] = "Rollen",
    ["Category_weaponEnchantment"] = "Waffenverzauberung",
    ["Category_classWeaponEnchantment"] = "Klassenwaffenverzauberungen",
    ["Category_none"] = "Nicht kategorisiert",

    ["options.general.group.AutoActions"] = "Reaktive Aktionen",
    ["options.general.group.Convenience"] = "Bequemlichkeit",
    ["options.general.group.General"] = "Allgemeine",
    ["options.general.group.Scan"] = "Scannen",
    ["options.general.group.Buffing"] = "Buff-Timer",
    ["options.general.group.Visibility"] = "Kategorien anzeigen",
    ["options.general.group.Class"] = "Klassenoptionen",

    ["tasklist.IgnoredBuffOn"] = "Ignoriert %s: %s", -- when a buff is not listed because a better buff exists
    ["task.target.Self"] = "Auf selbst",             -- use instead of name when buffing self
    ["task.target.SelfOnly"] = "Eigener Buff",
    ["task.type.Enchantment"] = "Waffenverzaub.",
    ["task.type.RegularBuff"] = "Buff",
    ["task.type.GroupBuff"] = "Gruppe",
    ["task.type.GroupBuff.Self"] = "Ziel selbst",
    ["task.type.Tracking"] = "Aufspüren",
    ["task.type.Reminder"] = "Erinnerung",
    ["task.type.Resurrect"] = "Auferstehen",
    ["task.type.MissingConsumable"] = "Fehlendes Verbrauchsmaterial",
    ["task.type.Consumable"] = "Verbrauchsmaterial", -- deprecated?
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

    ["profile.activeProfileMenuTag"] = "[aktiv]",
    ["profileName.auto"] = "Automatisch",
    ["profileName.group"] = "Gruppe",
    ["profileName.group_spec2"] = "Gruppe (Zweite Talente)",
    ["profileName.solo"] = "Allein",
    ["profileName.solo_spec2"] = "Allein (Zweite Talente)",
    ["profileName.raid"] = "Schlachtzug",
    ["profileName.raid_spec2"] = "Schlachtzug (Zweite Talente)",
    ["profileName.battleground"] = "Schlachtfeld",
    ["profileName.battleground_spec2"] = "Schlachtfeld (Zweite Talente)",

    AboutInfo = "Ausdauer! Int! Wille! - klingt das bekannt? Buffomat überprüft alle "
        .. "Gruppen/Raid-Mitglieder auf fehlende Buffs und ermöglicht diese dann mit einen klick zu "
        .. "verteilen. Wenn drei oder mehr den gleichen Buff brauchen, wird die Gruppenversion benutzt. "
        .. "Es erinnert dich auch die Suche wie Kräutersuche wieder zu aktivieren.|nAuch beim "
        .. "Wiederbeleben wird unterstützt, indem Paladine, Priester und Schamanen bevorzugt werden.",
    AboutSlashCommand = "",
    AboutUsage = "Es wird ein freier Makro-Platz benötigt. Das Hauptfenster hat zwei "
        .. "Reiter 'Buff' und 'Zauber'. Unter 'Buff' findet man die fehlenden buffs und ein "
        .. "'Zaubern'-Button.|nUnter 'Zauber' findet man Einstellungen z.B.: Welche Zauber überwacht "
        .. "werden sollen, ob die Gruppen-Varianten erlaubt sind, ob der Zauber nur auf den Spieler "
        .. "oder alle erfolgen soll, welche Klassen diesen Zauber bekommen sollen. Zudem lassen "
        .. "sich die Gruppen einschränken, bspw. im Raid, wenn man nur Gruppe 7&8 mit Int "
        .. "buffen soll. Auch kann man hier Einstellen, dass das aktuelle Ziel immer einen "
        .. "bestimmten Buff bekommen soll. Bspw. kann ein Druide den Haupttank auswählen und in "
        .. "der Zeile von 'Dornen' auf das '-' klicken. Es sollte sich dann in ein Zielkreuz "
        .. "änden. Von nun an wird immer Dornen auf den Tank aufrecht gehalten.|nMan hat zwei "
        .. "Möglichkeiten, einen Buff zu zaubern: Einmal der 'Zaubern'-Button in Hauptfenster oder "
        .. "das Buff'o'mat-Makro. Man findet es unter dem 'M'-Button in der Titelzeile des Fensters.|n"
        .. "ACHTUNG: Aufgrund von Einschränkungen von Blizzard funktioniert Buffomat nur außerhalb des "
        .. "Kampfes. Es kann auch bspw. das Hauptfenster nur außerhalb geöffnet und geschlossen werden!",
    BtnBuffs = "Verbrauchbares",
    BtnCancel = "Abbruch",
    ["popup.OpenBuffomat"] = "Öffnen",
    ButtonCastBuff = "Zaubere Buff",
    ["optionsMenu.Settings"] = "Einstellungen",
    BtnSettingsSpells = "Einstellungen Zauber",

    HintCancelThisBuff = "Brich diesen Buff",
    HintCancelThisBuff_Combat = "vor dem Kampf",
    HintCancelThisBuff_Always = "immer ab",

    ["options.short.ReputationTrinket"] = "Erinnere an die Anstecknadel der Argentumdämmerung",
    ["options.short.AutoDismount"] = "Automatisches Absitzen beim Zaubern",
    ["options.short.AutoDisTravel"] = "Automatisch  Reiseform abbrechen beim Zaubern",
    -- ["options.short.AutoOpen"] = "Automatisches öffnen",
    ["options.short.AutoClose"] = "Automatisches schließen",
    ["options.short.HideWhenScanBlocked"] = "Buffomat ausblenden, wenn Scannen blockiert ist",
    ["options.short.AutoStand"] = "Automatisches Aufstehen beim Zaubern",
    ["options.short.BuffTarget"] = "Aktuelles Ziel mit aufnehmen",
    ["options.short.Carrot"] = "Erinnere an die \"Karotte am Stiel\"",
    ["options.short.DeathBlock"] = "Kein Gruppenbuff, wenn jemand tot ist",
    ["options.short.DontUseConsumables"] = "Verbrauchbares nur mit shift, strg oder alt benutzen.",
    ["options.short.InInstance"] = "In Instanzen aktiv",
    ["options.short.InPVP"] = "In Schlachtfelder aktiv",
    ["options.short.InWorld"] = "Auf der Welt aktiv",
    -- ["options.short.LockMinimapButton"] = "Minimap-Icon-Position sperren",
    -- ["options.short.LockMinimapButtonDistance"] = "Minimap-Icon-Entfernung minimieren",
    ["options.short.MainHand"] = "Warne bei fehlender Haupthand-Waffenverzauberung",
    ["options.short.NoGroupBuff"] = "Kein Gruppenbuff benutzen",
    ["options.short.OpenLootable"] = "Öffne plünderbare Gegenstände",
    ["options.short.ReplaceSingle"] = "Ersetze Einzelbuffs mit Gruppenbuffs",
    ["options.short.ResGhost"] = "Freigelassene wiederbeleben",
    ["options.short.SameZone"] = "Überwache nur wenn in der gleicher Zone",
    ["options.short.SecondaryHand"] = "Warne bei fehlender Nebenhand-Waffenverzauberung",
    ["options.short.SelfFirst"] = "Immer zuerst sich selbst buffen",
    ["options.short.ShowMinimapButton"] = "Minimap-Icon anzeigen",
    ["options.short.UseProfiles"] = "Profile benutzen",
    ["options.short.UseRank"] = "Benutze Zauber mit Rang",

    ["options.short.MinBlessing"] = "Anzahl der fehlenden Segen für einen Großen Segen",
    ["options.short.MinBuff"] = "Anzahl der fehldenen Buffs für einen Gruppenbuff",
    ["options.short.Time1800"] = "Dauer <=30 Min:",
    ["options.short.Time300"] = "Dauer <=5 Min:",
    ["options.short.Time3600"] = "Dauer <=60 Min:",
    ["options.short.Time60"] = "Dauer <=60 Sek:",
    ["options.short.Time600"] = "Dauer <=10 Min:",

    -- ["options.long.AutoOpen"] = "Automatisches öffnen, wenn Aufgaben verfügbar sind",
    ["options.long.AutoClose"] = "Automatisches schließen, wenn alle Aufgaben erledigt sind",
    ["options.long.HideWhenScanBlocked"] =
    "Blendet das Buffomat-Fenster aus, wenn das Scannen durch inaktive Bedingungen gestoppt wird, z. B. Reiten, Rastgebiet, Verstohlenheit, Taxi, Fahrzeug, Tod, deaktivierte Zone oder Willensentzug.",

    Header_CANCELBUFF = "Buffs Abbrechen",
    Header_INFO = "Informationen",
    Header_item = "Verbrauchbares",
    Header_TRACKING = "Suche",
    HeaderCredits = "Credits",
    HeaderCustomLocales = "Lokalisierung",
    HeaderInfo = "Information",
    ["header.Profiles"] = "Profile",
    HeaderRenew = "Vor dem auslaufen erneuern (in Sekunden)",
    HeaderSlashCommand = "Befehle",
    HeaderSupportedSpells = "Unterstützte Zauber",
    HeaderUsage = "Benutzung",
    HeaderWatchGroup = "Im Raid Gruppe überwachen",
    FORMAT_BUFF_GROUP = "Gruppe %s %s",
    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s auf dich",
    ["castButton.Busy"] = "Beschäftigt",
    ["message.CancelBuff"] = "Beende Buff %s von %s",

    --["castButton.inactive.Mounted"] = "Buff on mount disabled",
    ["castButton.inactive.DeadMember"] = "Ein Gruppenmitglied ist tot",
    ["castButton.inactive.Flying"] = "Fliegen; Absteigen deaktiviert",
    ["castButton.inactive.InCombat"] = "Kampf",
    ["castButton.inactive.Instance"] = "Buff in Dungeons deaktiviert",
    ["castButton.inactive.IsDead"] = "Gestorben",
    ["castButton.inactive.IsStealth"] = "Buff im Stealth deaktiviert",
    ["castButton.inactive.MacroFrameShown"] = "Makros-Rahmen wird angezeigt",
    ["castButton.inactive.OpenWorld"] = "Buff in der Welt deaktiviert",
    ["castButton.inactive.PriestSpiritTap"] = "Der <Willensentzug> des Priesters ist aktiv",
    ["castButton.inactive.PvpZone"] = "Buff im PvP deaktiviert",
    ["castButton.inactive.RestArea"] = "Buff in Rastplätzen deaktiviert",
    ["castButton.inactive.Taxi"] = "Kein Buff am Taxi",
    ["castButton.inactive.Vehicle"] = "Kein Polieren am Fahrzeug",
    ["castbutton.inactive.GCD"] = "Globale Abklingzeit",

    ["error.castFailed.tooLowLevel"] = "Erniedrige den Rang für %s auf %s. Bitte neu zaubern.",
    ["castButton.NothingToDo"] = "Nichts zu tun",
    --MsgLocalRestart                             = "Die Lokalisierung wird erst nach einem Neustart übernommen (/reload)",
    ["castButton.NoMacroSlots"] = "Brauche Platz für ein Macro!",
    ["castButton.Next"] = "%s @ %s",
    ["message.BuffExpired"] = "%s ist abgelaufen.",
    PanelAbout = "Über",
    Pet = "Tier",
    SlashClose = "BOM-Fenster schließen",
    SlashOpen = "BOM-Fenster öffnen",
    SlashProfile = "Das aktuelle Profil zu solo/group/raid/battleground/auto wechseln",
    SlashReset = "BOM-Fenster zurücksetzen",
    SlashSpellBook = "Zauberbuch neu einlesen",
    SlashUpdate = "Update Macro / Liste",
    TabBuff = "Buff",
    TabSpells = "Zauber",
    Tank = "Tank",
    TooltipIncludesAllRanks = "Alle Varianten",
    TooltipEnableSpell = "Buffüberwachung ein-/ausschalten",
    TooltipEnableBuffCancel = "Automatisches beenden des Buff ein-/ausschalten",
    ["tooltip.SpellsDialog.watchGroup"] = "Gruppe %d",
    ["tooltip.mainhand"] = "Waffenhand",
    ["tooltip.offhand"] = "Schildhand",
    TooltipSelectTarget = "Wähle ein Gruppenmitglied um diese Option zu aktivieren.",
    --split into _Self and _Party ["TooltipSelfCastCheckbox"] = "Wirke auf Gruppe/Raid oder nur auf sich selbst",
    TooltipForceCastOnTarget = "Buff dauerhaft auf Ziel halten",
    TooltipWhisperWhenExpired = "Quelle anflüstern, wenn abgelaufen.",

    TooltipMacroButton = "Ziehe dieses Makro in deine Aktionsleiste, um die Buffs zu wirken|n"
        .. "Du kannst dem Makro unter Tastenbelegungen => Andere eine Tastenkombination hinzufügen",
    ["tooltip.button.AllSettings"] = "Alle Einstellungen",
    ["tooltip.button.QuickSettingsPopup"] = "Schnelleinstellungen und Profile",
    ["tooltip.button.AllBuffs"] = "Alle Buffs",
    ["tooltip.button.HideBuffomat"] =
    "Verstecken. Um wieder anzuzeigen, tippe /bom, klicke auf den Minimap-Button oder drücke %s",
    ["tooltip.TaskList.CastButton"] = "Wirke den Zauber aus der Liste.|nNicht im Kampf verfügbar.|n"
        .. "Kann auch über das Makro (in der obersten Reihe) aktiviert werden|n"
        .. "Noch eine Tastenkombination in Tastenkombinationen => Andere binden",
    ["taskList.holdOpenComment"] =
    "Buffomat-Fenster wurde von einem Benutzer geöffnet. Klicken Sie auf X oder drücken Sie %s, um das automatische Schließen wieder zu aktivieren.",
  }
end
