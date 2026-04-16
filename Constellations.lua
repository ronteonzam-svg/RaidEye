-- Constellations.lua
-- Знаки зодиака

RaidEye.Constellations = {}

RaidEye.Constellations.database = {
    [371805] = "Созвездие Быка",
    [371789] = "Созвездие Вулкана",
    [371804] = "Созвездие Вурдалака",
}

RaidEye.constellationCache = {}

function RaidEye:ScanPlayerConstellation(playerName)
    local unit = nil
    
    if UnitName("player") == playerName then
        unit = "player"
    else
        if GetNumRaidMembers() > 0 then
            for i = 1, 40 do
                if UnitName("raid" .. i) == playerName then
                    unit = "raid" .. i
                    break
                end
            end
        else
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
        
        if spellID and self.Constellations.database[spellID] then
            return spellID
        end
    end
    
    return nil
end

function RaidEye:UpdateConstellationCache()
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

function RaidEye:PassesConstellationFilter(playerName, spellID)
    local spellConfig = self.spells[spellID]
    
    if not spellConfig or not spellConfig.constellation then
        return true
    end
    
    return self.constellationCache[playerName] == spellConfig.constellation
end

function RaidEye:GetConstellationName(debuffID)
    if debuffID and self.Constellations.database[debuffID] then
        return self.Constellations.database[debuffID]
    end
    return "Неизвестное созвездие"
end

function RaidEye:GetPlayerConstellationName(playerName)
    local debuffID = self.constellationCache[playerName]
    if debuffID then
        return self:GetConstellationName(debuffID)
    end
    return nil
end