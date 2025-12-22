RaidEye = CreateFrame("Frame")

RaidEye.LibGroupTalents = LibStub("LibGroupTalents-1.0")
RaidEye.LibSharedMedia = LibStub("LibSharedMedia-3.0")
RaidEye.LibRangeCheck = LibStub("LibRangeCheck-2.0")

LibStub("AceTimer-3.0"):Embed(RaidEye)
LibStub("AceComm-3.0"):Embed(RaidEye)
LibStub("AceSerializer-3.0"):Embed(RaidEye)

RaidEye.groups = {}
RaidEye.localizedSpellNames = {}
RaidEye.deadUnits = {}
RaidEye.RebirthTargets = {}
RaidEye.db_ver = 4

RaidEye.comms = {
    oRA = "oRA",
    oRA3 = "oRA3",
    BLT = "BLT Raid Cooldowns",
    CTRA = "CTRA",
    RCD2 = "RaidCooldowns",
    FRCD3 = "FatCooldowns",
    FRCD3S = "FatCooldowns (single report)",
    RaidEye = "RaidEye",
}

-- Спеллы-исключения, которые НЕ сбрасываются после энкаунтера
RaidEye.encounterResetExceptions = {
    [47883] = true,  -- (Камень души)
}

-- Спеллы, которые игрок может нажать сам для сброса своих КД (чтобы не триггерить общий сброс)
RaidEye.selfResetSpells = {
    [23989] = true, -- Готовность (Хант)
    [14185] = true, -- Подготовка (Рога)
    [11958] = true, -- Холодная хватка (Маг)
}
RaidEye.lastSelfResetTime = 0

-- Флаг для отслеживания боя в рейде
RaidEye.wasInCombatInRaid = false
RaidEye.combatStartTime = 0

local playerInRaid = UnitInRaid("player")

local updateRaidRosterCooldown = 2
local updateRaidRosterTimestamp
local updateRaidRosterScheduleTimer

local ReadinessTimestamp = {}

local childSpells = {}

local groups = 2

-- Индекс для быстрого поиска фреймов: frameIndex[playerName][spellID] = frame
RaidEye.frameIndex = {}

-- Таблица для отслеживания недавних кастов: recentCasts[playerName][spellID] = timestamp
RaidEye.recentCasts = {}

-- Таблица для отслеживания прерываний: pendingInterrupts[playerName][spellID] = {icon, expireTime}
RaidEye.pendingInterrupts = {}

-- Таблица для отложенных прерываний ПО ИГРОКУ
RaidEye.pendingInterruptsByPlayer = {}

-- Кэш участников рейда/группы для быстрой проверки
RaidEye.raidMembersCache = {}
-- ОПТИМИЗАЦИЯ: Кэш спеллов, которые мы точно НЕ отслеживаем, чтобы не искать их каждый раз
RaidEye.nonTrackedSpells = {} 

local INTERRUPT_ICON_DURATION = 2.0
local CAST_INTERRUPT_WINDOW = 1.0

local date, floor, GetTime, pairs, select, string, strsplit, table, time, tonumber, tostring, type, unpack = date, floor, GetTime, pairs, select, {
    find = string.find,
    gmatch = string.gmatch
}, strsplit, {
    insert = table.insert,
    remove = table.remove,
    wipe = table.wipe
}, time, tonumber, tostring, type, unpack

-- === ОПТИМИЗАЦИЯ: Кэш участников рейда ===
-- Полностью переписано на событийную модель, убрана проверка GetTime() при каждом вызове
function RaidEye:isRaidMember(playerName)
    return self.raidMembersCache[playerName]
end

-- Принудительное обновление кэша (вызывается только при изменении группы)
function RaidEye:UpdateRaidMembersCache()
    table.wipe(self.raidMembersCache)
    
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local name = GetRaidRosterInfo(i)
            if name then
                self.raidMembersCache[name] = true
            end
        end
    else
        -- Группа
        local myName = UnitName("player")
        if myName then self.raidMembersCache[myName] = true end
        
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                self.raidMembersCache[name] = true
            end
        end
    end
end

RaidEye:RegisterEvent("ADDON_LOADED")

function RaidEye:LibGroupTalents_Update(...)
    self:refreshPlayerCooldowns((UnitName((select(3, ...)))))
    self:repositionFrames()
end

function RaidEye:LibGroupTalents_RoleChange(...)
    self:LibGroupTalents_Update(...)
end

