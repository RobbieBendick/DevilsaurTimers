local _, addon = ...
local DevilsaurTimers = LibStub("AceAddon-3.0"):GetAddon(addon.name)

function DevilsaurTimers:CreateProgressBars()
    local dinoColors = {"blue", "pink", "teal", "green", "yellow", "red"}

    local parentFrame = CreateFrame("Frame", "DevilsaurTimersParentFrame", UIParent)
    parentFrame:SetSize(200, 150)
    parentFrame:SetPoint("CENTER")

    parentFrame:SetMovable(true)
    parentFrame:EnableMouse(true)
    parentFrame:RegisterForDrag("LeftButton")
    parentFrame:SetScript("OnDragStart", parentFrame.StartMoving)
    parentFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeFrame, relativePoint, x, y = self:GetPoint()
        DevilsaurTimers.db.profile.parentFramePosition = {point, relativeFrame and relativeFrame:GetName() or nil, relativePoint, x, y}
    end)

    self.progressBars = {}

    for i, color in ipairs(dinoColors) do
        local progressBar = CreateFrame("StatusBar", "DevilsaurProgressBar" .. i, parentFrame)
        progressBar:SetSize(200, 20)
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
                self:TriggerFriendTimers(progressBar.color)
            elseif button == "RightButton" then
                self:ResetTimer(progressBar)
                self:ResetFriendTimers(progressBar.color)
            end
        end)

        self.progressBars[color] = progressBar
    end
end

function DevilsaurTimers:StartTimer(progressBar)
    local duration = self.db.profile.respawnTimer - 1

    progressBar:SetMinMaxValues(0, duration)
    progressBar:SetValue(duration)
    progressBar:SetStatusBarColor(1, 1, 0)

    local minutes = math.floor(duration / 60)
    local seconds = duration % 60
    progressBar.timerLabel:SetText(string.format("%02d:%02d", minutes, seconds))

    if progressBar.timerTicker then
        progressBar.timerTicker:Cancel()
    end

    progressBar.timerTicker = C_Timer.NewTicker(1, function()
        local currentValue = progressBar:GetValue()
        if currentValue > 0 then
            progressBar:SetValue(currentValue - 1)

            local minutes = math.floor(currentValue / 60)
            local seconds = currentValue % 60
            progressBar.timerLabel:SetText(string.format("%02d:%02d", minutes, seconds))
            progressBar.timer = currentValue

            -- update minimap text
            if self.timerTexts and self.timerTexts[progressBar.color] then
                self.timerTexts[progressBar.color]:SetText(string.format("%02d:%02d", minutes, seconds))
            end
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

    local r, g, b = self:GetColorByName("red")
    progressBar:SetStatusBarColor(r, g, b)
    
    -- update minimap text
    if self.timerTexts and self.timerTexts[progressBar.color] then
        self.timerTexts[progressBar.color]:SetText("")
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

function DevilsaurTimers:LoadSlashCommand()
    SLASH_DEVILSAURTIMERS1 = "/dt"
    SLASH_DEVILSAURTIMERS2 = "/devilsaur"
    SLASH_DEVILSAURTIMERS3 = "/devilsaurtimer"
    SLASH_DEVILSAURTIMERS4 = "/devilsaurtimers"
    SlashCmdList["DEVILSAURTIMERS"] = function(msg)
        self:Toggle()
    end
end

function DevilsaurTimers:RestorePosition()
    local frame = _G["DevilsaurTimersParentFrame"]
    if not frame then return end
    if #self.db.profile.parentFramePosition == 0 then return end
    
    C_Timer.After(0.25, function()
        frame:ClearAllPoints()
        frame:SetPoint(unpack(self.db.profile.parentFramePosition))
    end)
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

function DevilsaurTimers:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= self.name then return end
    
    local success, data = self:Deserialize(message)
    if not success then
        self:Print("Error: Failed to deserialize message from " .. sender)
        return
    end

    if data.color then
        local senderLower = sender:lower()
        local senderIsInList = false
        
        for _, player in ipairs(self.db.profile.sharedPlayers) do
            if player:lower() == senderLower then
                senderIsInList = true
                break
            end
        end
        if not senderIsInList then return end

        local progressBar = self.progressBars[data.color]
        if progressBar then
            if data.action == "StartTimer" then
                self:StartTimer(progressBar)
            elseif data.action == "ResetTimer" then
                self:ResetTimer(progressBar)
            end
        else
            self:Print("Error: Progress bar not found for color " .. data.color)
        end
    else
        self:Print("Error: Missing color message from " .. sender)
    end
end

function DevilsaurTimers:IsPlayerOnline(playerName)
    for i = 1, C_FriendList.GetNumFriends() do
        local friend = C_FriendList.GetFriendInfoByIndex(i)
        if friend.name:lower() == playerName:lower() then
            return friend.connected
        end
    end
    return false
end

function DevilsaurTimers:TriggerFriendTimers(color)
    if not color then
        self:Print("Error: No color specified for TriggerFriendTimers.")
        return
    end

    local data = {
        color = color,
        action = "StartTimer",
    }

    local serializedData = self:Serialize(data)

    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player and player ~= "" and self:IsPlayerOnline(player) then
            self:SendCommMessage(self.name, serializedData, "WHISPER", player)
        end
    end
end

function DevilsaurTimers:ResetFriendTimers(color)
    if not color then
        self:Print("Error: No color specified for ResetFriendTimers.")
        return
    end

    local data = {
        color = color,
        action = "ResetTimer",
    }

    local serializedData = self:Serialize(data)
    
    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player and player ~= "" and self:IsPlayerOnline(player) then
            self:SendCommMessage(self.name, serializedData, "WHISPER", player)
        end
    end
end

local defaults = {
    profile = {
        hideBars = false,
        hideLines = false,
        hideMapTimers = false,
        respawnTimer = 25 * 60,
        parentFramePosition = {},
        lineThickness = 4,
        mapTimerTextOffset = {
            x = 0,
            y = 0
        },
        sharedPlayers = {},
    }
}

function DevilsaurTimers:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(self.name.."DB", defaults, true)

    self:LoadHooks()
    self:LoadSlashCommand()
    self:CreateMenu()
    self:CreateProgressBars()
    self:RestorePosition()
    self:DrawPatrolPaths()
    self:UpdateVisibility()
    
    self:RegisterComm(self.name, "OnCommReceived")
end
