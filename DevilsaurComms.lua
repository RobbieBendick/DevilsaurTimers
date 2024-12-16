local _, addon = ...
local DevilsaurTimers = LibStub("AceAddon-3.0"):GetAddon(addon.name)

function DevilsaurTimers:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= self.name then return end

    if not self.db.profile.isSharedPlayersEnabled then return end

    if not self:IsPlayerEnabled(sender) then return end
    
    local success, data = self:Deserialize(message)
    if not success then
        self:Print("Error: Failed to deserialize message from " .. sender)
        return
    end

    if not self:IsSenderInSharedPlayers(sender) then return end
    
    if data.color then
        local progressBar = self.progressBars[data.color]
        if progressBar then
            if data.action == "StartTimer" then
                if data.remainingTime then
                    self:StartTimer(progressBar, data.remainingTime)
                else
                    self:StartTimer(progressBar)
                end
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

function DevilsaurTimers:IsSenderInSharedPlayers(sender)
    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player.name:lower() == sender:lower() then
            return true
        end
    end
    return false
end

function DevilsaurTimers:IsPlayerEnabled(playerName)
    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player.name:lower() == playerName:lower() then
            return player.enabled == true
        end
    end
    return false
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

function DevilsaurTimers:StartFriendTimer(color, remainingTime)
    if not self.db.profile.isSharedPlayersEnabled then return end

    if not color then
        self:Print("Error: No color specified for StartFriendTimer.")
        return
    end

    local data = {
        color = color,
        action = "StartTimer",
        remainingTime = remainingTime,
    }

    local serializedData = self:Serialize(data)

    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player.name and player.name ~= "" and self:IsPlayerOnline(player.name) then
            if self:IsPlayerEnabled(player.name) then
                self:SendCommMessage(self.name, serializedData, "WHISPER", player.name)
            end
        end
    end
end

function DevilsaurTimers:ResetFriendTimer(color)
    if not self.db.profile.isSharedPlayersEnabled then return end
    

    if not color then
        self:Print("Error: No color specified for ResetFriendTimer.")
        return
    end

    local data = {
        color = color,
        action = "ResetTimer",
    }

    local serializedData = self:Serialize(data)

    for _, player in ipairs(self.db.profile.sharedPlayers) do
        if player.name and player.name ~= "" and self:IsPlayerOnline(player.name) then
            if self:IsPlayerEnabled(player.name) then
                self:SendCommMessage(self.name, serializedData, "WHISPER", player.name)
            end
        end
    end
end