RaidEye:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, combatEvent, _, playerName, _, _, targetName, _, spellID, spellName = ...
        
        -- ОПТИМИЗАЦИЯ: Быстрый выход, если игрок не в рейде
        if not self.raidMembersCache[playerName] then
            return
        end

        -- ОПТИМИЗАЦИЯ: Если мы уже проверяли этот ID и он нам не нужен - выходим
        if self.nonTrackedSpells[spellID] then
            -- Исключение: прерывания требуют проверки события, даже если ID спелла не отслеживается
            if combatEvent ~= "SPELL_INTERRUPT" then
                return
            end
        end

        -- ОБРАБОТКА ПРЕРЫВАНИЙ
        if combatEvent == "SPELL_INTERRUPT" then
            local interruptedSpellID = select(12, ...)
            local interruptedIcon = interruptedSpellID and select(3, GetSpellInfo(interruptedSpellID))
            
            if not interruptedIcon then return end
            
            -- Определяем ID спелла-прерывания
            local interruptSpellID = spellID
            if not self.spells[interruptSpellID] then
                interruptSpellID = self.localizedSpellNames[spellName]
            end
            
            -- Если спелл в нашей базе — стандартный путь
            if interruptSpellID and self.spells[interruptSpellID] then
                self:handleInterrupt(interruptSpellID, playerName, targetName, interruptedIcon)
            else
                -- Спелл НЕ в базе (станы, рывки и т.п.)
                local found = self:handleUnknownInterrupt(playerName, interruptedIcon)
                
                if not found then
                    self.pendingInterruptsByPlayer[playerName] = {
                        icon = interruptedIcon,
                        time = GetTime()
                    }
                end
            end
            
        elseif combatEvent == "SPELL_CAST_SUCCESS" or combatEvent == "SPELL_RESURRECT" then
            local resolvedSpellID = self.spells[spellID] and spellID or nil
            
            -- Резолв по имени с проверкой класса
            if not resolvedSpellID and spellName then
                local candidateSpellID = self.localizedSpellNames[spellName]
                if candidateSpellID and self.spells[candidateSpellID] then
                    local spellConfig = self.spells[candidateSpellID]
                    if spellConfig.class then
                        local _, playerClass = UnitClass(playerName)
                        if playerClass == spellConfig.class then
                            resolvedSpellID = candidateSpellID
                        end
                    else
                        resolvedSpellID = candidateSpellID
                    end
                end
            end
            
            if resolvedSpellID then
                self:trackRecentCast(playerName, resolvedSpellID)
                
                -- Проверяем отложенное прерывание
                local pendingByPlayer = self.pendingInterruptsByPlayer[playerName]
                if pendingByPlayer and (GetTime() - pendingByPlayer.time) < 0.5 then
                    if not self.pendingInterrupts[playerName] then
                        self.pendingInterrupts[playerName] = {}
                    end
                    self.pendingInterrupts[playerName][resolvedSpellID] = {
                        icon = pendingByPlayer.icon,
                        expireTime = GetTime() + INTERRUPT_ICON_DURATION
                    }
                    self.pendingInterruptsByPlayer[playerName] = nil
                end
                
                self:setCooldown(resolvedSpellID, playerName, true, targetName)
            else
                -- ОПТИМИЗАЦИЯ: Запоминаем, что этот spellID нам не интересен
                self.nonTrackedSpells[spellID] = true
            end

        elseif combatEvent == "SPELL_AURA_APPLIED" then
            local resolvedSpellID = self.spells[spellID] and spellID or nil
            
            -- Резолв по имени с проверкой класса
            if not resolvedSpellID and spellName then
                local candidateSpellID = self.localizedSpellNames[spellName]
                if candidateSpellID and self.spells[candidateSpellID] then
                    local spellConfig = self.spells[candidateSpellID]
                    if spellConfig.class then
                        local _, playerClass = UnitClass(playerName)
                        if playerClass == spellConfig.class then
                            resolvedSpellID = candidateSpellID
                        end
                    else
                        resolvedSpellID = candidateSpellID
                    end
                end
            end
            
            if resolvedSpellID then
                if resolvedSpellID == 64843 or resolvedSpellID == 64901 or resolvedSpellID == 48447 then
                    if self:getCDLeft(playerName, resolvedSpellID) > 10 then
                        return
                    end
                end
                self:setCooldown(resolvedSpellID, playerName, true, nil)
            else
                 -- ОПТИМИЗАЦИЯ
                 self.nonTrackedSpells[spellID] = true
            end
            
        elseif combatEvent == "SPELL_HEAL" and spellID == 48153 then
            self:GSProc(targetName)
            
        elseif combatEvent == "UNIT_DIED" then
            self.deadUnits[playerName] = true
        end

    -- UNIT_SPELLCAST события для двойного Rebirth и отслеживания Readiness
    elseif event == "UNIT_SPELLCAST_SENT"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spellName, _, targetName = ...
        local spellID = self.localizedSpellNames[spellName]
        
        -- Ловим Rebirth
        if spellID == 48477 then
            self:Rebirth(event, (UnitName(unit)), targetName)
        end

        -- Ловим свои сбросы (Готовность и т.д.)
        if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
            -- Получаем ID заклинания, если возможно, или проверяем по имени
            local castSpellID = nil
            if self.localizedSpellNames[spellName] then
                castSpellID = self.localizedSpellNames[spellName]
            end
            
            -- Если это спелл, сбрасывающий кд, запоминаем время
            if castSpellID and self.selfResetSpells[castSpellID] then
                self.lastSelfResetTime = GetTime()
            end
        end

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        -- НОВЫЙ МЕХАНИЗМ СБРОСА
        self:CheckLocalReset()

    elseif event == "RAID_ROSTER_UPDATE" then
        self:UpdateRaidMembersCache() -- Сразу обновляем кэш
        local instant
        if playerInRaid ~= UnitInRaid("player") then
            if playerInRaid then
                self:RegisterEvent("PARTY_MEMBERS_CHANGED")
            else
                self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
                instant = true
            end
            playerInRaid = UnitInRaid("player")
        end
        if playerInRaid then
            self:updateRaidRoster(instant)
        end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        self:UpdateRaidMembersCache() -- Сразу обновляем кэш
        self:updateRaidRoster()
    elseif event == "INSPECT_READY" then
        self:OnInspectReady()
        
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        self:OnEquipmentChanged()
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Вход в бой
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "raid" or instanceType == "party") then
            self.wasInCombatInRaid = true
            self.combatStartTime = GetTime()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Выход из боя (оставляем как резервный метод)
        if self.wasInCombatInRaid then
            local combatDuration = GetTime() - self.combatStartTime
            self.wasInCombatInRaid = false
            
            local inInstance, instanceType = IsInInstance()
            local minCombatDuration = (instanceType == "party") and 5 or 10
            
            -- Сбрасываем только если нет DBM/BigWigs (они точнее) и бой был долгим
            if combatDuration > minCombatDuration and not DBM and not BigWigsLoader then
                self:ScheduleTimer(function()
                    self:OnEncounterEnd("combat_end")
                end, 1.5)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateRaidMembersCache() -- Инициализация кэша
        self:cacheLocalizedSpellNames()
        self:ScheduleTimer(function()
            self:updateRaidCooldowns()
        end, 2)
        self:ScheduleTimer(function()
            self:updateRaidCooldowns()
        end, 10)
        self:ScheduleTimer(function()
            self:updateRaidCooldowns()
        end, 30)
        if self.db.global.testMode then
            self:setTestMode(true)
        end
    elseif event == "ADDON_LOADED" then
        if (...) ~= "RaidEye" then
            return
        end
        self.db = LibStub("AceDB-3.0"):New("RaidEye_DB", self.defaults, true)
        self:upgradeDB()
        for playerName, spells in pairs(self.db.global.CDs) do
            for spellID, cd in pairs(spells) do
                if not cd.timestamp or cd.timestamp < time() then
                    table.wipe(self.db.global.CDs[playerName][spellID])
                end
            end
        end
        for childSpellID, childSpellConfig in pairs(self.spells) do
            if childSpellConfig.parent then
                childSpells[childSpellConfig.parent] = childSpellID
            end
        end
        for i = 1, groups do
            self:getGroup(i)
        end
        self.db.RegisterCallback(self, "OnProfileChanged", "loadProfile")
        self.db.RegisterCallback(self, "OnProfileCopied", "loadProfile")
        self.db.RegisterCallback(self, "OnProfileReset", "loadProfile")
        self:OptionsPanel()
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("UNIT_SPELLCAST_SENT")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED")
        self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self:RegisterEvent("RAID_ROSTER_UPDATE")
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN") -- Регистрация нового события
        if not playerInRaid then
            self:RegisterEvent("PARTY_MEMBERS_CHANGED")
        end
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("INSPECT_READY")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("PLAYER_REGEN_DISABLED")
        
        -- Инициализация системы сетовых бонусов
        self:InitSetBonuses()

        -- Интеграция с DBM для отслеживания энкаунтеров
        if DBM then
            DBM:RegisterCallback("kill", function(mod)
                RaidEye:OnEncounterEnd("kill")
            end)
            DBM:RegisterCallback("wipe", function(mod)
                RaidEye:OnEncounterEnd("wipe")
            end)
        end

        -- Интеграция с BigWigs (альтернатива DBM)
        if BigWigsLoader then
            BigWigsLoader.RegisterMessage(RaidEye, "BigWigs_OnBossWin", function()
                RaidEye:OnEncounterEnd("kill")
            end)
            BigWigsLoader.RegisterMessage(RaidEye, "BigWigs_OnBossWipe", function()
                RaidEye:OnEncounterEnd("wipe")
            end)
        end

        self.LibGroupTalents.RegisterCallback(self, "LibGroupTalents_Update")
        self.LibGroupTalents.RegisterCallback(self, "LibGroupTalents_RoleChange")
        for k, _ in pairs(self.comms) do
            if self.db.global.comms[k] then
                self:RegisterComm(k)
            end
        end
        self:ScheduleRepeatingTimer(function()
            for playerName, _ in pairs(self.deadUnits) do
                if not UnitIsDeadOrGhost(playerName) or (not UnitInRaid(playerName) and not UnitInParty(playerName)) then
                    self.deadUnits[playerName] = nil
                end
            end
            for i = 1, #self.groups do
                for j = 1, #self.groups[i].CooldownFrames do
                    self:setTimerColor(self.groups[i].CooldownFrames[j])
                    self:updateRange(self.groups[i].CooldownFrames[j])
                end
            end
            -- Очистка устаревших данных прерываний
            self:cleanupInterruptData()
        end, 1)
        
        -- Обработка очереди инспекта (каждые 2 секунды)
        self:ScheduleRepeatingTimer(function()
            self:ProcessInspectQueue()
        end, 2)
    end
end)


function RaidEye:OnCommReceived(...)
    local prefix, message, _, sender = ...

    if not self.db.global.comms[prefix] then
        return
    end

    if sender == (UnitName("player")) then
        return
    end

    local success, messageType, spellID, spellName, playerName, CDLeft, target
    if prefix == "oRA3" then
        success, messageType, spellID, CDLeft, target = self:Deserialize(message)

        if not success then
            return
        end

        if type(messageType) ~= "string" or messageType ~= "Cooldown" then
            return
        end
    elseif prefix == "BLT" then
        if not string.find(message, ":") then
            return
        end

        messageType, message = strsplit(":", message)
        if messageType ~= "CD" then
            return
        end

        if not string.find(message, ";") then
            return
        end

        playerName, spellName, spellID, target = strsplit(";", message)
    elseif prefix == "oRA" or prefix == "CTRA" then
        spellID, CDLeft = select(3, message:find("CD (%d) (%d+)"))
    elseif prefix == "RCD2" then
        spellID, CDLeft = select(3, message:find("(%d+) (%d+)"))
    elseif prefix == "FRCD3S" then
        spellID, playerName, CDLeft, target = select(3, message:find("(%d+)(%a+)(%d+)(%a*)"))
    elseif prefix == "FRCD3" then
        playerName = tostring(sender)
        if not UnitInRaid(playerName) and not UnitInParty(playerName) then
            return
        end

        for w in string.gmatch(message, "([^,]*),") do
            spellID, CDLeft = select(3, w:find("(%d+)-(%d+)"))
            spellID = tonumber(spellID)
            CDLeft = tonumber(CDLeft)

            if not spellID or not CDLeft then
                return
            end

            if not self.spells[spellID] then
                spellName = GetSpellInfo(spellID)
                if spellName then
                    spellID = self.localizedSpellNames[spellName]
                end
            end

            self:setCooldown(spellID, playerName, CDLeft, nil, true)
        end
        return
    elseif prefix == "RaidEye" then
        success, spellID, playerName, target = self:Deserialize(message)
        if not success then
            return
        end
    end

    if not spellID then
        return
    end

    playerName = playerName and tostring(playerName) or sender

    if not UnitInRaid(playerName) and not UnitInParty(playerName) then
        return
    end

    spellID = tonumber(spellID)

    CDLeft = CDLeft and tonumber(CDLeft)

    if not CDLeft then
        CDLeft = true
    elseif CDLeft <= 0 and not self:getSpellAlwaysShow(spellID) then
        return
    end

    if prefix == "oRA" then
        if spellID == 1 then
            spellID = 48477 -- Rebirth
        elseif spellID == 2 then
            spellID = 21169 -- Reincarnation
        elseif spellID == 3 then
            spellID = 47883 -- Soulstone Resurrection
        elseif spellID == 4 then
            spellID = 19752 -- Divine Intervention
        end
    elseif prefix == "BLT" then
        if spellID == 57934 then
            spellID = 59628
        elseif spellID == 34477 then
            spellID = 35079
        end
    end

    if not self.spells[spellID] then
        if not spellName then
            spellName = GetSpellInfo(spellID)
        end
        if spellName then
            spellID = self.localizedSpellNames[spellName]
        end
    end

    if prefix == "RCD2" and CDLeft == 0 and not self:UnitHasAbility(playerName, spellID) then
        return
    end

    if target then
        if target == "" then
            target = nil
        else
            target = tostring(target)
        end
    end

    self:setCooldown(spellID, playerName, CDLeft, target, true)
end

--- Обновляет визуальный индикатор режима баффа (для напула)
---@param frame table
function RaidEye:updateBuffIndicator(frame)
    if not frame.buffIndicator then
        -- Создаём текстовый индикатор слева от таймера
        frame.buffIndicator = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local font, size = frame.timerFontString:GetFont()
        frame.buffIndicator:SetFont(font, size)
        frame.buffIndicator:SetPoint("RIGHT", frame.timerFontString, "LEFT", -2, 0)
        frame.buffIndicator:SetTextColor(0.3, 0.8, 1, 1) -- Голубой цвет
    end
    
    if frame.isBuff then
        frame.buffIndicator:SetText("◆") -- Ромб как индикатор баффа
        frame.buffIndicator:Show()
    else
        frame.buffIndicator:SetText("")
        frame.buffIndicator:Hide()
    end
