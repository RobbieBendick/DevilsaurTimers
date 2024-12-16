local _, addon = ...
local DevilsaurTimers = LibStub("AceAddon-3.0"):GetAddon(addon.name)
DevilsaurTimers.patrolPaths = {
    -- coords // {startLine, endLine} forms 1 line
    blue = {
        {0.5711, 0.24}, {0.588, 0.286}, {0.603, 0.274}, {0.644, 0.26}, {0.668, 0.253}, {0.689, 0.261}, {0.7023, 0.2921}, {0.675, 0.311}, {0.644, 0.304}, {0.642, 0.331}
    },
    pink = {
        {0.73, 0.31}, {0.73, 0.35}, {0.74, 0.4}, {0.75, 0.44}, {0.75, 0.48}, {0.73, 0.50}, {0.71, 0.51}, {0.704, 0.554}, {0.688, 0.585}, {0.651, 0.593}, {0.628, 0.595}
    },
    red = {
        {0.34, 0.221}, {0.3435, 0.2485}, {0.3478, 0.286}, {0.3662, 0.3453}, {0.35, 0.363}, {0.33, 0.37}, {0.3244, 0.4368}, {0.31, 0.475}, {0.3116, 0.5120}, {0.30, 0.5314}
    },
    teal = {
        {0.5789, 0.742}, {0.5735, 0.7239}, {0.5864, 0.6984}, {0.5647, 0.6569}, {0.5591, 0.63}, {0.5732, 0.6069}, {0.5683, 0.5559}, {0.5676, 0.5144}, {0.5683, 0.4655}, {0.5874, 0.4453}, {0.58, 0.4050}, {0.5711, 0.357}, {0.5612, 0.32}
    },
    yellow = {
        {0.3116, 0.3453}, {0.32, 0.358}, {0.34, 0.3793}, {0.37, 0.424}, {0.39, 0.46}, {0.395, 0.496}, {0.4030, 0.54}, {0.40, 0.594}, {0.409, 0.608}, {0.423, 0.615},
    },
    green = {
        {0.432, 0.796}, {0.44, 0.76}, {0.459, 0.74}, {0.451, 0.67}, {0.45, 0.64}, {0.467, 0.62}, {0.501, 0.605}, {0.528, 0.5888}, {0.545, 0.615}, {0.545, 0.645},{0.525, 0.68}, {0.527, 0.705},{0.5358, 0.7345}, 
    },
}

function DevilsaurTimers:DrawSquareAtPoint(centerX, centerY, radius, numSegments, color)
    local mapOverlayFrame = _G["DevilsaurMapOverlayFrame"]
    
    local points = {}
    for i = 1, numSegments do
        local angle = (i - 1) * (2 * math.pi / numSegments)
        local x = centerX + radius * math.cos(angle)
        local y = centerY + radius * math.sin(angle)
        table.insert(points, {x, y})
    end

    -- draw lines between consecutive points to form a square
    for i = 1, #points - 1 do
        local line = mapOverlayFrame:CreateLine()
        line:SetColorTexture(self:GetColorByName(color))
        line:SetThickness(self.db.profile.lineThickness + 1)

        local x1, y1 = unpack(points[i])
        local x2, y2 = unpack(points[i + 1])

        local startX = x1 * mapOverlayFrame:GetWidth()
        local startY = -y1 * mapOverlayFrame:GetHeight()
        local endX = x2 * mapOverlayFrame:GetWidth()
        local endY = -y2 * mapOverlayFrame:GetHeight()

        line:SetStartPoint("TOPLEFT", mapOverlayFrame, startX, startY)
        line:SetEndPoint("TOPLEFT", mapOverlayFrame, endX, endY)
    end
end

function DevilsaurTimers:DrawPatrolPaths()
    self:ClearPatrolPaths()
    self:HideTimerTexts()
    self:HidePatrolSquares()
    self.patrolLines = self.patrolLines or {}
    self.timerTexts = self.timerTexts or {}

    local currentMapID = WorldMapFrame:GetMapID()
    local ungoroMapID = 1449
    if currentMapID ~= ungoroMapID then
        return
    end

    local mapOverlayFrame = _G["DevilsaurMapOverlayFrame"] or CreateFrame("Frame", "DevilsaurMapOverlayFrame", WorldMapFrame.ScrollContainer)
    mapOverlayFrame:ClearAllPoints()
    mapOverlayFrame:SetAllPoints(WorldMapFrame.ScrollContainer.Child)
    mapOverlayFrame:SetFrameStrata("HIGH")
    mapOverlayFrame:SetToplevel(true)

    for color, path in pairs(self.patrolPaths) do
        for i = 1, #path - 1 do
            local line = mapOverlayFrame:CreateLine()
            line:SetColorTexture(self:GetColorByName(color))
            line:SetThickness(self.db.profile.lineThickness or 4)

            local x1, y1 = unpack(path[i])
            local x2, y2 = unpack(path[i + 1])

            -- convert normalized map coordinates (0 to 1 range) to pixel positions
            local startX = x1 * mapOverlayFrame:GetWidth()
            local startY = -y1 * mapOverlayFrame:GetHeight()
            local endX = x2 * mapOverlayFrame:GetWidth()
            local endY = -y2 * mapOverlayFrame:GetHeight()

            line:SetStartPoint("TOPLEFT", mapOverlayFrame, startX, startY)
            line:SetEndPoint("TOPLEFT", mapOverlayFrame, endX, endY)

            table.insert(self.patrolLines, line)
        end

        local firstPoint = path[1]
        if firstPoint then
            local mapWidth = mapOverlayFrame:GetWidth()
            local mapHeight = mapOverlayFrame:GetHeight()

            local x, y = firstPoint[1], firstPoint[2]
            local posX = x * mapWidth + self.db.profile.mapTimerTextOffset.x
            local posY = -y * mapHeight - self.db.profile.mapTimerTextOffset.y

            local timerText = self.timerTexts[color]

            if not timerText then
                timerText = mapOverlayFrame:CreateFontString(color.."TimerText", "OVERLAY", "GameFontNormalSmall")
                self.timerTexts[color] = timerText
            end

            timerText:SetPoint("CENTER", mapOverlayFrame, "TOPLEFT", posX, posY)
            timerText:SetTextColor(1, 1, 1)

            self:DrawSquareAtPoint(x, y, 0.0042, 25, color)
        end
    end
    self:UpdateMapTimerTexts()
    self:UpdatePatrolPathVisibility()
