---@class BomLanguageFrenchModule

local frenchModule = LibStub("Buffomat-LanguageFrench") --[[@as BomLanguageFrenchModule]]

---@return BomLocaleDict
function frenchModule:Translations()
  return {
    ["shaman.flametongueDownranked"] = "Un rang en dessous",

    ["Category_class"] = "Buffs de classe",
    ["Category_blessing"] = "Bénédictions",
    ["Category_pet"] = "Familier / Compagnon",
    ["Category_tracking"] = "Pistage",
    ["Category_aura"] = "Auras",
    ["Category_seal"] = "Sceaux",
    ["Category_classicPhysFood"] = "Nourriture physique (Classic)",
    ["Category_classicSpellFood"] = "Nourriture magique (Classic)",
    ["Category_classicFood"] = "Autre nourriture (Classic)",
    ["Category_classicPhysElixir"] = "Élixirs physiques (Classic)",
    ["Category_classicPhysBuff"] = "Buffs physiques (Classic)",
    ["Category_classicSpellElixir"] = "Élixirs magiques (Classic)",
    ["Category_classicBuff"] = "Buffs (Classic)",
    ["Category_classicElixir"] = "Élixirs (Classic)",
    ["Category_classicFlask"] = "Flacons (Classic)",
    ["Category_tbcPhysFood"] = "Nourriture physique (TBC)",
    ["Category_tbcSpellFood"] = "Nourriture magique (TBC)",
    ["Category_tbcFood"] = "Autre nourriture (TBC)",
    ["Category_tbcPhysElixir"] = "Élixirs physiques (TBC)",
    ["Category_tbcSpellElixir"] = "Élixirs magiques (TBC)",
    ["Category_tbcElixir"] = "Autres élixirs (TBC)",
    ["Category_tbcFlask"] = "Flacons (TBC)",
    ["Category_wotlkPhysFood"] = "Nourriture physique (WotLK)",
    ["Category_wotlkSpellFood"] = "Nourriture magique (WotLK)",
    ["Category_wotlkFood"] = "Autre nourriture (WotLK)",
    ["Category_wotlkPhysElixir"] = "Élixirs physiques (WotLK)",
    ["Category_wotlkSpellElixir"] = "Élixirs magiques (WotLK)",
    ["Category_wotlkElixir"] = "Autres élixirs (WotLK)",
    ["Category_wotlkFlask"] = "Flacons (WotLK)",
    ["Category_cataFood"] = "Nourriture (Cataclysm)",
    ["Category_cataElixir"] = "Élixirs (Cataclysm)",
    ["Category_cataFlask"] = "Flacons (Cataclysm)",
    ["Category_scroll"] = "Parchemins",
    ["Category_weaponEnchantment"] = "Enchantements d'arme",
    ["Category_classWeaponEnchantment"] = "Enchantements de classe",
    ["Category_none"] = "Sans catégorie",

    ["options.OptionsTitle"] = "Buffomat",
    ["options.general.group.AutoActions"] = "Actions réactives",
    ["options.general.group.Convenience"] = "Confort",
    ["options.general.group.General"] = "Général",
    ["options.general.group.Scan"] = "Scan",
    ["options.general.group.Buffing"] = "Timers de buffs",
    ["options.general.group.Visibility"] = "Afficher les catégories",
    ["options.general.group.Class"] = "Options de classe",
    ["options.convenience.SomeoneIsDrinking.Hide"] = "Ignorer",
    ["options.convenience.SomeoneIsDrinking.LowPrio"] = "Afficher une note dans les tâches",
    ["options.convenience.SomeoneIsDrinking.Show"] = "Afficher une note et montrer Buffomat",
    ["options.short.ActivateBomOnSpiritTap"] = "Activer avec Connexion spirituelle sous % de mana",
    ["options.short.AutoClose"] = "Fermer automatiquement",
    ["options.short.HideWhenScanBlocked"] = "Masquer Buffomat si le scan est bloque",
    ["options.short.AutoCrusaderAura"] = "Suggérer l'aura de croisé",
    ["options.short.AutoDismount"] = "Démonter automatiquement",
    ["options.short.AutoDismountFlying"] = "Démonter en vol automatiquement",
    ["options.short.AutoDisTravel"] = "Quitter la forme de voyage automatiquement",
    ["options.short.AutoOpen"] = "Afficher Buffomat quand il y a des tâches",
    ["options.short.AutoStand"] = "Se lever automatiquement",
    ["options.short.BestAvailableConsume"] = "Choisir le meilleur consommable disponible",
    ["options.short.BuffTarget"] = "Buff la cible d'abord",
    ["options.short.Carrot"] = "Avertir pour les objets de monture",
    ["options.short.CustomBuffSorting"] = "Afficher les contrôles de tri dans la liste des buffs",
    ["options.short.DeathBlock"] = "Ne pas buff de groupe quand quelqu'un est mort",
    ["options.short.DontUseConsumables"] = "Ne pas utiliser les consommables",
    ["options.short.FadeWhenNothingToDo"] = "Atténuer la fenêtre Buffomat sans tâches",
    ["options.short.InInstance"] = "Scanner en instance",
    ["options.short.InPVP"] = "Scanner en JcJ",
    ["options.short.InWorld"] = "Scanner dans le monde",
    ["options.short.MainHand"] = "Enchantement main droite manquant",
    ["options.short.NoGroupBuff"] = "Ne pas utiliser les buffs de groupe",
    ["options.short.OpenLootable"] = "Ouvrir les conteneurs fouillables",
    ["options.short.PreventPVPTag"] = "Empêcher le tag JcJ",
    ["options.short.ReplaceSingle"] = "Remplacer les buffs simples",
    ["options.short.ReputationTrinket"] = "Avertir pour les objets de réputation",
    ["options.short.ResGhost"] = "Tenter de ressusciter les fantômes",
    ["options.short.SameZone"] = "Uniquement dans la même zone",
    ["options.short.ScanInRestArea"] = "Scanner en zone de repos",
    ["options.short.ScanInStealth"] = "Scanner en furtivité",
    ["options.short.ScanWhileMounted"] = "Scanner à monture",
    ["options.short.SecondaryHand"] = "Enchantement main gauche manquant",
    ["options.short.SelfFirst"] = "Soi-même d'abord",
    ["options.short.ShamanFlametongueRanked"] = "Chaman : utiliser Langue de feu rétrogradée en main droite",
    ["options.short.ShowMinimapButton"] = "Montrer bouton minimap",
    ["options.short.SlowerHardware"] = "Scanner les buffs moins souvent",
    ["options.short.SomeoneIsDrinking"] = "Quand quelqu'un boit...",
    ["options.short.UseProfiles"] = "Utiliser les profils",
    ["options.short.UseRank"] = "Utiliser les rangs et rétrograder si nécessaire",
    ["options.short.VisibleCategories"] = "Afficher les buffs (réglage par personnage)",
    ["options.long.ActivateBomOnSpiritTap"] = "Désactiver Buffomat si Connexion spirituelle du prêtre est active et si la mana est sous le % indiqué",
    ["options.long.AutoClose"] = "Fermer automatiquement, lorsque la dernière tâche est terminée",
    ["options.long.HideWhenScanBlocked"] = "Masquer la fenetre Buffomat quand le scan est arrete par des conditions inactives, comme monture, zone de repos, furtivite, taxi, vehicule, mort, zone desactivee ou Connexion spirituelle.",
    ["options.long.AutoCrusaderAura"] = "Paladin : aura de croisé automatique à monture",
    ["options.long.AutoDismount"] = "Démonter automatiquement de la monture terrestre au lancement",
    ["options.long.AutoDismountFlying"] = "Quitter automatiquement la monture volante au lancement (attention)",
    ["options.long.AutoDisTravel"] = "Retirer automatiquement la forme de voyage (ne fonctionne pas en Classic)",
    ["options.long.AutoOpen"] = "Si coché, la fenêtre des tâches apparaît quand des tâches sont disponibles ; sinon elle apparaît seulement avec son raccourci.",
    ["options.long.AutoStand"] = "Si le personnage est assis, Buffomat le fera se lever",
    ["options.long.BestAvailableConsume"] = "Si coché, choisit le consommable disponible le plus élevé. Sinon choisit le plus faible, utile en leveling pour utiliser l'ancien stock",
    ["options.long.BuffTarget"] = "Essayer aussi de buff la cible actuelle",
    ["options.long.Carrot"] = "Rappeler de déséquiper les bijoux de monte/vol",
    ["options.long.CustomBuffSorting"] = "Afficher un champ texte supplémentaire dans la liste des buffs. La valeur saisie servira au tri des tâches.",
    ["options.long.DeathBlock"] = "Ne pas lancer de buffs de groupe quand quelqu'un est mort",
    ["options.long.DontUseConsumables"] = "Utiliser les consommables seulement avec Shift, Ctrl ou Alt",
    ["options.long.FadeWhenNothingToDo"] = "Régler l'opacité de la fenêtre Buffomat quand il n'y a rien à faire",
    ["options.long.GroupBuff"] = "Lancer les buffs de groupe si nécessaire (coût en réactifs plus élevé)",
    ["options.long.InInstance"] = "Scanner les buffs en donjons et raids",
    ["options.long.InPVP"] = "Scanner les buffs en champs de bataille",
    ["options.long.InWorld"] = "Scanner les buffs dans le monde et les villes",
    ["options.long.MainHand"] = "Avertir si l'enchantement de main droite manque",
    ["options.long.NoGroupBuff"] = "Toujours buff simple",
    ["options.long.OpenLootable"] = "Ouvrir les objets fouillables dans les sacs",
    ["options.long.PreventPVPTag"] = "Ignorer les cibles JcJ quand votre JcJ est désactivé",
    ["options.long.ReplaceSingle"] = "Remplacer les buffs simples par des buffs de groupe",
    ["options.long.ReputationTrinket"] = "Rappeler de déséquiper le bijou de réputation",
    ["options.long.ResGhost"] = "Tenter de ressusciter les fantômes en espérant que le corps soit accessible (pas de vérification de distance)",
    ["options.long.SameZone"] = "Surveiller seulement dans la même zone",
    ["options.long.ScanInRestArea"] = "Scanner les buffs dans les zones de repos (ville et auberge)",
    ["options.long.ScanInStealth"] = "Scanner les buffs en furtivité",
    ["options.long.ScanWhileMounted"] = "Scanner quand le joueur est à monture",
    ["options.long.SecondaryHand"] = "Avertir si l'enchantement de main gauche manque",
    ["options.long.SelfFirst"] = "Toujours se buff soi-même d'abord",
    ["options.long.ShamanFlametongueRanked"] = "Chaman : utiliser Langue de feu rétrogradée en main droite et le rang max en main gauche. À utiliser quand les vitesses d'armes correspondent et que la main droite a de la puissance des sorts.",
    ["options.long.ShowClassicConsumables"] = "Afficher les consommables disponibles en Classic",
    ["options.long.ShowMinimapButton"] = "Afficher le bouton de minimap",
    ["options.long.ShowTBCConsumables"] = "Afficher les consommables disponibles en TBC",
    ["options.long.SlowerHardware"] = "Vérifications de buffs moins fréquentes (matériel lent/raid)",
    ["options.long.SomeoneIsDrinking"] = "Quand quelqu'un boit, un message peut être affiché ou masqué",
    ["options.long.UseProfiles"] = "Utiliser les profils selon que le joueur est seul, en groupe, raid ou champ de bataille",
    ["options.long.UseRank"] = "Utiliser les sorts avec rangs ; si la cible est trop bas niveau, un rang inférieur sera utilisé la prochaine fois",
    ["options.long.VisibleCategories"] = "Afficher une catégorie de buffs dans la liste des sorts (réglage par personnage)",

    ["tasklist.IgnoredBuffOn"] = "Ignoré %s : %s",

    ["task.target.Self"] = "Soi-même",
    ["task.target.SelfOnly"] = "Buff personnel",
    ["task.type.Enchantment"] = "Enchantement",
    ["task.type.RegularBuff"] = "Buff",
    ["task.type.GroupBuff"] = "Buff de groupe",
    ["task.type.GroupBuff.Self"] = "Cibler soi-même",
    ["task.type.Tracking"] = "Pistage",
    ["task.type.Reminder"] = "Rappel",
    ["task.type.Resurrect"] = "Ressusciter",
    ["task.type.MissingConsumable"] = "Consommable manquant",
    ["task.type.Consumable"] = "Consommable",
    ["task.hint.HoldShiftConsumable"] = "Maintenir Shift/Ctrl ou Alt",

    TASK_BLESS_GROUP = "Bénir le groupe",
    TASK_BLESS = "Bénir",
    TASK_SUMMON = "Invoquer",
    TASK_CAST = "Lancer",

    ["task.type.Use"] = "Utiliser",
    ["task.type.Consume"] = "Consommer",
    ["task.type.tbcHunterPetBuff"] = "Utiliser sur le familier",

    TASK_ACTIVATE = "Activer",

    ["task.type.Unequip"] = "Déséquiper",
    ["task.error.range"] = "Portée",

    ["reminder.reputationTrinket"] = "Bijou de réputation",
    ["reminder.ridingSpeedTrinket"] = "Bijou de vitesse de monte/vol",

    ["task.hint.DontHaveItem"] = "Pas dans les sacs",
    ["task.notifications.no-sound"] = "Aucun son",
    ["task.error.missingMainhandWeapon"] = "Impossible d'enchanter la main droite",
    ["task.error.missingOffhandWeapon"] = "Impossible d'enchanter la main gauche (pas d'arme)",

    CHAT_MSG_PREFIX = "Buffomat : ",

    Buffomat = "Buffomat",

    ResetWatchGroups = "réinitialisation des groupes de buffs à 1-8",

    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s sur toi-même",
    FORMAT_BUFF_GROUP = "Groupe %s %s",
    FORMAT_GROUP_NUM = "G%s",

    ["castButton.Next"] = "%s @ %s",
    ["castButton.InCombat"] = "En combat",
    ["castButton.Busy"] = "Occupé",
    ["castButton.BusyChanneling"] = "Occupé / canalisation",
    ["castButton.NothingToDo"] = "Rien à faire",
    ["castButton.NoMacroSlots"] = "Besoin d'un emplacement macro!",
    ["castButton.CantCastMaybeOOM"] = "Impossible de buff, manque de mana ou autre raison",

    ["message.CancelBuff"] = "Annuler le buff %s de %s",
    ["message.BuffExpired"] = "%s a expiré.",

    ["task.UseOrOpen"] = "Ouvrir",

    MSG_MAINHAND_ENCHANT_MISSING = "Enchantement main droite manquant",
    MSG_OFFHAND_ENCHANT_MISSING = "Enchantement main gauche manquant",

    InfoSomeoneIsDrinking = "1 personne boit",

    InfoMultipleDrinking = "%d personnes boivent",

    ["castButton.inactive.DeadMember"] = "Quelqu'un est mort",
    ["castButton.inactive.Flying"] = "En vol ; démontage désactivé",
    ["castButton.inactive.InCombat"] = "En combat",
    ["castButton.inactive.Instance"] = "Buffs désactivés en donjon",
    ["castButton.inactive.IsDead"] = "Mort",
    ["castButton.inactive.IsStealth"] = "Buffs désactivés en furtivité",
    ["castButton.inactive.MacroFrameShown"] = "La fenêtre des macros est ouverte",
    ["castButton.inactive.Mounted"] = "Buffs à monture désactivés",
    ["castButton.inactive.OpenWorld"] = "Buffs dans le monde désactivés",
    ["castButton.inactive.PriestSpiritTap"] = "<Connexion spirituelle> du prêtre est active",
    ["castButton.inactive.PvpZone"] = "Buffs en JcJ désactivés",
    ["castButton.inactive.RestArea"] = "Buffs en zone de repos désactivés",
    ["castButton.inactive.Taxi"] = "Pas de buff sur taxi",
    ["castButton.inactive.Vehicle"] = "Pas de buff en véhicule",

    ["castbutton.inactive.GCD"] = "Temps de recharge global",

    ["error.castFailed.tooLowLevel"] = "Rang de sort réduit %s pour %s. Veuillez relancer.",

    CRUSADER_AURA_COMMENT = "Peut être lancé automatiquement selon les réglages",

    HeaderRenew = "Renouveler avant expiration (en Secondes)",

    ["options.short.Time60"] = "Durée <=60 sec:",
    ["options.short.Time300"] = "Durée <=5 min:",
    ["options.short.Time600"] = "Durée <=10 min:",
    ["options.short.Time1800"] = "Durée <=30 min:",
    ["options.short.Time3600"] = "Durée <=60 min:",
    ["options.short.UIWindowScale"] = "Échelle UI",
    ["options.short.MinBuff"] = "Buffs manquants pour utiliser un buff de groupe",
    ["options.short.MinBlessing"] = "Cibles de bénédiction pour une bénédiction supérieure",
    ["options.short.PlaySoundWhenTask"] = "Jouer un son quand il y a des tâches de buff",
    ["options.short.PlaySoundWhenTask.test"] = "Jouer",
    ["options.short.DebugLogging"] = "[Développeur] Afficher des messages de debug supplémentaires (bruyant !)",
    ["options.general.sound.None"] = "- aucun effet sonore -",
    ["options.long.Time60"] = "Rafraîchir les buffs de durée totale <=60 s s'il reste moins de",
    ["options.long.Time300"] = "Rafraîchir les buffs de durée totale <=5 min s'il reste moins de",
    ["options.long.Time600"] = "Rafraîchir les buffs de durée totale <=10 min s'il reste moins de",
    ["options.long.Time1800"] = "Rafraîchir les buffs de durée totale <=30 min s'il reste moins de",
    ["options.long.Time3600"] = "Rafraîchir les buffs de durée totale <=60 min s'il reste moins de",
    ["options.long.UIWindowScale"] = "Échelle de l'interface, agrandir ou réduire Buffomat (défaut 1.0)",
    ["options.long.MinBuff"] = "Nombre de buffs manquants requis pour utiliser un buff de groupe",
    ["options.long.MinBlessing"] = "Nombre de bénédictions manquantes requis pour utiliser une bénédiction supérieure",
    ["options.long.PlaySoundWhenTask"] = "Jouer un son quand la liste des tâches n'est pas vide",
    ["options.long.PlaySoundWhenTask.test"] = "Cliquer pour tester le son choisi",
    ["options.long.DebugLogging"] = "Pour le développement, affiche des messages supplémentaires aidant à trouver les problèmes, ne pas utiliser !",

    TooltipCustomSorting = "Le texte saisi ici servira à trier les buffs. Appuyez sur Entrée pour enregistrer.",

    TooltipSelfCastCheckbox_Self = "Seulement sur soi",
    TooltipSelfCastCheckbox_Party = "Buff groupe et groupes de raid",

    TooltipEnableSpell = "Activer/Désactiver sort",

    TooltipEnableBuffCancel = "Annuler ce buff dès qu'il est trouvé",

    FormatToggleTarget = "Cliquer pour basculer le joueur : %s",

    FormatAllForceCastTargets = "Lancer de force sur : ",

    FormatForceCastNone = "La liste de lancement forcé est vide",

    FormatAllExcludeTargets = "Ignorés : ",

    FormatExcludeNone = "La liste d'ignorés est vide",

    TooltipForceCastOnTarget = "Forcer sort sur Cible actuelle",

    TooltipExcludeTarget = "Ajouter la cible actuelle du raid ou groupe à la liste d'exclusion",

    TooltipSelectTarget = "Choisir un membre groupe/raid pour activer cette option",

    ["tooltip.SpellsDialog.watchGroup"] = "Groupe %d",

    TooltipRaidGroupsSettings = "Réglages des groupes de raid à surveiller",

    MessageAddedForced = "Buff forcé ",

    MessageClearedForced = "Buff forcé retiré pour",

    MessageAddedExcluded = "Ne buffera jamais ",

    MessageClearedExcluded = "Exclusion retirée pour",

    HintCancelThisBuff = "Annuler ce buff",
    HintCancelThisBuff_Combat = "Avant le combat",
    HintCancelThisBuff_Always = "Toujours",

    TooltipWhisperWhenExpired = "Chuchoter au joueur qui a lancé le buff quand il expire",

    ["tooltip.mainhand"] = "Main droite",
    ["tooltip.offhand"] = "Main gauche",

    ShamanEnchantBlocked = "En attente de la main droite",

    PreventPVPTagBlocked = "La cible est JcJ",

    TooltipIncludesAllRanks = "Tout buff de ce type",

    TooltipSimilar = "Tout similaire",

    TooltipSimilarFoods = "Toute nourriture similaire",

    ["tooltip.buff.conjure"] = "Conjurer",
    ["tooltip.buff.agility"] = "+Agi",
    ["tooltip.buff.allResist"] = "+Toutes rés.",
    ["tooltip.buff.attackPower"] = "+Attaque",
    ["tooltip.buff.crit"] = "+Crit",
    ["tooltip.buff.fireResist"] = "+Rés. feu",
    ["tooltip.buff.frostResist"] = "+Rés. givre",
    ["tooltip.buff.haste"] = "+Hâte",
    ["tooltip.buff.healing"] = "+Soins",
    ["tooltip.buff.hit"] = "+Toucher",
    ["tooltip.buff.intellect"] = "+Int",
    ["tooltip.buff.maxHealth"] = "+PV max",
    ["tooltip.buff.mp5"] = "+Mana/5",
    ["tooltip.buff.resilience"] = "+Résil",
    ["tooltip.buff.spellPower"] = "+Sorts",
    ["tooltip.buff.spellCrit"] = "+Crit sorts",
    ["tooltip.buff.spirit"] = "+Esprit",
    ["tooltip.buff.stamina"] = "+Endu",
    ["tooltip.buff.strength"] = "+Force",
    ["tooltip.buff.comboMealWotlk"] = "+Attaque/+Sorts",
    ["tooltip.buff.armorPenetration"] = "+Péné. armure",
    ["tooltip.buff.petStrength"] = "Familier +Force",
    ["tooltip.buff.petStamina"] = "Familier +Endu",
    ["tooltip.buff.alchemistOnly"] = "Alchimiste seulement",
    ["tooltip.consumable.bestInBag"] = " (meilleur dans vos sacs)",
    ["tooltip.elixir.bestInBag"] = " (meilleur élixir dans vos sacs)",
    ["tooltip.food.bestInBag"] = " (meilleure nourriture dans vos sacs)",
    ["tooltip.scroll.bestInBag"] = " (meilleur parchemin dans vos sacs)",

    ["consumeType.food"] = "Nourriture",
    ["consumeType.elixir"] = "Élixir",
    ["consumeType.scroll"] = "Parchemin",

    ["Items, which provide buff for %s:"] = "Objets fournissant le buff %s :",

    ["Click to print all items which provide this buff"] = "Ceci est un groupe d'objets fournissant le même type de buff\nCliquer pour afficher tous les objets qui fournissent ce buff",

    ["tooltip.alcohol.stamina"] = "Alcool +Endurance",
    ["tooltip.alcohol.spirit"] = "Alcool +Esprit",

    ["Healing Power"] = "Puissance des soins",

    TabBuff = "Buff",

    TabDoNotBuff = "Ne pas buff",

    TabBuffOnlySelf = "Buff soi-même seulement",

    TabSpells = "Sorts",

    ["popup.OpenBuffomat"] = "Ouvrir",

    BtnCancel = "Annuler",

    ["popup.QuickSettings"] = "Réglages rapides",

    ["optionsMenu.Settings"] = "Réglages",

    BtnSettingsSpells = "Réglage sorts",

    BtnBuffs = "Consommables",

    ButtonCastBuff = "Lancer le buff",

    ButtonBuffomatWindow = "Afficher/masquer la fenêtre Buffomat",

    Header_TRACKING = "Pistage",
    Header_INFO = "Information",
    Header_CANCELBUFF = "Annuler buff",
    Header_item = "Consommables",

    HeaderSupportedSpells = "Sorts supportés",

    HeaderWatchGroup = "Groupe à surveiller en raid",

    PanelAbout = "A propos",

    HeaderInfo = "Information",

    HeaderUsage = "Utilisation",

    HeaderSlashCommand = "Commandes",

    HeaderCredits = "Crédits",

    HeaderCustomLocales = "Localisation",

    ["header.Profiles"] = "Profils",

    SlashSpellBook = "Rescanner Grimoire",

    SlashUpdate = "Mettre à jour macro / liste",

    SlashClose = "Fermer fenêtre BOM",

    SlashReset = "Réinitialiser fenêtre BOM",

    SlashOpen = "Ouvrir fenêtre BOM",

    SlashProfile = "Changer le profil actuel en solo/groupe/raid/champ de bataille/auto",

    Tank = "Tank",

    Pet = "Familier",

    TooltipCastOnClass = "Lancer sur la classe",

    TooltipCastOnTank = "Lancer sur les tanks",

    TooltipCastOnPet = "Lancer sur les familiers",

    ["profile.activeProfileMenuTag"] = "[actif]",

    ["profileName.solo"] = "Solo",
    ["profileName.solo_spec2"] = "Solo (Secondes)",
    ["profileName.group"] = "Groupe",
    ["profileName.group_spec2"] = "Groupe (Secondes)",
    ["profileName.raid"] = "Raid",
    ["profileName.raid_spec2"] = "Raid (Secondes)",
    ["profileName.battleground"] = "Champs de bataille",
    ["profileName.battleground_spec2"] = "Champs de bataille (Secondes)",
    ["profileName.auto"] = "Automatique",

    AboutInfo = "Endurance ! Int ! Esprit ! Cela vous dit quelque chose ? Buffomat scanne le groupe/raid pour les buffs manquants et les lance d'un clic. Quand trois membres ou plus ont besoin du même buff, la version de groupe est utilisée. Il active aussi les pistages comme 'Find Herbs'.|nIl aide aussi à ressusciter les joueurs en priorisant paladins, prêtres et chamans.",

    AboutUsage = "Vous avez besoin d'un emplacement de macro libre pour utiliser cet addon. La fenêtre principale a deux onglets 'Buff' et 'Sorts'. Sous 'Buff' se trouvent les buffs manquants et un bouton de lancement. Sous 'Sorts', vous choisissez quels sorts surveiller, si la version de groupe doit être lancée, si le sort doit être lancé seulement sur vous ou sur tout le groupe, et quelle classe doit recevoir quel buff. Vous pouvez aussi ignorer des groupes entiers, par exemple en raid si vous ne devez mettre l'intelligence que sur les groupes 7 et 8. Vous pouvez également choisir qu'un buff soit actif sur la cible actuelle. Exemple : druide, ciblez le tank principal et cliquez sur '-' dans la section 'Épines' ; il devient un réticule et Buffomat vous rappellera de rebuff le tank. Vous avez deux façons de lancer un buff : le bouton de sort dans la fenêtre ou la macro Buff'o'mat via le bouton 'M' dans la barre de titre.|nIMPORTANT : Buff'o'mat fonctionne seulement hors combat car Blizzard interdit de changer les macros en combat. Vous ne pouvez pas non plus ouvrir ou fermer la fenêtre principale en combat !",

    AboutSlashCommand = "<valeur> peut être true, 1, enable, false, 0, disable. Si <valeur> est omis, la valeur actuelle s'inverse.",

    TooltipMacroButton = "Glissez cette macro sur votre barre d'action pour lancer les buffs|nVous pouvez aussi assigner un raccourci dans Raccourcis clavier => Autre",

    ["tooltip.button.AllSettings"] = "Tous les réglages",
    ["tooltip.button.QuickSettingsPopup"] = "Réglages rapides et profils",
    ["tooltip.button.AllBuffs"] = "Tous les buffs",
    ["tooltip.button.HideBuffomat"] = "Masquer. Pour réafficher, tapez /bom, cliquez le bouton de minimap ou appuyez sur %s",
    ["tooltip.TaskList.CastButton"] = "Lancer le sort de la liste.|nIndisponible en combat.|nPeut aussi être activé via la macro (ligne du haut)|nou par un raccourci dans Raccourcis clavier => Autre",

    SpellLabel_TrackHumanoids = "Chat seulement - remplace le pistage des herbes et minerais",

    ["title.SpellsWindow"] = "Choisir sorts et buffs (%s)",

    SpellsWindow_ShowCategory = "Cocher pour afficher cette catégorie",

    ["title.ForceTarget"] = "Forcer le buff sur",
    ["title.ExcludeTarget"] = "Exclure lors du buff",

    ["button.ForceCast.AddTarget"] = "Ajouter cible",

    ["buttonTooltip.ForceCast.AddTarget"] = "Ciblez un joueur ou familier et ajoutez-le à la liste forcée/ignorée",

    ["button.ForceCast.RemoveTarget"] = "Retirer cible",

    ["buttonTooltip.ForceCast.RemoveTarget"] = "Ciblez un joueur ou familier et retirez-le de la liste forcée/ignorée",

    ["label.ForceCast.TargetList"] = "Liste des cibles",
    ["label.SpellsDialog.ProfileSelector"] = "Choix de buffs pour le profil",
    ["label.SpellsDialog.GroupScanSelector"] = "Groupes de raid surveillés",

    ["binding.notSet"] = "[non défini]",
  }
end