end

---@param spellID number
---@param playerName string
---@param CDLeft number|boolean|nil
---@param target string|nil
---@param isRemote boolean|nil
---@param interruptedSpellID number|nil
function RaidEye:setCooldown(spellID, playerName, CDLeft, target, isRemote, testMode, interruptedSpellID)
    if spellID == 23989 then -- Readiness хантера
        self:Readiness(playerName)
    end
    if not spellID or not self.spells[spellID] then
        return
    end
    if not isRemote and CDLeft == true then
        self:SendCommMessage("RaidEye", self:Serialize(spellID, playerName, target), "RAID")
    end
    if self.db.global.selfignore and playerName == UnitName("player") then
        return
    end
    -- Убираем проверку isSpellEnabled здесь, чтобы гарантировать создание фрейма по событию,
    -- даже если role-check его скрыл ранее. 
    -- Если спелл выключен галочкой (enable=false), он все равно не покажется, проверка ниже.
    if not self:isSpellEnabled(spellID) then 
        return 
    end

    if self.spells[spellID].parent then
        local parentSpellID = self.spells[spellID].parent
        local frame = self:getCooldownFrame(playerName, parentSpellID)
        
        -- Если это child спелл (активация напула) - переключаем в режим КД
        if frame then
            if frame.isBuff then
                -- Напул активировался! Переключаем из режима баффа в режим КД
                frame.isBuff = false
                frame.CD = self.spells[parentSpellID].cd
                frame.CDLeft = frame.CD
                frame.CDReady = GetTime() + frame.CDLeft
                
                -- Сбрасываем таймер если был
                if frame.CDtimer then
                    self:CancelTimer(frame.CDtimer)
                    frame.CDtimer = nil
                end
                
                self:setTarget(frame, target)
                self:updateBuffIndicator(frame)
                self:setBarColor(frame)
                
                -- Сохраняем в БД
                self.db.global.CDs[playerName][parentSpellID].timestamp = time() + frame.CDLeft
                self.db.global.CDs[playerName][parentSpellID].isBuff = false
                
                -- Запускаем новый таймер КД
                frame.timerFontString:SetText(date("!%M:%S", frame.CDLeft):gsub('^0+:?0?', ''))
                self:startCooldownTimer(frame, playerName, parentSpellID)
                self:updateCooldownBarProgress(frame)
                self:setTimerColor(frame)
                return
            elseif frame.CDLeft ~= 0 then
                self:setTarget(frame, target)
                return
            else
                self:removeCooldownFrames(playerName, parentSpellID)
            end
        end
        
        -- Если это parent спелл с buffDuration - создаём фрейм в режиме баффа
        if self.spells[spellID].buffDuration then
            local parentFrame = self:createCooldownFrame(playerName, parentSpellID, testMode)
            parentFrame.isBuff = true
            parentFrame.CD = self.spells[spellID].buffDuration
            parentFrame.CDLeft = parentFrame.CD
            parentFrame.CDReady = GetTime() + parentFrame.CDLeft
            
            self:setTarget(parentFrame, target)
            self:updateBuffIndicator(parentFrame)
            self:setBarColor(parentFrame)
            
            -- Сохраняем в БД
            if not self.db.global.CDs[playerName] then
                self.db.global.CDs[playerName] = {}
            end
            if not self.db.global.CDs[playerName][parentSpellID] then
                self.db.global.CDs[playerName][parentSpellID] = {}
            end
            self.db.global.CDs[playerName][parentSpellID].timestamp = time() + parentFrame.CDLeft
            self.db.global.CDs[playerName][parentSpellID].isBuff = true
            
            parentFrame.timerFontString:SetText(date("!%M:%S", parentFrame.CDLeft):gsub('^0+:?0?', ''))
            self:startCooldownTimer(parentFrame, playerName, parentSpellID)
            self:updateCooldownBarProgress(parentFrame)
            self:setTimerColor(parentFrame)
            parentFrame.initialized = true
            
            self:sortFrames(self:getSpellGroup(parentSpellID))
            return
        end
    end

    local frame = self:createCooldownFrame(playerName, spellID, testMode)

    -- === УЛУЧШЕННАЯ ЛОГИКА ИКОНОК ===
    local pendingInterrupt = self.pendingInterrupts[playerName] and self.pendingInterrupts[playerName][spellID]
    local now = GetTime()
    
    if interruptedSpellID then
        local icon = select(3, GetSpellInfo(interruptedSpellID))
        if icon then
            frame.icon:SetTexture(icon)
            frame.lastInterruptTime = now
        end
    elseif pendingInterrupt and pendingInterrupt.expireTime > now then
        frame.icon:SetTexture(pendingInterrupt.icon)
        frame.lastInterruptTime = now
        self.pendingInterrupts[playerName][spellID] = nil
    elseif not frame.lastInterruptTime or (now - frame.lastInterruptTime > INTERRUPT_ICON_DURATION) then
        frame.icon:SetTexture(select(3, GetSpellInfo(spellID)))
    end

    if CDLeft == true then
        CDLeft = self:getSpellCooldown(frame)
    end

    if not CDLeft and frame.CDLeft == 0 and self.db.global.CDs[playerName][spellID].timestamp and self.db.global.CDs[playerName][spellID].timestamp > time() then
        CDLeft = self.db.global.CDs[playerName][spellID].timestamp - time()
        target = self.db.global.CDs[playerName][spellID].target
        isRemote = true
    end

    target = self:setTarget(frame, target)

    if CDLeft then
        if frame.isRemote then
            if isRemote then
                if frame.CDLeft > 5 then
                    if CDLeft >= frame.CDLeft and CDLeft - frame.CDLeft < 5 then
                        return
                    end
                end
            else
                frame.isRemote = false
            end
        else
            if isRemote then
                if frame.CDLeft > 5 then
                    return
                end
                if CDLeft >= frame.CDLeft and CDLeft - frame.CDLeft < 5 then
                    return
                end
            else
                if CDLeft >= frame.CDLeft and CDLeft - frame.CDLeft < 2 then
                    return
                end
            end
        end
        frame.CDLeft = CDLeft
    elseif frame.initialized then
        return
    end

    if childSpells[spellID] then
        if not target then
            self:setTarget(frame, self:getTarget(playerName, childSpells[spellID]))
        end
        self:removeCooldownFrames(playerName, childSpells[spellID])
    end

    frame.CDLeft = CDLeft or frame.CDLeft
    frame.CDReady = GetTime() + frame.CDLeft
    frame.isRemote = isRemote
    frame.CD = self:getSpellCooldown(frame)

    if frame.CD < frame.CDLeft then
        frame.CD = frame.CDLeft
    end

    if not testMode then
        self.db.global.CDs[playerName][spellID].timestamp = frame.CDLeft > 0 and (time() + frame.CDLeft) or nil
    end

    if frame.CDLeft > 0 then
        frame.timerFontString:SetText(date("!%M:%S", frame.CDLeft):gsub('^0+:?0?', ''))
        self:startCooldownTimer(frame, playerName, spellID)
    elseif not self:getSpellAlwaysShow(spellID) then
        self:removeCooldownFrames(playerName, spellID, true)
        self:repositionFrames(self:getSpellGroup(spellID))
        return
    else
        frame.timerFontString:SetText("R")
        frame.target = nil
        frame.targetFontString:SetText("")
        frame.icon:SetTexture(select(3, GetSpellInfo(spellID))) -- сброс на оригинал если остаётся
        frame.lastInterruptTime = nil
    end

    self:updateCooldownBarProgress(frame)
    self:sortFrames(self:getSpellGroup(spellID))
    self:setTimerColor(frame)
    frame.initialized = true
end

-- === НОВОЕ: ПРОВЕРКА ЛОКАЛЬНОГО СБРОСА КУЛДАУНОВ ===
function RaidEye:CheckLocalReset()
    -- Если игрок недавно жал Готовность/Подготовку (2 сек задержка), не проверяем
    if GetTime() - self.lastSelfResetTime < 2 then 
        return 
    end

    local me = UnitName("player")
    local myFrames = self.frameIndex[me]
    
    if not myFrames then return end

    local resetDetected = false

    for spellID, frame in pairs(myFrames) do
        -- Проверяем только длинные кулдауны, которые еще тикают в аддоне
        -- И которые НЕ являются исключениями (как Rebirth)
        if frame.CDLeft > 30 and not self.encounterResetExceptions[spellID] then
            local start, duration = GetSpellCooldown(spellID)
            
            -- Если игра говорит, что спелл готов (start == 0) или почти готов (< 2 сек)
            -- А аддон думает, что там еще > 30 сек...
            -- Значит сервер сбросил КД
            if start == 0 or (start > 0 and duration <= 1.5) then
                resetDetected = true
                break
            end
        end
    end

    if resetDetected then
        self:OnEncounterEnd("local_reset_detected")
    end
end


function RaidEye:getCooldownFrame(playerName, spellID)
    -- Быстрый поиск через индекс
    if self.frameIndex[playerName] and self.frameIndex[playerName][spellID] then
        return self.frameIndex[playerName][spellID]
    end
    return nil
end

