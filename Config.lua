local _, addon = ...
addon.name = "DevilsaurTimers"
local DevilsaurTimers = LibStub("AceAddon-3.0"):NewAddon(addon.name, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
DevilsaurTimers.name = addon.name
local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

DevilsaurTimers.pathColors = {"blue", "pink", "teal", "green", "yellow", "red"}

local defaults = {
    profile = {
        hideBars = false,
        hideLines = false,
        hideMapTimers = false,
        respawnTimer = 7 * 60,
        timers = {},
        previousTimers = {},
        parentProgressBarFramePosition = {},
        lineThickness = 4,
        mapTimerTextOffset = {
            x = 0,
            y = 0
        },
        sharedPlayers = {},
        autoTimer = true,
        isSharedPlayersEnabled = true,
        parentProgressBarDimensions = {
            width = 200,
            height = 150,
        },
        progressBarDimensions = {
            width = 200,
            height = 20,
        },
    }
}

function DevilsaurTimers:CreateMenu()
    local version = GetAddOnMetadata(self.name, "Version") or "Unknown"
    local author = GetAddOnMetadata(self.name, "Author") or "Mageiden"
    
    self.options = {
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
                            self:UpdateProgressBarVisibility()
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
                        desc = string.format("Set the respawn timer for devilsaurs in seconds (default is %d seconds, or %d minutes).", defaults.profile.respawnTimer, defaults.profile.respawnTimer / 60),
                        min = 60,
                        max = 1800,
                        step = 1,
                        get = function(info) return self.db.profile.respawnTimer or 420 end,
                        set = function(info, value)
                            self.db.profile.respawnTimer = value
                        end,
                    },
                    lineThickness = {
                        order = 2,
                        type = "range",
                        name = "Line Thickness",
                        desc = string.format("Set the line thickness for the devilsaur paths on the map. (default is %d)", defaults.profile.lineThickness),
                        min = 1,
                        max = 8,
                        step = 1,
                        get = function(info) return self.db.profile.lineThickness or 4 end,
                        set = function(info, value)
                            self.db.profile.lineThickness = value
                        end,
                    },
                    description1 = {
                        order = 3,
                        type = "description",
                        name = " ",
                        width = 0.05,
                    },
                    autoTimer = {
                        order = 4,
                        type = "toggle",
                        name = "Enable Auto Timer",
                        desc = "Tracks the location where you first spot a Devilsaur and automatically sets the timer for the corresponding color when the Devilsaur is killed. |cff808080(May occasionally have issues with yellow/red due to overlapping paths.)|r",
                        get = function(info) return self.db.profile.autoTimer end,
                        set = function(info, value)
                            self.db.profile.autoTimer = value
                        end,
                    },
                },
            },
            progressBar = {
                type = "group",
                name = "Progress Bar Settings",
                order = 5,
                inline = true,
                args = {
                    width = {
                        order = 1,
                        type = "range",
                        name = "Progress Bar Width",
                        desc = "Adjust progress bar width",
                        min = 0,
                        max = 400,
                        step = 1,
                        get = function(info) return self.db.profile.progressBarDimensions.width or 200 end,
                        set = function(info, value)
                            self.db.profile.progressBarDimensions.width = value
                            self:UpdateProgressBarSize()
                        end,
                    },
                    
                },
            },  
            mapTimerSettings = {
                type = "group",
                name = "Map Timer Settings",
                order = 5,
                inline = true,
                args = {
                    timerXOffset = {
                        order = 1,
                        type = "range",
                        name = "Timer Text X Offset",
                        desc = string.format("Adjust the X offset for the map respawn timer next to each devilsaur path. (Default is %d)", defaults.profile.mapTimerTextOffset.x),
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
                        desc = string.format("Adjust the Y offset for the map respawn timer next to each devilsaur path. (Default is %d)", defaults.profile.mapTimerTextOffset.y),
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
                order = 6,
                inline = true,
                args = {
                    description1 = {
                        order = 0,
                        type = "description",
                        name = "|TInterface\\COMMON\\help-i:17:17|t Will only work if the player also has you in their shared player list as well, |cffffd700AND|r they must be on |cffffd700YOUR|r friends list.",
                    },
                    description2 = {
                        order = 1,
                        type = "description",
                        name = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16:16|t Player is not on your friends list   |TInterface\\RAIDFRAME\\ReadyCheck-Ready:16:16|t Player is on your friends list",
                        hidden = function()
                            return #self.db.profile.sharedPlayers == 0
                        end,
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
                                    if player.name and player.name:lower() == value:lower() then
                                        self:Print("Player already exists in the shared list: " .. player.name)
                                        return
                                    end
                                end
                                table.insert(self.db.profile.sharedPlayers, { name = value, enabled = true })
                                self:Print("Added player: " .. value)
                                self.options.args.playerToggles.args = self:GetPlayerToggles()
                                AceConfigRegistry:NotifyChange("DevilsaurTimers")                            
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
                                if player.name:lower() == value:lower() then
                                    table.remove(self.db.profile.sharedPlayers, i)
                                    self:Print("Removed player: " .. player.name)
                                    self.options.args.playerToggles.args = self:GetPlayerToggles()
                                    AceConfigRegistry:NotifyChange("DevilsaurTimers")
                                    break
                                end
                            end
                        end,
                    },
                    toggleSharedTimer = {
                        order = 4,
                        type = "toggle",
                        name = "Enable Shared Timer",
                        desc = "Disable or enable the shared timers with players on your shared player list.",
                        get = function() return self.db.profile.isSharedPlayersEnabled end,
                        set = function(info, value)
                            self.db.profile.isSharedPlayersEnabled = value
                        end,
                    },
                },
            }
        },
    }

    self.options.args.playerToggles = {
        order = 10, type = "group", name = "Shared Player List", inline = true, args = self:GetPlayerToggles()
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name)
end

