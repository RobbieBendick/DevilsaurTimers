local _, addon = ...
local DevilsaurTimers = LibStub("AceAddon-3.0"):GetAddon(addon.name)

function DevilsaurTimers:CreateProgressBars()
    local parentFrame = CreateFrame("Frame", "DevilsaurTimersParentFrame", UIParent)
    parentFrame:SetSize(self.db.profile.parentProgressBarDimensions.width, self.db.profile.parentProgressBarDimensions.height)
    parentFrame:SetPoint("CENTER")

    parentFrame:SetMovable(true)
    parentFrame:EnableMouse(true)
    parentFrame:RegisterForDrag("LeftButton")
    parentFrame:SetScript("OnDragStart", parentFrame.StartMoving)
    parentFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeFrame, relativePoint, x, y = self:GetPoint()
        DevilsaurTimers.db.profile.parentProgressBarFramePosition = {point, relativeFrame and relativeFrame:GetName() or nil, relativePoint, x, y}
    end)

    self.progressBars = {}

    for i, color in ipairs(self.pathColors) do
        local progressBar = CreateFrame("StatusBar", "DevilsaurProgressBar" .. i, parentFrame)
        progressBar:SetSize(self.db.profile.progressBarDimensions.width, self.db.profile.progressBarDimensions.height)
        local spacing = 25
        progressBar:SetPoint("TOP", parentFrame, "TOP", 0, -(i - 1) * spacing)

        progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        local r, g, b = self:GetColorByName("red")
        progressBar:SetStatusBarColor(r, g, b)

        progressBar:SetMinMaxValues(0, 1)
        progressBar:SetValue(1)

        local bg = progressBar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0.5)

        local nameLabel = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("RIGHT", progressBar, "RIGHT", -5, 0)
        nameLabel:SetText(color)
        nameLabel:SetTextColor(1, 1, 1)
        
        progressBar.color = color

        local timerLabel = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        timerLabel:SetPoint("LEFT", progressBar, "LEFT", 5, 0)
        timerLabel:SetTextColor(1, 1, 1)

        progressBar.timerLabel = timerLabel

        local dinoIcon = progressBar:CreateTexture(nil, "OVERLAY")
        dinoIcon:SetSize(20, 20)
        dinoIcon:SetPoint("RIGHT", progressBar, "RIGHT", 20, 0)
        dinoIcon:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_Raptor")

        progressBar.dinoIcon = dinoIcon

        progressBar:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                if IsAltKeyDown() then
                    self:UndoTimer(progressBar)
                elseif IsControlKeyDown() then
                    progressBar.isDragging = true
                    progressBar.startX = GetCursorPosition()
                    self:StartTimer(progressBar)
                else
                    self:StartTimer(progressBar)
                    self:StartFriendTimer(color)
                    self:PrintColorized(progressBar.color, string.format(
                        'Timer has been started for %s.',
                        progressBar.color:sub(1, 1):upper() .. progressBar.color:sub(2):lower()
                    ))
                end
            elseif button == "RightButton" then
                self:ResetTimer(progressBar)
                self:ResetFriendTimer(color)
                self:PrintColorized(progressBar.color, string.format(
                    'Timer has been reset for %s.',
                    progressBar.color:sub(1, 1):upper() .. progressBar.color:sub(2):lower()
                ))
            end
        end)

        progressBar:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and progressBar.isDragging then
                progressBar.isDragging = false
                progressBar.startX = nil
                local remainingTime = progressBar:GetValue()
                self:StartTimer(progressBar, remainingTime)
                self:StartFriendTimer(progressBar.color, remainingTime)

                local minutes = math.floor(progressBar:GetValue() / 60)
                local seconds = progressBar:GetValue() % 60
                self:PrintColorized(
                    progressBar.color, 
                    string.format(
                        "Timer for %s has been set to%s%s%s.",
                        progressBar.color:sub(1, 1):upper() .. progressBar.color:sub(2):lower(),
                        minutes > 0 and string.format(" %d %s", minutes, minutes == 1 and "minute" or "minutes") or "",
                        minutes > 0 and seconds > 0 and " and" or "",
                        seconds > 0 and string.format(" %d seconds", seconds) or ""
                    )
                )
            end
        end)
        progressBar:SetScript("OnUpdate", function()
            if progressBar.isDragging and IsControlKeyDown() then
                self:HandleProgressBarDrag(progressBar)
            end
        end)

        self.progressBars[progressBar.color] = progressBar
    end
end

