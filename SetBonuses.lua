-- SetBonuses.lua
-- Единая система сетовых бонусов

local RaidEye = RaidEye

RaidEye.SetBonuses = {}

RaidEye.setBonusCache = {}
RaidEye.tierBonusCache = {}
RaidEye.inspectQueue = {}
RaidEye.isInspecting = false
RaidEye.lastInspectTime = 0
RaidEye.currentInspectTarget = nil

local INSPECT_INTERVAL = 1.5
local EQUIPMENT_SLOTS = {1, 3, 5, 6, 7, 8, 9, 10}

--[[
============================================================
    БАЗА СЕТОВ
============================================================
    
Поля:
- class: класс
- tier: "T4", "T5", "T6" и т.д.
- role: "TANK", "HEALER", "DPS" (для отображения в UI)
- name: человекочитаемое имя для UI
- piecesForBonus: сколько частей нужно для фильтра (по умолчанию 4)
- items: список itemID
- bonuses: CD reduction бонусы
============================================================
--]]

RaidEye.SetBonuses.database = {

    -- ===========================================
    -- ПАЛАДИН
    -- ===========================================
    
    ["PALADIN_HOLY_T4"] = {
        class = "PALADIN",
        tier = "T4",
        role = "HEALER",
        name = "Паладин Свет T4",
        piecesForBonus = 4,
        items = {
            117490, 117491, 117492, 117493, 117494,
            100445, 100446, 100447, 100448, 100449,
            101345, 101346, 101347, 101348, 101349,
        },
        bonuses = {
            [2] = { spellID = 20216, cdReduction = 100 },
        }
    },
    
    --[[["PALADIN_PROT_T4"] = {
        class = "PALADIN",
        tier = "T4",
        role = "TANK",
        name = "Паладин Защита T4",
        piecesForBonus = 4,
        items = {
        },
        bonuses = {}
    },--]]
    
    --[[["PALADIN_RET_T4"] = {
        class = "PALADIN",
        tier = "T4",
        role = "DPS",
        name = "Паладин Воздаяние T4",
        piecesForBonus = 4,
        items = {
        },
        bonuses = {}
    },--]]
    
    ["PALADIN_HOLY_T5"] = {
        class = "PALADIN",
        tier = "T5",
        role = "HEALER",
        name = "Паладин Свет T5",
        piecesForBonus = 4,
        items = {
            30134, 30135, 30136, 30137, 30138,
            103426, 103427, 103428, 103429, 103430,
            151620, 151621, 151622, 151623, 151624,
        },
        bonuses = {
            [4] = { spellID = 31842, cdReduction = 120 },
        }
    },
    
    ["PALADIN_PROT_T5"] = {
        class = "PALADIN",
        tier = "T5",
        role = "TANK",
        name = "Паладин Защита T5",
        piecesForBonus = 4,
        items = {
            30123, 30124, 30125, 30126, 30127,
            103416, 103417, 103418, 103419, 103420,
            151610, 151611, 151612, 151613, 151614,
        },
        bonuses = {
            [2] = { 
                { spellID = 48827, cdReduction = 24 },
                { spellID = 48952, cdReduction = 2 },
            },
        }
    },
    
    ["PALADIN_PROT_T9"] = {
        class = "PALADIN",
        tier = "T9",
        role = "TANK",
        name = "Паладин Защита T9",
        piecesForBonus = 4,
        items = {
            48652, 48653, 48654, 48655, 48656,
            48657, 48658, 48659, 48660, 48661,
            48647, 48648, 48649, 48650, 48651,
        },
        bonuses = {
            [2] = { spellID = 62124, cdReduction = 2 },
            [4] = { spellID = 498, cdReduction = 30 },
        }
    },

    -- ===========================================
    -- ВОИН
    -- ===========================================
    
    ["WARRIOR_PROT_T4"] = {
        class = "WARRIOR",
        tier = "T4",
        role = "TANK",
        name = "Воин Защита T4",
        piecesForBonus = 4,
        items = {
            117450, 117451, 117452, 117453, 117454,
            100405, 100406, 100407, 100408, 100409,
            101305, 101306, 101307, 101308, 101309,
        },
        bonuses = {
            [4] = { spellID = 871, cdReduction = 15 },
        }
    },
    
    --[[["WARRIOR_ARMS_T4"] = {
        class = "WARRIOR",
        tier = "T4",
        role = "DPS",
        name = "Воин Оружие T4",
        piecesForBonus = 4,
        items = {
        },
        bonuses = {}
    },--]]
    
    --[[["WARRIOR_FURY_T4"] = {
        class = "WARRIOR",
        tier = "T4",
        role = "DPS",
        name = "Воин Неистовство T4",
        piecesForBonus = 4,
        items = {
        },
        bonuses = {}
    },--]]
    
    ["WARRIOR_PROT_T5"] = {
        class = "WARRIOR",
        tier = "T5",
        role = "TANK",
        name = "Воин Защита T5",
        piecesForBonus = 4,
        items = {
            30113, 30114, 30115, 30116, 30117,
            103406, 103407, 103408, 103409, 103410,
            151600, 151601, 151602, 151603, 151604,
        },
        bonuses = {
            [2] = { spellID = 46968, cdReduction = 11 },
        }
    },
    
    ["WARRIOR_PROT_T9"] = {
        class = "WARRIOR",
        tier = "T9",
        role = "TANK",
        name = "Воин Защита T9",
        piecesForBonus = 4,
        items = {
            48456, 48457, 48458, 48459, 48460,
            48461, 48462, 48463, 48464, 48465,
            48466, 48467, 48468, 48469, 48470,
        },
        bonuses = {
            [2] = { spellID = 355, cdReduction = 2 },
            [4] = { spellID = 2565, cdReduction = 10 },
        }
    },

    -- ===========================================
    -- ДРУИД
    -- ===========================================
    
    ["DRUID_FERAL_BEAR_T4"] = {
        class = "DRUID",
        tier = "T4",
        role = "TANK",
        name = "Друид Медведь T4",
        piecesForBonus = 4,
        items = {
            117300, 117301, 117302, 117303, 117304,
            117365, 117366, 117367, 117368, 117369,
            117430, 117431, 117432, 117433, 117434,
        },
        bonuses = {
            [4] = { spellID = 61336, cdReduction = 30 },
        }
    },
    
    ["DRUID_FERAL_CAT_T4"] = {
        class = "DRUID",
        tier = "T4",
        role = "DPS",
        name = "Друид Кот T4",
        piecesForBonus = 4,
        items = {
            117300, 117301, 117302, 117303, 117304,
            117365, 117366, 117367, 117368, 117369,
            117430, 117431, 117432, 117433, 117434,
        },
        bonuses = {}
    },
    
    ["DRUID_RESTO_T4"] = {
        class = "DRUID",
        tier = "T4",
        role = "HEALER",
        name = "Друид Исцеление T4",
        piecesForBonus = 4,
        items = {
            117515, 117516, 117517, 117518, 117519,
            100470, 100471, 100472, 100473, 100474,
            101370, 101371, 101372, 101373, 101374,
        },
        bonuses = {
            [2] = { spellID = 17116, cdReduction = 150 },
        }
    },
    
    --[[["DRUID_BALANCE_T4"] = {
        class = "DRUID",
        tier = "T4",
        role = "DPS",
        name = "Друид Баланс T4",
        piecesForBonus = 4,
        items = {
        },
        bonuses = {}
    },--]]
    
    ["DRUID_FERAL_T5"] = {
        class = "DRUID",
        tier = "T5",
        role = "TANK",  
        name = "Друид Ферал T5",
        piecesForBonus = 4,
        items = {
            159175, 159176, 159177, 159178, 159179,
            159185, 159186, 159187, 159188, 159189,
            159195, 159196, 159197, 159198, 159199,
        },
        bonuses = {
            [4] = { spellID = 5229, cdReduction = 15 },
        }
    },
    
    ["DRUID_FERAL_T7"] = {
        class = "DRUID",
        tier = "T7",
        role = "TANK",
        name = "Друид Ферал T7",
        piecesForBonus = 4,
        items = {
            39553, 39554, 39555, 39556, 39557,
            40471, 40472, 40473, 40493, 40494,
        },
        bonuses = {
            [4] = { spellID = 22812, cdReduction = 20 },
        }
    },

    -- ===========================================
    -- ЖРЕЦ
    -- ===========================================
    
    --[[["PRIEST_HOLY_T4"] = {
        class = "PRIEST",
        tier = "T4",
        role = "HEALER",
        name = "Жрец Свет T4",
        piecesForBonus = 4,
        items = {

        },
        bonuses = {}
    },--]]
    
    --[[["PRIEST_DISC_T4"] = {
        class = "PRIEST",
        tier = "T4",
        role = "HEALER",
        name = "Жрец Послушание T4",
        piecesForBonus = 4,
        items = {
 
        },
        bonuses = {}
    },--]]
    
    --[[["PRIEST_SHADOW_T4"] = {
        class = "PRIEST",
        tier = "T4",
        role = "DPS",
        name = "Жрец Тьма T4",
        piecesForBonus = 4,
        items = {

        },
        bonuses = {}
    },--]]

    -- ===========================================
    -- РЫЦАРЬ СМЕРТИ
    -- ===========================================
    
    ["DEATHKNIGHT_TANK_T4"] = {
        class = "DEATHKNIGHT",
        tier = "T4",
        role = "TANK",
        name = "Рыцарь смерти Танк T4",
        piecesForBonus = 4,
        items = {
            117533, 117536, 117537, 117538, 117539,
            100488, 100491, 100492, 100493, 100494,
            101388, 101391, 101392, 101393, 101394,
        },
        bonuses = {}
    },

}

