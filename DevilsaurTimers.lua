local _, addon = ...
local DevilsaurTimers = LibStub("AceAddon-3.0"):GetAddon(addon.name)

function DevilsaurTimers:CreateProgressBars()
    local dinoColors = {"blue", "pink", "teal", "green", "yellow", "red"}

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

    for i, color in ipairs(dinoColors) do
        local progressBar = CreateFrame("StatusBar", "DevilsaurProgressBar" .. i, parentFrame)
        progressBar:SetSize(self.db.profile.progressBarDimensions.width, self.db.profile.progressBarDimensions.height)
        local spacing = 25
        progressBar:SetPoint("TOP", parentFrame, "TOP", 0, -(i - 1) * spacing)

        progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        local r, g, b = self:GetColorByName("red")
        progressBar:SetStatusBarColor(r, g, b)

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
        timerLabel:SetText("")
        timerLabel:SetTextColor(1, 1, 1)

        progressBar.timerLabel = timerLabel

        local dinoIcon = progressBar:CreateTexture(nil, "OVERLAY")
        dinoIcon:SetSize(20, 20)
        dinoIcon:SetPoint("RIGHT", progressBar, "RIGHT", 20, 0)
        dinoIcon:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_Raptor")

        progressBar.dinoIcon = dinoIcon

        progressBar:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                self:StartTimer(progressBar)
                self:StartFriendTimer(color)
            elseif button == "RightButton" then
                self:ResetTimer(progressBar)
                self:ResetFriendTimer(color)
            end
        end)

        self.progressBars[progressBar.color] = progressBar
    end
end

function DevilsaurTimers:RestoreTimers()
    local c = 0
    for progressBarColor, timerData in pairs(self.db.profile.timers) do
        local remainingTime = timerData.duration - (GetServerTime() - timerData.startTime)
        c = c + 1
        if remainingTime > 0 then
            local progressBar = self.progressBars[progressBarColor]
            self:StartTimer(progressBar, remainingTime)
        else
            self.db.profile.timers[progressBarColor] = nil
        end
    end
end

function DevilsaurTimers:StartTimer(progressBar, optionalDuration)
    local duration = optionalDuration or (self.db.profile.respawnTimer - 1)

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

function DevilsaurTimers:UpdateMapTimerText(color, text)
    if self.timerTexts and self.timerTexts[color] then
        self.timerTexts[color]:SetText(text)
    end
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
    hooksecurefunc(WorldMapFrame, "OnShow", function()
        self:DrawPatrolPaths()
        local frame = _G["DevilsaurMapOverlayFrame"]
        if frame then
            frame:SetSize(WorldMapFrame.ScrollContainer:GetSize())
        end
    end)
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
    local _, eventType, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID = CombatLogGetCurrentEventInfo()
    if eventType == "SPELL_DAMAGE" or eventType == "SWING_DAMAGE" or eventType == "RANGE_DAMAGE" then
        if sourceGUID == UnitGUID("player") and destName and destName:lower():find("devilsaur") then
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
    end
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

function DevilsaurTimers:HandleSkinnedDevilsaur(event, msg, ...)
    local map = C_Map.GetBestMapForUnit("player")
    if not map then return end

    local position = C_Map.GetPlayerMapPosition(map, "player")
    if not position then return end

    local ungoroMapID = 1449
    if map ~= ungoroMapID then return end

    if not msg:find("Devilsaur") then return end

    if not self.db.profile.autoTimer then return end

    if not self.lastDevilsaurTargetedGUID then return end

    local targetDino = self.taggedDevilsaurs and self.taggedDevilsaurs[self.lastDevilsaurTargetedGUID] or nil
    if not targetDino then return end

    local closestDistance = math.huge
    local closestLineColor = nil

    for pathColor, pathPoints in pairs(self.patrolPaths) do
        for i = 1, #pathPoints - 1 do
            local x1, y1 = unpack(pathPoints[i])    
            local x2, y2 = unpack(pathPoints[i + 1])

            local distance = self:DistanceToSegment(targetDino.x, targetDino.y, x1, y1, x2, y2)

            if distance < closestDistance then
                closestDistance = distance
                closestLineColor = pathColor
            end
        end
    end

    if closestLineColor then
        local progressBar = self.progressBars[closestLineColor]
        self:StartTimer(progressBar)
        self:StartFriendTimer(closestLineColor)
        self:Print("Automatically started timer for ".. closestLineColor .. ".")
    end
end

function DevilsaurTimers:HandleUnitTarget(_, unitWhoSwitchedTarget)
    if unitWhoSwitchedTarget ~= "player" then return end
    if UnitIsFriend("player", "target") then return end
    if UnitIsPlayer("target") then return end
    local targetName = GetUnitName("target")
    if not targetName then return end
    if not string.find(targetName, "Devilsaur") then return end

    self.lastDevilsaurTargetedGUID = UnitGUID("target")
end