function RaidEye:createCooldownFrame(playerName, spellID, testMode)
    local frame = self:getCooldownFrame(playerName, spellID)

    if frame then
        return frame
    end

    local group = self:getGroup(self:getSpellGroup(spellID))
    frame = CreateFrame("Frame", nil, group)

    frame.playerName = playerName
    frame.spellID = spellID
    frame.CDLeft = 0
    frame.class = self.spells[spellID].class
    if not frame.class then
        frame.class = testMode and select(2, UnitClass("player")) or select(2, UnitClass(playerName))
    end
    frame.CD = self:getSpellCooldown(frame)
    frame.testMode = testMode
    frame.isBuff = false

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetPoint("LEFT")
    
    -- Проверяем, есть ли pending interrupt для этого спелла
    local pendingInterrupt = self.pendingInterrupts[playerName] and self.pendingInterrupts[playerName][spellID]
    if pendingInterrupt and pendingInterrupt.expireTime > GetTime() then
        frame.icon:SetTexture(pendingInterrupt.icon)
        frame.lastInterruptTime = GetTime()
    else
        frame.icon:SetTexture(select(3, GetSpellInfo(spellID)))
    end

    frame.bar = CreateFrame("Frame", nil, frame)
    frame.bar:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT")
    frame.bar:SetPoint("BOTTOMRIGHT")

    frame.bar.active = frame.bar:CreateTexture(nil, "ARTWORK")
    frame.bar.active:SetPoint("LEFT")
    frame.bar.inactive = frame.bar:CreateTexture(nil, "ARTWORK")
    frame.bar.inactive:SetPoint("RIGHT")
    frame.bar.inactive:SetPoint("LEFT", frame.bar.active, "RIGHT")

    self:updateRange(frame)

    frame.playerNameFontString = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.playerNameFontString:SetText(frame.playerName)
    frame.playerNameFontString:SetTextColor(1, 1, 1, 1)

    frame.targetFontString = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.targetFontString:SetPoint("LEFT", frame.playerNameFontString, "RIGHT", 1, 0)

    frame.timerFontString = frame.bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")

    self:applyGroupSettings(frame)

    if self.db.global.link then
        self:EnableMouse(frame)
    end

    -- Добавляем в индекс для быстрого поиска
    if not self.frameIndex[playerName] then
        self.frameIndex[playerName] = {}
    end
    self.frameIndex[playerName][spellID] = frame

    table.insert(group.CooldownFrames, frame)
    self:updateFramesVisibility(self:getSpellGroup(spellID))
    return frame
end

function RaidEye:EnableMouse(frame, disable)
    if disable then
        frame:SetScript("OnMouseDown", nil)
        frame:EnableMouse(false)
    else
        frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and (IsShiftKeyDown() or IsControlKeyDown()) then
                local message = frame.playerName .. " " .. (GetSpellLink(frame.spellID))
                if frame.CDLeft == 0 then
                    message = message .. " READY"
                else
                    if frame.target then
                        message = message .. " (" .. frame.target .. ")"
                    end
                    message = message .. " " .. date("!%M:%S", frame.CDLeft)
                end
                if IsShiftKeyDown() then
                    ChatThrottleLib:SendChatMessage("NORMAL", "RaidEye", message, playerInRaid and "RAID" or "PARTY")
                elseif IsControlKeyDown() then
                    ChatThrottleLib:SendChatMessage("NORMAL", "RaidEye", message, "WHISPER", nil, frame.playerName)
                end
            end
        end)
        frame:EnableMouse(true)
    end
end

function RaidEye:repositionFrames(groupIndex)
    if not groupIndex then
        for i = 1, #self.groups do
            self:repositionFrames(i)
        end
        return
    end
    local titleBarHeight = 0
    if self:getIProp(groupIndex, "showTitleBar") and self.groups[groupIndex].titleBar and self.groups[groupIndex].titleBar:IsShown() then
        titleBarHeight = self:getIProp(groupIndex, "titleBarHeight")
    end
    for j = 1, #self.groups[groupIndex].CooldownFrames do
        self.groups[groupIndex].CooldownFrames[j]:SetPoint("TOPLEFT", 0, -titleBarHeight - (self:getIProp(groupIndex, "iconSize") + self:getIProp(groupIndex, "padding")) * (j - 1))
    end
end

function RaidEye:loadProfile()
    for i = 1, #self.groups do
        self.groups[i].anchor:ClearAllPoints()
        self.groups[i].anchor:SetPoint(self.db.profile[i].pos.point, self.db.profile[i].pos.relativeTo, self.db.profile[i].pos.relativePoint, self.db.profile[i].pos.xOfs, self.db.profile[i].pos.yOfs)
        for j = 1, #self.groups[i].CooldownFrames do
            if i ~= self:getSpellGroup(self.groups[i].CooldownFrames[j].spellID) then
                self:moveFrameToGroup(self.groups[i].CooldownFrames[j].spellID, i, self:getSpellGroup(self.groups[i].CooldownFrames[j].spellID))
            else
                self:applyGroupSettings(self.groups[i].CooldownFrames[j])
            end
        end
    end
    self:updateRaidCooldowns()
    self:sortFrames()
end

function RaidEye:removeCooldownFrames(playerName, spellID, onlyWhenReady, startGroup, startIndex, testMode)
    if spellID then
        startGroup = self:getSpellGroup(spellID)
    end
    for i = startGroup or 1, #self.groups do
        for j = startIndex or 1, #self.groups[i].CooldownFrames do
            if (
                    self.groups[i].CooldownFrames[j].playerName == playerName
                            and (not spellID or self.groups[i].CooldownFrames[j].spellID == spellID)
                            and (not onlyWhenReady or self.groups[i].CooldownFrames[j].CDLeft <= 0)
            ) or (
                    testMode and self.groups[i].CooldownFrames[j].testMode
            ) then
                -- Удаляем из индекса
                local pName = self.groups[i].CooldownFrames[j].playerName
                local sID = self.groups[i].CooldownFrames[j].spellID
                if self.frameIndex[pName] then
                    self.frameIndex[pName][sID] = nil
                end
                
                self.groups[i].CooldownFrames[j]:Hide()
                if self.groups[i].CooldownFrames[j].CDtimer then
                    self:CancelTimer(self.groups[i].CooldownFrames[j].CDtimer)
                end
                table.remove(self.groups[i].CooldownFrames, j)
                self:updateFramesVisibility(i)
                if spellID then
                    break
                end
                return self:removeCooldownFrames(playerName, spellID, onlyWhenReady, i, j, testMode)
            end
        end

        if startIndex then
            -- reset start frame index when we proceed to next frames group
            startIndex = nil
        end
    end
end

function RaidEye:updateRaidRoster(instant, startGroup, startIndex)
    if not instant then
        if updateRaidRosterScheduleTimer then
            -- update is scheduled
            return
        end

        if updateRaidRosterTimestamp and time() - updateRaidRosterTimestamp < updateRaidRosterCooldown then
            -- update is on cooldown
            updateRaidRosterScheduleTimer = self:ScheduleTimer(function()
                updateRaidRosterScheduleTimer = nil
                self:updateRaidRoster()
            end, updateRaidRosterCooldown)
            return
        end
    end

    for i = startGroup or 1, #self.groups do
        for j = startIndex or 1, #self.groups[i].CooldownFrames do
            if not UnitInRaid(self.groups[i].CooldownFrames[j].playerName) and not UnitInParty(self.groups[i].CooldownFrames[j].playerName) or not UnitIsConnected(self.groups[i].CooldownFrames[j].playerName) then
                self:removeCooldownFrames(self.groups[i].CooldownFrames[j].playerName)
                return self:updateRaidRoster(true, i, j)
            end
        end
    end
    self:updateRaidCooldowns()
    updateRaidRosterTimestamp = time()
end

function RaidEye:updateRaidCooldowns()
    -- Запускаем фоновый инспект для определения сетовых бонусов
    self:QueueRaidInspect()
    
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local playerName, _, _, _, _, class, _, online, isDead = GetRaidRosterInfo(i)
            if isDead then
                self.deadUnits[playerName] = true
            end
            if playerName and online then
                self:refreshPlayerCooldowns(playerName, class)
            end
        end
    else
        self:refreshPlayerCooldowns((UnitName("player")))
        for i = 1, GetNumPartyMembers() do
            if UnitIsConnected("party" .. i) then
                self:refreshPlayerCooldowns((UnitName("party" .. i)))
            end
        end
    end
    self:repositionFrames()
end

function RaidEye:refreshPlayerCooldowns(playerName, class)
    if not class then
        class = select(2, UnitClass(playerName))
    end

    local groupsToReposition = {}  -- Отслеживаем группы, где были изменения

    for spellID, spellConfig in pairs(self.spells) do
        if not spellConfig.class or spellConfig.class == class then
            local shouldShow = true
            
            -- Базовые проверки
            if not self.db.profile.spells[spellID] then
                shouldShow = false
            elseif not self:isSpellEnabled(spellID) then
                shouldShow = false
            elseif not self:UnitHasAbility(playerName, spellID) then
                shouldShow = false
            elseif self:isSpellTanksOnly(spellID) and self.LibGroupTalents:GetUnitRole(playerName) ~= "tank" then
                shouldShow = false
            elseif self.db.global.selfignore and playerName == UnitName("player") then
                shouldShow = false
            elseif self.db.profile.spells[spellID].feralonly and (select(5, self.LibGroupTalents:GetTalentInfo(playerName, 2, 23)) or 0) == 0 then
                shouldShow = false
            -- Фильтр по сету
            elseif not self:PassesSetFilter(playerName, spellID) then
                shouldShow = false
            -- Improved-фильтр
            elseif not self:PassesImprovedFilter(playerName, spellID) then
                shouldShow = false
            end
            
            if shouldShow then
                if not spellConfig.parent then
                    self:setCooldown(spellID, playerName)
                end
            else
                -- Проверяем, существует ли фрейм перед удалением
                local frame = self:getCooldownFrame(playerName, spellID)
                if frame then
                    local groupIndex = self:getSpellGroup(spellID)
                    groupsToReposition[groupIndex] = true
                    self:removeCooldownFrames(playerName, spellID)
                end
            end
        end
    end
    
    -- Перестраиваем позиции в группах, где были удаления
    for groupIndex in pairs(groupsToReposition) do
        self:repositionFrames(groupIndex)
    end