end

function DevilsaurTimers:DrawSquareAtPoint(centerX, centerY, radius, numSegments, color)
    local mapOverlayFrame = _G["DevilsaurMapOverlayFrame"]

    local mapWidth = mapOverlayFrame:GetWidth()
    local mapHeight = mapOverlayFrame:GetHeight()

    local pixelRadius = radius * mapWidth

    local points = {}
    for i = 1, numSegments do
        local angle = (i - 1) * (2 * math.pi / numSegments)
        local x = centerX + radius * math.cos(angle)
        local y = centerY + radius * math.sin(angle)
        table.insert(points, {x, y})
    end

    if not self.squares then
        self.squares = {}
    end
    self.squares[color] = self.squares[color] or {}

    for i = 1, #points - 1 do
        local line = mapOverlayFrame:CreateLine()
        line:SetColorTexture(self:GetColorByName(color))
        line:SetThickness(2)

        local x1, y1 = unpack(points[i])
        local x2, y2 = unpack(points[i + 1])

        local startX = x1 * mapWidth
        local startY = -y1 * mapHeight
        local endX = x2 * mapWidth
        local endY = -y2 * mapHeight

        line:SetStartPoint("TOPLEFT", mapOverlayFrame, startX, startY)
        line:SetEndPoint("TOPLEFT", mapOverlayFrame, endX, endY)

        table.insert(self.squares[color], line)
    end

    local filledSquare = mapOverlayFrame:CreateTexture(nil, "OVERLAY")
    filledSquare:SetColorTexture(self:GetColorByName(color))
    filledSquare:SetSize(pixelRadius * 2, pixelRadius * 2)

    filledSquare:SetPoint("CENTER", mapOverlayFrame, "TOPLEFT", centerX * mapWidth, -centerY * mapHeight)

    table.insert(self.squares[color], filledSquare)
end

function DevilsaurTimers:ClearPatrolPaths()
    if self.patrolLines then
        self:HidePatrolPaths()
        self.patrolLines = {}
    end
end

function DevilsaurTimers:HidePatrolPaths()
    if self.patrolLines then
        for _, line in ipairs(self.patrolLines) do
            line:Hide()
        end
    end
end

function DevilsaurTimers:HidePatrolSquares()
    if not self.squares then return end
    for i, color in ipairs(self.pathColors) do
        local square = self.squares[color]
        if square then
            for _, line in ipairs(square) do
                line:Hide()
            end
            square = nil
        end
    end
end

function DevilsaurTimers:ShowPatrolPaths()
    if self.patrolLines then
        for _, line in ipairs(self.patrolLines) do
            line:Show()
        end
    end
end

function DevilsaurTimers:UpdatePatrolPathVisibility()
    if self.db.profile.hideLines then
        self:HidePatrolPaths()
    else
        self:ShowPatrolPaths()
    end
end

function DevilsaurTimers:HideTimerTexts()
    for _, color in ipairs(self.pathColors) do
        local frame = _G[color.."TimerText"]
        if frame then
            frame:Hide()
        end
    end
end

function DevilsaurTimers:ShowTimerTexts()
    for _, color in ipairs(self.pathColors) do
        local frame = _G[color.."TimerText"]
        if frame then
            frame:Show()
        end
    end
end

function DevilsaurTimers:GetColorByName(colorName)
    local colors = {
        blue = {0, 0.5, 1},
        pink = {1, 0.5, 0.75},
        teal = {0, 1, 1},
        green = {0, 1, 0},
        yellow = {1, 1, 0},
        red = {1, 0, 0},
    }
    return unpack(colors[colorName] or {1, 1, 1})
end

function DevilsaurTimers:PrintColorized(colorName, sentence)
    local r, g, b = self:GetColorByName(colorName)
    local hexColor = ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)

    local colorizedWord = ("%s%s|r"):format(hexColor, colorName:sub(1, 1):upper() .. colorName:sub(2):lower())
    local colorizedSentence = sentence:gsub(colorName:sub(1, 1):upper() .. colorName:sub(2):lower(), colorizedWord)

    self:Print(colorizedSentence)
end
