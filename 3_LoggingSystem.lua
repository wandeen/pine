--[[
LOGGING SYSTEM
Comprehensive activity tracking for chat and player joins/leaves.
- Timestamp all events
- Capture user info, session duration, disconnect reasons
- Export logs to JSON files
- Auto-cleanup old logs (configurable retention)
- Query logs by player, time range, keywords

Usage:
    local Logger = require(this_module).new()
    Logger:StartChatLogging()
    Logger:StartJoinLogging()
    
    Logger:GetChatLog(playerName)
    Logger:GetJoinLog()
    Logger:ExportChatLogs()
    Logger:ExportJoinLogs()
    Logger:CleanupOldLogs(7)  -- Keep last 7 days
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Logger = {}
Logger.__index = Logger

-- ── Configuration ─────────────────────────────────────
local CHAT_LOG_FILE = "phantom_chat_logs.json"
local JOIN_LOG_FILE = "phantom_join_logs.json"
local LOG_RETENTION_DAYS = 30
local MAX_LOGS_PER_SESSION = 10000

-- ── Internal State ────────────────────────────────────
function Logger.new()
    local self = setmetatable({}, Logger)
    
    self.chatLogs = {}      -- {playerName, message, timestamp, userId}
    self.joinLogs = {}      -- {playerName, joinTime, leaveTime, duration, userId}
    self.activeSessions = {} -- {userId = {name, joinTime}}
    
    self.chatLoggingActive = false
    self.joinLoggingActive = false
    
    self._chatConnections = {}
    self._joinConnections = {}
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- ── CHAT LOGGING ──────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Logger:StartChatLogging()
    if self.chatLoggingActive then return end
    self.chatLoggingActive = true
    
    -- Hook existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:_hookPlayerChat(player)
    end
    
    -- Hook future players
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if self.chatLoggingActive then
            self:_hookPlayerChat(player)
        end
    end)
    
    table.insert(self._chatConnections, playerAddedConn)
end

function Logger:_hookPlayerChat(player)
    if not player then return end
    
    local chatConn = player.Chatted:Connect(function(message)
        if self.chatLoggingActive then
            self:_logChat(player, message)
        end
    end)
    
    table.insert(self._chatConnections, chatConn)
end

function Logger:_logChat(player, message)
    if #self.chatLogs >= MAX_LOGS_PER_SESSION then
        table.remove(self.chatLogs, 1)  -- Remove oldest
    end
    
    table.insert(self.chatLogs, {
        playerName = player.Name,
        userId = player.UserId,
        message = message,
        timestamp = os.time(),
        displayTime = os.date("%Y-%m-%d %H:%M:%S"),
    })
end

function Logger:StopChatLogging()
    self.chatLoggingActive = false
    for _, conn in ipairs(self._chatConnections) do
        pcall(function() conn:Disconnect() end)
    end
    self._chatConnections = {}
end

function Logger:GetChatLog(playerNameFilter)
    if not playerNameFilter then
        return self.chatLogs
    end
    
    local filtered = {}
    for _, entry in ipairs(self.chatLogs) do
        if entry.playerName:lower() == playerNameFilter:lower() then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

function Logger:ClearChatLog()
    self.chatLogs = {}
end

-- ════════════════════════════════════════════════════════════════
-- ── JOIN/LEAVE LOGGING ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Logger:StartJoinLogging()
    if self.joinLoggingActive then return end
    self.joinLoggingActive = true
    
    -- Log existing players as already joined
    for _, player in ipairs(Players:GetPlayers()) do
        self.activeSessions[player.UserId] = {
            name = player.Name,
            joinTime = os.time(),
        }
    end
    
    -- Hook new joins
    local playerAddedConn = Players.PlayerAdded:Connect(function(player)
        if self.joinLoggingActive then
            self:_logJoin(player)
        end
    end)
    
    -- Hook leaves
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        if self.joinLoggingActive then
            self:_logLeave(player)
        end
    end)
    
    table.insert(self._joinConnections, playerAddedConn)
    table.insert(self._joinConnections, playerRemovingConn)
end

function Logger:_logJoin(player)
    self.activeSessions[player.UserId] = {
        name = player.Name,
        joinTime = os.time(),
    }
end

