-- SetBonuses.lua
-- Система отслеживания сетовых бонусов для корректировки кулдаунов
-- Легко добавлять кастомные сеты для приватных серверов

--[[
============================================================
    КАК ДОБАВИТЬ СВОЙ СЕТ:
============================================================

1. Найди секцию "КАСТОМНЫЕ СЕТЫ" ниже
2. Добавь новую запись по шаблону:

    ["УНИКАЛЬНОЕ_ИМЯ_СЕТА"] = {
        spellID = 12345,           -- ID заклинания, КД которого снижается
        cdReduction = 30,          -- На сколько секунд снижается КД
        piecesRequired = 4,        -- Сколько частей сета нужно для бонуса (обычно 2 или 4)
        items = {                  -- Список itemID всех частей сета
            11111, 22222, 33333,   -- (можно узнать на wowhead или в игре через /run print(GetInventoryItemID("player", SLOT)))
            44444, 55555,
        }
    },

Слоты экипировки для справки:
    1 = Голова, 3 = Плечи, 5 = Грудь, 6 = Пояс, 7 = Ноги
    8 = Ступни, 9 = Запястья, 10 = Кисти рук

============================================================
--]]

local RaidEye = RaidEye

-- Создаём таблицу для модуля
RaidEye.SetBonuses = {}

-- Кэш сетовых бонусов игроков: setBonusCache[playerName][setKey] = true/false
RaidEye.setBonusCache = {}

-- Очередь на инспект
RaidEye.inspectQueue = {}
RaidEye.isInspecting = false
RaidEye.lastInspectTime = 0
RaidEye.currentInspectTarget = nil

-- Константы
local INSPECT_INTERVAL = 1.5  -- Интервал между инспектами (секунды)
local EQUIPMENT_SLOTS = {1, 3, 5, 6, 7, 8, 9, 10}  -- Слоты для проверки

-- =====================================================
-- БАЗА ДАННЫХ СЕТОВ
-- =====================================================

RaidEye.SetBonuses.database = {

    -- ===========================================
    -- СТАНДАРТНЫЕ СЕТЫ WotLK
    -- ===========================================

        -- Паладин PROT T9(2pc): Длань возмездия -2 сек
        ["PALADIN_PROT_T9_2PC"] = {
            spellID = 62124,  -- Длань возмездия
            cdReduction = 2,
            piecesRequired = 2,
            items = {
                -- Т9.1/т9.2/т9.3
                48652, 48653, 48654, 48655, 48656,
                48657, 48658, 48659, 48660, 48661,
                48647, 48648, 48649, 48650, 48651,
            }
        },

        -- Паладин PROT T9(4pc): Божественная защита -30 сек
        ["PALADIN_PROT_T9_4PC"] = {
            spellID = 498,  -- Божественная защита
            cdReduction = 30,
            piecesRequired = 4,
            items = {
                -- Т9.1/т9.2/т9.3
                48652, 48653, 48654, 48655, 48656,
                48657, 48658, 48659, 48660, 48661,
                48647, 48648, 48649, 48650, 48651,
            }
        },

    -- ===========================================
    -- КАСТОМНЫЕ СЕТЫ (ДОБАВЛЯТЬ СЮДА)
    -- ===========================================

    --[[
    -- Пример кастомного сета:
    ["MY_CUSTOM_SET"] = {
        spellID = 12345,      -- ID заклинания
        cdReduction = 30,     -- Снижение КД в секундах
        piecesRequired = 4,   -- Нужно частей
        items = {
            111111, 222222, 333333,
            444444, 555555,
        }
    },
    --]]

        -- Паладин Holy T4(2pc): Божественное одобрение -100 сек
        ["PALADIN_HOLY_T4_2PC"] = {
            spellID = 20216,  -- Божественное одобрение
            cdReduction = 100,
            piecesRequired = 2,
            items = {
                -- Т4.1/т4.2/т4.3
                117490, 117491, 117492, 117493, 117494,
                100445, 100446, 100447, 100448, 100449,
                101345, 101346, 101347, 101348, 101349,
            }
        },    

        -- Паладин Holy T5(4pc): Божественное просветление -120 сек
        ["PALADIN_HOLY_T5_4PC"] = {
            spellID = 31842,  -- Божественное просветление
            cdReduction = 120,
            piecesRequired = 4,
            items = {
                -- Т5.1/т5.2/т5.3
                30134, 30135, 30136, 30137, 30138,
                103426, 103427, 103428, 103429, 103430,
                151620, 151621, 151622, 151623, 151624,
            }
        },

        -- Паладин PROT T5(2pc): Щит Мстителя -24 сек
        ["PALADIN_PROT_T5_2PC_AvShield"] = {
            spellID = 48827,  -- Щит Мстителя
            cdReduction = 24,
            piecesRequired = 2,
            items = {
                -- Т5.1/т5.2/т5.3
                30123, 30124, 30125, 30126, 30127,
                103416, 103417, 103418, 103419, 103420,
                151610, 151611, 151612, 151613, 151614,
            }
        },
        -- Паладин PROT T5(2pc): Щит Небес -2 сек
        ["PALADIN_PROT_T5_2PC_HoShield"] = {
            spellID = 48952,  -- Щит Небес
            cdReduction = 2,
            piecesRequired = 2,
            items = {
                -- Т5.1/т5.2/т5.3
                30123, 30124, 30125, 30126, 30127,
                103416, 103417, 103418, 103419, 103420,
                151610, 151611, 151612, 151613, 151614,
            }
        },             

}

