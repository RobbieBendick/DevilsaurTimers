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
                self:StartFriendTimer(color)
            elseif button == "RightButton" then
                self:ResetTimer(progressBar)
                self:ResetFriendTimer(color)
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

    local r, g, b = self:GetColorByName("red")
    progressBar:SetStatusBarColor(r, g, b)
    
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

function DevilsaurTimers:RestorePosition()
    local frame = _G["DevilsaurTimersParentFrame"]
    if not frame then return end
    if #self.db.profile.parentFramePosition == 0 then return end
    
    frame:ClearAllPoints()
    frame:SetPoint(unpack(self.db.profile.parentFramePosition))
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

function DevilsaurTimers:HandleSkinnedDevilsaur(msg, ...)
    local map = C_Map.GetBestMapForUnit("player")
    if not map then return end

    local position = C_Map.GetPlayerMapPosition(map, "player")
    if not position then return end

    local ungoroMapID = 1449
    if map ~= ungoroMapID then return end

    if not msg:find("Devilsaur") then return end

    if not self.db.profile.autoTimer then return end

    local posX, posY = position:GetXY()

    for color, path in pairs(self.patrolPaths) do
        local firstPoint = path[1]
        if firstPoint then
            local startX, startY = firstPoint[1], firstPoint[2]

            local deltaX = math.abs(posX - startX)
            local deltaY = math.abs(posY - startY)
            local totalDelta = deltaX + deltaY

            if totalDelta <= 0.11 then
                local progressBar = self.progressBars[color]
                self:StartTimer(progressBar)
                self:StartFriendTimer(color)
                return
            end
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
        autoTimer = true,
    }
}

function DevilsaurTimers:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(self.name.."DB", defaults, true)

    self:LoadHooks()
    self:LoadSlashCommands()
    self:CreateMenu()
    self:CreateProgressBars()
    self:RestorePosition()
    self:DrawPatrolPaths()
    self:UpdateVisibility()
    
    self:RegisterEvent("CHAT_MSG_LOOT", "HandleSkinnedDevilsaur")

    self:RegisterComm(self.name, "OnCommReceived")
end
