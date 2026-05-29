---@class BomLanguageChineseModule

local chineseModule = LibStub("Buffomat-LanguageChinese") --[[@as BomLanguageChineseModule]]

---@return BomLocaleDict
function chineseModule:Translations()
  return {
    ["shaman.flametongueDownranked"] = "低一级",

    ["Category_class"] = "职业增益",
    ["Category_blessing"] = "祝福",
    ["Category_pet"] = "宠物/伙伴",
    ["Category_tracking"] = "追踪",
    ["Category_aura"] = "光环",
    ["Category_seal"] = "圣印",
    ["Category_classicPhysFood"] = "物理食物 (Classic)",
    ["Category_classicSpellFood"] = "法术食物 (Classic)",
    ["Category_classicFood"] = "其他食物 (Classic)",
    ["Category_classicPhysElixir"] = "物理药剂 (Classic)",
    ["Category_classicPhysBuff"] = "物理增益 (Classic)",
    ["Category_classicSpellElixir"] = "法术药剂 (Classic)",
    ["Category_classicBuff"] = "增益 (Classic)",
    ["Category_classicElixir"] = "药剂 (Classic)",
    ["Category_classicFlask"] = "合剂 (Classic)",
    ["Category_tbcPhysFood"] = "物理食物 (TBC)",
    ["Category_tbcSpellFood"] = "法术食物 (TBC)",
    ["Category_tbcFood"] = "其他食物 (TBC)",
    ["Category_tbcPhysElixir"] = "物理药剂 (TBC)",
    ["Category_tbcSpellElixir"] = "法术药剂 (TBC)",
    ["Category_tbcElixir"] = "其他药剂 (TBC)",
    ["Category_tbcFlask"] = "合剂 (TBC)",
    ["Category_wotlkPhysFood"] = "物理食物 (WotLK)",
    ["Category_wotlkSpellFood"] = "法术食物 (WotLK)",
    ["Category_wotlkFood"] = "其他食物 (WotLK)",
    ["Category_wotlkPhysElixir"] = "物理药剂 (WotLK)",
    ["Category_wotlkSpellElixir"] = "法术药剂 (WotLK)",
    ["Category_wotlkElixir"] = "其他药剂 (WotLK)",
    ["Category_wotlkFlask"] = "合剂 (WotLK)",
    ["Category_cataFood"] = "食物 (Cataclysm)",
    ["Category_cataElixir"] = "药剂 (Cataclysm)",
    ["Category_cataFlask"] = "合剂 (Cataclysm)",
    ["Category_scroll"] = "卷轴",
    ["Category_weaponEnchantment"] = "武器附魔",
    ["Category_classWeaponEnchantment"] = "职业附魔",
    ["Category_none"] = "未分类",

    ["options.OptionsTitle"] = "Buffomat",
    ["options.general.group.AutoActions"] = "自动操作",
    ["options.general.group.Convenience"] = "便利性",
    ["options.general.group.General"] = "常规",
    ["options.general.group.Scan"] = "扫描",
    ["options.general.group.Buffing"] = "增益",
    ["options.general.group.Visibility"] = "显示分类",
    ["options.general.group.Class"] = "职业选项",
    ["options.convenience.SomeoneIsDrinking.Hide"] = "忽略",
    ["options.convenience.SomeoneIsDrinking.LowPrio"] = "在任务中显示备注",
    ["options.convenience.SomeoneIsDrinking.Show"] = "显示备注并显示 Buffomat",
    ["options.short.ActivateBomOnSpiritTap"] = "在低于 % 的精神激活",
    ["options.short.AutoClose"] = "自动关闭 Buffomat",
    ["options.short.HideWhenScanBlocked"] = "扫描被阻止时隐藏 Buffomat",
    ["options.short.AutoCrusaderAura"] = "提醒：十字军光环",
    ["options.short.AutoDismount"] = "自动离开坐骑",
    ["options.short.AutoDismountFlying"] = "自动离开飞行坐骑",
    ["options.short.AutoDisTravel"] = "自动离开旅行状态",
    ["options.short.AutoOpen"] = "有任务时自动显示 Buffomat",
    ["options.short.AutoStand"] = "自动站立",
    ["options.short.BestAvailableConsume"] = "选择可用的最佳消耗品",
    ["options.short.BuffTarget"] = "优先目标增益",
    ["options.short.Carrot"] = "装备物品的警告",
    ["options.short.CustomBuffSorting"] = "在增益列表中显示排序控件",
    ["options.short.DeathBlock"] = "如果有人死亡就暂停",
    ["options.short.DontUseConsumables"] = "不使用消耗品",
    ["options.short.FadeWhenNothingToDo"] = "无任务时淡化 Buffomat 窗口",
    ["options.short.InInstance"] = "在地下城/团本扫描",
    ["options.short.InPVP"] = "在战场扫描",
    ["options.short.InWorld"] = "在世界扫描",
    ["options.short.MainHand"] = "缺少主手附魔",
    ["options.short.NoGroupBuff"] = "不使用群体BUFF",
    ["options.short.OpenLootable"] = "打开可拾取的容器",
    ["options.short.PreventPVPTag"] = "防止PVP标志",
    ["options.short.ReplaceSingle"] = "替换单体增益",
    ["options.short.ReputationTrinket"] = "警告:声望物品",
    ["options.short.ResGhost"] = "尝试复活灵魂",
    ["options.short.SameZone"] = "扫描同一地区的成员",
    ["options.short.ScanInRestArea"] = "休息区时扫描",
    ["options.short.ScanInStealth"] = "隐身时扫描",
    ["options.short.ScanWhileMounted"] = "安装时扫描",
    ["options.short.SecondaryHand"] = "缺少副手附魔",
    ["options.short.SelfFirst"] = "永远自我",
    ["options.short.ShamanFlametongueRanked"] = "萨满：主手使用降级火舌",
    ["options.short.ShowMinimapButton"] = "显示小地图按钮",
    ["options.short.SlowerHardware"] = "减少扫描增益的频率",
    ["options.short.SomeoneIsDrinking"] = "隐藏'有人在喝酒'",
    ["options.short.UseProfiles"] = "使用配置文档",
    ["options.short.UseRank"] = "使用等级增益",
    ["options.short.VisibleCategories"] = "显示增益（角色设置）",
    ["options.long.ActivateBomOnSpiritTap"] = "如果牧师的'精神' 处于活跃状态且玩家法力低于 % ,则禁用",
    ["options.long.AutoClose"] = "当没有工作要做时自动关闭 Buffomat",
    ["options.long.HideWhenScanBlocked"] = "当扫描因非活动条件停止时隐藏 Buffomat 窗口，例如骑乘、休息区、潜行、飞行点、载具、死亡、禁用区域或精神分流。",
    ["options.long.AutoCrusaderAura"] = "圣骑士: 骑乘时自动开启十字军光环",
    ["options.long.AutoDismount"] = "施法时自动取消地面坐骑",
    ["options.long.AutoDismountFlying"] = "施法时自动取消飞行坐骑 (小心摔死)",
    ["options.long.AutoDisTravel"] = "自动离开旅行状态 (在经典中不起作用)",
    ["options.long.AutoOpen"] = "勾选后，有任务时会显示任务列表窗口；否则只有按下快捷键时才显示。",
    ["options.long.AutoStand"] = "如果你在坐着的状态, Buffomat 会站起来",
    ["options.long.BestAvailableConsume"] = "勾选后会选择可用的最高级消耗品；取消勾选会选择较低级，升级时可先用旧物品。",
    ["options.long.BuffTarget"] = "强制给当前目标施放增益",
    ["options.long.Carrot"] = "提醒取消装备的骑乘/飞行饰品",
    ["options.long.CustomBuffSorting"] = "在增益列表中显示额外文本字段，输入值会用于增益任务排序。",
    ["options.long.DeathBlock"] = "当有人死亡,不施放群体增益",
    ["options.long.DontUseConsumables"] = "仅通过 Shift, Ctrl 或 Alt 使用消耗品",
    ["options.long.FadeWhenNothingToDo"] = "设置没有任务时 Buffomat 窗口的透明度",
    ["options.long.GroupBuff"] = "一直施放群体BUFF(额外的材料成本)",
    ["options.long.InInstance"] = "在地下城和团本扫描增益",
    ["options.long.InPVP"] = "在战场扫描增益",
    ["options.long.InWorld"] = "在世界和城市扫描增益",
    ["options.long.MainHand"] = "主手缺少附魔,则发出警告",
    ["options.long.NoGroupBuff"] = "总是单体增益",
    ["options.long.OpenLootable"] = "开启背包内可拾取的物品",
    ["options.long.PreventPVPTag"] = "当你非PVP状态时跳过开启PVP的目标",
    ["options.long.ReplaceSingle"] = "将单体增益替换为群体增益",
    ["options.long.ReputationTrinket"] = "提醒更换银色黎明饰品",
    ["options.long.ResGhost"] = "尝试复活灵魂状态的",
    ["options.long.SameZone"] = "在同一地区扫描",
    ["options.long.ScanInRestArea"] = "在休息区(城市和旅店)扫描增益",
    ["options.long.ScanInStealth"] = "扫描增益(隐身的)",
    ["options.long.ScanWhileMounted"] = "安装时扫描",
    ["options.long.SecondaryHand"] = "副手缺少附魔,则发出警告",
    ["options.long.SelfFirst"] = "永远先给自己加BUFF",
    ["options.long.ShamanFlametongueRanked"] = "萨满：增强法伤玩法在主手使用降级火舌，副手使用最高等级。",
    ["options.long.ShowClassicConsumables"] = "显示经典可能的消耗品",
    ["options.long.ShowMinimapButton"] = "显示小地图按钮",
    ["options.long.ShowTBCConsumables"] = "显示TBC可用的消耗品",
    ["options.long.SlowerHardware"] = "不太频繁的增益检查 (针对硬件不好/团队)",
    ["options.long.SomeoneIsDrinking"] = "隐藏'有人在喝酒' 的信息",
    ["options.long.UseProfiles"] = "使用配置文档",
    ["options.long.UseRank"] = "使用有等级的技能",
    ["options.long.VisibleCategories"] = "在法术列表中显示某个增益分类（角色设置）",

    ["tasklist.IgnoredBuffOn"] = "已忽略 %s：%s",

    ["task.target.Self"] = "自己",
    ["task.target.SelfOnly"] = "自己-Buff",
    ["task.type.Enchantment"] = "附魔",
    ["task.type.RegularBuff"] = "Buff",
    ["task.type.GroupBuff"] = "团队-Buff ",
    ["task.type.GroupBuff.Self"] = "目标自己",
    ["task.type.Tracking"] = "追踪",
    ["task.type.Reminder"] = "提醒",
    ["task.type.Resurrect"] = "复活",
    ["task.type.MissingConsumable"] = "缺少材料",
    ["task.type.Consumable"] = "材料",
    ["task.hint.HoldShiftConsumable"] = "按住 Shift/Ctrl 和 Alt",

    TASK_BLESS_GROUP = "强效祝福",
    TASK_BLESS = "祝福",
    TASK_SUMMON = "召唤",
    TASK_CAST = "施放",

    ["task.type.Use"] = "使用",
    ["task.type.Consume"] = "消费",
    ["task.type.tbcHunterPetBuff"] = "对宠物使用",

    TASK_ACTIVATE = "启用",

    ["task.type.Unequip"] = "取下装备",
    ["task.error.range"] = "类别",

    ["reminder.reputationTrinket"] = "银色黎明徽记",
    ["reminder.ridingSpeedTrinket"] = "骑术/飞行速度饰品",

    ["task.hint.DontHaveItem"] = "不在背包",
    ["task.notifications.no-sound"] = "无声音",
    ["task.error.missingMainhandWeapon"] = "无法附魔主手",
    ["task.error.missingOffhandWeapon"] = "无法附魔副手（无武器）",

    CHAT_MSG_PREFIX = "Buffomat: ",

    Buffomat = "Buffomat",

    ResetWatchGroups = "重置为1-8队",

    FORMAT_BUFF_SINGLE = "%s %s",
    FORMAT_BUFF_SELF = "%s %s 对自己",
    FORMAT_BUFF_GROUP = "团队 %s %s",
    FORMAT_GROUP_NUM = "团%s",

    ["castButton.Next"] = "%s @ %s",
    ["castButton.InCombat"] = "战斗中",
    ["castButton.Busy"] = "繁忙中/角色",
    ["castButton.BusyChanneling"] = "繁忙中/聊天信息",
    ["castButton.NothingToDo"] = "无事可做",
    ["castButton.NoMacroSlots"] = "需要一个宏!",
    ["castButton.CantCastMaybeOOM"] = "无法增益，可能法力不足或其他原因",

    ["message.CancelBuff"] = "%s 取消增益 %s",
    ["message.BuffExpired"] = "%s 时间到了",

    ["task.UseOrOpen"] = "使用/打开",

    MSG_MAINHAND_ENCHANT_MISSING = "主手缺少临时附魔",
    MSG_OFFHAND_ENCHANT_MISSING = "副手缺少临时附魔",

    InfoSomeoneIsDrinking = "1 在喝酒",

    InfoMultipleDrinking = "%d 在喝酒",

    ["castButton.inactive.DeadMember"] = "队友死亡",
    ["castButton.inactive.Flying"] = "飞行:下坐骑禁用",
    ["castButton.inactive.InCombat"] = "你在战斗中",
    ["castButton.inactive.Instance"] = "地下城禁用检查",
    ["castButton.inactive.IsDead"] = "你已死亡",
    ["castButton.inactive.IsStealth"] = "隐身禁用检查",
    ["castButton.inactive.MacroFrameShown"] = "宏窗口已打开",
    ["castButton.inactive.Mounted"] = "坐骑上禁用检查",
    ["castButton.inactive.OpenWorld"] = "野外禁用检查",
    ["castButton.inactive.PriestSpiritTap"] = "牧师的 <精神> 处于活跃状态",
    ["castButton.inactive.PvpZone"] = "战场禁用检查",
    ["castButton.inactive.RestArea"] = "休息区禁用检查",
    ["castButton.inactive.Taxi"] = "坐骑上不检查",
    ["castButton.inactive.Vehicle"] = "载具中不增益",

    ["castbutton.inactive.GCD"] = "公共冷却",

    ["error.castFailed.tooLowLevel"] = "%s 的技能等级降级为 %s。请再补一次。",

    CRUSADER_AURA_COMMENT = "根据设置可以自动施放",

    HeaderRenew = "到时间前通知 (秒)",

    ["options.short.Time60"] = "时间 <=60 秒:",
    ["options.short.Time300"] = "时间 <=5 分:",
    ["options.short.Time600"] = "时间 <=10 分:",
    ["options.short.Time1800"] = "时间 <=30 分:",
    ["options.short.Time3600"] = "时间 <=60 分:",
    ["options.short.UIWindowScale"] = "UI 比例",
    ["options.short.MinBuff"] = "群体增益需达到多少人以上使用",
    ["options.short.MinBlessing"] = "强效祝福需达到多少人以上使用",
    ["options.short.PlaySoundWhenTask"] = "有增益任务时播放声音",
    ["options.short.PlaySoundWhenTask.test"] = "播放",
    ["options.short.DebugLogging"] = "[开发] 打印额外调试信息（很多）",
    ["options.general.sound.None"] = "- 无音效 -",
    ["options.long.Time60"] = "刷新增益的时间，如何剩余时间少于 <=60 秒 ",
    ["options.long.Time300"] = "刷新增益的时间，如何剩余时间少于 <=5 分",
    ["options.long.Time600"] = "刷新增益的时间，如何剩余时间少于 <=10 分",
    ["options.long.Time1800"] = "刷新增益的时间，如何剩余时间少于 <=30 分",
    ["options.long.Time3600"] = "刷新增益的时间，如何剩余时间少于 <=60 分",
    ["options.long.UIWindowScale"] = "UI 比例 (默认 1; 隐藏和显示Buffomat设置)",
    ["options.long.MinBuff"] = "群体增益使用需要缺失的数量",
    ["options.long.MinBlessing"] = "强效祝福使用需要缺失祝福的数量",
    ["options.long.PlaySoundWhenTask"] = "任务列表非空时播放声音",
    ["options.long.PlaySoundWhenTask.test"] = "点击测试所选声音",
    ["options.long.DebugLogging"] = "开发用途：输出帮助开发者定位问题的额外信息，请勿日常使用！",

    TooltipCustomSorting = "这里输入的文本将用于增益排序。按 Enter 保存。",

    TooltipSelfCastCheckbox_Self = "仅自己",
    TooltipSelfCastCheckbox_Party = "队伍/团队的Buff",

    TooltipEnableSpell = "添加这个 Buff 到列表内",

    TooltipEnableBuffCancel = "发现这个 Buff 就取消",

    FormatToggleTarget = "点击切换队伍: %s",

    FormatAllForceCastTargets = "强制施法: ",

    FormatForceCastNone = "强制施法列表",

    FormatAllExcludeTargets = "忽略: ",

    FormatExcludeNone = "忽略施法列表",

    TooltipForceCastOnTarget = "将当前团队/队伍目标添加到监控列表",

    TooltipExcludeTarget = "将当前团队/队伍目标添加到忽略列表",

    TooltipSelectTarget = "选择一个团队/队伍启用此选项",

    ["tooltip.SpellsDialog.watchGroup"] = "在副本中检查 Buff %d",

    TooltipRaidGroupsSettings = "团队小组检查设置",

    MessageAddedForced = "强制 Buff ",

    MessageClearedForced = "取消强制 Buff",

    MessageAddedExcluded = "永不 Buff ",

    MessageClearedExcluded = "删除为",

    HintCancelThisBuff = "取消这个 Buff",
    HintCancelThisBuff_Combat = "战斗前",
    HintCancelThisBuff_Always = "一直",

    TooltipWhisperWhenExpired = "当BUFF过期时，对施放者密语提醒",

    ["tooltip.mainhand"] = "主手",
    ["tooltip.offhand"] = "副手",

    ShamanEnchantBlocked = "主手等待",

    PreventPVPTagBlocked = "目标开启 PvP",

    TooltipIncludesAllRanks = "所有这种类型的BUFF",

    TooltipSimilar = "任何类似的",

    TooltipSimilarFoods = "所有类型的食物",

    ["tooltip.buff.conjure"] = "制造",
    ["tooltip.buff.agility"] = "+敏捷",
    ["tooltip.buff.allResist"] = "+全抗",
    ["tooltip.buff.attackPower"] = "+攻击",
    ["tooltip.buff.crit"] = "+暴击",
    ["tooltip.buff.fireResist"] = "+火抗",
    ["tooltip.buff.frostResist"] = "+冰抗",
    ["tooltip.buff.haste"] = "+急速",
    ["tooltip.buff.healing"] = "+治疗",
    ["tooltip.buff.hit"] = "+命中",
    ["tooltip.buff.intellect"] = "+智力",
    ["tooltip.buff.maxHealth"] = "+最大生命",
    ["tooltip.buff.mp5"] = "+法力/5秒",
    ["tooltip.buff.resilience"] = "+韧性",
    ["tooltip.buff.spellPower"] = "+法术",
    ["tooltip.buff.spellCrit"] = "+法术暴击",
    ["tooltip.buff.spirit"] = "+精神",
    ["tooltip.buff.stamina"] = "+耐力",
    ["tooltip.buff.strength"] = "+力量",
    ["tooltip.buff.comboMealWotlk"] = "+攻击/+法术",
    ["tooltip.buff.armorPenetration"] = "+破甲",
    ["tooltip.buff.petStrength"] = "宠物 +力量",
    ["tooltip.buff.petStamina"] = "宠物 +耐力",
    ["tooltip.buff.alchemistOnly"] = "炼金专用",
    ["tooltip.consumable.bestInBag"] = "（背包中最佳）",
    ["tooltip.elixir.bestInBag"] = "（背包中最佳药剂）",
    ["tooltip.food.bestInBag"] = "（背包中最佳食物）",
    ["tooltip.scroll.bestInBag"] = "（背包中最佳卷轴）",

    ["consumeType.food"] = "食物",
    ["consumeType.elixir"] = "药剂",
    ["consumeType.scroll"] = "卷轴",

    ["Items, which provide buff for %s:"] = "提供 %s 增益的物品：",

    ["Click to print all items which provide this buff"] = "这是一组提供同类增益的物品\n点击打印所有提供此增益的物品",

    ["tooltip.alcohol.stamina"] = "酒类 +耐力",
    ["tooltip.alcohol.spirit"] = "酒类 +精神",

    ["Healing Power"] = "治疗能量",

    TabBuff = "Buff",

    TabDoNotBuff = "不要 Buff",

    TabBuffOnlySelf = "Buff 仅限自己",

    TabSpells = "技能",

    ["popup.OpenBuffomat"] = "打开",

    BtnCancel = "取消",

    ["popup.QuickSettings"] = "快速设置",

    ["optionsMenu.Settings"] = "设置窗口",

    BtnSettingsSpells = "设置技能",

    BtnBuffs = "材料",

    ButtonCastBuff = "施放BUFF",

    ButtonBuffomatWindow = "显示/隐藏 Buffomat 窗口",

    Header_TRACKING = "追踪",
    Header_INFO = "信息",
    Header_CANCELBUFF = "取消 BUFF",
    Header_item = "材料",

    HeaderSupportedSpells = "支持的技能",

    HeaderWatchGroup = "团队中监控[队伍]",

    PanelAbout = "关于",

    HeaderInfo = "信息",

    HeaderUsage = "用法",

    HeaderSlashCommand = "可用命令",

    HeaderCredits = "Credits",

    HeaderCustomLocales = "本地化",

    ["header.Profiles"] = "简介",

    SlashSpellBook = "重新扫描技能书",

    SlashUpdate = "更新宏/列表",

    SlashClose = "取消 BOM 窗口",

    SlashReset = "重置 BOM 窗口",

    SlashOpen = "打开 BOM 窗口",

    SlashProfile = "将当前配置文件更改为 个人/队伍/团队/战场/自动",

    Tank = "坦克",

    Pet = "宠物",

    TooltipCastOnClass = "给职业施法",

    TooltipCastOnTank = "给坦克施法",

    TooltipCastOnPet = "给宠物施法",

    ["profile.activeProfileMenuTag"] = "[当前]",

    ["profileName.solo"] = "个人",
    ["profileName.solo_spec2"] = "个人2",
    ["profileName.group"] = "队伍",
    ["profileName.group_spec2"] = "队伍2",
    ["profileName.raid"] = "团队",
    ["profileName.raid_spec2"] = "团队2",
    ["profileName.battleground"] = "战场",
    ["profileName.battleground_spec2"] = "战场2",
    ["profileName.auto"] = "自动",

    AboutInfo =
    "耐力!智力!精神! - 这听起来很熟悉吗？ Buffomat 监控 扫描团队成员是否缺失BUFF,然后单击它就能给缺失BUFF的队友施放。当三 个或更多成员丢失同一个BUFF时,会使用群体BUFF 插件的另一个功能是你提醒你启用'寻找草药'之类的追踪技能。插件同样可以用于复活技能 当你点击宏时,它将复活你身边的人-优先级最高为萨满,圣骑士和牧师。 ",

    AboutUsage =
    "你需要一个宏才能使用此插件。 主窗口有 两个标签'BUFF'和'技能'。 在'BUFF'下你会找到所有缺失的BUFF和一个施放按钮. 在'技能'下,你可以设置那些技能应该被监控,是否 应该使用群体BUFF。选择是对你还是对所有队伍成员. 选择哪个BUFF应该在哪个职业上使用。 你也可以忽略整个队伍 (例如在副本中,当你被分配给7队和8队上增益BUFF时)你也可以在这里选择,一个BUFF应该在当前目标上施放。例如 当德鲁伊点击主坦克,在'荆棘术'点击'-'（最后一个符号）- 会变成十字准星,现在插件将记住你要把BUFF施放给主坦克。你有两个选项可以从缺失的BUFF列表中选择一个去施放BUFF。窗口中的法术按钮或插件的宏。 你可以在主窗口的'标题栏'上找到'M'按钮。|n重要提醒：插件只在脱战后起作用,因为暴雪 不允许在战斗中更改宏。另外,在战斗中也不允许打开或关闭主窗口！",

    AboutSlashCommand = "",

    TooltipMacroButton = "将此宏拖到您的动作条中来施放BUFF|您也可以在按键绑定 =>其他 中为宏添加快捷键 ",

    ["tooltip.button.AllSettings"] = "所有设置",
    ["tooltip.button.QuickSettingsPopup"] = "打开快速设置和配置文件存档",
    ["tooltip.button.AllBuffs"] = "所有增益",
    ["tooltip.button.HideBuffomat"] = "隐藏窗口。|n要显示，请输入 /bom，单击小地图按钮|n或使用您指定的键盘快捷键",
    ["tooltip.TaskList.CastButton"] = "从列表中施放法术。|n在战斗中不可用。|n可以通过宏来施放（在顶部）|n需要在按键绑定=>其他 中绑定快捷键",

    SpellLabel_TrackHumanoids = "Cat only - 覆盖跟踪草药和矿石",

    ["title.SpellsWindow"] = "选择法术和增益 (%s)",

    SpellsWindow_ShowCategory = "勾选以显示此分类",

    ["title.ForceTarget"] = "强制增益目标",
    ["title.ExcludeTarget"] = "增益时排除",

    ["button.ForceCast.AddTarget"] = "添加目标",

    ["buttonTooltip.ForceCast.AddTarget"] = "选择玩家或宠物，并加入强制施法/忽略列表",

    ["button.ForceCast.RemoveTarget"] = "移除目标",

    ["buttonTooltip.ForceCast.RemoveTarget"] = "选择玩家或宠物，并从强制施法/忽略列表移除",

    ["label.ForceCast.TargetList"] = "目标列表",
    ["label.SpellsDialog.ProfileSelector"] = "此配置的增益选择",
    ["label.SpellsDialog.GroupScanSelector"] = "监控团队小队",

    ["binding.notSet"] = "[未设置]",
  }
end