-- Роли для отображения в UI
RaidEye.SetBonuses.ROLE_NAMES = {
    TANK = "|cff00ff00Танк|r",
    HEALER = "|cff00ffffХил|r", 
    DPS = "|cffff0000ДПС|r",
}

-- =====================================================
-- ИНДЕКСЫ
-- =====================================================

RaidEye.SetBonuses.itemIndex = {}
RaidEye.SetBonuses.tierIndex = {}
RaidEye.SetBonuses.spellIndex = {}
RaidEye.SetBonuses.classIndex = {} 

function RaidEye.SetBonuses:BuildIndexes()
    self.itemIndex = {}
    self.tierIndex = {}
    self.spellIndex = {}
    self.classIndex = {}
    
    for setKey, setData in pairs(self.database) do
        -- Индекс по items
        for _, itemID in ipairs(setData.items) do
            if not self.itemIndex[itemID] then
                self.itemIndex[itemID] = {}
            end
            table.insert(self.itemIndex[itemID], setKey)
        end
        
        -- Индекс по class+tier
        if setData.class and setData.tier then
            if not self.tierIndex[setData.class] then
                self.tierIndex[setData.class] = {}
            end
            if not self.tierIndex[setData.class][setData.tier] then
                self.tierIndex[setData.class][setData.tier] = {}
            end
            table.insert(self.tierIndex[setData.class][setData.tier], setKey)
        end
        
        -- НОВОЕ: Индекс по классам (для UI)
        if setData.class then
            if not self.classIndex[setData.class] then
                self.classIndex[setData.class] = {}
            end
            table.insert(self.classIndex[setData.class], setKey)
        end
        
        -- Индекс по spellID
        if setData.bonuses then
            for pieces, bonusData in pairs(setData.bonuses) do
                if bonusData.spellID then
                    if not self.spellIndex[bonusData.spellID] then
                        self.spellIndex[bonusData.spellID] = {}
                    end
                    table.insert(self.spellIndex[bonusData.spellID], {
                        setKey = setKey,
                        pieces = pieces,
                        cdReduction = bonusData.cdReduction
                    })
                elseif type(bonusData) == "table" then
                    for _, bonus in ipairs(bonusData) do
                        if bonus.spellID then
                            if not self.spellIndex[bonus.spellID] then
                                self.spellIndex[bonus.spellID] = {}
                            end
                            table.insert(self.spellIndex[bonus.spellID], {
                                setKey = setKey,
                                pieces = pieces,
                                cdReduction = bonus.cdReduction
                            })
                        end
                    end
                end
            end
        end
    end