function DevilsaurTimers:GetPlayerToggles()
    local toggles = {}
    for index, player in ipairs(self.db.profile.sharedPlayers) do
        toggles["playerToggle" .. index] = {
            type = "toggle",
            name = function()
                local statusIcon = self:IsFriend(player.name) and 
                                    "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:16:16|t" or
                                    "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:16:16|t"
                return player.name:sub(1, 1):upper() .. player.name:sub(2):lower() .. " " .. statusIcon
            end,
            desc = "Toggle timer sharing for " .. player.name:sub(1, 1):upper() .. player.name:sub(2):lower(),
            get = function() return player.enabled end,
            set = function(info, value)
                player.enabled = value
            end,
            disabled = function()
                return not self.db.profile.isSharedPlayersEnabled
            end
            
        }
    end
    return toggles
end

function DevilsaurTimers:UpdateProgressBarSize()
    for i=1, 6 do
        local frame = _G["DevilsaurProgressBar"..i]
        if not frame then return end
        frame:SetSize(self.db.profile.progressBarDimensions.width, self.db.profile.progressBarDimensions.height)
    end
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

function DevilsaurTimers:UpdateProgressBarVisibility()
    local parentFrame = _G["DevilsaurTimersParentFrame"]
    if not parentFrame then return end

    parentFrame:SetShown(not self.db.profile.hideBars)
end

function DevilsaurTimers:UpdateMapTimerTexts()
    local action = self.db.profile.hideMapTimers and "Hide" or "Show"

    for _, color in ipairs(self.pathColors) do
        local frame = _G[color.."TimerText"]
        if frame and frame[action] then
            frame[action](frame)
        end
    end
end

function DevilsaurTimers:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New(self.name.."DB", defaults, true)

    -- fix stuff for ppl with old version of addon
    if self.db.profile.sharedPlayers[1] and type(self.db.profile.sharedPlayers[1]) ~= "table" then
        self.db.profile.sharedPlayers = {}
    end

    self:LoadHooks()    
    self:LoadSlashCommands()

    self:CreateMenu()
    self:CreateProgressBars()
    self:RestoreProgressBarPosition()
    self:DrawPatrolPaths()
    self:UpdateProgressBarVisibility()
    self:RestoreTimers()
    
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "HandleCombatLog")
    self:RegisterEvent("UNIT_TARGET", "HandleUnitTarget")

    self:RegisterComm(self.name, "OnCommReceived")
end