function DevilsaurTimers:StartTimer(progressBar, optionalDuration)
    local duration = optionalDuration or (self.db.profile.respawnTimer - 1)

    if self.db.profile.timers[progressBar.color] then
        local timerData = self.db.profile.timers[progressBar.color]
        local remainingTime = timerData.duration - (GetServerTime() - timerData.startTime)
        
        if remainingTime > 0 then
            if self.db.profile.previousTimers then
                self.db.profile.previousTimers[progressBar.color] = {
                    startTime = timerData.startTime,
                    duration = timerData.duration,
                }
            end
        else
            self.db.profile.previousTimers[progressBar.color] = nil
        end
    end

    progressBar:SetMinMaxValues(0, self.db.profile.respawnTimer - 1)
    progressBar:SetValue(duration)
    progressBar:SetStatusBarColor(1, 1, 0)

    local minutes = math.floor(duration / 60)
    local seconds = duration % 60
    progressBar.timerLabel:SetText(string.format("%02d:%02d", minutes, seconds))

    if progressBar.timerTicker then
        progressBar.timerTicker:Cancel()
    end

    local currentTime = GetServerTime()
    self.db.profile.timers[progressBar.color] = {
        startTime = currentTime,
        duration = duration,
    }

    progressBar.timerTicker = C_Timer.NewTicker(1, function()
        local currentValue = progressBar:GetValue()
        if currentValue > 0 then
            progressBar:SetValue(currentValue - 1)

            local minutes = math.floor(currentValue / 60)
            local seconds = currentValue % 60
            local formattedTime = string.format("%02d:%02d", minutes, seconds)
            progressBar.timerLabel:SetText(formattedTime)
            progressBar.timer = currentValue

            self:UpdateMapTimerText(progressBar.color, formattedTime)
        else
            self:ResetTimer(progressBar)
        end
    end)

end

function DevilsaurTimers:ResetTimer(progressBar)
    if progressBar.timerTicker then
        progressBar.timerTicker:Cancel()
        progressBar.timerTicker = nil
    end

    progressBar:SetMinMaxValues(0, 1)
    progressBar:SetValue(1)

    progressBar.timerLabel:SetText("")

    progressBar:SetStatusBarColor(self:GetColorByName("red"))
    
    self.db.profile.timers[progressBar.color] = nil

    self:UpdateMapTimerText(progressBar.color, "")
end

function DevilsaurTimers:UndoTimer(progressBar)
    local previousTimerData = self.db.profile.previousTimers[progressBar.color]
    if previousTimerData and previousTimerData.duration > 0 then
        local remainingTime = previousTimerData.duration - (GetServerTime() - previousTimerData.startTime)
        local currentTimerData = self.db.profile.timers[progressBar]
        local currentRemainingTime = currentTimerData and currentTimerData.duration or 0

        if remainingTime > 0 then
            self:StartTimer(progressBar, remainingTime)
            self:StartFriendTimer(progressBar.color, remainingTime)
            self:PrintColorized(
                progressBar.color,
                string.format("%s has been changed to its previous timer.", 
                progressBar.color:sub(1, 1):upper() .. progressBar.color:sub(2):lower())
            )
        end
    end
end

function DevilsaurTimers:RestoreTimers()
    for progressBarColor, timerData in pairs(self.db.profile.timers) do
        local remainingTime = timerData.duration - (GetServerTime() - timerData.startTime)
        if remainingTime > 0 then
            local progressBar = self.progressBars[progressBarColor]
            self:StartTimer(progressBar, remainingTime)
        else
            self.db.profile.timers[progressBarColor] = nil
        end
    end
end

function DevilsaurTimers:UpdateMapTimerText(color, text)
    if self.timerTexts and self.timerTexts[color] then
        self.timerTexts[color]:SetText(text)
    end
end

function DevilsaurTimers:SetClassColor(label, class)
    local color = class and RAID_CLASS_COLORS[class] or { r = 1, g = 1, b = 1 }
    label:SetTextColor(color.r, color.g, color.b)
end