end

--- Возвращает человекочитаемое имя сета
---@param setKey string
---@return string
function RaidEye.SetBonuses:GetSetDisplayName(setKey)
    local setData = self.database[setKey]
    if not setData then return setKey end
    
    if setData.name then
        return setData.name
    end
    
    -- Генерируем имя из ключа
    local roleName = self.ROLE_NAMES[setData.role] or ""
    return string.format("%s %s", setData.tier or "", roleName)
end

--- Возвращает список сетов для класса (для UI dropdown)
---@param class string
---@return table { [setKey] = displayName, ... }
function RaidEye.SetBonuses:GetSetsForClass(class)
    local result = {}
    local sets = self.classIndex[class]
    if sets then
        for _, setKey in ipairs(sets) do
            result[setKey] = self:GetSetDisplayName(setKey)
        end
    end
    return result
end

-- =====================================================
-- АНАЛИЗ ЭКИПИРОВКИ
-- =====================================================

function RaidEye:AnalyzeEquipment(playerName, equippedItems)
    if not self.setBonusCache[playerName] then
        self.setBonusCache[playerName] = {}
    end
    if not self.tierBonusCache[playerName] then
        self.tierBonusCache[playerName] = {}
    end
    
    if not equippedItems then
        equippedItems = {}
        for _, slot in ipairs(EQUIPMENT_SLOTS) do
            local itemID = GetInventoryItemID(playerName, slot)
            if itemID then
                equippedItems[itemID] = true
            end
        end
    end
    
    -- Подсчитываем части для каждого сета
    for setKey, setData in pairs(RaidEye.SetBonuses.database) do
        local count = 0
        for _, itemID in ipairs(setData.items) do
            if equippedItems[itemID] then
                count = count + 1
            end
        end
        self.setBonusCache[playerName][setKey] = count
    end
    
    self.tierBonusCache[playerName]._inspected = true
