-- Constellations.lua
-- Система отслеживания созвездий (расовых способностей, привязанных к дебаффам)

RaidEye.Constellations = {}

-- База данных созвездий: debuffID -> название
-- Заполни реальными ID дебаффов с твоего сервера
RaidEye.Constellations.database = {
    -- Пример структуры:
    [371805] = "Созвездие Быка",
    [371789] = "Созвездие Вулкана",
    [371804] = "Созвездие Вурдалака",
    -- [12346] = "Созвездие Мага",
    -- [12347] = "Созвездие Орка",
}

-- Кэш созвездий игроков: playerName -> debuffID (или nil)
RaidEye.constellationCache = {}

--- Сканирует дебаффы игрока и находит его созвездие
---@param playerName string
---@return number|nil debuffID созвездия или nil
function RaidEye:ScanPlayerConstellation(playerName)
    -- Проверяем, можем ли мы сканировать этого игрока
    local unit = nil
    
    -- Находим unit ID для игрока
    if UnitName("player") == playerName then
        unit = "player"
    else
        -- Ищем в рейде
        if GetNumRaidMembers() > 0 then
            for i = 1, 40 do
                if UnitName("raid" .. i) == playerName then
                    unit = "raid" .. i
                    break
                end
            end
        else
            -- Ищем в группе
            for i = 1, GetNumPartyMembers() do
                if UnitName("party" .. i) == playerName then
                    unit = "party" .. i
                    break
                end
            end
        end
    end
    
    if not unit then
        return nil
    end
    
    -- Сканируем дебаффы
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, i)
        if not name then
            break
        end
        
        -- Проверяем, есть ли этот дебафф в нашей базе созвездий
        if spellID and self.Constellations.database[spellID] then
            return spellID
        end
    end
    
    return nil
end

--- Обновляет кэш созвездий для всего рейда/группы
function RaidEye:UpdateConstellationCache()
    -- Очищаем старый кэш
    table.wipe(self.constellationCache)
    
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local name = GetRaidRosterInfo(i)
            if name then
                local constellation = self:ScanPlayerConstellation(name)
                if constellation then
                    self.constellationCache[name] = constellation
                end
            end
        end
    else
        -- Группа
        local myName = UnitName("player")
        if myName then
            local constellation = self:ScanPlayerConstellation(myName)
            if constellation then
                self.constellationCache[myName] = constellation
            end
        end
        
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                local constellation = self:ScanPlayerConstellation(name)
                if constellation then
                    self.constellationCache[name] = constellation
                end
            end
        end
    end
end

--- Проверяет, есть ли у игрока нужное созвездие для спелла
---@param playerName string
---@param spellID number
---@return boolean
function RaidEye:PassesConstellationFilter(playerName, spellID)
    local spellConfig = self.spells[spellID]
    
    -- Если у спелла нет требования к созвездию - пропускаем
    if not spellConfig or not spellConfig.constellation then
        return true
    end
    
    -- Проверяем кэш
    local playerConstellation = self.constellationCache[playerName]
    
    -- Если созвездие игрока совпадает с требуемым
    return playerConstellation == spellConfig.constellation
end

--- Получает название созвездия по ID
---@param debuffID number
---@return string
function RaidEye:GetConstellationName(debuffID)
    if debuffID and self.Constellations.database[debuffID] then
        return self.Constellations.database[debuffID]
    end
    return "Неизвестное созвездие"
end

--- Получает название созвездия игрока
---@param playerName string
---@return string|nil
function RaidEye:GetPlayerConstellationName(playerName)
    local debuffID = self.constellationCache[playerName]
    if debuffID then
        return self:GetConstellationName(debuffID)
    end
    return nil
end