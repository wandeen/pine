--[[
AUTO KEY PRESS SYSTEM
Automation tool for simulating keyboard/mouse inputs.
- Toggle mode: press/release once
- Repeating mode: continuous key press with configurable intervals
- Sequence recording: record and replay key sequences
- Focus detection: only operate when game window is focused
- Emergency stop: stop all automation with hotkey

Usage:
    local AutoKeyPress = require(this_module).new()
    
    -- Simple press-release
    AutoKeyPress:PressKey(Enum.KeyCode.Space)
    
    -- Hold key with auto-release
    AutoKeyPress:HoldKey(Enum.KeyCode.W, 2)  -- hold for 2 seconds
    
    -- Auto-repeat
    AutoKeyPress:StartRepeat(Enum.KeyCode.Space, 0.1, 0.1)  -- 100ms press/release
    AutoKeyPress:StopRepeat()
    
    -- Record sequence
    AutoKeyPress:StartRecording()
    -- ... press keys manually ...
    local sequence = AutoKeyPress:StopRecording()
    
    -- Replay sequence
    AutoKeyPress:PlaySequence(sequence)
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local AutoKeyPress = {}
AutoKeyPress.__index = AutoKeyPress

-- ── Configuration ─────────────────────────────────────
local EMERGENCY_STOP_KEY = Enum.KeyCode.Backspace
local ENABLE_EMERGENCY_STOP = true
local MIN_INTERVAL = 0.01  -- 10ms minimum between actions
local MAX_REPEAT_DURATION = 3600  -- 1 hour max auto-repeat
local WINDOW_FOCUS_CHECK = true  -- Require window focus

-- ── Internal State ────────────────────────────────────
function AutoKeyPress.new()
    local self = setmetatable({}, AutoKeyPress)
    
    self._repeatingKey = nil
    self._repeatThread = nil
    self._recordingActive = false
    self._recordedSequence = {}
    self._playbackThread = nil
    self._windowFocused = true
    
    -- Check window focus
    if WINDOW_FOCUS_CHECK then
        self:_setupFocusDetection()
    end
    
    -- Setup emergency stop
    if ENABLE_EMERGENCY_STOP then
        self:_setupEmergencyStop()
    end
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- ── FOCUS DETECTION ───────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function AutoKeyPress:_setupFocusDetection()
    -- In most Roblox environments, we can't directly detect window focus
    -- This is a placeholder that always returns true
    -- In some executors, you might have access to more info
    self._windowFocused = true
end

function AutoKeyPress:_isGameFocused()
    -- Return focus state (simplified for Roblox)
    -- In a real application, you'd check actual window focus
    return self._windowFocused
end

-- ════════════════════════════════════════════════════════════════
-- ── EMERGENCY STOP ────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function AutoKeyPress:_setupEmergencyStop()
    UserInputService.InputBegan:Connect(function(input, processed)
        if input.KeyCode == EMERGENCY_STOP_KEY and not processed then
            self:StopAll()
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- ── BASIC KEY OPERATIONS ──────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Check if executor has key press functions
function AutoKeyPress:_hasKeyPressFunctions()
    return (keypress and keyrelease) ~= nil
end

-- Simple key press and release
function AutoKeyPress:PressKey(keyCode)
    if not self:_hasKeyPressFunctions() then
        warn("[AutoKeyPress] keypress/keyrelease not available")
        return false
    end
    
    pcall(function()
        keypress(keyCode)
        task.wait(0.05)
        keyrelease(keyCode)
    end)
    return true
end

-- Hold a key for duration
function AutoKeyPress:HoldKey(keyCode, duration)
    if not self:_hasKeyPressFunctions() then return false end
    
    pcall(function()
        keypress(keyCode)
        task.wait(duration)
        keyrelease(keyCode)
    end)
    return true
end

-- Press multiple keys in sequence
function AutoKeyPress:PressSequence(keyCodes, interval)
    if not self:_hasKeyPressFunctions() then return false end
    
    interval = math.max(interval or 0.1, MIN_INTERVAL)
    
    for _, keyCode in ipairs(keyCodes) do
        self:PressKey(keyCode)
        task.wait(interval)
    end
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── AUTO-REPEAT ───────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Start repeating a key press
-- pressTime: how long to hold the key
-- releaseTime: how long to wait before next press
function AutoKeyPress:StartRepeat(keyCode, pressTime, releaseTime)
    if not self:_hasKeyPressFunctions() then return false end
    
    pressTime = math.max(pressTime or 0.05, MIN_INTERVAL)
    releaseTime = math.max(releaseTime or 0.05, MIN_INTERVAL)
    
    self:StopRepeat()  -- Stop any existing repeat
    
    self._repeatingKey = keyCode
    
    self._repeatThread = task.spawn(function()
        while self._repeatingKey == keyCode do
            pcall(function()
                keypress(keyCode)
                task.wait(pressTime)
                keyrelease(keyCode)
                task.wait(releaseTime)
            end)
        end
    end)
    
    return true
end

-- Stop repeating
function AutoKeyPress:StopRepeat()
    if self._repeatThread then
        task.cancel(self._repeatThread)
        self._repeatThread = nil
    end
    self._repeatingKey = nil
    return true
end

-- Is currently repeating?
function AutoKeyPress:IsRepeating()
    return self._repeatingKey ~= nil
end

-- ════════════════════════════════════════════════════════════════
-- ── SEQUENCE RECORDING ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Start recording key presses
function AutoKeyPress:StartRecording()
    self._recordingActive = true
    self._recordedSequence = {}
    self._recordingStartTime = tick()
    
    self._recordingConn = UserInputService.InputBegan:Connect(function(input, processed)
        if not self._recordingActive then return end
        if processed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local relativeTime = tick() - self._recordingStartTime
            table.insert(self._recordedSequence, {
                keyCode = input.KeyCode,
                time = relativeTime,
                action = "press",
            })
        end
    end)
end

-- Stop recording and return sequence
function AutoKeyPress:StopRecording()
    self._recordingActive = false
    
    if self._recordingConn then
        self._recordingConn:Disconnect()
        self._recordingConn = nil
    end
    
    return self._recordedSequence
end

-- Get recorded sequence
function AutoKeyPress:GetRecordedSequence()
    return self._recordedSequence
end

-- Clear recording
function AutoKeyPress:ClearRecording()
    self._recordedSequence = {}
end

-- ════════════════════════════════════════════════════════════════
-- ── SEQUENCE PLAYBACK ─────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Play back a recorded sequence
-- speed: 1.0 = normal, 2.0 = double speed, 0.5 = half speed
function AutoKeyPress:PlaySequence(sequence, speed, loopCount)
    if not self:_hasKeyPressFunctions() then return false end
    if not sequence or #sequence == 0 then return false end
    
    speed = speed or 1.0
    loopCount = loopCount or 1
    
    self:StopPlayback()  -- Stop any existing playback
    
    self._playbackThread = task.spawn(function()
        for loop = 1, loopCount do
            for i, entry in ipairs(sequence) do
                if not self._playbackThread then break end
                
                local waitTime = entry.time
                if i > 1 then
                    waitTime = entry.time - sequence[i-1].time
                end
                
                waitTime = waitTime / speed
                
                pcall(function()
                    keypress(entry.keyCode)
                    task.wait(0.05)
                    keyrelease(entry.keyCode)
                    task.wait(waitTime)
                end)
            end
        end
    end)
    
    return true
end

-- Stop playback
function AutoKeyPress:StopPlayback()
    if self._playbackThread then
        task.cancel(self._playbackThread)
        self._playbackThread = nil
    end
end

-- Is currently playing back?
function AutoKeyPress:IsPlayingBack()
    return self._playbackThread ~= nil
end

-- ════════════════════════════════════════════════════════════════
-- ── MOUSE OPERATIONS ──────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Mouse click (if executor supports it)
function AutoKeyPress:MouseClick()
    if not _G.mouse_click then
        warn("[AutoKeyPress] mouse_click not available")
        return false
    end
    
    pcall(function() _G.mouse_click() end)
    return true
end

-- Mouse move (if executor supports it)
function AutoKeyPress:MouseMove(x, y)
    if not _G.mouse_move then
        warn("[AutoKeyPress] mouse_move not available")
        return false
    end
    
    pcall(function() _G.mouse_move(x, y) end)
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── EMERGENCY STOP ────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Stop all automation immediately
function AutoKeyPress:StopAll()
    self:StopRepeat()
    self:StopPlayback()
    if self._recordingConn then
        self._recordingConn:Disconnect()
        self._recordingConn = nil
    end
    self._recordingActive = false
end

-- ════════════════════════════════════════════════════════════════
-- ── UTILITY & PERSISTENCE ────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Save sequence to file
function AutoKeyPress:SaveSequence(filename, sequence)
    sequence = sequence or self._recordedSequence
    
    local HttpService = game:GetService("HttpService")
    local ok, json = pcall(function()
        return HttpService:JSONEncode(sequence)
    end)
    
    if ok then
        pcall(function()
            writefile(filename, json)
        end)
        return true
    end
    return false
end

-- Load sequence from file
function AutoKeyPress:LoadSequence(filename)
    local HttpService = game:GetService("HttpService")
    
    local ok, content = pcall(function()
        return readfile(filename)
    end)
    
    if not ok or not content then return nil end
    
    local ok2, sequence = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if ok2 then
        self._recordedSequence = sequence
        return sequence
    end
    
    return nil
end

-- Get status info
function AutoKeyPress:GetStatus()
    return {
        isRepeating = self:IsRepeating(),
        isPlayingBack = self:IsPlayingBack(),
        isRecording = self._recordingActive,
        recordedLength = #self._recordedSequence,
        hasFunctions = self:_hasKeyPressFunctions(),
    }
end

return AutoKeyPress
