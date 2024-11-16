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
                    hide = {
                        type = "toggle",
                        name = "Hide Devilsaur Bars",
                        desc = "Enable or disable the devilsaur progress bars.",
						get = function(info) return self.db.profile.hide end,
						set = function(info, value)
                            self.db.profile.hide = value
                            self:UpdateVisibility()
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

    parentFrame:SetShown(not parentFrame:IsShown())
end