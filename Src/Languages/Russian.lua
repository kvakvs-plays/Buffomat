---@class BomLanguageRussianModule

local russianModule = LibStub("Buffomat-LanguageRussian") --[[@as BomLanguageRussianModule]]

---@return BomLocaleDict
function russianModule:Translations()
  return {
    ["shaman.flametongueDownranked"] = "На один ранг ниже",

    ["Category_class"] = "Бафы вашего класса",
    ["Category_blessing"] = "Благословения",
    ["Category_pet"] = "Питомец",
    ["Category_tracking"] = "Поиск вокруг",
    ["Category_aura"] = "Ауры",
    ["Category_seal"] = "Печати",
    ["Category_classicPhysFood"] = "Еда для физ. атак (Classic)",
    ["Category_classicSpellFood"] = "Еда для заклинаний (Classic)",
    ["Category_classicFood"] = "Прочая еда (Classic)",
    ["Category_classicPhysElixir"] = "Эликсиры для физ. атак (Classic)",
    ["Category_classicPhysBuff"] = "Бафы для физ. атак (Classic)",
    ["Category_classicSpellElixir"] = "Эликсиры для заклинаний (Classic)",
    ["Category_classicBuff"] = "Бафы (Classic)",
    ["Category_classicElixir"] = "Эликсиры (Classic)",
    ["Category_classicFlask"] = "Настои (Classic)",
    ["Category_tbcPhysFood"] = "Еда для физ. атак (TBC)",
    ["Category_tbcSpellFood"] = "Еда для заклинаний (TBC)",
    ["Category_tbcFood"] = "Прочая еда (TBC)",
    ["Category_tbcPhysElixir"] = "Эликсиры для физ. атак (TBC)",
    ["Category_tbcSpellElixir"] = "Эликсиры для заклинаний (TBC)",
    ["Category_tbcElixir"] = "Эликсиры (TBC)",
    ["Category_tbcFlask"] = "Настои (TBC)",
    ["Category_wotlkPhysFood"] = "Еда для физ. атак (WotLK)",
    ["Category_wotlkSpellFood"] = "Еда для заклинаний (WotLK)",
    ["Category_wotlkFood"] = "Прочая еда (WotLK)",
    ["Category_wotlkPhysElixir"] = "Эликсиры для физ. атак (WotLK)",
    ["Category_wotlkSpellElixir"] = "Эликсиры для заклинаний (WotLK)",
    ["Category_wotlkElixir"] = "Эликсиры (WotLK)",
    ["Category_wotlkFlask"] = "Настои (WotLK)",
    ["Category_cataFood"] = "Food (Cataclysm)",
    ["Category_cataElixir"] = "Elixirs (Cataclysm)",
    ["Category_cataFlask"] = "Flasks (Cataclysm)",
    ["Category_scroll"] = "Свитки",
    ["Category_weaponEnchantment"] = "Временные зачарования оружия",
    ["Category_classWeaponEnchantment"] = "Зачарования вашего класса",
    ["Category_none"] = "Прочее",

    ["options.OptionsTitle"] = "Buffomat",
    ["options.general.group.AutoActions"] = "Реакция на события",
    ["options.general.group.Convenience"] = "Удобство",
    ["options.general.group.General"] = "Общие настройки",
    ["options.general.group.Scan"] = "Сканирование",
    ["options.general.group.Buffing"] = "Время бафов",
    ["options.general.group.Visibility"] = "Скрыть категории",
    ["options.general.group.Class"] = "Классы",
    ["options.convenience.SomeoneIsDrinking.Hide"] = "Игнорировать",
    ["options.convenience.SomeoneIsDrinking.LowPrio"] = "Показать заметку в задачах",
    ["options.convenience.SomeoneIsDrinking.Show"] = "Показать заметку и окно Buffomat",
    ["options.short.ActivateBomOnSpiritTap"] = "Запретить Бафомёт, при 'Захвате духа' жреца",
    ["options.short.AutoClose"] = "Авто-закрытие. Предпочитать оставаться открытым.",
    ["options.short.HideWhenScanBlocked"] = "Скрывать Бафомёт, если сканирование заблокировано",
    ["options.short.AutoCrusaderAura"] = "Предлагать ауру рыцаря",
    ["options.short.AutoDismount"] = "Автоматически спешиваться",
    ["options.short.AutoDismountFlying"] = "Автоматически спешиваться в полёте",
    ["options.short.AutoDisTravel"] = "Автоматически выходить из походного облика",
    ["options.short.AutoOpen"] = "Авто-открытие, когда есть задачи",
    ["options.short.AutoStand"] = "Автоматически вставать",
    ["options.short.BestAvailableConsume"] = "Выбирать лучшее из имеющегося",
    ["options.short.BuffTarget"] = "Сначала бафать цель",
    ["options.short.Carrot"] = "Предупреждать о предметах для скорости",
    ["options.short.CustomBuffSorting"] = "Показать доп. поля для сортировки бафов",
    ["options.short.DeathBlock"] = "Не применять групповые эффекты, когда кто-то мертв",
    ["options.short.DontUseConsumables"] = "Не использовать расходники",
    ["options.short.FadeWhenNothingToDo"] = "Делать окно прозрачным, когда нет задач",
    ["options.short.InInstance"] = "Сканировать бафы в подземельях и рейдах",
    ["options.short.InPVP"] = "Сканировать бафы на полях битвы",
    ["options.short.InWorld"] = "Сканировать бафы в открытом мире",
    ["options.short.MainHand"] = "Нет зачарования основной руки",
    ["options.short.NoGroupBuff"] = "Всегда давать одиночные бафы",
    ["options.short.OpenLootable"] = "Открывать добываемые контейнеры",
    ["options.short.PreventPVPTag"] = "Не бафать PvP игроков, если ваш PvP выключен",
    ["options.short.ReplaceSingle"] = "Заменить одиночный баф групповым",
    ["options.short.ReputationTrinket"] = "Не забудьте (снять)экипировать Жетон Серебряного Рассвета",
    ["options.short.ResGhost"] = "Пытаться воскрешать призраки, если тело лежит близко",
    ["options.short.SameZone"] = "Только если находится в одной зоне со мной",
    ["options.short.ScanInRestArea"] = "Сканировать бафы в городах и тавернах",
    ["options.short.ScanInStealth"] = "Сканировать бафы в режиме незаметности",
    ["options.short.ScanWhileMounted"] = "Сканировать, сидя на ездовом животном",
    ["options.short.SecondaryHand"] = "Нет зачарования второй руки",
    ["options.short.SelfFirst"] = "Сначала себя",
    ["options.short.ShamanFlametongueRanked"] = "Шаман: Использовать пониженный ранг языков пламени на правой руке",
    ["options.short.ShowMinimapButton"] = "Показать кнопку у миникарты",
    ["options.short.SlowerHardware"] = "Сканировать бафы реже",
    ["options.short.SomeoneIsDrinking"] = "Когда кто-то в группе пьёт",
    ["options.short.UseProfiles"] = "Использовать профили",
    ["options.short.UseRank"] = "Использовать понижение ранга заклинаний",
    ["options.short.VisibleCategories"] = "Показывать бафы (настройка персонажа)",
    ["options.long.ActivateBomOnSpiritTap"] = "Запретить Бафомёт, если 'Захват духа' жреца активен и мана меньше указанного процента",
    ["options.long.AutoClose"] = "Автоматически закрывать Бафомёт, когда все задачи выполнены",
    ["options.long.HideWhenScanBlocked"] = "Скрывать окно Бафомёта, когда сканирование остановлено неактивными условиями: верхом, зона отдыха, незаметность, такси, транспорт, смерть, отключенная зона или Захват духа.",
    ["options.long.AutoCrusaderAura"] = "Паладин: автоматически включать ауру рыцаря верхом",
    ["options.long.AutoDismount"] = "Автоматически спешиваться с наземного средства при касте",
    ["options.long.AutoDismountFlying"] = "Автоматически спешиваться с летающего средства при касте (опасно)",
    ["options.long.AutoDisTravel"] = "Автоматически снимать походный облик (не работает в Classic)",
    ["options.long.AutoOpen"] = "Автоматически открывать Бафомёт, когда есть задачи, иначе только по нажатию горячих клавиш",
    ["options.long.AutoStand"] = "Если персонаж сидел, Buffomat поставит его на ноги",
    ["options.long.BestAvailableConsume"] = "Если галочка установлена, то при наличии множества вариантов, будет предпочитатся лучший. Иначе - худший - пока игрок качается, чтобы доедать старую еду и эликсиры",
    ["options.long.BuffTarget"] = "Также пытаться бафать текущую цель",
    ["options.long.Carrot"] = "Напоминать снять аксессуары для езды/полёта",
    ["options.long.CustomBuffSorting"] = "В списке бафов станут видны дополнительные текстовые поля. Введённый в них текст будет использован для сортировки бафов.",
    ["options.long.DeathBlock"] = "Не кастовать групповые бафы, когда кто-то мёртв",
    ["options.long.DontUseConsumables"] = "Использовать расходники только с Shift, Ctrl или Alt",
    ["options.long.FadeWhenNothingToDo"] = "Установить прозрачность окна Бафомёта, если нечего делать",
    ["options.long.GroupBuff"] = "Кастовать групповые бафы при необходимости (дополнительная стоимость реагентов)",
    ["options.long.InInstance"] = "Сканировать бафы в подземельях и рейдах",
    ["options.long.InPVP"] = "Сканировать бафы на полях боя",
    ["options.long.InWorld"] = "Сканировать бафы в мире и городах",
    ["options.long.MainHand"] = "Предупреждать, если нет зачарования основной руки",
    ["options.long.NoGroupBuff"] = "Всегда одиночный баф",
    ["options.long.OpenLootable"] = "Открывать добываемые предметы в сумках",
    ["options.long.PreventPVPTag"] = "Пропускать PvP-цели, если ваш PvP выключен",
    ["options.long.ReplaceSingle"] = "Заменять одиночный баф групповым",
    ["options.long.ReputationTrinket"] = "Напоминать снять репутационный аксессуар",
    ["options.long.ResGhost"] = "Пытаться воскрешать призраков, если тело может быть доступно (без проверки дистанции)",
    ["options.long.SameZone"] = "Следить только в той же зоне",
    ["options.long.ScanInRestArea"] = "Сканировать бафы в зонах отдыха (город и таверна)",
    ["options.long.ScanInStealth"] = "Сканировать бафы в незаметности",
    ["options.long.ScanWhileMounted"] = "Разрешить сканирование бафов, когда игрок сидит на ездовом животном",
    ["options.long.SecondaryHand"] = "Предупреждать, если нет зачарования второй руки",
    ["options.long.SelfFirst"] = "Всегда бафать себя первым",
    ["options.long.ShamanFlametongueRanked"] = "Шаман: Для spellhancement шаманов использовать язык пламени пониженного ранга на правом оружии, и максимального ранга на левом. Включайте эту опцию, когда в правой руке у вас оружие с силой заклинаний.",
    ["options.long.ShowClassicConsumables"] = "Показывать расходники Classic",
    ["options.long.ShowMinimapButton"] = "Показать кнопку у миникарты",
    ["options.long.ShowTBCConsumables"] = "Показывать расходники TBC",
    ["options.long.SlowerHardware"] = "Менее частые проверки бафов (слабое железо/рейд)",
    ["options.long.SomeoneIsDrinking"] = "Когда кто-то пьёт, сообщение можно показать или скрыть",
    ["options.long.UseProfiles"] = "Использовать профили в зависимости от соло, группы, рейда или поля боя",
    ["options.long.UseRank"] = "Если у цели уровень слишком низкий, то использовать пониженный ранг заклинания",
    ["options.long.VisibleCategories"] = "Показывать категорию бафов в списке заклинаний (настройка персонажа)",

    ["tasklist.IgnoredBuffOn"] = "Пропускаем %s: %s",

    ["task.target.Self"] = "На себя",
    ["task.target.SelfOnly"] = "Самобаф",
    ["task.type.Enchantment"] = "Зачарование",
    ["task.type.RegularBuff"] = "Баф",
    ["task.type.GroupBuff"] = "Групповой",
    ["task.type.GroupBuff.Self"] = "Групповой (на себя)",
    ["task.type.Tracking"] = "Слежение",
    ["task.type.Reminder"] = "Напоминание",
    ["task.type.Resurrect"] = "Воскрешение",
    ["task.type.MissingConsumable"] = "Не хватает",
    ["task.type.Consumable"] = "Расходник",
    ["task.hint.HoldShiftConsumable"] = "Удерживайте Shift/Ctrl или Alt",

    TASK_BLESS_GROUP = "Благословить группу",
    TASK_BLESS = "Благословить",
    TASK_SUMMON = "Призвать",
    TASK_CAST = "Кастовать",

    ["task.type.Use"] = "Использовать",
    ["task.type.Consume"] = "Употребить",
    ["task.type.tbcHunterPetBuff"] = "Для питомца",

    TASK_ACTIVATE = "Активировать",

    ["task.type.Unequip"] = "Снять",
    ["task.error.range"] = "Дистанция",

    ["reminder.reputationTrinket"] = "Репутационный аксессуар",
    ["reminder.ridingSpeedTrinket"] = "Аксессуар скорости езды/полёта",

    ["task.hint.DontHaveItem"] = "Нет в сумках",
    ["task.notifications.no-sound"] = "Без звука",
    ["task.error.missingMainhandWeapon"] = "Невозможно зачаровать оружие в основной руке",
    ["task.error.missingOffhandWeapon"] = "Нет оружия во второй руке",

    CHAT_MSG_PREFIX = "Бафомёт: ",

    Buffomat = "Бафомёт",

    ResetWatchGroups = "сброс групп бафов на 1-8",

    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s на себя",
    FORMAT_BUFF_GROUP = "Группа %s %s",
    FORMAT_GROUP_NUM = "Г%s",

    ["castButton.Next"] = "%s @ %s",
    ["castButton.InCombat"] = "В бою",
    ["castButton.Busy"] = "Занят / Кастую",
    ["castButton.BusyChanneling"] = "Занят / Долгое заклинание",
    ["castButton.NothingToDo"] = "Нечего делать",
    ["castButton.NoMacroSlots"] = "Нужен хотя бы один свободный слот для макро!",
    ["castButton.CantCastMaybeOOM"] = "Недостаточно маны или другая причина",

    ["message.CancelBuff"] = "Отменён баф %s от %s",
    ["message.BuffExpired"] = "%s заклинание истекло.",

    ["task.UseOrOpen"] = "Открыть",

    MSG_MAINHAND_ENCHANT_MISSING = "Нет зачарования основной руки",
    MSG_OFFHAND_ENCHANT_MISSING = "Нет зачарования второй руки",

    InfoSomeoneIsDrinking = "Один игрок пьёт",

    InfoMultipleDrinking = "Несколько игроков пьют (%d)",

    ["castButton.inactive.DeadMember"] = "Кто-то мертв",
    ["castButton.inactive.Flying"] = "В полёте бафы отключены",
    ["castButton.inactive.InCombat"] = "В бою",
    ["castButton.inactive.Instance"] = "Бафы в подземельях отключены",
    ["castButton.inactive.IsDead"] = "Мертв",
    ["castButton.inactive.IsStealth"] = "Режим незаметности (откл. в опциях)",
    ["castButton.inactive.MacroFrameShown"] = "Открыт диалог макро",
    ["castButton.inactive.Mounted"] = "Игрок в седле (откл. в опциях)",
    ["castButton.inactive.OpenWorld"] = "Бафы в открытом мире отключены",
    ["castButton.inactive.PriestSpiritTap"] = "<Захват Духа> священника активен",
    ["castButton.inactive.PvpZone"] = "Бафы в ПвП зоне отключены",
    ["castButton.inactive.RestArea"] = "В зоне отдыха (откл. в опциях)",
    ["castButton.inactive.Taxi"] = "В такси бафы отключены",
    ["castButton.inactive.Vehicle"] = "На транспорте бафы отключены",

    ["castbutton.inactive.GCD"] = "Глобальная перезарядка",
    ["castButton.inactive.GlobalCooldown"] = "Глобальная перезарядка",

    ["error.castFailed.tooLowLevel"] = "Понижение ранга заклинания %s для %s. Попробуйте выполнить баф ещё раз.",

    CRUSADER_AURA_COMMENT = "Можно автокастовать по настройкам",

    HeaderRenew = "Продлить баф до истечения срока действия (в секундах)",

    ["options.short.Time60"] = "Продолжительность <=60 сек:",
    ["options.short.Time300"] = "Продолжительность <=5 мин:",
    ["options.short.Time600"] = "Продолжительность <=10 мин:",
    ["options.short.Time1800"] = "Продолжительность <=30 мин:",
    ["options.short.Time3600"] = "Продолжительность <=60 мин:",
    ["options.short.UIWindowScale"] = "Масштаб UI",
    ["options.short.MinBuff"] = "Групповой баф, если нуждаются более",
    ["options.short.MinBlessing"] = "Большое благословение, если нуждаются более",
    ["options.short.PlaySoundWhenTask"] = "Играть звук, когда есть задачи бафов",
    ["options.short.PlaySoundWhenTask.test"] = "Играть",
    ["options.short.DebugLogging"] = "[Разработка] Печатать дополнительные отладочные сообщения (много)",
    ["options.general.sound.None"] = "- не играть звук -",
    ["options.long.Time60"] = "Освежать баф продолжительностью <=60 сек, если осталось менее",
    ["options.long.Time300"] = "Освежать баф продолжительностью <=5 мин, если осталось менее",
    ["options.long.Time600"] = "Освежать баф продолжительностью <=10 мин, если осталось менее",
    ["options.long.Time1800"] = "Освежать баф продолжительностью <=30 мин, если осталось менее",
    ["options.long.Time3600"] = "Освежать баф продолжительностью <=60 мин, если осталось менее",
    ["options.long.UIWindowScale"] = "Масштаб интерфейса, сделать Buffomat больше или меньше (по умолчанию 1.0)",
    ["options.long.MinBuff"] = "Количество отсутствующих бафов, необходимое для использования группового бафа",
    ["options.long.MinBlessing"] = "Количество отсутствующих благословений, чтобы использовать большее благословение",
    ["options.long.PlaySoundWhenTask"] = "Играть звук, когда список задач не пуст",
    ["options.long.PlaySoundWhenTask.test"] = "Нажмите, чтобы проверить выбранный звук",
    ["options.long.DebugLogging"] = "Для разработки: выводит дополнительные сообщения для поиска проблем, не используйте!",

    TooltipCustomSorting = "Введённый здесь текст будет использован для сортировки бафов. Нажмите Enter, чтобы подтвердить новое значение.",

    TooltipSelfCastCheckbox_Self = "Применить баф только на себя",
    TooltipSelfCastCheckbox_Party = "Бафать группу или рейд",

    TooltipEnableSpell = "Вкл./откл. заклинание",

    TooltipEnableBuffCancel = "Отменять этот баф сразу после обнаружения",

    FormatToggleTarget = "Нажмите, чтобы переключить игрока: %s",

    FormatAllForceCastTargets = "Принудительно кастовать на: ",

    FormatForceCastNone = "Список принудительных целей пуст",

    FormatAllExcludeTargets = "Игнорировать: ",

    FormatExcludeNone = "Список игнорирования пуст",

    TooltipForceCastOnTarget = "Наложить заклинание на текущую цель",

    TooltipExcludeTarget = "Добавить выбранного игрока в список исключений и не бафать",

    TooltipSelectTarget = "Выберите участника рейда/группы, чтобы включить эту опцию",

    ["tooltip.SpellsDialog.watchGroup"] = "Следить за группой %d в рейде",

    TooltipRaidGroupsSettings = "Настройки рейдовых групп",

    MessageAddedForced = "Добавлена цель в список бафов",

    MessageClearedForced = "Убрана дополнительная цель из списка бафов",

    MessageAddedExcluded = "Добавлена цель в список пропуска",

    MessageClearedExcluded = "Цель убрана из списка пропуска",

    HintCancelThisBuff = "Отменять баф",
    HintCancelThisBuff_Combat = "Перед боем",
    HintCancelThisBuff_Always = "Сразу",

    TooltipWhisperWhenExpired = "Сообщить игроку, который дал этот баф, когда время бафа истечёт",

    ["tooltip.mainhand"] = "Правая рука",
    ["tooltip.offhand"] = "Левая рука",

    ShamanEnchantBlocked = "Ожидание бафа на другую руку",

    PreventPVPTagBlocked = "Цель в PvP",

    TooltipIncludesAllRanks = "Любой вариант этого бафа",

    TooltipSimilar = "Любой похожий",

    TooltipSimilarFoods = "Любая подобная еда",

    ["tooltip.buff.conjure"] = "Сотворить",
    ["tooltip.buff.agility"] = "+Ловк.",
    ["tooltip.buff.allResist"] = "+Сопр. магии всех школ",
    ["tooltip.buff.attackPower"] = "+Атака",
    ["tooltip.buff.crit"] = "+Крит",
    ["tooltip.buff.fireResist"] = "+Сопр. огню",
    ["tooltip.buff.frostResist"] = "+Сопр. льду",
    ["tooltip.buff.haste"] = "+Скорость",
    ["tooltip.buff.healing"] = "+Лечение",
    ["tooltip.buff.hit"] = "+Меткость",
    ["tooltip.buff.intellect"] = "+Инт",
    ["tooltip.buff.maxHealth"] = "+Макс. здоровье",
    ["tooltip.buff.mp5"] = "+Мана/5",
    ["tooltip.buff.resilience"] = "+Устойч.",
    ["tooltip.buff.spellPower"] = "+Заклинания",
    ["tooltip.buff.spellCrit"] = "+Крит заклинаний",
    ["tooltip.buff.spirit"] = "+Дух",
    ["tooltip.buff.stamina"] = "+Выносл.",
    ["tooltip.buff.strength"] = "+Сила",
    ["tooltip.buff.comboMealWotlk"] = "+Атака/+Заклинания",
    ["tooltip.buff.armorPenetration"] = "+Пробивание брони",
    ["tooltip.buff.petStrength"] = "Питомец +Сила",
    ["tooltip.buff.petStamina"] = "Питомец +Выносл.",
    ["tooltip.buff.alchemistOnly"] = "Только алхимик",
    ["tooltip.consumable.bestInBag"] = " (лучшее, что есть в сумке)",
    ["tooltip.elixir.bestInBag"] = " (лучший эликсир в сумке)",
    ["tooltip.food.bestInBag"] = " (лучшая еда в сумке)",
    ["tooltip.scroll.bestInBag"] = " (лучший свиток в сумке)",

    ["consumeType.food"] = "Еда",
    ["consumeType.elixir"] = "Эликсир",
    ["consumeType.scroll"] = "Свиток",

    ["Items, which provide buff for %s:"] = "Товары народного потребления, дающие %s:",

    ["Click to print all items which provide this buff"] = "Это группа товаров потребления, дающих один и тот же баф\nНажмите здесь, чтобы вывести список предметов",

    ["tooltip.alcohol.stamina"] = "Алкоголь +Выносл",
    ["tooltip.alcohol.spirit"] = "Алкоголь +Дух",

    ["Healing Power"] = "Сила исцеления",

    TabBuff = "Баф",

    TabDoNotBuff = "Не бафать",

    TabBuffOnlySelf = "Баф только себя",

    TabSpells = "Заклинания",

    ["popup.OpenBuffomat"] = "Открыть",

    BtnCancel = "Закрыть",

    ["popup.QuickSettings"] = "Быстрые настройки",

    ["optionsMenu.Settings"] = "Настройки",

    BtnSettingsSpells = "Настройки заклинаний",

    BtnBuffs = "Расходники",

    ButtonCastBuff = "Кастовать баф",

    ButtonBuffomatWindow = "Показать/скрыть окно Buffomat",

    Header_TRACKING = "Отслеживание",
    Header_INFO = "Информация",
    Header_CANCELBUFF = "Отмена бафов",
    Header_item = "Расходники",

    HeaderSupportedSpells = "Поддерживаемые заклинания",

    HeaderWatchGroup = "Смотреть в рейдовой группе",

    PanelAbout = "Информация",

    HeaderInfo = "Информация",

    HeaderUsage = "Использование",

    HeaderSlashCommand = "/ Команды",

    HeaderCredits = "Авторы",

    HeaderCustomLocales = "Перевод",

    ["header.Profiles"] = "Профили",

    SlashSpellBook = "Повторное сканирование книги заклинаний",

    SlashUpdate = "Обновить список макросов",

    SlashClose = "Закрыть окно Бафомёта",

    SlashReset = "Сбросить окно Бафомёта",

    SlashOpen = "Открыть Бафомёт",

    SlashProfile = "Сменить текущий профиль на соло/группа/рейд/поле боя/авто",

    Tank = "Танк",

    Pet = "Питомец",

    TooltipCastOnClass = "Кастовать на класс",

    TooltipCastOnTank = "Кастовать на танков",

    TooltipCastOnPet = "Кастовать на питомцев",

    ["profile.activeProfileMenuTag"] = "[активный]",

    ["profileName.solo"] = "Соло",
    ["profileName.solo_spec2"] = "Соло (Вторая специализация)",
    ["profileName.group"] = "Группа",
    ["profileName.group_spec2"] = "Группа (Вторая специализация)",
    ["profileName.raid"] = "Рейд",
    ["profileName.raid_spec2"] = "Рейд (Вторая специализация)",
    ["profileName.battleground"] = "Поле боя",
    ["profileName.battleground_spec2"] = "Поле боя (Вторая специализация)",
    ["profileName.auto"] = "Авто профиль",

    AboutInfo = "Выносливость! Интеллект! Дух! - Это звучит знакомо? Бафомёт просканирует участников рейда/группы на отсутствие положительных эффектов и в одно мгновение примените их. Когда у троих или более участников отсутствует эффект, то будет использовано одно заклинание для всей группы. Он также запоминает активацию отслеживания для 'Поиска травы'.|nОн также поможет вам воскресить игроков, выбрав сначала паладинов, священников и шаманов. ",

    AboutUsage = "Вам нужен свободный слот макроса, чтобы использовать это дополнение. Главное окно имеет две вкладки 'Эффекты' и 'Заклинания'. В разделе 'Эффектов' вы найдете все недостающие эффекты и кнопку применить.В разделе 'Заклинания' вы можете настроить, какие заклинания следует контролировать или если он должен использовать групповую версию. Выберите, если он должен использовать только на вас или для всех участников группы. Выберите, какой эффект должен быть активен, для какого класса. Вы также можете игнорировать целые группы (например, в рейде, когда вы должны использовать только инт в группе 7 и 8). Вы также можете выбрать здесь, что один эффект должен быть активен на текущей цели. Например, как друид, нажмите на основного танка и выберете 'Шипы' - или другой '-' (последний символ) - оно изменится на перекрестие, и теперь Бафомёт помнит, что вы держите эффект на основном танке. У вас есть два варианта, чтобы применить эффект из списка пропущенных эффектов. Кнопка с заклинанием в окне или макрос Buff'o'mat. Вы найдете его с помощью кнопки 'Macro' в «строке заголовка» главного окна.|nВАЖНо: Бафомёт работает только вне боя, потому что игра не позволяет менять макросы во время боя. Кроме того, вы не можете открыть или закрыть главное окно во время боя!",

    AboutSlashCommand = "На данный момент это должна быть команда без параметров!",

    TooltipMacroButton = "Перетащите этот макрос на вашу панель заклинаний|nМожно также привязать клавишу в Настройках - Прочие",

    ["tooltip.button.AllSettings"] = "Все настройки",
    ["tooltip.button.QuickSettingsPopup"] = "Меню быстрых настроек и профайлов",
    ["tooltip.button.AllBuffs"] = "Все бафы",
    ["tooltip.button.HideBuffomat"] = "Скрыть. Чтобы снова показать, введите /bom, нажмите на кнопку на миникарте, или нажмите %s",
    ["tooltip.TaskList.CastButton"] = "Скастовать заклинание из списка.|nКнопка становится недоступной в бою.|nТакже можно использовать макро (вытащите кнопку Макро сверху на панель заклинаний)|nили привязать клавишу в Настройках - Прочие",

    SpellLabel_TrackHumanoids = "Только кот - заменяет поиск трав и руды",

    ["title.SpellsWindow"] = "Выберите заклинания и бафы (%s)",

    SpellsWindow_ShowCategory = "Отметьте, чтобы показать эту категорию",

    ["title.ForceTarget"] = "Наложить баф на",
    ["title.ExcludeTarget"] = "Исключить при бафовании",

    ["button.ForceCast.AddTarget"] = "Добавить цель",

    ["buttonTooltip.ForceCast.AddTarget"] = "Выберите игрока или питомца, и добавьте его в список принудительного бафа/исключений",

    ["button.ForceCast.RemoveTarget"] = "Удалить цель",

    ["buttonTooltip.ForceCast.RemoveTarget"] = "Выберите игрока или питомца, и удалите его из списка принудительного бафа/исключений",

    ["label.ForceCast.TargetList"] = "Список целей",
    ["label.SpellsDialog.ProfileSelector"] = "Настройки бафов для профиля",
    ["label.SpellsDialog.GroupScanSelector"] = "Смотреть в рейдовых группах",

    ["binding.notSet"] = "[не задано]",
  }
end