function DevilsaurTimers:AddTombstonePin(x, y, destGUID, destName, class, optionalTime)
    local tombstoneData = self.db.profile.tombstones[destGUID]
    local runBackTime = optionalTime or math.ceil(self:CalculateDistanceToGraveyard(x, y) / 8)
    local startTime = tombstoneData and tombstoneData.startTime or GetServerTime()
    local remainingTime = runBackTime - (GetServerTime() - startTime)
    local minutes, seconds = math.floor(remainingTime / 60), remainingTime % 60
    local formattedTime = (minutes < 10) and string.format("%d:%02d", minutes, seconds) or string.format("%02d:%02d", minutes, seconds)

    local tombstonePin = _G["TombstonePin"..destGUID]

    local pin = CreateFrame("Frame", "TombstonePin" .. destGUID, WorldMapFrame.ScrollContainer)
    pin:SetSize(20, 20)
    pin:SetPoint("CENTER", WorldMapFrame.ScrollContainer, "TOPLEFT", x * WorldMapFrame.ScrollContainer:GetWidth(), -y * WorldMapFrame.ScrollContainer:GetHeight())
    pin:Show()

    local icon = pin:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bone_01")

    local nameLabel = pin:CreateFontString("PinNameLabel"..destGUID, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("BOTTOM", pin, "TOP", 0, 2)
    nameLabel:SetText(destName)
    self:SetClassColor(nameLabel, class)

    local timerLabel = pin:CreateFontString("PinTimerLabel"..destGUID, "OVERLAY", "GameFontNormalSmall")
    timerLabel:SetPoint("TOP", pin, "BOTTOM", 0, -2)
    timerLabel:SetText(formattedTime)
    timerLabel:SetTextColor(1,1,1)

    self.db.profile.tombstones[destGUID] = {
        x = x, y = y, pin = pin, nameLabel = nameLabel, timerLabel = timerLabel,
        startTime = startTime, duration = tombstoneData and tombstoneData.duration and tombstoneData.duration or runBackTime, playerName = destName, class = class
    }

    self:StartTombstoneTimer(destGUID, remainingTime)
end

function DevilsaurTimers:RestoreTombstones()
    if not self.db.profile.tombstones then return end
    for guid, tombstoneData in pairs(self.db.profile.tombstones) do
        local remainingTime = tombstoneData.duration - (GetServerTime() - tombstoneData.startTime)
        if remainingTime > 0 then
            self:AddTombstonePin(tombstoneData.x, tombstoneData.y, guid, tombstoneData.playerName, tombstoneData.class)
        else
            self.db.profile.tombstones[guid] = nil
        end
    end
end

function DevilsaurTimers:HandleProgressBarDrag(progressBar)
    local cursorX = GetCursorPosition()
        
    local progressBarLeft = progressBar:GetLeft()
    local progressBarRight = progressBar:GetRight()

    local scaleX = progressBar:GetEffectiveScale() -- ui scale
    local cursorRelativePosition = (cursorX / scaleX) - progressBarLeft

    local progressBarWidth = progressBarRight - progressBarLeft

    local percentage = cursorRelativePosition / progressBarWidth

    percentage = math.min(math.max(percentage, 0), 1)

    local minDuration, maxDuration = progressBar:GetMinMaxValues()

    local newValue = percentage * (maxDuration - minDuration) + minDuration

    progressBar:SetValue(newValue)

    local remaining = math.ceil(newValue)
    local minutes = math.floor(remaining / 60)
    local seconds = remaining % 60
    progressBar.timerLabel:SetText(string.format("%02d:%02d", minutes, seconds))

    progressBar.startX = cursorX
end


function DevilsaurTimers:Toggle()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(addon.name)
    else
        InterfaceOptionsFrame_OpenToCategory(addon.name)
        InterfaceOptionsFrame_OpenToCategory(addon.name)
    end
end

function DevilsaurTimers:LoadSlashCommands()
    SLASH_DEVILSAURTIMERS1 = "/dst"
    SLASH_DEVILSAURTIMERS2 = "/devilsaur"
    SLASH_DEVILSAURTIMERS3 = "/devilsaurtimer"
    SLASH_DEVILSAURTIMERS4 = "/devilsaurtimers"
    SlashCmdList["DEVILSAURTIMERS"] = function(msg)
        self:Toggle()
    end
end

function DevilsaurTimers:RestoreProgressBarPosition()
    local frame = _G["DevilsaurTimersParentFrame"]
    if not frame then return end
    if #self.db.profile.parentProgressBarFramePosition == 0 then return end
    
    frame:ClearAllPoints()
    frame:SetPoint(unpack(self.db.profile.parentProgressBarFramePosition))
end

function DevilsaurTimers:LoadHooks()
    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        self:DrawPatrolPaths()
        local frame = _G["DevilsaurMapOverlayFrame"]
        if frame then
            frame:SetSize(WorldMapFrame.ScrollContainer:GetSize())
        end
    end)
    hooksecurefunc(WorldMapFrame.MaximizeMinimizeFrame, "Maximize", function()
        self:DrawPatrolPaths()
        local frame = _G["DevilsaurMapOverlayFrame"]
        if frame then
            frame:SetSize(WorldMapFrame.ScrollContainer:GetSize())
        end
    end)
    hooksecurefunc(WorldMapFrame.MaximizeMinimizeFrame, "Minimize", function()
        self:DrawPatrolPaths()
        local frame = _G["DevilsaurMapOverlayFrame"]
        if frame then
            frame:SetSize(WorldMapFrame.ScrollContainer:GetSize())
        end
    end)
end

function DevilsaurTimers:HandleCombatLog()
    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    local x, y = position:GetXY()
    
    local _, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
    local feignDeathSpellID = 5384
    if feignDeathSpellID == spellID then
        print('spell id is feign death: ', feignDeathSpellID == spellID)
    end


    if eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE" then
        self:HandleDevilsaurTagged(destGUID, destName)
    elseif eventType == "UNIT_DIED" then
        self:HandleDevilsaurDied(destGUID, destName, x, y)
        self:HandleEnemyPlayerDied(destGUID, destName, x, y)
    end