end

function RaidEye:UnitHasAbility(playerName, spellID)
    if self.spells[spellID].parent then
        spellID = self.spells[spellID].parent
    end
    -- using UnitHasTalent() as GetTalentInfo() does not return correct value right after respec
    return not self.spells[spellID].talentTab or not self.spells[spellID].talentIndex or self.LibGroupTalents:UnitHasTalent(playerName, (GetSpellInfo(spellID)))
end

function RaidEye:saveFramePosition(groupIndex)
    local point, relativeTo, relativePoint, xOfs, yOfs = self.groups[groupIndex].anchor:GetPoint(0)
    self.db.profile[groupIndex].pos = {
        point = point,
        relativeTo = relativeTo and relativeTo:GetName(),
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end

function RaidEye:Readiness(hunterName)
    -- Защита от рекурсии - проверяем И устанавливаем timestamp СРАЗУ
    local now = GetTime()
    if ReadinessTimestamp[hunterName] and now - ReadinessTimestamp[hunterName] < 1 then
        return
    end
    ReadinessTimestamp[hunterName] = now

    local refreshSpellIDs = {}
    for i = 1, #self.groups do
        for j = 1, #self.groups[i].CooldownFrames do
            local frame = self.groups[i].CooldownFrames[j]
            if frame.playerName == hunterName 
               and frame.spellID ~= 34477   -- Misdirection
               and frame.spellID ~= 23989 then -- Исключаем сам Readiness!
                table.insert(refreshSpellIDs, frame.spellID)
            end
        end
    end

    for _, spellID in ipairs(refreshSpellIDs) do
        self:setCooldown(spellID, hunterName, 0)
    end
end

function RaidEye:GSProc(targetName)
    local spellGroup = self:getSpellGroup(47788)
    for i = #self.groups[spellGroup].CooldownFrames, 1, -1 do
        if self.groups[spellGroup].CooldownFrames[i].spellID == 47788
                and self.groups[spellGroup].CooldownFrames[i].target == targetName
                and self.groups[spellGroup].CooldownFrames[i].CDLeft > 0 then
            self:setCooldown(47788, self.groups[spellGroup].CooldownFrames[i].playerName, 180)
            break
        end
    end
end

function RaidEye:sortFrames(groupIndex)
    if not groupIndex then
        for i = 1, #self.groups do
            self:sortFrames(i)
        end
        return
    end

    for j = 1, #self.groups[groupIndex].CooldownFrames - 1 do
        for k = j + 1, #self.groups[groupIndex].CooldownFrames do
            if self:cooldownSorter(self.groups[groupIndex].CooldownFrames[j], self.groups[groupIndex].CooldownFrames[k]) then
                self.groups[groupIndex].CooldownFrames[j], self.groups[groupIndex].CooldownFrames[k] = self.groups[groupIndex].CooldownFrames[k], self.groups[groupIndex].CooldownFrames[j]
            end
        end
    end
    self:repositionFrames(groupIndex)
end

---cooldownSorter
---@param frame1 table cooldown frame to be moved
---@param frame2 table cooldown frame to compare against
---@return boolean true if frame1 should be below frame2
function RaidEye:cooldownSorter(frame1, frame2)
    local groupIndex = self:getSpellGroup(frame1.spellID)
    local spellId1 = self.spells[frame1.spellID].parent or frame1.spellID
    local spellId2 = self.spells[frame2.spellID].parent or frame2.spellID
    if frame1.inRange < frame2.inRange then
        if self:getIProp(groupIndex, "rangeUngroup") then
            return true
        elseif spellId1 == spellId2 and self:getIProp(groupIndex, "rangeDimout") then
            return true
        end
    elseif frame1.inRange > frame2.inRange then
        if self:getIProp(groupIndex, "rangeUngroup") or spellId1 == spellId2 then
            return
        end
    end

    if self.db.profile.spells[spellId1].priority < self.db.profile.spells[spellId2].priority then
        return true
    elseif spellId1 == spellId2 then
        if frame1.CDLeft > frame2.CDLeft then
            return true
        end
    elseif self.db.profile.spells[spellId1].priority == self.db.profile.spells[spellId2].priority and spellId1 < spellId2 then
        -- attempt to group spells by ID
        return true
    end
end

function RaidEye:getGroup(i)
    i = i or 1
    if self.groups[i] then
        return self.groups[i]
    end
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:ClearAllPoints()

    frame.anchor = CreateFrame("Frame", nil, frame)
    frame.anchor:SetClampedToScreen(true)
    frame.anchor:SetSize(20, 20)
    frame.anchor:SetPoint(self.db.profile[i].pos.point, self.db.profile[i].pos.relativeTo, self.db.profile[i].pos.relativePoint, self.db.profile[i].pos.xOfs, self.db.profile[i].pos.yOfs)
    frame.anchor:SetFrameStrata("HIGH")
    frame.anchor:SetMovable(true)
    frame.anchor:RegisterForDrag("LeftButton")
    frame.anchor:SetScript("OnDragStart", function(s)
        s:StartMoving()
    end)
    frame.anchor:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        self:saveFramePosition(i)
    end)
    frame.anchor:EnableMouse(true)

    frame:SetAllPoints(frame.anchor)

    -- Create title bar
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetHeight(self:getIProp(i, "titleBarHeight"))
    frame.titleBar:SetWidth(self:getIProp(i, "frameWidth"))
    frame.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

    -- Enable dragging on title bar
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function()
        frame.anchor:StartMoving()
    end)
    frame.titleBar:SetScript("OnDragStop", function()
        frame.anchor:StopMovingOrSizing()
        self:saveFramePosition(i)
    end)

    -- Visual feedback when hovering over title bar
    frame.titleBar:SetScript("OnEnter", function(s)
        local bgColor = self:getIProp(i, "titleBackgroundColor")
        s.bg:SetVertexColor(bgColor[1] * 1.2, bgColor[2] * 1.2, bgColor[3] * 1.2, bgColor[4])
    end)
    frame.titleBar:SetScript("OnLeave", function(s)
        local bgColor = self:getIProp(i, "titleBackgroundColor")
        s.bg:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    end)

    -- Title background (optional)
    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints(frame.titleBar)
    frame.titleBar.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    local bgColor = self:getIProp(i, "titleBackgroundColor")
    frame.titleBar.bg:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    -- Title text
    frame.titleBar.text = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleBar.text:SetPoint("LEFT", frame.titleBar, "LEFT", 2, 0)
    frame.titleBar.text:SetPoint("RIGHT", frame.titleBar, "RIGHT", -2, 0)
    frame.titleBar.text:SetJustifyH("LEFT")
    local titleText = self:getIProp(i, "titleText")
    local displayText = titleText ~= "" and titleText or ("Group " .. i)
    frame.titleBar.text:SetText(displayText)
    frame.titleBar.text:SetTextColor(1, 1, 1, 1)
    local font = frame.titleBar.text:GetFont()
    frame.titleBar.text:SetFont(font, self:getIProp(i, "titleFontSize"))

    -- Show/hide title bar based on settings
    if self:getIProp(i, "showTitleBar") then
        frame.titleBar:Show()
    else
        frame.titleBar:Hide()
    end

    frame.CooldownFrames = {}

    frame:Hide()

    table.insert(self.groups, frame)
    return frame
end

---@param playerName string
---@param spellID number
function RaidEye:getCDLeft(playerName, spellID)
    for i = 1, #self.groups[self:getSpellGroup(spellID)].CooldownFrames do
        if playerName == self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].playerName
                and spellID == self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].spellID then
            return self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].CDLeft
        end
    end
    return 0
end

function RaidEye:getTarget(playerName, spellID)
    for i = 1, #self.groups[self:getSpellGroup(spellID)].CooldownFrames do
        if playerName == self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].playerName
                and spellID == self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].spellID then
            return self.groups[self:getSpellGroup(spellID)].CooldownFrames[i].target
        end
    end
end

function RaidEye:setTarget(frame, target)
    -- Проверяем, нужно ли показывать цель
    if not self:ShouldShowTarget(frame.spellID) then
        frame.targetFontString:SetText("")
        frame.targetFontString:Hide()
        return
    end
    
    -- Показываем targetFontString если он был скрыт
    frame.targetFontString:Show()
    
    if not target or target == frame.target or self.spells[frame.spellID].notarget then
        return
    end
    if self.spells[frame.spellID].noself and target == frame.playerName then
        return
    end
    frame.target = target
    self.db.global.CDs[frame.playerName][frame.spellID].target = target
    frame.targetFontString:SetText(target)
    local class = select(2, UnitClass(target))
    if class then
        local targetClassColor = RAID_CLASS_COLORS[class]
        frame.targetFontString:SetTextColor(targetClassColor.r, targetClassColor.g, targetClassColor.b, 1)
    end
    return target
end

