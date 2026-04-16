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
        improved = true,
        improvedTalentTab = 2,
        improvedTalentIndex = 9,
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
        improved = true,
        improvedTalentTab = 3,
        improvedTalentIndex = 16,
        category = "UTILITY",
    },

    -- Божественный щит (Divine Shield)
    [642] = {
        cd = 300,
        class = "PALADIN",
        tanksonly = true,
        notarget = true,
        category = "MITIGATION",
    },

    -- Длань защиты (Hand of Protection)
    [10278] = {
        cd = 300,
        class = "PALADIN",
        category = "UTILITY",
    },

    -- Божественная защита (Divine Protection)
    [498] = {
        cd = 180,
        class = "PALADIN",
        tanksonly = true,
        notarget = true,
        category = "MITIGATION",
    },

    -- Возложение рук (Lay on Hands)
    [48788] = {
        cd = 1200,
        class = "PALADIN",
        improved = true,
        improvedTalentTab = 1,
        improvedTalentIndex = 8,
        category = "UTILITY",
    },

    -- Мастер аура (Aura Mastery)
    [31821] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 1,
        talentIndex = 6,
        notarget = true,
        category = "UTILITY",
    },

    -- Гнев небес (Holy Wrath)
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

    -- Праведный защитник (Ardent Defender)
    [66233] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 18,
        notarget = true,
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
        notarget = true,
        category = "OTHER",
    },

    -- Божественное одобрение (Divine Favor)
    [20216] = {
        cd = 120,
        class = "PALADIN",
        talentTab = 1,
        talentIndex = 13,
        notarget = true,
        category = "OTHER",
    },
    -- Щит мстителя (Avenger's Shield)
    [48827] = {
        cd = 30,
        class = "PALADIN",
        talentTab = 2,
        talentIndex = 22,
        notarget = true,
        category = "CC",
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

    -- Исчадие Тьмы (Shadowfiend)
    [34433] = {
        cd = 300,
        class = "PRIEST",
        notarget = true,
        category = "OTHER",
    },

    -- Молитва отчаяния (Prayer of Despair)
    [48173] = {
        cd = 120,
        class = "PRIEST",
        notarget = true,
        category = "MITIGATION",
    },

    -- Ментальный крик (Psychic Scream)
    [10890] = {
        cd = 30,
        class = "PRIEST",
        notarget = true,
        category = "CC",
    },

    -- Уход в тень (Fade)
    [586] = {
        cd = 30,
        class = "PRIEST",
        notarget = true,
        category = "UTILITY",
    },

    -- Безмолвие (Silence)
    [15487] = {
        cd = 45,
        class = "PRIEST",
        talentTab = 3,
        talentIndex = 13,
        category = "CC",
    },

    -- Глубинный ужас (Deep Terror)
    [64044] = {
        cd = 120,
        class = "PRIEST",
        talentTab = 3,
        talentIndex = 23,
        category = "CC",
    },

    -- Слияние с Тьмой (Dispersion)
    [47585] = {
        cd = 120,
        class = "PRIEST",
        talentTab = 3,
        talentIndex = 27,
        notarget = true,
        category = "MITIGATION",
    },

    -- Придание сил (Power Infusion)
    [10060] = {
        cd = 120,
        class = "PRIEST",
        notarget = true,
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
        notarget = true,
        category = "MITIGATION",
    },

    -- Инстинкты выживания (Survival Instincts)
    [61336] = {
        cd = 180,
        class = "DRUID",
        talentTab = 2,
        talentIndex = 7,
        tanksonly = true,
        notarget = true,
        category = "MITIGATION",
        availableSets = {"DRUID_FERAL_BEAR_T4"},
    },

    -- Тайфун (Typhoon)
    [61384] = {
        cd = 20,
        class = "DRUID",
        talentTab = 1,
        talentIndex = 24,
        notarget = true,
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
        notarget = true,
        category = "MITIGATION",
    },

        -- Стремительный рывок – медведь (Feral Charge - Bear)
    [16979] = {
        cd = 15,
        class = "DRUID",
        tanksonly = true,
        category = "CC",
    },

    -- Рык
    [6795] = {
        cd = 8,
        class = "DRUID",
        tanksonly = true,
        category = "OTHER",
    },

    -- Вызывающий рев
    [5209] = {
        cd = 180,
        class = "DRUID",
        tanksonly = true,
        notarget = true,
        category = "OTHER",
    },

    -- Берсерк
    [50334] = {
        cd = 180,
        class = "DRUID",
        talentTab = 2,
        talentIndex = 31,
        category = "OTHER",
    },
    -- Оглушить (Bash)
    [8983] = {
        cd = 60,
        tanksonly = true,
        class = "DRUID",
        category = "CC",
    },
    -- Порыв
    [33357] = {
        cd = 180,
        class = "DRUID",
        notarget = true,
        category = "OTHER",
    },  
    -- Калечение (Maim)
    [49802] = {
        cd = 10,
        class = "DRUID",
        feralonly = true,
        category = "CC",
    },    
    -- Исступление (Rampage)
    [5229] = {
        cd = 60,
        class = "DRUID",
        tanksonly = true,
        notarget = true,
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
        buffDuration = 30,  -- длительность баффа (стадия ожидания)
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
        buffDuration = 30,  -- длительность баффа
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
        notarget = true,
        category = "MITIGATION",
    },

    -- Незыблемость льда (Icebound Fortitude)
    [48792] = {
        cd = 120,
        class = "DEATHKNIGHT",
        tanksonly = true,
        notarget = true,
        category = "MITIGATION",
        availableSets = {"DEATHKNIGHT_TANK_T4"},
    },

    -- Антимагический панцирь (Anti-Magic Shell)
    [48707] = {
        cd = 45,
        class = "DEATHKNIGHT",
        notarget = true,
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
        tanksonly = true,
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
        notarget = true,
        tanksonly = true,
        talentTab = 1,
        talentIndex = 29,
        category = "MITIGATION",
    },

    -- Темняя власть 
    [56222] = {
        cd = 8,
        class = "DEATHKNIGHT",
        tanksonly = true,
        category = "OTHER",
    },

    -- Захват рун
    [48982] = {
        cd = 30,
        class = "DEATHKNIGHT",
        notarget = true,
        tanksonly = true,
        talentTab = 1,
        talentIndex = 7,
        improved = true,
        improvedTalentTab = 1,
        improvedTalentIndex = 10,
        category = "MITIGATION",
    },

    -- Смертельный союз
    [48743] = {
        cd = 120,
        class = "DEATHKNIGHT",
        notarget = true,
        tanksonly = true,
        category = "MITIGATION",
    },
    -- Перерождение
    [49039] = {
        cd = 120,
        class = "DEATHKNIGHT",
        notarget = true,
        tanksonly = true,
        talentTab = 2,
        talentIndex = 8,
        category = "UTILITY",
    },

    -- Ненасытная стужа
    [49203] = {
        cd = 60,
        class = "DEATHKNIGHT",
        notarget = true,
        talentTab = 2,
        talentIndex = 20,
        category = "CC",
    },

    -- Зона антимагии
    [51052] = {
        cd = 120,
        class = "DEATHKNIGHT",
        notarget = true,
        talentTab = 3,
        talentIndex = 22,
        category = "MITIGATION",
    },

    -- Костяной щит
    [49222] = {
        cd = 60,
        class = "DEATHKNIGHT",
        notarget = true,
        tanksonly = true,
        talentTab = 3,
        talentIndex = 26,
        category = "MITIGATION",
    },

    -- Призыв гаргульи
    [49206] = {
        cd = 180,
        class = "DEATHKNIGHT",
        notarget = true,
        talentTab = 3,
        talentIndex = 31,
        category = "OTHER",
    },

    -- Зимний горн
    [57623] = {
        cd = 20,
        class = "DEATHKNIGHT",
        notarget = true,
        tanksonly = true,
        category = "OTHER",
        -- TODO: availableSets = {"DEATHKNIGHT_FROST_TANK_T6"},
    },

    -- Хватка смерти
    [49576] = {
        cd = 35,
        class = "DEATHKNIGHT",
        category = "UTILITY",
    },

    -- =========================
    -- ШАМАН
    -- =========================

    -- Перерождение (Reincarnation)
    [21169] = {
        cd = 1800,
        class = "SHAMAN",
        notarget = true,
        category = "UTILITY",
    },

    -- Тотем заземления 
    [8177] = {
        cd = 15,
        class = "SHAMAN",
        notarget = true,
        category = "UTILITY",
    },

    -- Тотем элементаля земли
    [2062] = {
        cd = 600,
        class = "SHAMAN",
        notarget = true,
        category = "UTILITY",
    },

    -- Тотем каменного когтя
    [58582] = {
        cd = 30,
        class = "SHAMAN",
        notarget = true,
        category = "UTILITY",
    },

    -- Тотем оков земли
    [2484] = {
        cd = 15,
        class = "SHAMAN",
        notarget = true,
        category = "CC",
    },

    -- Сглаз (Hex)
    [51514] = {
        cd = 45,
        class = "SHAMAN",
        category = "CC",
    },

    -- Гром и молния
    [51490] = {
        cd = 45,
        class = "SHAMAN",
        notarget = true,
        talentTab = 1,
        talentIndex = 25,
        category = "UTILITY",
    },

    -- Дух дикого волка
    [51533] = {
        cd = 180,
        class = "SHAMAN",
        notarget = true,
        talentTab = 1,
        talentIndex = 29,
        category = "OTHER",
    },

    -- Ярость шамана
    [30823] = {
        cd = 60,
        class = "SHAMAN",
        notarget = true,
        talentTab = 1,
        talentIndex = 26,
        category = "MITIGATION",
    },

    -- Тотем прилива маны (Mana Tide Totem)
    [16190] = {
        cd = 300,
        class = "SHAMAN",
        notarget = true,
        talentTab = 3,
        talentIndex = 17,
        category = "UTILITY",
    },

    -- Героизм (Heroism)
    [32182] = {
        cd = 300,
        class = "SHAMAN",
        notarget = true,
        category = "UTILITY",
    },

    -- Жажда крови (Bloodlust)
    [2825] = {
        cd = 300,
        class = "SHAMAN",
        notarget = true,
        parent = 32182,
    },

    -- Пронизывающий ветер
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
        notarget = true,
        tanksonly = true,
        category = "MITIGATION",
        availableSets = {"WARRIOR_PROT_T4"},
    },

    -- Ни шагу назад (Last Stand)
    [12975] = {
        cd = 180,
        class = "WARRIOR",
        notarget = true,
        talentTab = 3,
        talentIndex = 6,
        tanksonly = true,
        category = "MITIGATION",
    },

    -- Безудержное восстановление
    [55694] = {
        cd = 180,
        class = "WARRIOR",
        notarget = true,
        tanksonly = true,
        category = "MITIGATION",
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
        category = "OTHER",
    },
    -- Блок щитом
    [2565] = {
        cd = 60,
        class = "WARRIOR",
        notarget = true,
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

    -- Отражение заклинаний
    [23920] = {
        cd = 10,
        class = "WARRIOR",
        notarget = true,
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
        category = "OTHER"
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
        notarget = true,
        category = "UTILITY",
    },

    -- Возмездие
    [20230] = {
        cd = 300,
        class = "WARRIOR",
        notarget = true,
        tanksonly = true,
        category = "OTHER",
    },

    -- Дразнящий удар
    [694] = {
        cd = 60,
        class = "WARRIOR",
        tanksonly = true,
        category = "OTHER",
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
        notarget = true,
        tanksonly = true,   
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
        notarget = true,
        category = "MITIGATION",
    },

    -- Невидимость (Invisibility)
    [66] = {
        cd = 180,
        class = "MAGE",
        notarget = true,
        category = "UTILITY",
    },

    -- Прилив сил (Evocation)
    [12051] = {
        cd = 240,
        class = "MAGE",
        notarget = true,
        category = "UTILITY",
    },

    -- Антимагия (Counterspell)
    [2139] = {
        cd = 24,
        class = "MAGE",
        category = "KICK",
    },

    -- =========================
    -- ЧЕРНОКНИЖНИК
    -- =========================

    -- Камень души: воскрешение (Soulstone Resurrection buff)
    [47883] = {
        cd = 600,
        class = "WARLOCK",
        category = "UTILITY",
    },

    -- Инфернал (Infernal)
    [1122] = {
        cd = 600,
        class = "WARLOCK",
        notarget = true,
        category = "OTHER",
    },
    -- Заслон от тёмной магии
    [47891] = {
        cd = 30,
        class = "WARLOCK",
        notarget = true,
        category = "MITIGATION",
    },

    -- Ритуал призыва
    [698] = {
        cd = 120,
        class = "WARLOCK",
        notarget = true,
        category = "OTHER",
    },

    -- Ритуал душ
    [58887] = {
        cd = 300,
        class = "WARLOCK",
        notarget = true,
        improved = true,
        improvedTalentTab = 2,
        improvedTalentIndex = 1,
        category = "OTHER",
    },

    -- Раскол души
    [29858] = {
        cd = 180,
        class = "WARLOCK",
        notarget = true,
        category = "UTILITY",
    },

    -- Вой ужаса
    [17928] = {
        cd = 40,
        class = "WARLOCK",
        notarget = true,
        category = "CC",
    },

    -- Лик смерти
    [47860] = {
        cd = 120,
        class = "WARLOCK",
        category = "CC",
    },

    -- Господство скверны
    [18708] = {
        cd = 180,
        class = "WARLOCK",
        notarget = true,
        talentTab = 2,
        talentIndex = 10,
        category = "OTHER",
    },

    -- Метаморфоза
    [59672] = {
        cd = 180,
        class = "WARLOCK",
        notarget = true,
        talentTab = 3,
        talentIndex = 27,
        category = "OTHER",
    },

    -- Поджигание
    [17962] = {
        cd = 10,
        class = "WARLOCK",
        talentTab = 3,
        talentIndex = 17,
        improved = true,
        improvedTalentTab = 3,
        improvedTalentIndex = 3,
        category = "CC",
    },

    -- Неистовство тьмы
    [30283] = {
        cd = 20,
        class = "WARLOCK",
        notarget = true,
        talentTab = 3,
        talentIndex = 23,
        category = "CC",
    },

    -- =========================
    -- Созвездия
    -- =========================  
    -- Созвездие Быка Сила Матери Земли 
    [375056] = {
        cd = 60,
        category = "MITIGATION",
        constellation = 371805,
        tanksonly = true,
        notarget = true,
    },
    -- Созвездие Вулкана Извержение Вулкана
    [375125] = {
        cd = 60,
        category = "CC",
        constellation = 371789,
        notarget = true,
    },
    --Созвездие Вурдалака Гнильное Поветрие
    [375053] = {
        cd = 60,
        category = "OTHER",
        constellation = 371804,
        notarget = true,
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