end

function DevilsaurTimers:HandleEnemyPlayerDied(destGUID, destName, x, y)
    if not self.targetedEnemyPlayers or not self.targetedEnemyPlayers[destGUID] then return end
    if self.targetedEnemyPlayers[destGUID].isFeigned then return end

    self:AddTombstonePin(x, y, destGUID, destName, self.targetedEnemyPlayers[destGUID].class and self.targetedEnemyPlayers[destGUID].class or nil)
end

function DevilsaurTimers:HandleDevilsaurTagged(destGUID, destName)
    if not destName or not destName:lower():find("devilsaur") then return end

    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    local x, y = position:GetXY()
    if x and y then
        if not self.taggedDevilsaurs then
            self.taggedDevilsaurs = {}
        end

        if not self.taggedDevilsaurs[destGUID] then
            self.taggedDevilsaurs[destGUID] = {
                x = x,
                y = y,
                timestamp = time(),
                guid = destGUID
            }
        end
    end
end

function DevilsaurTimers:HandleDevilsaurDied(destGUID, destName, x, y)
    if not self.db.profile.autoTimer then return end

    if not destName or not destName:lower():find("devilsaur") then return end

    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    local x, y = position:GetXY()

    if not self.deadDevilsaurs then
        self.deadDevilsaurs = {}
    end
    if self.lastDevilsaurTargeted and self.lastDevilsaurTargeted.guid and self.lastDevilsaurTargeted.guid == destGUID then
        -- use first targeted x and y instead
        x = self.lastDevilsaurTargeted.x
        y = self.lastDevilsaurTargeted.y
    end

    self.deadDevilsaurs[destGUID] = {
        x = x,
        y = y,
        timestamp = time(),
        guid = destGUID
    }

    local closestLineColor = self:FindClosestLineColor(x, y)
    
    if closestLineColor then
        local progressBar = self.progressBars[closestLineColor]
        self:StartTimer(progressBar)
        self:StartFriendTimer(closestLineColor)
        self:PrintColorized(
            closestLineColor,
            string.format("Automatically started timer for %s.", 
            closestLineColor:sub(1, 1):upper() .. closestLineColor:sub(2):lower())
        )
    end
end

function DevilsaurTimers:FindClosestLineColor(x, y)
    local closestDistance = math.huge
    local closestLineColor = nil

    for pathColor, pathPoints in pairs(self.patrolPaths) do
        for i = 1, #pathPoints - 1 do
            local x1, y1 = unpack(pathPoints[i])    
            local x2, y2 = unpack(pathPoints[i + 1])

            local distance = self:DistanceToSegment(x, y, x1, y1, x2, y2)
            if distance < closestDistance then
                closestDistance = distance
                closestLineColor = pathColor
            end
        end
    end
    return closestLineColor
end

function DevilsaurTimers:DistanceToSegment(px, py, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = math.max(0, math.min(1, t))

    local closestX = x1 + t * dx
    local closestY = y1 + t * dy

    local distX = px - closestX
    local distY = py - closestY
    return math.sqrt(distX * distX + distY * distY)
end

function DevilsaurTimers:HandleUnitTarget(_, unitWhoSwitchedTarget)
    if unitWhoSwitchedTarget ~= "player" then return end

    self:HandleDevilsaurTargeted()
    self:HandleEnemyPlayerTargeted()
end

function DevilsaurTimers:HandleEnemyPlayerTargeted()
    local targetGUID = UnitGUID("target")
    local targetName = GetUnitName("target")
    if not targetName or not targetGUID then return end

    if UnitIsFriend("player", "target") or not UnitIsPlayer("target") then return end

    if not self.targetedEnemyPlayers then
        self.targetedEnemyPlayers = {}
    end

    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    local x, y = position:GetXY()

    local _, targetClass = UnitClass("target")

    self.targetedEnemyPlayers[targetGUID] = {
        x = x,
        y = y,
        class = targetClass
    }
end

function DevilsaurTimers:HandleDevilsaurTargeted()
    if UnitIsFriend("player", "target") then return end
    if UnitIsPlayer("target") then return end
    local targetGUID = UnitGUID("target")

    local targetName = GetUnitName("target")
    if not targetName then return end

    if not targetName:find("Devilsaur") then return end
    
    -- dont override x,y positions, get the position where the user first targets the devilsaur
    if self.lastDevilsaurTargeted and self.lastDevilsaurTargeted.guid and self.lastDevilsaurTargeted.guid == targetGUID then return end

    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    local x, y = position:GetXY()

    self.lastDevilsaurTargeted = {
        x = x,
        y = y,
        guid = targetGUID,
    }
end

