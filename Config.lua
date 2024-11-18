local _, addon = ...
addon.name = "DevilsaurTimers"
local DevilsaurTimers = _G.LibStub("AceAddon-3.0"):NewAddon(addon.name, "AceConsole-3.0", "AceEvent-3.0")
DevilsaurTimers.name = addon.name
local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function DevilsaurTimers:CreateMenu()
    local version = GetAddOnMetadata(self.name, "Version") or "Unknown"
	local author = GetAddOnMetadata(self.name, "Author") or "Mageiden"
    local options = {
        type = "group",
        name = self.name,
        args = {
            info = {
                order = 1,
                type = "description",
                name = "|cffffd700Version|r " .. version .. "\n|cffffd700Author|r " .. author,
            },
            visibility = {
                type = "group",
                name = "Visibility Settings",
                order = 2,
                inline = true,
                args = {
                    hideBars = {
                        order = 1,
                        type = "toggle",
                        name = "Hide Progress Bars",
                        desc = "Enable or disable the devilsaur progress bars.",
                        get = function(info) return self.db.profile.hideBars end,
                        set = function(info, value)
                            self.db.profile.hideBars = value
                            self:UpdateVisibility()
                        end,
                    },
                    hideLines = {
                        order = 2,
                        type = "toggle",
                        name = "Hide Path Lines",
                        desc = "Hide the color-coded lines on the map to represent the devilsaur pathing.",
                        get = function(info) return self.db.profile.hideLines end,
                        set = function(info, value)
                            self.db.profile.hideLines = value
                            self:ToggleShowLines()
                        end,
                    },
                    hideMapTimers = {
                        order = 3,
                        type = "toggle",
                        name = "Hide Map Timers",
                        desc = "Hide the timer counting down on each devilsaur path.",
                        get = function(info) return self.db.profile.hideMapTimers end,
                        set = function(info, value)
                            self.db.profile.hideMapTimers = value
                            self:UpdateMapTimerTexts()
                        end,
                    },
                },
            },
            settings = {
                type = "group",
                name = "General Settings",
                order = 3,
                inline = true,
                args = {
                    respawnTimer = {
                        order = 1,
                        type = "range",
                        name = "Respawn Timer (Seconds)",
                        desc = "Set the respawn timer for devilsaurs in seconds (default is 1500 seconds, or 25 minutes).",
                        min = 60,
                        max = 3600,
                        step = 1,
                        get = function(info) return self.db.profile.respawnTimer or 1500 end,
                        set = function(info, value)
                            self.db.profile.respawnTimer = value
                        end,
                    },
                    lineThickness = {
                        order = 2,
                        type = "range",
                        name = "Line Thickness",
                        desc = "Set the line thickness for the devilsaur paths on the map.",
                        min = 1,
                        max = 8,
                        step = 1,
                        get = function(info) return self.db.profile.lineThickness or 4 end,
                        set = function(info, value)
                            self.db.profile.lineThickness = value
                        end,
                    },
                },
            },
            mapTimerSettings = {
                type = "group",
                name = "Map Timer Settings",
                order = 4,
                inline = true,
                args = {
                    timerXOffset = {
                        order = 1,
                        type = "range",
                        name = "Timer Text X Offset",
                        desc = "Adjust the X offset for the map respawn timer next to each devilsaur path.",
                        min = -40,
                        max = 40,
                        step = 1,
                        get = function(info) return self.db.profile.mapTimerTextOffset.x or 0 end,
                        set = function(info, value)
                            self.db.profile.mapTimerTextOffset.x = value
                            self:DrawPatrolPaths()
                        end,
                    },
                    timerYOffset = {
                        order = 2,
                        type = "range",
                        name = "Timer Text Y Offset",
                        desc = "Adjust the Y offset for the map respawn timer next to each devilsaur path.",
                        min = -40,
                        max = 40,
                        step = 1,
                        get = function(info) return self.db.profile.mapTimerTextOffset.y or 0 end,
                        set = function(info, value)
                            self.db.profile.mapTimerTextOffset.y = value
                            self:DrawPatrolPaths()
                        end,
                    },
                },
            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end

function DevilsaurTimers:UpdateVisibility()
    local parentFrame = _G["DevilsaurTimersParentFrame"]
    if not parentFrame then return end

    parentFrame:SetShown(not self.db.profile.hideBars)
end

function DevilsaurTimers:ToggleShowLines()
    local mapOverlayFrame = _G["DevilsaurMapOverlayFrame"]
    if self.db.profile.hideLines then
        self:UnloadHooks()
        self:ClearPatrolPaths()
        self:HideTimerTexts()
        if mapOverlayFrame then
            mapOverlayFrame:Hide()
        end
    else
        self:LoadHooks()
        self:DrawPatrolPaths()
        self:ShowTimerTexts()
        if mapOverlayFrame then
            mapOverlayFrame:Show()
        end
    end
end

function DevilsaurTimers:UpdateMapTimerTexts()
    local dinoColors = {"blue", "pink", "teal", "green", "yellow", "red"}
    local action = self.db.profile.hideMapTimers and "Hide" or "Show"

    for _, color in ipairs(dinoColors) do
        local frame = _G[color.."TimerText"]
        if frame and frame[action] then
            frame[action](frame)
        end
    end
end