function RaidEye:updateRange(frame)
    if not frame.inRange then
        if frame.testMode then
            frame.inRange = (random(1, 100) <= 80) and 1 or 0
        else
            frame.inRange = self:UnitInRange(frame.playerName) and 1 or 0
        end

        self:setBarColor(frame)
        self:sortFrames()
    elseif not frame.testMode then
        if frame.inRange == 1 then
            if not self:UnitInRange(frame.playerName) then
                frame.inRange = 0
                if self:getIPropBySpellId(frame.spellID, "rangeDimout") then
                    self:setBarColor(frame)
                end
                self:sortFrames()
            end
        elseif self:UnitInRange(frame.playerName) then
            frame.inRange = 1
            if self:getIPropBySpellId(frame.spellID, "rangeDimout") then
                self:setBarColor(frame)
            end
            self:sortFrames()
        end
    end
end

---@param frame
function RaidEye:setBarColor(frame)
    local opacity = self:getIPropBySpellId(frame.spellID, "opacity")
    
    if frame.isBuff then
        -- Режим баффа (ожидание активации) - голубоватый цвет
        if frame.inRange == 1 or not self:getIPropBySpellId(frame.spellID, "rangeDimout") then
            frame.bar.active:SetVertexColor(0.3, 0.7, 1.0, opacity) -- Голубой
        else
            frame.bar.active:SetVertexColor(0.3, 0.4, 0.5, opacity) -- Приглушённый голубой
        end
    elseif frame.inRange == 1 or not self:getIPropBySpellId(frame.spellID, "rangeDimout") then
        local playerClassColor = RAID_CLASS_COLORS[frame.class]
        frame.bar.active:SetVertexColor(playerClassColor.r, playerClassColor.g, playerClassColor.b, opacity)
    else
        frame.bar.active:SetVertexColor(0.5, 0.5, 0.5, opacity)
    end
end

function RaidEye:setTimerColor(frame)
    if self.deadUnits[frame.playerName] then
        frame.timerFontString:SetTextColor(1, 0, 0, 1)
    elseif frame.isBuff then
        -- Режим баффа - голубой цвет таймера
        frame.timerFontString:SetTextColor(0.3, 0.8, 1, 1)
    elseif frame.CDLeft <= 0 then
        if self.db.profile.spells[frame.spellID].alwaysShow then
            frame.timerFontString:SetTextColor(0, 1, 0, 1)
        end
    else
        frame.timerFontString:SetTextColor(0.9, 0.7, 0, 1)
    end
end

function RaidEye:getSpellCooldown(frame)
    local CDmodifier = 0
    if frame.spellID == 498 or frame.spellID == 642 then
        -- Divine Shield and Divine Protection
        CDmodifier = -30 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 2, 14)) or 0)
    elseif frame.spellID == 10278 then
        -- HoP
        CDmodifier = -60 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 2, 4)) or 0)
    elseif frame.spellID == 48788 then
        -- Lay on Hands
        CDmodifier = -120 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 1, 8)) or 0)
        if self:UnitHasGlyph(frame.playerName, 57955) then
            CDmodifier = CDmodifier - 300
        end
    elseif frame.spellID == 20608 then
        -- Reincarnation
        local talentPoints = select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 3))
        if talentPoints == 1 then
            CDmodifier = -420
        elseif talentPoints == 2 then
            CDmodifier = -900
        end
    elseif frame.spellID == 871 then
        -- Shield Wall
        CDmodifier = -30 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 13)) or 0)
        if self:UnitHasGlyph(frame.playerName, 63329) then
            CDmodifier = CDmodifier - 120
        end
    elseif frame.spellID == 12975 then
        -- Last Stand
        if self:UnitHasGlyph(frame.playerName, 58376) then
            CDmodifier = CDmodifier - 60
        end
    elseif frame.spellID == 48447 then
        -- Tranquility
        local talentPoints = select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 14))
        if talentPoints == 1 then
            CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.3
        elseif talentPoints == 2 then
            CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.5
        end
    elseif frame.spellID == 47585 then
        -- Dispersion
        if self:UnitHasGlyph(frame.playerName, 63229) then
            CDmodifier = CDmodifier - 45
        end
    elseif frame.spellID == 45438 then
        -- Ice Block
        local talentPoints = select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 3))
        if talentPoints == 1 then
            CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.07
        elseif talentPoints == 2 then
            CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.14
        elseif talentPoints == 3 then
            CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.2
        end
    elseif frame.spellID == 66 or frame.spellID == 12051 then
        -- Invisibility or Evocation
        CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.15 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 1, 24)) or 0)
    elseif frame.spellID == 12292 then
        -- Death Wish
        CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.11 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 2, 18)) or 0)
    elseif frame.spellID == 10060 or frame.spellID == 33206 then
        -- Power Infusion and Pain Suppression
        CDmodifier = -(self.spells[frame.spellID] and self.spells[frame.spellID].cd or 0) * 0.1 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 1, 23)) or 0)
    elseif frame.spellID == 47788 then
        -- Guardian spirit
        if frame.CDLeft > self.spells[frame.spellID].cd then
            return 180
        end
        if not self:UnitHasGlyph(frame.playerName, 63231, true) then
            return 180
        end
    elseif frame.spellID == 42650 then
        -- Army of the Dead
        CDmodifier = -120 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 13)) or 0)
    elseif frame.spellID == 5209 then
        -- Вызывающий рев
        if self:UnitHasGlyph(frame.playerName, 57858) then
                CDmodifier = CDmodifier - 30
        end
    elseif frame.spellID == 33357 then
        -- Порыв
        if self:UnitHasGlyph(frame.playerName, 59219) then
                CDmodifier = CDmodifier - 36
        end
    elseif frame.spellID == 53201 then
        -- Звездопад
        if self:UnitHasGlyph(frame.playerName, 54828) then
                CDmodifier = CDmodifier - 30
        end
    elseif frame.spellID == 8983 then
        -- Оглушение
        CDmodifier = -15 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 2, 13)) or 0)
    elseif frame.spellID == 2565 then
        -- Блок щитом
        CDmodifier = -10 * (select(5, self.LibGroupTalents:GetTalentInfo(frame.playerName, 3, 8)) or 0)
    --[[elseif frame.spellID == 1680 then
        -- Вихрь
        if self:UnitHasGlyph(frame.playerName, 54828) then
                CDmodifier = CDmodifier - 2
        end   --]]
    end

    -- Учёт сетовых бонусов
    local setBonusReduction = self:GetSetBonusCDReduction(frame.playerName, frame.spellID)
    if setBonusReduction > 0 then
        CDmodifier = CDmodifier - setBonusReduction
    end

    return self.spells[frame.spellID].cd + CDmodifier
end

function RaidEye:cacheLocalizedSpellNames()
    for spellID, _ in pairs(self.spells) do
        local spellName = GetSpellInfo(spellID)
        self.localizedSpellNames[spellName] = spellID
    end
end

function RaidEye:getSpellGroup(spellID)
    return self.spells[spellID].parent and self.db.profile.spells[self.spells[spellID].parent].group or self.db.profile.spells[spellID].group
end

function RaidEye:applyGroupSettings(frame, groupIndex)
    groupIndex = groupIndex or self:getSpellGroup(frame.spellID)

    frame:SetParent(self:getGroup(groupIndex))

    self:setFrameHeight(frame, self:getIProp(groupIndex, "iconSize"))
    frame:SetWidth(self:getIProp(groupIndex, "frameWidth"))
    frame.playerNameFontString:SetFont(self.LibSharedMedia:Fetch("font", self:getIProp(groupIndex, "fontPlayer")), self:getIProp(groupIndex, "fontSize"))
    frame.targetFontString:SetFont(self.LibSharedMedia:Fetch("font", self:getIProp(groupIndex, "fontTarget")), self:getIProp(groupIndex, "fontSizeTarget"))
    frame.targetFontString:SetJustifyH(self:getIProp(groupIndex, "targetJustify") == "l" and "LEFT" or "RIGHT")
    self:setBarTexture(frame, self.LibSharedMedia:Fetch("statusbar", self:getIProp(groupIndex, "statusbar")))
    self:setBarColor(frame)
    frame.bar.inactive:SetVertexColor(unpack(self:getIProp(groupIndex, "background")))
    frame.timerFontString:SetFont(self.LibSharedMedia:Fetch("font", self:getIProp(groupIndex, "fontTimer")), self:getIProp(groupIndex, "fontSizeTimer"))
    self:setTimerPosition(frame)
end

function RaidEye:setSpellGroupIndex(spellID, groupIndex)
    if self.db.profile.spells[spellID].group == groupIndex then
        return
    end
    self:moveFrameToGroup(spellID, self.db.profile.spells[spellID].group, groupIndex)
    self:sortFrames(self.db.profile.spells[spellID].group)
    self:sortFrames(groupIndex)
    self.db.profile.spells[spellID].group = groupIndex
end

function RaidEye:moveFrameToGroup(spellID, sourceGroupIndex, destGroupIndex, startIndex)
    for i = startIndex or 1, #self.groups[sourceGroupIndex].CooldownFrames do
        if spellID == self.groups[sourceGroupIndex].CooldownFrames[i].spellID then
            local frame = table.remove(self.groups[sourceGroupIndex].CooldownFrames, i)
            self:updateFramesVisibility(sourceGroupIndex)
            self:applyGroupSettings(frame, destGroupIndex)
            table.insert(self.groups[destGroupIndex].CooldownFrames, frame)
            self:updateFramesVisibility(destGroupIndex)
            return self:moveFrameToGroup(spellID, sourceGroupIndex, destGroupIndex, i)
        end
    end
end

function RaidEye:UnitInRange(unit)
    return select(2, self.LibRangeCheck:GetRange(unit))
end