-- =====================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- =====================================================

-- Строим быстрый индекс item -> set для оптимизации
function RaidEye.SetBonuses:BuildItemIndex()
    self.itemToSet = {}
    for setKey, setData in pairs(self.database) do
        for _, itemID in ipairs(setData.items) do
            if not self.itemToSet[itemID] then
                self.itemToSet[itemID] = {}
            end
            self.itemToSet[itemID][setKey] = true
        end
    end
end

-- =====================================================
-- ФУНКЦИИ ИНСПЕКТА
-- =====================================================

function RaidEye:QueueInspect(playerName)
    -- Если функция отключена, не добавляем в очередь
    if not self.db or not self.db.global.enableSetBonuses then
        return
    end

    if playerName == UnitName("player") then
        self:CheckOwnSetBonuses()
        return
    end

    -- Не добавляем дубликаты
    for _, name in ipairs(self.inspectQueue) do
        if name == playerName then
            return
        end
    end

    table.insert(self.inspectQueue, playerName)
end

function RaidEye:ProcessInspectQueue()
    -- Если функция отключена, очищаем очередь и выходим
    if not self.db or not self.db.global.enableSetBonuses then
        table.wipe(self.inspectQueue)
        return
    end

    if self.isInspecting then return end
    if #self.inspectQueue == 0 then return end
    if InCombatLockdown() then return end  -- Не инспектим в бою

    local now = GetTime()
    if now - self.lastInspectTime < INSPECT_INTERVAL then return end

    local playerName = table.remove(self.inspectQueue, 1)

    -- Проверяем, что игрок ещё в рейде и в пределах досягаемости
    if not UnitExists(playerName) or not UnitIsConnected(playerName) then
        return self:ProcessInspectQueue()  -- Пробуем следующего
    end

    if not CheckInteractDistance(playerName, 1) then
        -- Слишком далеко, возвращаем в конец очереди
        table.insert(self.inspectQueue, playerName)
        return
    end

    self.isInspecting = true
    self.currentInspectTarget = playerName
    self.lastInspectTime = now

    NotifyInspect(playerName)
end

