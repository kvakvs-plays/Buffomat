---@class BomLanguageRussianModule

local russianModule = LibStub("Buffomat-LanguageRussian") --[[@as BomLanguageRussianModule]]

---@return BomLocaleDict
function russianModule:Translations()
  return {
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

    ["Category_scroll"] = "Свитки",
    ["Category_weaponEnchantment"] = "Временные зачарования оружия",
    ["Category_classWeaponEnchantment"] = "Зачарования вашего класса",
    ["Category_none"] = "Прочее",

    CHAT_MSG_PREFIX = "Бафомёт: ", --префикс в чате
    Buffomat = "Бафомёт", --шапка окна аддона
    AboutInfo = "Выносливость! Интеллект! Дух! - Это звучит знакомо? "
        .. "Бафомёт просканирует участников рейда/группы на отсутствие положительных эффектов "
        .. "и в одно мгновение примените их. Когда у троих или более участников отсутствует эффект, "
        .. "то будет использовано одно заклинание для всей группы. Он также запоминает активацию "
        .. "отслеживания для 'Поиска травы'.|nОн также поможет вам воскресить игроков, выбрав "
        .. "сначала паладинов, священников и шаманов. ",
    AboutSlashCommand = "На данный момент это должна быть команда без параметров!",
    AboutUsage = "Вам нужен свободный слот макроса, чтобы использовать это дополнение. "
        .. "Главное окно имеет две вкладки 'Эффекты' и 'Заклинания'. В разделе 'Эффектов' вы "
        .. "найдете все недостающие эффекты и кнопку применить.В разделе 'Заклинания' вы можете "
        .. "настроить, какие заклинания следует контролировать или если он должен использовать "
        .. "групповую версию. Выберите, если он должен использовать только на вас или для всех "
        .. "участников группы. Выберите, какой эффект должен быть активен, для какого класса. "
        .. "Вы также можете игнорировать целые группы (например, в рейде, когда вы должны использовать "
        .. "только инт в группе 7 и 8). Вы также можете выбрать здесь, что один эффект должен "
        .. "быть активен на текущей цели. Например, как друид, нажмите на основного танка и "
        .. "выберете 'Шипы' - или другой '-' (последний символ) - оно изменится на перекрестие, "
        .. "и теперь Бафомёт помнит, что вы держите эффект на основном танке. У вас есть два "
        .. "варианта, чтобы применить эффект из списка пропущенных эффектов. Кнопка с "
        .. "заклинанием в окне или макрос Buff'o'mat. Вы найдете его с помощью кнопки 'Macro' "
        .. "в «строке заголовка» главного окна.|nВАЖНо: Бафомёт работает только вне боя, потому "
        .. "что игра не позволяет менять макросы во время боя. Кроме того, вы не можете открыть "
        .. "или закрыть главное окно во время боя!",
    BtnCancel = "Закрыть",
    ["popup.OpenBuffomat"] = "Открыть",
    ["optionsMenu.Settings"] = "Настройки",
    BtnSettingsSpells = "Настройки заклинаний",

    ["options.general.group.AutoActions"] = "Реакция на события",
    ["options.general.group.Convenience"] = "Удобство",
    ["options.general.group.General"] = "Общие настройки",
    ["options.general.group.Scan"] = "Сканирование",
    ["options.general.group.Buffing"] = "Время бафов",
    ["options.general.group.Visibility"] = "Скрыть категории",
    ["options.general.group.Class"] = "Классы",

    ["options.short.ActivateBomOnSpiritTap"] = "Запретить Бафомёт, при 'Захвате духа' жреца",
    ["options.short.ReputationTrinket"] = "Не забудьте (снять)экипировать Жетон Серебряного Рассвета",
    ["options.short.AutoOpen"] = "Авто-открытие, когда есть задачи",
    ["options.short.AutoClose"] = "Авто-закрытие. Предпочитать оставаться открытым.",
    ["options.short.HideWhenScanBlocked"] = "Скрывать Бафомёт, если сканирование заблокировано",
    ["options.short.DeathBlock"] = "Не применять групповые эффекты, когда кто-то мертв",
    ["options.short.GroupBuff"] = "Групповые бафы, если это экономит ману (увеличенный расход реагентов)",
    ["options.short.InInstance"] = "Сканировать бафы в подземельях и рейдах",
    ["options.short.InPVP"] = "Сканировать бафы на полях битвы",
    ["options.short.InWorld"] = "Сканировать бафы в открытом мире",
    -- ["options.short.LockMinimapButton"] = "Блокировка положения кнопки у миникарты",
    -- ["options.short.LockMinimapButtonDistance"] = "Минимизировать расстояние до миникарты",
    ["options.short.NoGroupBuff"] = "Всегда давать одиночные бафы",
    ["options.short.PreventPVPTag"] = "Не бафать PvP игроков, если ваш PvP выключен",
    ["options.short.ReplaceSingle"] = "Заменить одиночный баф групповым",
    ["options.short.ResGhost"] = "Пытаться воскрешать призраки, если тело лежит близко",
    ["options.short.SameZone"] = "Только если находится в одной зоне со мной",
    ["options.short.ScanInRestArea"] = "Сканировать бафы в городах и тавернах",
    ["options.short.ScanInStealth"] = "Сканировать бафы в режиме незаметности",
    ["options.short.ScanWhileMounted"] = "Сканировать, сидя на ездовом животном",
    ["options.short.BestAvailableConsume"] = "Выбирать лучшее из имеющегося",
    ["options.short.ShowClassicConsumables"] = "Показывать бафы из классической версии",
    ["options.short.ShowMinimapButton"] = "Показать кнопку у миникарты",
    ["options.short.ShowTBCConsumables"] = "Показывать бафы из TBC",
    ["options.short.SomeoneIsDrinking"] = "Когда кто-то в группе пьёт",
    ["options.short.UseRank"] = "Использовать понижение ранга заклинаний",
    ["options.short.FadeWhenNothingToDo"] = "Делать окно прозрачным, когда нет задач",
    ["options.short.ShamanFlametongueRanked"] =
    "Шаман: Использовать пониженный ранг языков пламени на правой руке",
    ["options.short.CustomBuffSorting"] = "Показать доп. поля для сортировки бафов",

    ["options.long.UseRank"] = "Если у цели уровень слишком низкий, то использовать пониженный ранг заклинания",
    ["options.long.AutoOpen"] = "Автоматически открывать Бафомёт, когда есть задачи, иначе только по нажатию горячих клавиш",
    ["options.long.AutoClose"] = "Автоматически закрывать Бафомёт, когда все задачи выполнены",
    ["options.long.HideWhenScanBlocked"] =
    "Скрывать окно Бафомёта, когда сканирование остановлено неактивными условиями: верхом, зона отдыха, незаметность, такси, транспорт, смерть, отключенная зона или Захват духа.",
    ["options.long.FadeWhenNothingToDo"] = "Установить прозрачность окна Бафомёта, если нечего делать",
    ["options.long.ActivateBomOnSpiritTap"] =
    "Запретить Бафомёт, если 'Захват духа' жреца активен и мана меньше указанного процента",
    ["options.long.ScanWhileMounted"] = "Разрешить сканирование бафов, когда игрок сидит на ездовом животном",
    ["options.long.BestAvailableConsume"] =
    "Если галочка установлена, то при наличии множества вариантов, будет предпочитатся лучший. Иначе - худший - пока игрок качается, чтобы доедать старую еду и эликсиры",

    InfoSomeoneIsDrinking = "Один игрок пьёт",
    InfoMultipleDrinking = "Несколько игроков пьют (%d)",

    ["options.long.MinBlessing"] =
    "Количество отсутствующих благословений, чтобы использовать большее благословение",
    ["options.long.MinBuff"] =
    "Количество отсутствующих бафов, необходимое для использования группового бафа",
    ["options.long.Time1800"] = "Освежать баф продолжительностью <=30 мин, если осталось менее",
    ["options.long.Time300"] = "Освежать баф продолжительностью <=5 мин, если осталось менее",
    ["options.long.Time3600"] = "Освежать баф продолжительностью <=60 мин, если осталось менее",
    ["options.long.Time60"] = "Освежать баф продолжительностью <=60 сек, если осталось менее",
    ["options.long.Time600"] = "Освежать баф продолжительностью <=10 мин, если осталось менее",
    ["options.long.ShamanFlametongueRanked"] = "Шаман: Для spellhancement шаманов использовать язык пламени "
        .. "пониженного ранга на правом оружии, и максимального ранга на левом. "
        .. "Включайте эту опцию, когда в правой руке у вас оружие с силой заклинаний.",
    ["options.long.CustomBuffSorting"] = "В списке бафов станут видны дополнительные текстовые поля. "
        .. "Введённый в них текст будет использован для сортировки бафов.",

    ["options.short.MinBlessing"] = "Большое благословение, если нуждаются более",
    ["options.short.MinBuff"] = "Групповой баф, если нуждаются более",
    ["options.short.Time1800"] = "Продолжительность <=30 мин:",
    ["options.short.Time300"] = "Продолжительность <=5 мин:",
    ["options.short.Time3600"] = "Продолжительность <=60 мин:",
    ["options.short.Time60"] = "Продолжительность <=60 сек:",
    ["options.short.Time600"] = "Продолжительность <=10 мин:",

    ["options.general.sound.None"] = "- не играть звук -", -- play no sound on task

    ["tasklist.IgnoredBuffOn"] = "Пропускаем %s: %s", -- when a buff is not listed because a better buff exists
    ["task.target.Self"] = "На себя", -- use instead of name when buffing self
    ["task.target.SelfOnly"] = "Самобаф",
    ["task.type.RegularBuff"] = "Баф",
    ["task.type.Enchantment"] = "Зачарование",
    ["task.type.GroupBuff"] = "Групповой",
    ["task.type.GroupBuff.Self"] = "Групповой (на себя)",
    ["task.type.Tracking"] = "Слежение",
    ["task.type.Reminder"] = "Напоминание",
    ["task.type.Resurrect"] = "Воскрешение",
    ["task.type.MissingConsumable"] = "Не хватает", -- deprecated?
    ["task.type.Consumable"] = "Расходник", -- deprecated?
    ["task.hint.HoldShiftConsumable"] = "Удерживайте Shift/Ctrl или Alt",
    ["task.error.missingMainhandWeapon"] = "Невозможно зачаровать оружие в основной руке",
    ["task.error.missingOffhandWeapon"] = "Нет оружия во второй руке",

    ["task.type.Use"] = "Использовать",
    ["task.type.Consume"] = "Употребить",
    ["task.type.tbcHunterPetBuff"] = "Для питомца",

    Header_TRACKING = "Отслеживание",
    HeaderCredits = "Авторы",
    HeaderCustomLocales = "Перевод",
    HeaderInfo = "Информация",
    HeaderRenew = "Продлить баф до истечения срока действия (в секундах)",
    HeaderSlashCommand = "/ Команды",
    HeaderSupportedSpells = "Поддерживаемые заклинания",
    HeaderUsage = "Использование",
    HeaderWatchGroup = "Смотреть в рейдовой группе",
    FORMAT_BUFF_GROUP = "Группа %s %s",
    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s на себя",
    ["castButton.Busy"] = "Занят / Кастую",
    ["castButton.BusyChanneling"] = "Занят / Долгое заклинание",

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

    ["castButton.CantCastMaybeOOM"] = "Недостаточно маны или другая причина",
    ["message.CancelBuff"] = "Отменён баф %s от %s",
    ["message.BuffExpired"] = "%s заклинание истекло.",
    -- ["message.ShowHideInCombat"] = "Во время боя нельзя показывать или скрывать панели",
    ["error.castFailed.tooLowLevel"] = "Понижение ранга заклинания %s для %s. Попробуйте выполнить баф ещё раз.",
    ["castButton.NothingToDo"] = "Нечего делать",
    --MsgLocalRestart                             = "Настройки не подействуют до перезагрузки модов (команда /reload)",
    ["castButton.NoMacroSlots"] = "Нужен хотя бы один свободный слот для макро!",
    ["castButton.Next"] = "%s @ %s",
    PanelAbout = "Информация",
    SlashClose = "Закрыть окно Бафомёта",
    SlashOpen = "Открыть Бафомёт",
    SlashReset = "Сбросить окно Бафомёта",
    SlashSpellBook = "Повторное сканирование книги заклинаний",
    SlashUpdate = "Обновить список макросов",
    TabBuff = "Баф",
    TabBuffOnlySelf = "Баф только себя", -- Shown if all raid groups deselected
    TabSpells = "Заклинания",
    TooltipEnableSpell = "Вкл./откл. заклинание",
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
    ShamanEnchantBlocked = "Ожидание бафа на другую руку", -- TBC
    TooltipIncludesAllRanks = "Любой вариант этого бафа",
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

    ["tooltip.consumable.bestInBag"] = " (лучшее, что есть в сумке)",
    ["tooltip.elixir.bestInBag"] = " (лучший эликсир в сумке)",
    ["tooltip.food.bestInBag"] = " (лучшая еда в сумке)",
    ["tooltip.scroll.bestInBag"] = " (лучший свиток в сумке)",
    ["consumeType.food"] = "Еда",
    ["consumeType.elixir"] = "Эликсир",
    ["consumeType.scroll"] = "Свиток",
    ["Items, which provide buff for %s:"] = "Товары народного потребления, дающие %s:",
    ["Click to print all items which provide this buff"] =
    "Это группа товаров потребления, дающих один и тот же баф\nНажмите здесь, чтобы вывести список предметов",

    ["tooltip.alcohol.stamina"] = "Алкоголь +Выносл",
    ["tooltip.alcohol.spirit"] = "Алкоголь +Дух",

    TooltipExcludeTarget = "Добавить выбранного игрока в список исключений и не бафать",

    TooltipCustomSorting = "Введённый здесь текст будет использован для сортировки бафов. "
        .. "Нажмите Enter, чтобы подтвердить новое значение.",
    TooltipSelectTarget = "Выберите участника рейда/группы, чтобы включить эту опцию",
    TooltipSelfCastCheckbox_Self = "Применить баф только на себя",
    TooltipSelfCastCheckbox_Party = "Бафать группу или рейд",
    TooltipForceCastOnTarget = "Наложить заклинание на текущую цель",
    TooltipMacroButton =
    "Перетащите этот макрос на вашу панель заклинаний|nМожно также привязать клавишу в Настройках - Прочие",
    ["tooltip.button.AllSettings"] = "Все настройки",
    ["tooltip.button.QuickSettingsPopup"] = "Меню быстрых настроек и профайлов",
    ["tooltip.button.AllBuffs"] = "Все бафы",
    ["tooltip.button.HideBuffomat"] =
    "Скрыть. Чтобы снова показать, введите /bom, нажмите на кнопку на миникарте, или нажмите %s",
    ["tooltip.TaskList.CastButton"] =
        "Скастовать заклинание из списка.|n"
        .. "Кнопка становится недоступной в бою.|n"
        .. "Также можно использовать макро (вытащите кнопку Макро сверху на панель заклинаний)|n"
        .. "или привязать клавишу в Настройках - Прочие",

    ["title.SpellsWindow"] = "Выберите заклинания и бафы (%s)",

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

    ["title.ForceTarget"] = "Наложить баф на",
    ["title.ExcludeTarget"] = "Исключить при бафовании",
    ["button.ForceCast.AddTarget"] = "Добавить цель",
    ["buttonTooltip.ForceCast.AddTarget"] =
    "Выберите игрока или питомца, и добавьте его в список принудительного бафа/исключений",
    ["button.ForceCast.RemoveTarget"] = "Удалить цель",
    ["buttonTooltip.ForceCast.RemoveTarget"] =
    "Выберите игрока или питомца, и удалите его из списка принудительного бафа/исключений",
    ["label.ForceCast.TargetList"] = "Список целей",
    ["label.SpellsDialog.ProfileSelector"] = "Настройки бафов для профиля",
    ["label.SpellsDialog.GroupScanSelector"] = "Смотреть в рейдовых группах",
    ["taskList.holdOpenComment"] =
    "Окно Бафомёта было открыто пользователем. Нажмите X или нажмите %s, чтобы снова разрешить автоматическое закрытие.",
  }
end
