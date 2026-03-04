-- SettingsManager.lua
-- Saves and loads hub feature states to/from a local JSON file.
-- Uses writefile / readfile (available in most Roblox executors).
-- Auto-applies settings after each respawn via CharacterAdded.
--
-- Usage:
--   local SM = require(SettingsManager).new(Hub)
--   SM:Register("WalkSpeed", function() return currentSpeed end, function(v) setSpeed(v) end)
--   SM:Save()     -- write to file
--   SM:Load()     -- read and apply
--   SM:StartAutoApply()  -- re-apply on respawn

local HS = game:GetService("HttpService")

local FILE_PREFIX = "phantom_sm_"

local SettingsManager = {}
SettingsManager.__index = SettingsManager

-- Create a new SettingsManager bound to a Phantom hub instance.
-- hub  – the Phantom window object returned by Phantom.new()
-- name – optional file name suffix (default "default")
function SettingsManager.new(hub, name)
    local self       = setmetatable({}, SettingsManager)
    self._hub        = hub
    self._name       = name or "default"
    self._entries    = {}   -- { key = string, get = fn, set = fn }
    self._charConn   = nil
    return self
end

-- Register a setting to persist.
-- key    – unique string identifier for this setting
-- getter – function() → current value (bool, number, string, Color3 table, etc.)
-- setter – function(value) → applies the loaded value
function SettingsManager:Register(key, getter, setter)
    self._entries[key] = { get = getter, set = setter }
end

-- Serialize a value into something JSON-safe.
local function encode(v)
    if typeof(v) == "Color3" then
        return { __type = "Color3", r = math.round(v.R * 255), g = math.round(v.G * 255), b = math.round(v.B * 255) }
    end
    return v
end

-- Deserialize a JSON-decoded value back to its Lua type.
local function decode(v)
    if type(v) == "table" and v.__type == "Color3" then
        return Color3.fromRGB(v.r or 0, v.g or 0, v.b or 0)
    end
    return v
end

-- Save all registered settings to disk.
function SettingsManager:Save()
    local data = {}
    for key, entry in pairs(self._entries) do
        local ok, val = pcall(entry.get)
        if ok then
            data[key] = encode(val)
        end
    end
    local ok, json = pcall(function() return HS:JSONEncode(data) end)
    if ok then
        pcall(function()
            writefile(FILE_PREFIX .. self._name .. ".json", json)
        end)
    end
end

-- Load settings from disk and apply them.
-- Returns true on success, false if file is missing or corrupt.
function SettingsManager:Load()
    local ok, content = pcall(function()
        return readfile(FILE_PREFIX .. self._name .. ".json")
    end)
    if not ok or not content or content == "" then return false end
    local ok2, data = pcall(function() return HS:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return false end
    for key, entry in pairs(self._entries) do
        if data[key] ~= nil then
            pcall(function() entry.set(decode(data[key])) end)
        end
    end
    return true
end

-- Re-apply saved settings every time the character respawns.
function SettingsManager:StartAutoApply()
    if self._charConn then self._charConn:Disconnect() end
    local lp = game:GetService("Players").LocalPlayer
    self._charConn = lp.CharacterAdded:Connect(function()
        task.wait(1)   -- wait for character to fully load
        self:Load()
    end)
end

-- Stop listening for respawns.
function SettingsManager:StopAutoApply()
    if self._charConn then
        self._charConn:Disconnect()
        self._charConn = nil
    end
end

return SettingsManager