function RaidEye:updateCooldownBarProgress(frame)
    local pct = frame.CDLeft / frame.CD
    if self:getIPropBySpellId(frame.spellID, "invertColors") then
        if pct ~= 0 then
            if not frame.bar.active:IsShown() then
                frame.bar.active:Show()
                frame.bar.inactive:SetPoint("LEFT", frame.bar.active, "RIGHT")
            end
            frame.bar.active:SetWidth((self:getIPropBySpellId(frame.spellID, "frameWidth") - self:getIPropBySpellId(frame.spellID, "iconSize")) * pct)
        elseif frame.bar.active:IsShown() then
            frame.bar.active:Hide()
            frame.bar.inactive:SetPoint("LEFT", frame.icon, "RIGHT")
        end
    else
        if pct ~= 1 then
            if not frame.bar.active:IsShown() then
                frame.bar.active:Show()
                frame.bar.inactive:SetPoint("LEFT", frame.bar.active, "RIGHT")
            end
            frame.bar.active:SetWidth((self:getIPropBySpellId(frame.spellID, "frameWidth") - self:getIPropBySpellId(frame.spellID, "iconSize")) * (1 - pct))
        elseif frame.bar.active:IsShown() then
            frame.bar.active:Hide()
            frame.bar.inactive:SetPoint("LEFT", frame.icon, "RIGHT")
        end
    end
end

function RaidEye:setTimerPosition(frame)
    frame.timerFontString:ClearAllPoints()
    if self:getIPropBySpellId(frame.spellID, "timerPosition") == "l" then
        frame.timerFontString:SetPoint("LEFT", frame.icon, "RIGHT", 1, 0)
        frame.playerNameFontString:SetPoint("LEFT", frame.timerFontString, "RIGHT", 2, 0)
        frame.targetFontString:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    else
        frame.timerFontString:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
        frame.playerNameFontString:SetPoint("LEFT", frame.icon, "RIGHT", 1, 0)
        frame.targetFontString:SetPoint("RIGHT", frame.timerFontString, "LEFT", -1, 0)
    end
end

function RaidEye:getSpellAlwaysShow(spellID)
    return self.spells[spellID]
            and self.spells[spellID].parent
            and self.db.profile.spells[self.spells[spellID].parent].alwaysShow
            or self.db.profile.spells[spellID].alwaysShow
end

function RaidEye:isSpellEnabled(spellID)
    return self.spells[spellID].parent and self.db.profile.spells[self.spells[spellID].parent].enable or self.db.profile.spells[spellID].enable
end

function RaidEye:isSpellTanksOnly(spellID)
    return self.spells[spellID].parent and self.db.profile.spells[self.spells[spellID].parent].tanksonly or self.db.profile.spells[spellID].tanksonly
end

function RaidEye:Rebirth(event, playerName, target)
    if event == "UNIT_SPELLCAST_SENT" then
        self.RebirthTargets[playerName] = target
    elseif event == "UNIT_SPELLCAST_FAILED" then
        self.RebirthTargets[playerName] = nil
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        self:setCooldown(48477, playerName, true, self.RebirthTargets[playerName])
        self.RebirthTargets[playerName] = nil
    end
end

function RaidEye:UnitHasGlyph(unit, glyphID, default)
    if self.LibGroupTalents:UnitHasGlyph(unit, glyphID) then
        return true
    end
    if not default then
        return false
    end
    local a, b, c, d, e, f = self.LibGroupTalents:GetUnitGlyphs(unit)
    if a or b or c or d or e or f then
        -- checking if any glyph info exists to make sure glyph info was actually fetched
        return false
    end
    -- assume player has glyph if glyph info is empty and default=true
    return true
end

function RaidEye:setBarTexture(frame, texture)
    frame.bar.active:SetTexture(texture)
    frame.bar.inactive:SetTexture(texture)
end

function RaidEye:setFrameHeight(frame, height)
    if not height then
        height = self:getIPropBySpellId(frame.spellID, "iconSize")
    end
    frame:SetHeight(height)
    frame.icon:SetSize(height, height)
    frame.bar.active:SetHeight(height)
    frame.bar.inactive:SetHeight(height)
    self:updateCooldownBarProgress(frame)
end

---getIProp
---@param frameId number frame group number
---@param propertyName string property name to get
function RaidEye:getIProp(frameId, propertyName)
    -- Title bar properties are never inherited - always use the specific group's settings
    local titleBarProperties = {
        showTitleBar = true,
        titleText = true,
        titleBarHeight = true,
        titleFontSize = true,
        titleBackgroundColor = true
    }

    if titleBarProperties[propertyName] then
        return self.db.profile[frameId][propertyName]
    else
        return self.db.profile[self.db.profile[frameId].inherit or frameId][propertyName]
    end
end

function RaidEye:getIPropBySpellId(spellId, propertyName)
    return self:getIProp(self:getSpellGroup(spellId), propertyName)
end

function RaidEye:updateFramesVisibility(groupIndex)
    if groupIndex then
        if self.groups[groupIndex]:IsShown() then
            if #self.groups[groupIndex].CooldownFrames == 0
                    or (self.db.global.hidesolo and not playerInRaid and GetNumPartyMembers() == 0) then
                self.groups[groupIndex]:Hide()
            end
        elseif #self.groups[groupIndex].CooldownFrames ~= 0
                and (not self.db.global.hidesolo or playerInRaid or GetNumPartyMembers() ~= 0) then
            self.groups[groupIndex]:Show()
        end

        return
    end

    for i = 1, #self.groups do
        self:updateFramesVisibility(i)
    end
end

function RaidEye:setTestMode(enable)
    self.db.global.testMode = enable
    if enable then
        for spellId, _ in pairs(self.db.profile.spells) do
            if self.spells[spellId] then
                -- Create test cooldown with varying times
                local testCDLeft = random(1, 5) * 10
                self:setCooldown(spellId, "Test frame", testCDLeft, nil, nil, true)
            end
        end
    else
        -- Remove all test frames
        self:removeCooldownFrames(nil, nil, nil, nil, nil, true)
    end

    self:repositionFrames()
end

function RaidEye:AddGroup()
    local newIndex = #self.groups + 1
    self:getGroup(newIndex)
    -- Обновляем настройки, чтобы ползунки узнали о новой группе
    self:OptionsPanel()
    -- Сообщение пользователю
    print("|cff00ff00RaidEye:|r Добавлена новая панель: " .. newIndex)
end

--- Отслеживает недавние касты для связывания с прерываниями
---@param playerName string
---@param spellID number
function RaidEye:trackRecentCast(playerName, spellID)
    if not self.recentCasts[playerName] then
        self.recentCasts[playerName] = {}
    end
    self.recentCasts[playerName][spellID] = GetTime()
end

--- Обработка прерывания для известного спелла
---@param spellID number ID спелла-прерывания
---@param playerName string
---@param targetName string
---@param interruptedIcon string|nil текстура сбитого заклинания
function RaidEye:handleInterrupt(spellID, playerName, targetName, interruptedIcon)
    if interruptedIcon then
        if not self.pendingInterrupts[playerName] then
            self.pendingInterrupts[playerName] = {}
        end
        self.pendingInterrupts[playerName][spellID] = {
            icon = interruptedIcon,
            expireTime = GetTime() + INTERRUPT_ICON_DURATION
        }
    end
    
    self:setCooldown(spellID, playerName, true, targetName)
end

--- Обработка прерывания для неизвестного спелла (станы и т.п.)
---@param playerName string
---@param interruptedIcon string|nil
---@return boolean found - нашли ли подходящий фрейм
function RaidEye:handleUnknownInterrupt(playerName, interruptedIcon)
    if not interruptedIcon then return false end
    
    local now = GetTime()
    local bestMatch = nil
    local bestTimeDiff = CAST_INTERRUPT_WINDOW
    
    -- Ищем недавний каст этого игрока
    if self.recentCasts[playerName] then
        for spellID, castTime in pairs(self.recentCasts[playerName]) do
            local timeDiff = now - castTime
            if timeDiff >= 0 and timeDiff < bestTimeDiff then
                -- Проверяем, что фрейм существует и на кулдауне
                local frame = self:getCooldownFrame(playerName, spellID)
                if frame and frame.CDLeft > 0 then
                    bestMatch = spellID
                    bestTimeDiff = timeDiff
                end
            end
        end
    end
    
    if bestMatch then
        if not self.pendingInterrupts[playerName] then
            self.pendingInterrupts[playerName] = {}
        end
        self.pendingInterrupts[playerName][bestMatch] = {
            icon = interruptedIcon,
            expireTime = now + INTERRUPT_ICON_DURATION
        }
        
        local frame = self:getCooldownFrame(playerName, bestMatch)
        if frame then
            frame.icon:SetTexture(interruptedIcon)
            frame.lastInterruptTime = now
        end
        return true
    end
    
    return false
end

--- Очистка устаревших данных прерываний
function RaidEye:cleanupInterruptData()
    local now = GetTime()
    
    -- Очистка pendingInterrupts (вложенная структура)
    for playerName, spells in pairs(self.pendingInterrupts) do
        for spellID, data in pairs(spells) do
            if data.expireTime < now then
                spells[spellID] = nil
            end
        end
        -- Удаляем пустые таблицы игроков
        if not next(spells) then
            self.pendingInterrupts[playerName] = nil
        end
    end
    
    -- Очистка pendingInterruptsByPlayer (старше 1 секунды)
    for playerName, data in pairs(self.pendingInterruptsByPlayer) do
        if now - data.time > 1 then
            self.pendingInterruptsByPlayer[playerName] = nil
        end
    end
    
    -- Очистка recentCasts (старше 5 секунд)
    for playerName, casts in pairs(self.recentCasts) do
        for spellID, castTime in pairs(casts) do
            if now - castTime > 5 then
                casts[spellID] = nil
            end
        end
        if not next(casts) then
            self.recentCasts[playerName] = nil
        end
    end