function Logger:_logLeave(player)
    local session = self.activeSessions[player.UserId]
    if not session then return end
    
    local leaveTime = os.time()
    local duration = leaveTime - session.joinTime
    
    table.insert(self.joinLogs, {
        playerName = session.name,
        userId = player.UserId,
        joinTime = session.joinTime,
        leaveTime = leaveTime,
        duration = duration,
        joinDisplay = os.date("%Y-%m-%d %H:%M:%S", session.joinTime),
        leaveDisplay = os.date("%Y-%m-%d %H:%M:%S", leaveTime),
        durationString = self:_formatDuration(duration),
    })
    
    self.activeSessions[player.UserId] = nil
end

function Logger:StopJoinLogging()
    self.joinLoggingActive = false
    for _, conn in ipairs(self._joinConnections) do
        pcall(function() conn:Disconnect() end)
    end
    self._joinConnections = {}
end

function Logger:GetJoinLog(playerNameFilter)
    if not playerNameFilter then
        return self.joinLogs
    end
    
    local filtered = {}
    for _, entry in ipairs(self.joinLogs) do
        if entry.playerName:lower() == playerNameFilter:lower() then
            table.insert(filtered, entry)
        end
    end
    return filtered
end

function Logger:ClearJoinLog()
    self.joinLogs = {}
end

-- ════════════════════════════════════════════════════════════════
-- ── EXPORT & PERSISTENCE ─────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Logger:ExportChatLogs(filename)
    filename = filename or CHAT_LOG_FILE
    
    local ok, json = pcall(function()
        return HttpService:JSONEncode(self.chatLogs)
    end)
    
    if ok then
        pcall(function()
            writefile(filename, json)
        end)
        return true
    end
    return false
end

function Logger:ExportJoinLogs(filename)
    filename = filename or JOIN_LOG_FILE
    
    local ok, json = pcall(function()
        return HttpService:JSONEncode(self.joinLogs)
    end)
    
    if ok then
        pcall(function()
            writefile(filename, json)
        end)
        return true
    end
    return false
end

function Logger:LoadChatLogs(filename)
    filename = filename or CHAT_LOG_FILE
    
    local ok, content = pcall(function()
        return readfile(filename)
    end)
    
    if ok and content then
        local ok2, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if ok2 then
            self.chatLogs = data or {}
            return true
        end
    end
    return false
end

function Logger:LoadJoinLogs(filename)
    filename = filename or JOIN_LOG_FILE
    
    local ok, content = pcall(function()
        return readfile(filename)
    end)
    
    if ok and content then
        local ok2, data = pcall(function()
            return HttpService:JSONDecode(content)
        end)
        
        if ok2 then
            self.joinLogs = data or {}
            return true
        end
    end
    return false
end

-- ════════════════════════════════════════════════════════════════
-- ── MAINTENANCE & CLEANUP ────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Logger:CleanupOldLogs(retentionDays)
    retentionDays = retentionDays or LOG_RETENTION_DAYS
    local cutoffTime = os.time() - (retentionDays * 86400)
    
    -- Clean chat logs
    local newChatLogs = {}
    for _, entry in ipairs(self.chatLogs) do
        if entry.timestamp >= cutoffTime then
            table.insert(newChatLogs, entry)
        end
    end
    self.chatLogs = newChatLogs
    
    -- Clean join logs
    local newJoinLogs = {}
    for _, entry in ipairs(self.joinLogs) do
        if entry.leaveTime >= cutoffTime then
            table.insert(newJoinLogs, entry)
        end
    end
    self.joinLogs = newJoinLogs
end

function Logger:GetStats()
    return {
        chatLogCount = #self.chatLogs,
        joinLogCount = #self.joinLogs,
        activePlayers = table.countall(self.activeSessions),
    }
end

-- ════════════════════════════════════════════════════════════════
-- ── UTILITY ───────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Logger:_formatDuration(seconds)
    if seconds < 60 then
        return seconds .. "s"
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds/60), seconds%60)
    else
        local hours = math.floor(seconds/3600)
        local mins = math.floor((seconds%3600)/60)
        return string.format("%dh %dm", hours, mins)
    end
end

function Logger:QueryChatByKeyword(keyword)
    keyword = keyword:lower()
    local results = {}
    
    for _, entry in ipairs(self.chatLogs) do
        if entry.message:lower():find(keyword, 1, true) then
            table.insert(results, entry)
        end
    end
    
    return results
end

function Logger:QueryChatByTimeRange(startTime, endTime)
    local results = {}
    
    for _, entry in ipairs(self.chatLogs) do
        if entry.timestamp >= startTime and entry.timestamp <= endTime then
            table.insert(results, entry)
        end
    end
    
    return results
end

function Logger:Cleanup()
    self:StopChatLogging()
    self:StopJoinLogging()
end

return Logger
