local _, addon = ...
addon.name = "DevilsaurTimers"
local DevilsaurTimers = _G.LibStub("AceAddon-3.0"):NewAddon(addon.name, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
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
                            self:UpdatePatrolPathVisibility()
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
                        desc = "Adjust the X offset for the map respawn timer next to each devilsaur path. (Default is 0)",
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
                        desc = "Adjust the Y offset for the map respawn timer next to each devilsaur path. (Default is 0)",
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
            sharedPlayers = {
                type = "group",
                name = "Shared Timer Settings",
                order = 5,
                inline = true,
                args = {
                    description1 = {
                        order = 0,
                        type = "description",
                        name = "|TInterface\\COMMON\\help-i:17:17|t Will only work if the player also has you in their shared player list aswell, |cffffd700AND|r must be on your friends list.",
                    },
                    description2 = {
                        order = 1,
                        type = "description",
                        name = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16:16|t not on friendlist |TInterface\\RAIDFRAME\\ReadyCheck-Ready:16:16|t on friendlist",
                    },
                    addPlayer = {
                        order = 2,
                        type = "input",
                        name = "Add Player Name",
                        desc = "Enter a player's name to share respawn times.",
                        get = function() return "" end,
                        set = function(info, value)
                            if value and value ~= "" then
                                for _, player in ipairs(self.db.profile.sharedPlayers) do
                                    if player:lower() == value:lower() then
                                        self:Print("Player already exists in the shared list: " .. player)
                                        return
                                    end
                                end
                    
                                table.insert(self.db.profile.sharedPlayers, value)
                                self:Print("Added player: " .. value)
                            end
                        end,
                    },
                    removePlayer = {
                        order = 3,
                        type = "input",
                        name = "Remove Player Name",
                        desc = "Enter a player's name to remove from the shared list.",
                        get = function() return "" end,
                        set = function(info, value)
                            for i, player in ipairs(self.db.profile.sharedPlayers) do
                                if player:lower() == value:lower() then
                                    table.remove(self.db.profile.sharedPlayers, i)
                                    self:Print("Removed player: " .. player)
                                    break
                                end
                            end
                        end,
                    },
                    sharedPlayersList = {
                        order = 4,
                        type = "description",
                        name = function()
                            local players = self.db.profile.sharedPlayers
                            if #players == 0 then
                                return "No players to share with."
                            end
                    
                            local result = "Players sharing respawn times:\n"
                            for _, player in ipairs(players) do
                                if player and player ~= "" then
                                    local isFriend = self:IsFriend(player)
                                    local statusIcon = isFriend and "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16:16|t" or "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16:16|t"
                                    result = result .. statusIcon .. " " .. player .. "\n"
                                end
                            end
                    
                            return result
                        end,
                    }
                    
                },
            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end

function DevilsaurTimers:IsFriend(playerName)
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name and info.name:lower() == playerName:lower() then
            return true
        end
    end
    return false
end

function DevilsaurTimers:UpdateVisibility()
    local parentFrame = _G["DevilsaurTimersParentFrame"]
    if not parentFrame then return end

    parentFrame:SetShown(not self.db.profile.hideBars)
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
