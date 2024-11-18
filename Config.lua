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
				name = "|cffffd700Version|r " .. version .. "\n|cffffd700 Author|r " .. author,
			},
			visibility = {
				type = "group",
				name = "Visibility Settings",
				order = 2,
				inline = true,
				args = {
                    hideBars = {
                        type = "toggle",
                        name = "Hide Devilsaur Bars",
                        desc = "Enable or disable the devilsaur progress bars.",
						get = function(info) return self.db.profile.hideBars end,
						set = function(info, value)
                            self.db.profile.hideBars = value
                            self:UpdateVisibility()
                         end,
                    },
                    hideLines = {
                        type = "toggle",
                        name = "Hide Devilsaur Path Lines",
                        desc = "Hide the color coded lines on the map to represent the devilsaur pathing.",
						get = function(info) return self.db.profile.hideLines end,
						set = function(info, value)
                            self.db.profile.hideLines = value
                            self:ToggleShowLines()
                         end,
                    }
                }
            },
            settings = {
                type = "group",
                name = "Settings",
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
                    }
                },
            },
        }
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)

    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end

function DevilsaurTimers:UpdateVisibility()
    local parentFrame = _G["DevilsaurTimersParentFrame"]
    if not parentFrame then return end

    parentFrame:SetShown(not self.db.profile.hideBars)
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

function DevilsaurTimers:ToggleShowLines()
    local mapOverlayFrame = _G["DevilsaurMapOverlayFrame"]
    if self.db.profile.hideLines then
        self:UnloadHooks()
        self:ClearPatrolPaths()
        if mapOverlayFrame then
            mapOverlayFrame:Hide()
        end
    else
        self:LoadHooks()
        self:DrawPatrolPaths()
        if mapOverlayFrame then
            mapOverlayFrame:Show()
        end
    end
end
