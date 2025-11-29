RaidEye.spells = {

    -- =========================
    -- ПАЛАДИН
    -- =========================

    -- Божественная жертва (Divine Sacrifice)
    [64205] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 6,
        notarget = true,
        category = "MITIGATION",
    },

    -- Длань жертвы (Hand of Sacrifice)
    [6940] = {
        cd = 120,
        class = "PALADIN",
        category = "MITIGATION",
    },

    -- Длань свободы (Hand of Freedom)
    [1044] = {
        cd = 25,
        class = "PALADIN",
        category = "UTILITY",
    },

    -- Божественный щит (Divine Shield)
    [642] = {
        cd = 300,
        class = "PALADIN",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Длань защиты (Hand of Protection)
    [10278] = {
        cd = 300,
        class = "PALADIN",
        category = "MITIGATION",
    },

    -- Божественная защита (Divine Protection)
    [498] = {
        cd = 180,
        class = "PALADIN",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Возложение рук (Lay on Hands)
    [48788] = {
        cd = 1200,
        class = "PALADIN",
        category = "MITIGATION",
    },

    -- Аура благочестия (Aura Mastery)
    [31821] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 1,
        talentIndex = 6,
        notarget = true,
        category = "MITIGATION",
    },

    -- Священная каратель (Holy Wrath)
    [48817] = {
        cd = 30,
        class = "PALADIN",
        notarget = true,
        category = "OTHER",
    },

    -- Длань спасения (Hand of Salvation)
    [1038] = {
        cd = 120,
        class = "PALADIN",
        category = "UTILITY",
    },

    -- Страж праведника (Ardent Defender)
    [66233] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 18,
        category = "MITIGATION",
    },

    -- Божественное вмешательство (Divine Intervention)
    [19752] = {
        cd = 600,
        class = "PALADIN",
        category = "UTILITY",
    },

    -- Молот правосудия (Hammer of Justice)
    [853] = {
        cd = 60,
        class = "PALADIN",
        category = "CC",
    },

    -- Божественное просветление (Divine Illumination)
    [31842] = {
        cd = 180,
        class = "PALADIN",
        talentTab = 1,
        talentIndex = 22,
        category = "UTILITY",
    },

    -- Божественное одобрение (Divine Favor)
    [20216] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 1,
        talentIndex = 13,
        category = "UTILITY",
    },
    -- Щит мстителя (Avenger's Shield)
    [48827] = {
        cd = 30,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 22,
        category = "CC",
    },
    -- Щит Небес
    [48952] = {
        cd = 8,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 17,
        category = "MITIGATION",
    },

    -- =========================
    -- ЖРЕЦ
    -- =========================

    -- Подавление боли (Pain Suppression)
    [33206] = {
        cd = 180,
        class = "PRIEST",
        talentTab = 1,
        talentIndex = 25,
        category = "MITIGATION",
    },

    -- Охранный дух (Guardian Spirit)
    [47788] = {
        cd = 70,
        class = "PRIEST",
        talentTab = 2,
        talentIndex = 27,
        category = "MITIGATION",
    },

    -- Защита от страха (Fear Ward)
    [6346] = {
        cd = 180,
        class = "PRIEST",
        category = "UTILITY",
    },

    -- Гимн надежды (Hymn of Hope)
    [64901] = {
        cd = 360,
        class = "PRIEST",
        notarget = true,
        category = "UTILITY",
    },

    -- Божественный гимн (Divine Hymn)
    [64843] = {
        cd = 480,
        class = "PRIEST",
        notarget = true,
        category = "UTILITY",
    },

    -- Рассеивание (Dispersion)
    [47585] = {
        cd = 120,
        class = "PRIEST",
        talentTab = 3,
        talentIndex = 27,
        category = "MITIGATION",
    },

    -- Придание сил (Power Infusion)
    [10060] = {
        cd = 120,
        class = "PRIEST",
        talentTab = 1,
        talentIndex = 19,
        category = "UTILITY",
    },

    -- =========================
    -- ДРУИД
    -- =========================

    -- Звездопад (Starfall)
    [53201] = {
        cd = 90,
        class = "DRUID",
        talentTab = 1,
        talentIndex = 28,
        notarget = true,
        category = "OTHER",
    },

    -- Возрождение (Rebirth)
    [48477] = {
        cd = 600,
        class = "DRUID",
        category = "UTILITY",
    },

    -- Озарение (Innervate)
    [29166] = {
        cd = 180,
        class = "DRUID",
        category = "UTILITY",
    },

    -- Дубовая кожа (Barkskin)
    [22812] = {
        cd = 60,
        class = "DRUID",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Инстинкты выживания (Survival Instincts)
    [61336] = {
        cd = 180,
        class = "DRUID",
        talentTab = 2,
        talentIndex = 7,
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Тайфун (Typhoon)
    [61384] = {
        cd = 20,
        class = "DRUID",
        talentTab = 1,
        talentIndex = 24,
        category = "CC",
    },

    -- Спокойствие (Tranquility)
    [48447] = {
        cd = 480,
        class = "DRUID",
        notarget = true,
        category = "UTILITY",
    },

    -- Неистовое восстановление (Frenzied Regeneration)
    [22842] = {
        cd = 180,
        class = "DRUID",
        tanksonly = true,
        category = "MITIGATION",
    },

        -- Стремительный рывок – медведь (Feral Charge - Bear) New
    [16979] = {
        cd = 15,
        class = "DRUID",
        tanksonly = true,
        category = "CC",
    },

    -- Рык New
    [6795] = {
        cd = 8,
        class = "DRUID",
        tanksonly = true,
        category = "OTHER",
    },

    -- Вызывающий рев New
    [5209] = {
        cd = 180,
        class = "DRUID",
        tanksonly = true,
        notarget = true,
        category = "OTHER",
    },

    -- Берсерк New
    [50334] = {
        cd = 180,
        class = "DRUID",
        talentTab = 2,
        talentIndex = 31,
        category = "OTHER",
    },
    -- Оглушить (Bash) New
    [8983] = {
        cd = 60,
        tanksonly = true,
        class = "DRUID",
        category = "CC",
    },
    -- Порыв New
    [33357] = {
        cd = 180,
        class = "DRUID",
        category = "OTHER",
    },  
    -- Калечение (Maim) New
    [49802] = {
        cd = 10,
        class = "DRUID",
        feralonly = true,
        category = "CC",
    },    
    -- Исступление (Rampage) New
    [5229] = {
        cd = 60,
        class = "DRUID",
        tanksonly = true,
        category = "OTHER",
    },

    --[[
    -- Природная Стремительность (Nature's Swiftness)
    [17116] = {
        cd = 180,
        class = "DRUID",
        talentTab = 1,
        talentIndex = 12,
        category = "UTILITY",
    }, --]]

    -- =========================
    -- ОХОТНИК
    -- =========================
    
    -- Перенаправление (первичный каст) (Misdirection initial)
    [34477] = {
        buffDuration = 30,  -- НОВОЕ: длительность баффа (стадия ожидания)
        cd = 30,            -- КД после активации (наследуется от parent)
        class = "HUNTER",
        parent = 35079,
        noself = true,
        category = "UTILITY",
    },

    -- Перенаправление (Misdirection)
    [35079] = {
        cd = 30,
        class = "HUNTER",
        noself = true,
        category = "UTILITY",
    },

    -- Готовность (Readiness)
    [23989] = {
        cd = 180,
        class = "HUNTER",
        talentTab = 2,
        talentIndex = 14,
        notarget = true,
        category = "UTILITY",
    },

    -- Выстрел немоты (Silencing Shot)
    [34490] = {
        cd = 20,
        class = "HUNTER",
        category = "KICK",
    },

    -- =========================
    -- РАЗБОЙНИК
    -- =========================

    -- Хитрость (первичный каст) (Tricks of the Trade initial)
    [57934] = {
        buffDuration = 30,  -- НОВОЕ: длительность баффа
        cd = 30,
        class = "ROGUE",
        parent = 59628,
        noself = true,
        category = "UTILITY",
    },

    -- Хитрость (Tricks of the Trade)
    [59628] = {
        cd = 30,
        class = "ROGUE",
        noself = true,
        category = "UTILITY",
    },

    -- Обезоруживание (Dismantle)
    [51722] = {
        cd = 60,
        class = "ROGUE",
        category = "CC",
    },

    -- =========================
    -- РЫЦАРЬ СМЕРТИ
    -- =========================

    -- Вампирская кровь (Vampiric Blood)
    [55233] = {
        cd = 60,
        class = "DEATHKNIGHT",
        talentTab = 1,
        talentIndex = 23,
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Незыблемость льда (Icebound Fortitude)
    [48792] = {
        cd = 120,
        class = "DEATHKNIGHT",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Антимагический панцирь (Anti-Magic Shell)
    [48707] = {
        cd = 45,
        class = "DEATHKNIGHT",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Армия мертвых (Army of the Dead)
    [42650] = {
        cd = 600,
        class = "DEATHKNIGHT",
        notarget = true,
        category = "OTHER",
    },

    -- Кровавый знак (Mark of Blood)
    [49005] = {
        cd = 180,
        class = "DEATHKNIGHT",
        talentTab = 1,
        talentIndex = 15,
        category = "MITIGATION",
    },

    -- Заморозка разума (Mind Freeze)
    [47528] = {
        cd = 10,
        class = "DEATHKNIGHT",
        category = "KICK",
    },

    -- Удушение (Strangulate)
    [47476] = {
        cd = 120,
        class = "DEATHKNIGHT",
        category = "KICK",
    },

    -- Танцующее руническое оружие
    [49028] = {
        cd = 90,
        class = "DEATHKNIGHT",
        category = "Mitigation",
    },

    -- Темняя власть 
    [56222] = {
        cd = 8,
        class = "DEATHKNIGHT",
        category = "OTHER",
    },

    -- Захват рун
    [48982] = {
        cd = 30,
        class = "DEATHKNIGHT",
        category = "Mitigation",
    },


    -- =========================
    -- ШАМАН
    -- =========================

    -- Перерождение (Reincarnation)
    [21169] = {
        cd = 1800,
        class = "SHAMAN",
        category = "UTILITY",
    },

    -- Тотем прилива маны (Mana Tide Totem)
    [16190] = {
        cd = 300,
        class = "SHAMAN",
        talentTab = 3,
        talentIndex = 17,
        category = "UTILITY",
    },

    -- Героизм (Heroism)
    [32182] = {
        cd = 300,
        class = "SHAMAN",
        category = "UTILITY",
    },

    -- Кровожадность (Bloodlust)
    [2825] = {
        cd = 300,
        class = "SHAMAN",
        category = "UTILITY",
    },

    -- Сокрушающая волна (Wind Shear)
    [57994] = {
        cd = 6,
        class = "SHAMAN",
        category = "KICK",
    },

    -- =========================
    -- ВОИН
    -- =========================

    -- Глухая оборона (Shield Wall)
    [871] = {
        cd = 300,
        class = "WARRIOR",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Ни шагу назад (Last Stand)
    [12975] = {
        cd = 180,
        class = "WARRIOR",
        talentTab = 3,
        talentIndex = 6,
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Безудержное восстановление
    [55694] = {
        cd = 180,
        class = "WARRIOR",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Жажда смерти (Death Wish)
    [12292] = {
        cd = 180,
        class = "WARRIOR",
        talentTab = 2,
        talentIndex = 14,
        category = "UTILITY",
    },

    -- Перехват щитом (Shield Bash)
    [72] = {
        cd = 12,
        class = "WARRIOR",
        category = "KICK",
    },

    -- Пинок (Pummel)
    [6552] = {
        cd = 10,
        class = "WARRIOR",
        category = "KICK",
    },

    -- Разоружение (Disarm)
    [676] = {
        cd = 60,
        class = "WARRIOR",
        category = "CC",
    },
    -- Провокация
    [355] = {
        cd = 8,
        class = "WARRIOR",
        tanksonly = true,
        category = "UTILITY",
    },
    -- Блок щитом
    [2565] = {
        cd = 60,
        class = "WARRIOR",
        tanksonly = true,
        category = "MITIGATION",
    },
    -- Оглущающий удар
    [12809] = {
        cd = 30,
        class = "WARRIOR",
        talentTab = 3,
        talentIndex = 14,
        category = "CC",
    },   

    -- Ударная волна
    [46968] = {
        cd = 20,
        class = "WARRIOR",
        talentTab = 3,
        talentIndex = 27,
        notarget = true,
        category = "CC",
    },  

    -- Неистовство героя
    [60970] = {
        cd = 45,
        class = "WARRIOR",
        talentTab = 2,
        talentIndex = 23,
        notarget = true,
        category = "UTILITY",
    },

    -- Размашистые удары
    [12328] = {
        cd = 30,
        class = "WARRIOR",
        talentTab = 1,
        talentIndex = 14,
        notarget = true,
        category = "OTHER",
    },

    -- Вмешательство
    [3411] = {
        cd = 15,
        class = "WARRIOR",
        tanksonly = true,
        improved = true,
        improvedTalentTab = 3,
        improvedTalentIndex = 21,
        category = "UTILITY",
    },

    -- Кровавая ярость
    [2687] = {
        cd = 60,
        class = "WARRIOR",
        category = "OTHER"
    },

    -- Отражение заклинаний
    [23920] = {
        cd = 10,
        class = "WARRIOR",
        tanksonly = true,
        category = "MITIGATION",
        improved = true,
        improvedTalentTab = 3,
        improvedTalentIndex = 10,
    },

    -- Вызывающий крик
    [1161] = {
        cd = 180,
        class = "WARRIOR",
        tanksonly = true,
        notarget = true,
        category = "UTILITY"
    },

    -- Перехват
    [20252] = {
        cd = 20,
        class = "WARRIOR",
        tanksonly = true,
        category = "UTILITY",
    },

    -- Устрашающий крик
    [5246] = {
        cd = 120,
        class = "WARRIOR",
        notarget = true,
        category = "CC",
    },

    -- Ярость берсерка
    [18499] = {
        cd = 30,
        class = "WARRIOR",
        category = "UTILITY",
    },

    -- Возмездие
    [20230] = {
        cd = 300,
        class = "WARRIOR",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Дразнящий удар
    [694] = {
        cd = 60,
        class = "WARRIOR",
        tanksonly = true,
        category = "UTILITY",
    },

    -- Рывок
    [11578] = {
        cd = 15,
        class = "WARRIOR",
        tanksonly = true,
        category = "UTILITY",
    },

    -- Удар грома
    [47502] = {
        cd = 6,
        class = "WARRIOR",
        category = "OTHER",
        availableSets = {"WARRIOR_PROT_T4"},
    },

    --[[-- Вихрь
    [1680] = {
        cd = 10,
        class = "WARRIOR",
        category = "OTHER",
    },--]]

    -- =========================
    -- МАГ
    -- =========================

    -- Ледяная глыба (Ice Block)
    [45438] = {
        cd = 300,
        class = "MAGE",
        category = "MITIGATION",
    },

    -- Невидимость (Invisibility)
    [66] = {
        cd = 180,
        class = "MAGE",
        category = "UTILITY",
    },

    -- Прилив сил (Evocation)
    [12051] = {
        cd = 240,
        class = "MAGE",
        category = "UTILITY",
    },

    -- Антимагия (Counterspell)
    [2139] = {
        cd = 24,
        class = "MAGE",
        category = "KICK",
    },

    -- =========================
    -- ЧЕЛОВЕК / ДВОРФ
    -- =========================

    -- Каждому свое (Every Man for Himself)
    [59752] = {
        cd = 120,
        race = "Human",
        category = "UTILITY",
    },

    -- Каменная форма (Stoneform)
    [20594] = {
        cd = 120,
        race = "Dwarf",
        tanksonly = true,
        category = "MITIGATION",
    },

    -- =========================
    -- ЧЕРНОКНИЖНИК
    -- =========================

    -- Камень души: воскрешение (Soulstone Resurrection buff)
    [47883] = {
        cd = 900,
        class = "WARLOCK",
        category = "UTILITY",
    },

    -- =========================
    -- ПРОЧЕЕ / ПРЕДМЕТЫ
    -- =========================

    -- Глаза Сумерек (обычный) (Eyes of Twilight normal)
    [75490] = {
        cd = 120,
        category = "OTHER",
    },

    -- Глаза Сумерек (героический) (Eyes of Twilight heroic)
    [75495] = {
        cd = 120,
        category = "OTHER",
    },

    -- Эгида Даларана (героич.) (Aegis of Dalaran heroic)
    [71638] = {
        cd = 60,
        category = "MITIGATION",
    },
}