end


function RaidEye:RemoveLastGroup()
    local index = #self.groups
    if index <= 2 then 
        print("|cffff0000RaidEye:|r Нельзя удалить последние 2 панели.")
        return 
    end

    -- Переносим все заклинания с этой группы на 1-ю, чтобы они не пропали
    for spellID, spellConfig in pairs(self.db.profile.spells) do
        if spellConfig.group == index then
            spellConfig.group = 1
        end
    end

    -- Скрываем фрейм
    if self.groups[index] then
        self.groups[index]:Hide()
        -- Очищаем настройки позиционирования для этой группы
        self.db.profile[index] = nil
    end

    -- Удаляем из таблицы
    table.remove(self.groups, index)

    -- Обновляем интерфейс и настройки
    self:updateRaidCooldowns()
    self:OptionsPanel()
    
    print("|cff00ff00RaidEye:|r Панель " .. index .. " удалена. Заклинания перенесены на Панель 1.")
end

--- Обработка окончания энкаунтера (килл/вайп)
--- Сбрасывает все кулдауны кроме исключений
---@param reason string причина сброса: "kill", "wipe", "combat_end"
function RaidEye:OnEncounterEnd(reason)
    -- Проверяем, что мы в группе или рейде
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    
    if not inRaid and not inParty then 
        return 
    end
    
    -- Проверяем, что мы в инстансе (рейд или данж)
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "raid" and instanceType ~= "party") then 
        return 
    end
    
    -- Защита от повторных вызовов
    if self.lastEncounterEndTime and (GetTime() - self.lastEncounterEndTime) < 5 then
        return
    end
    self.lastEncounterEndTime = GetTime()
    
    local instanceName = instanceType == "raid" and "рейде" or "подземелье"
    -- print("|cff00ff00RaidEye:|r Энкаунтер завершён в " .. instanceName .. " (" .. (reason or "unknown") .. "), сброс кулдаунов...")
    
    local resetCount = 0
    
    -- Проходим по всем группам фреймов
    for i = 1, #self.groups do
        -- Идём с конца, так как можем удалять фреймы
        for j = #self.groups[i].CooldownFrames, 1, -1 do
            local frame = self.groups[i].CooldownFrames[j]
            
            if frame and frame.spellID then
                local spellID = frame.spellID
                local playerName = frame.playerName
                
                -- Проверяем, что спелл не в исключениях и на кулдауне
                if not self.encounterResetExceptions[spellID] and frame.CDLeft > 0 then
                    resetCount = resetCount + 1
                    
                    -- Останавливаем таймер
                    if frame.CDtimer then
                        self:CancelTimer(frame.CDtimer)
                        frame.CDtimer = nil
                    end
                    
                    -- Сбрасываем значения кулдауна
                    frame.CDLeft = 0
                    frame.CDReady = GetTime()
                    frame.timerText = nil
                    
                    -- Очищаем сохранённые данные в БД
                    if self.db.global.CDs[playerName] and 
                       self.db.global.CDs[playerName][spellID] then
                        table.wipe(self.db.global.CDs[playerName][spellID])
                    end
                    
                    -- Если спелл не должен показываться всегда - удаляем фрейм
                    if not self:getSpellAlwaysShow(spellID) then
                        -- Удаляем из индекса
                        if self.frameIndex[playerName] then
                            self.frameIndex[playerName][spellID] = nil
                        end
                        
                        frame:Hide()
                        table.remove(self.groups[i].CooldownFrames, j)
                        self:updateFramesVisibility(i)
                    else
                        -- Иначе показываем как Ready
                        frame.timerFontString:SetText("R")
                        frame.timerFontString:SetTextColor(0, 1, 0, 1)
                        frame.target = nil
                        frame.targetFontString:SetText("")
                        frame.icon:SetTexture(select(3, GetSpellInfo(spellID)))
                        frame.lastInterruptTime = nil
                        self:updateCooldownBarProgress(frame)
                        self:setBarColor(frame)
                    end
                end
            end
        end
    end
    
    self:repositionFrames()
    
    if resetCount > 0 then
        -- print("|cff00ff00RaidEye:|r Сброшено кулдаунов: " .. resetCount)
    end
end

--- Запускает таймер кулдауна для фрейма
---@param frame table
---@param playerName string
---@param spellID number
function RaidEye:startCooldownTimer(frame, playerName, spellID)
    if frame.CDtimer then
        self:CancelTimer(frame.CDtimer)
        frame.CDtimer = nil
    end
    
    local tick = 0.1
    frame.CDtimer = self:ScheduleRepeatingTimer(function()
        frame.CDLeft = frame.CDReady - GetTime()
        if frame.CDLeft <= 0 then
            self:CancelTimer(frame.CDtimer)
            frame.CDtimer = nil
            
            -- Если это был бафф и он истёк без активации
            if frame.isBuff then
                frame.isBuff = false
                self:updateBuffIndicator(frame)
            end
            
            if self.db.global.CDs[playerName] and self.db.global.CDs[playerName][spellID] then
                table.wipe(self.db.global.CDs[playerName][spellID])
            end
            
            if not self:getSpellAlwaysShow(spellID) then
                self:removeCooldownFrames(playerName, spellID)
                self:repositionFrames(self:getSpellGroup(spellID))
                return
            else
                if frame.CDLeft < 0 then
                    frame.CDLeft = 0
                end
                frame.timerFontString:SetText("R")
                self:setTimerColor(frame)
                frame.target = nil
                frame.targetFontString:SetText("")
                frame.icon:SetTexture(select(3, GetSpellInfo(spellID)))
                frame.lastInterruptTime = nil
            end
        elseif frame.timerText ~= floor(frame.CDLeft) then
            frame.timerText = floor(frame.CDLeft)
            frame.timerFontString:SetText(date("!%M:%S", frame.CDLeft):gsub('^0+:?0?', ''))
            self:setTimerColor(frame)
        end
        self:updateCooldownBarProgress(frame)
    end, tick)
end

---Проверяет, проходит ли спелл фильтр по сету
---@param playerName string
---@param spellID number
---@return boolean
function RaidEye:PassesSetFilter(playerName, spellID)
    local savedConfig = self.db.profile.spells[spellID]
    
    if not savedConfig then
        return true
    end
    
    -- Если сет не выбран - не фильтруем
    local requiredSet = savedConfig.requiredSet
    if not requiredSet or requiredSet == "" or requiredSet == "NONE" then
        return true
    end
    
    -- Проверяем наличие сета
    local piecesRequired = savedConfig.requiredSetPieces
    return self:HasSetBonus(playerName, requiredSet, piecesRequired)
end

---Проверяет, проходит ли спелл improved-фильтр для игрока
---@param playerName string
---@param spellID number
---@return boolean
function RaidEye:PassesImprovedFilter(playerName, spellID)
    local spellConfig = self.spells[spellID]
    local savedConfig = self.db.profile.spells[spellID]
    
    -- Если флаг improved не установлен в Spells.lua или галочка не включена - пропускаем
    if not spellConfig.improved or not savedConfig.improvedonly then
        return true
    end
    
    -- Проверяем наличие таланта-улучшения
    local talentTab = spellConfig.improvedTalentTab
    local talentIndex = spellConfig.improvedTalentIndex
    
    if talentTab and talentIndex then
        local points = select(5, self.LibGroupTalents:GetTalentInfo(playerName, talentTab, talentIndex)) or 0
        return points > 0
    end
    
    return true
end

---Проверяет, нужно ли показывать цель для спелла
---@param spellID number
---@return boolean
function RaidEye:ShouldShowTarget(spellID)
    local spellConfig = self.spells[spellID]
    local savedConfig = self.db.profile.spells[spellID]
    
    -- Если notarget в конфиге спелла - никогда не показываем
    if spellConfig.notarget then
        return false
    end
    
    -- Иначе смотрим настройку пользователя
    return savedConfig.showTarget ~= false
end


-- Команда для отладки tier-бонусов
SLASH_RAIDEYE_DEBUG1 = "/redebug"
SlashCmdList["RAIDEYE_DEBUG"] = function(msg)
    local playerName = UnitName("player")
    
    print("|cff00ff00=== RaidEye Debug ===|r")
    print("Player: " .. playerName)
    print("enableSetBonuses: " .. tostring(RaidEye.db.global.enableSetBonuses))
    
    -- Tier cache
    print("|cffff9900Tier Bonuses:|r")
    local tierCache = RaidEye.tierBonusCache[playerName]
    if tierCache then
        print("  _inspected: " .. tostring(tierCache._inspected))
        for tier, value in pairs(tierCache) do
            if tier ~= "_inspected" then
                print("  " .. tier .. ": " .. tostring(value))
            end
        end
    else
        print("  (no cache)")
    end
    
    -- Set cache
    print("|cffff9900Set Piece Counts:|r")
    local setCache = RaidEye.setBonusCache[playerName]
    if setCache then
        for setKey, count in pairs(setCache) do
            if count > 0 then
                print("  " .. setKey .. ": " .. count .. " pieces")
            end
        end
    else
        print("  (no cache)")
    end
    
    -- Check specific spell filter
    if msg and msg ~= "" then
        local spellID = tonumber(msg)
        if spellID then
            print("|cffff9900Spell " .. spellID .. " filter check:|r")
            print("  PassesTierFilter: " .. tostring(RaidEye:PassesTierFilter(playerName, spellID)))
            print("  PassesImprovedFilter: " .. tostring(RaidEye:PassesImprovedFilter(playerName, spellID)))
        end
    end
end