end

function RaidEye:CheckOwnSetBonuses()
    if not self.db or not self.db.global.enableSetBonuses then
        return
    end
    
    local playerName = UnitName("player")
    local equippedItems = {}
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID("player", slot)
        if itemID then
            equippedItems[itemID] = true
        end
    end
    
    self:AnalyzeEquipment(playerName, equippedItems)
end

-- =====================================================
-- ПРОВЕРКИ
-- =====================================================

---Проверяет, есть ли у игрока конкретный сет с нужным количеством частей
---@param playerName string
---@param setKey string ключ сета (например "WARRIOR_PROT_T4")
---@param piecesRequired number|nil количество частей (по умолчанию из конфига сета или 4)
---@return boolean
function RaidEye:HasSetBonus(playerName, setKey, piecesRequired)
    if not self.db or not self.db.global.enableSetBonuses then
        return true  -- Не фильтруем если отключено
    end
    
    local cache = self.setBonusCache[playerName]
    local tierCache = self.tierBonusCache[playerName]
    
    -- Если инспект ещё не прошёл, показываем всем
    if not tierCache or not tierCache._inspected then
        return true
    end
    
    if not cache then
        return false
    end
    
    local setData = RaidEye.SetBonuses.database[setKey]
    if not setData then
        return false
    end
    
    -- Определяем требуемое количество частей
    piecesRequired = piecesRequired or setData.piecesForBonus or 4
    
    local pieceCount = cache[setKey] or 0
    return pieceCount >= piecesRequired
end

---Получает снижение КД от сетовых бонусов
function RaidEye:GetSetBonusCDReduction(playerName, spellID)
    if not self.db or not self.db.global.enableSetBonuses then
        return 0
    end
    
    local bonusInfo = RaidEye.SetBonuses.spellIndex[spellID]
    if not bonusInfo then return 0 end
    
    local playerCache = self.setBonusCache[playerName]
    if not playerCache then return 0 end
    
    local totalReduction = 0
    for _, info in ipairs(bonusInfo) do
        local pieceCount = playerCache[info.setKey] or 0
        if pieceCount >= info.pieces then
            totalReduction = totalReduction + info.cdReduction
        end
    end
    
    return totalReduction
end

-- =====================================================
-- ИНСПЕКТ (без изменений)
-- =====================================================

function RaidEye:QueueInspect(playerName)
    if not self.db or not self.db.global.enableSetBonuses then return end
    if playerName == UnitName("player") then
        self:CheckOwnSetBonuses()
        return
    end
    for _, name in ipairs(self.inspectQueue) do
        if name == playerName then return end
    end
    table.insert(self.inspectQueue, playerName)
end

function RaidEye:ProcessInspectQueue()
    if not self.db or not self.db.global.enableSetBonuses then
        table.wipe(self.inspectQueue)
        return
    end
    if self.isInspecting or #self.inspectQueue == 0 or InCombatLockdown() then return end
    
    local now = GetTime()
    if now - self.lastInspectTime < INSPECT_INTERVAL then return end
    
    local playerName = table.remove(self.inspectQueue, 1)
    if not UnitExists(playerName) or not UnitIsConnected(playerName) then
        return self:ProcessInspectQueue()
    end
    if not CheckInteractDistance(playerName, 1) then
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
    local equippedItems = {}
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local itemID = GetInventoryItemID(playerName, slot)
        if itemID then equippedItems[itemID] = true end
    end
    
    self:AnalyzeEquipment(playerName, equippedItems)
    self:refreshPlayerCooldowns(playerName)
    
    ClearInspectPlayer()
    self.isInspecting = false
    self.currentInspectTarget = nil
    
    self:ScheduleTimer(function() self:ProcessInspectQueue() end, 0.5)
end

function RaidEye:QueueRaidInspect()
    if not self.db or not self.db.global.enableSetBonuses then return end
    self:CheckOwnSetBonuses()
    
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if name and online and name ~= UnitName("player") then
                self:QueueInspect(name)
            end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name and UnitIsConnected("party" .. i) then
                self:QueueInspect(name)
            end
        end
    end
end

function RaidEye:OnEquipmentChanged()
    if not self.db or not self.db.global.enableSetBonuses then return end
    self:CheckOwnSetBonuses()
    self:refreshPlayerCooldowns(UnitName("player"))
end

function RaidEye:InitSetBonuses()
    if RaidEye.SetBonuses and RaidEye.SetBonuses.BuildIndexes then
        RaidEye.SetBonuses:BuildIndexes()
    end
end