function RaidEye:OnInspectReady()
    if not self.currentInspectTarget then return end
    if not self.db or not self.db.global.enableSetBonuses then
        ClearInspectPlayer()
        self.isInspecting = false
        self.currentInspectTarget = nil
        return
    end

    local playerName = self.currentInspectTarget
    self:AnalyzeEquipment(playerName)

    ClearInspectPlayer()
    self.isInspecting = false
    self.currentInspectTarget = nil

    -- Продолжаем очередь
    self:ScheduleTimer(function()
        self:ProcessInspectQueue()
    end, 0.5)
end

function RaidEye:AnalyzeEquipment(playerName)
    if not self.setBonusCache[playerName] then
        self.setBonusCache[playerName] = {}
    end

    -- Собираем все itemID экипировки
    local equippedItems = {}
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID(playerName, slot)
        if itemID then
            equippedItems[itemID] = true
        end
    end

    -- Проверяем каждый сет
    for setKey, setData in pairs(RaidEye.SetBonuses.database) do
        local count = 0
        for _, itemID in ipairs(setData.items) do
            if equippedItems[itemID] then
                count = count + 1
            end
        end

        local hadBonus = self.setBonusCache[playerName][setKey]
        local hasBonus = (count >= setData.piecesRequired)
        self.setBonusCache[playerName][setKey] = hasBonus

        -- Если статус изменился, обновляем фреймы этого игрока
        if hadBonus ~= hasBonus then
            self:refreshPlayerCooldowns(playerName)
        end
    end
end

function RaidEye:CheckOwnSetBonuses()
    if not self.db or not self.db.global.enableSetBonuses then
        return
    end

    local playerName = UnitName("player")
    if not self.setBonusCache[playerName] then
        self.setBonusCache[playerName] = {}
    end

    local equippedItems = {}
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            equippedItems[itemID] = true
        end
    end

    for setKey, setData in pairs(RaidEye.SetBonuses.database) do
        local count = 0
        for _, itemID in ipairs(setData.items) do
            if equippedItems[itemID] then
                count = count + 1
            end
        end

        self.setBonusCache[playerName][setKey] = (count >= setData.piecesRequired)
    end
end

-- =====================================================
-- ПРОВЕРКА СЕТОВОГО БОНУСА ДЛЯ КОНКРЕТНОГО СПЕЛЛА
-- =====================================================

---@param playerName string
---@param spellID number
---@return number cdReduction (в секундах, 0 если нет бонуса или функция отключена)
function RaidEye:GetSetBonusCDReduction(playerName, spellID)
    -- Если функция отключена, возвращаем 0
    if not self.db or not self.db.global.enableSetBonuses then
        return 0
    end

    local cache = self.setBonusCache[playerName]
    if not cache then return 0 end

    for setKey, setData in pairs(RaidEye.SetBonuses.database) do
        if setData.spellID == spellID and cache[setKey] then
            return setData.cdReduction
        end
    end

    return 0
end

-- =====================================================
-- ЗАПУСК ИНСПЕКТА ДЛЯ ВСЕГО РЕЙДА
-- =====================================================

function RaidEye:QueueRaidInspect()
    if not self.db or not self.db.global.enableSetBonuses then
        return
    end

    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online then
                self:QueueInspect(name)
            end
        end
    else
        self:CheckOwnSetBonuses()
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and UnitIsConnected("party" .. i) then
                self:QueueInspect(name)
            end
        end
    end
end

-- =====================================================
-- ОБРАБОТЧИК СМЕНЫ ЭКИПИРОВКИ
-- =====================================================

function RaidEye:OnEquipmentChanged()
    if not self.db or not self.db.global.enableSetBonuses then
        return
    end

    self:CheckOwnSetBonuses()
    self:refreshPlayerCooldowns(UnitName("player"))
end

-- =====================================================
-- ИНИЦИАЛИЗАЦИЯ (вызывается из Core.lua)
-- =====================================================

function RaidEye:InitSetBonuses()
    if self.SetBonuses and self.SetBonuses.BuildItemIndex then
        self.SetBonuses:BuildItemIndex()
    end
end