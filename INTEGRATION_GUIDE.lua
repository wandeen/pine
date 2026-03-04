--[[
PHANTOM HUB ENHANCEMENT - INTEGRATION GUIDE
Complete setup instructions for adding all 7 systems to Phantom

This guide shows how to integrate:
1. Event Hook System
2. Noclip System (replacement)
3. Logging System
4. Alias System
5. Auto Key Press System
6. Plugin System
7. Keybind Customization UI

Priority implementation order is listed below.
]]

-- ════════════════════════════════════════════════════════════════
-- STEP 1: LOAD ALL MODULES (at top of Hub.lua)
-- ════════════════════════════════════════════════════════════════

local EventHooks = require("path/to/1_EventHooks").new()
local Noclip = require("path/to/2_NoclipSystem").new()
local Logger = require("path/to/3_LoggingSystem").new()
local Aliases = require("path/to/4_AliasSystem").new()
local AutoKeyPress = require("path/to/5_AutoKeyPressSystem").new()
local PluginManager = require("path/to/6_PluginSystem").new()
local KeybindUI = require("path/to/7_KeybindUI").new(Hub)

-- ════════════════════════════════════════════════════════════════
-- STEP 2: WIRE SYSTEMS TOGETHER
-- ════════════════════════════════════════════════════════════════

-- Tell plugin system about event hooks
PluginManager:SetEventHooks(EventHooks)

-- Load aliases from file
Aliases:Load()

-- Load keybinds from file
KeybindUI:LoadKeybinds()

-- ════════════════════════════════════════════════════════════════
-- STEP 3: REPLACE EXISTING NOCLIP WITH NEW SYSTEM
-- ════════════════════════════════════════════════════════════════

-- In your Movement/Utility tab where you have noclip toggle:

local NoclipSec = MovementTab:NewSection({Position="Left", Title="Movement"})

NoclipSec:NewToggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        if v then
            Noclip:Enable()
            Hub:Notify({Title="Noclip", Message="Enabled", Duration=2})
        else
            Noclip:Disable()
            Hub:Notify({Title="Noclip", Message="Disabled", Duration=2})
        end
    end
})

NoclipSec:NewSlider({
    Title = "Noclip Speed",
    Min = 10,
    Max = 500,
    Default = 50,
    Callback = function(v)
        Noclip:SetSpeed(v)
    end
})

-- ════════════════════════════════════════════════════════════════
-- STEP 4: SETUP LOGGING
-- ════════════════════════════════════════════════════════════════

-- Start logging in Settings tab
Logger:StartChatLogging()
Logger:StartJoinLogging()

-- Add logging controls to Settings tab
local LoggingSec = SettingsTab:NewSection({Position="Right", Title="Activity Logging"})

LoggingSec:NewToggle({
    Title = "Chat Logging",
    Default = true,
    Callback = function(v)
        if v then
            Logger:StartChatLogging()
        else
            Logger:StopChatLogging()
        end
    end
})

LoggingSec:NewToggle({
    Title = "Join/Leave Logging",
    Default = true,
    Callback = function(v)
        if v then
            Logger:StartJoinLogging()
        else
            Logger:StopJoinLogging()
        end
    end
})

LoggingSec:NewButton({
    Title = "Export Chat Logs",
    Callback = function()
        Logger:ExportChatLogs()
        Hub:Notify({Title="Exported", Message="Chat logs saved", Duration=2})
    end
})

LoggingSec:NewButton({
    Title = "Export Join Logs",
    Callback = function()
        Logger:ExportJoinLogs()
        Hub:Notify({Title="Exported", Message="Join logs saved", Duration=2})
    end
})

LoggingSec:NewButton({
    Title = "Cleanup Old Logs",
    Callback = function()
        Logger:CleanupOldLogs(7)  -- Keep last 7 days
        Hub:Notify({Title="Cleanup", Message="Old logs removed", Duration=2})
    end
})

-- ════════════════════════════════════════════════════════════════
-- STEP 5: SETUP ALIASES
-- ════════════════════════════════════════════════════════════════

-- Predefined aliases for common phrases
Aliases:Add("gg", "Good game!")
Aliases:Add("tnx", "Thanks!")
Aliases:Add("lol", "Haha!")
Aliases:Add("wp", "Well played!")
Aliases:Add("ns", "Nice shot!")
Aliases:Add("sorry", "Sorry about that")
Aliases:Add("bye", "Goodbye everyone!")

-- Aliases with variables
Aliases:Add("time", "Current time: %time%")
Aliases:Add("greet", "Hello %username%!")
Aliases:Add("whoami", "I'm %username% (ID: %userid%)")

-- Parameterized aliases
Aliases:Add("hello", "Hey $1, how are you?")
Aliases:Add("msg", "To $1: $2")

Aliases:Save()

-- Add Aliases section to Settings
local AliasSec = SettingsTab:NewSection({Position="Left", Title="Chat Aliases"})

AliasSec:NewLabel("Use /alias to expand shortcuts")
AliasSec:NewLabel("Example: /gg -> Good game!")

AliasSec:NewButton({
    Title = "Save Aliases",
    Callback = function()
        Aliases:Save()
        Hub:Notify({Title="Aliases", Message="Saved", Duration=2})
    end
})

-- ════════════════════════════════════════════════════════════════
-- STEP 6: SETUP EVENT HOOKS
-- ════════════════════════════════════════════════════════════════

-- Example: Auto-notify on player join
EventHooks:Listen("OnJoin", function(player)
    Hub:Notify({
        Title = "Player Joined",
        Message = player.Name .. " joined the game",
        Duration = 3,
    })
end, EventHooks.PRIORITY.HIGH)

-- Example: Log on death
EventHooks:Listen("OnDeath", function(player)
    print("[EVENT] " .. player.Name .. " died")
    Logger:_logChat(player, "[DIED]")
end)

-- Fired by your aimbot/combat features:
-- EventHooks:Fire("OnDeath", player, killedBy)
-- EventHooks:Fire("OnDamage", player, damage)
-- etc.

-- ════════════════════════════════════════════════════════════════
-- STEP 7: SETUP AUTO KEY PRESS
-- ════════════════════════════════════════════════════════════════

-- Add Auto Key Press section
local AutoKeySec = UtilitySec:NewSection({Position="Right", Title="Automation"})

AutoKeySec:NewToggle({
    Title = "Record Key Sequence",
    Default = false,
    Callback = function(v)
        if v then
            AutoKeyPress:StartRecording()
            Hub:Notify({Title="Recording", Message="Press keys to record sequence", Duration=2})
        else
            local sequence = AutoKeyPress:StopRecording()
            if #sequence > 0 then
                AutoKeyPress:SaveSequence("phantom_keyseq.json", sequence)
                Hub:Notify({Title="Recorded", Message=#sequence.." keys saved", Duration=2})
            end
        end
    end
})

AutoKeySec:NewButton({
    Title = "Play Last Sequence",
    Callback = function()
        local sequence = AutoKeyPress:LoadSequence("phantom_keyseq.json")
        if sequence then
            AutoKeyPress:PlaySequence(sequence, 1.0, 1)
            Hub:Notify({Title="Playing", Message="Key sequence playback started", Duration=2})
        end
    end
})

AutoKeySec:NewSlider({
    Title = "Repeat Interval (ms)",
    Min = 10,
    Max = 500,
    Default = 100,
    Callback = function(v)
        -- Store for later use
        _G.AutoKeyPressInterval = v / 1000
    end
})

-- ════════════════════════════════════════════════════════════════
-- STEP 8: SETUP KEYBIND CUSTOMIZATION
-- ════════════════════════════════════════════════════════════════

-- Register all bindable actions
KeybindUI:Register("Aimbot Toggle", Enum.KeyCode.RightAlt, {
    category = "Combat",
    description = "Toggle aimbot on/off",
    onPress = function()
        _abEnabled = not _abEnabled
        if _abEnabled then _startAimbot() else _stopAimbot() end
    end
})

KeybindUI:Register("Noclip Toggle", Enum.KeyCode.N, {
    category = "Movement",
    description = "Toggle noclip",
    onPress = function()
        Noclip:Toggle()
    end
})

KeybindUI:Register("Fly Toggle", Enum.KeyCode.F, {
    category = "Movement",
    description = "Toggle flight",
    onPress = function()
        if _flyEnabled then stopFly() else startFly() end
    end
})

KeybindUI:Register("ESP Toggle", Enum.KeyCode.E, {
    category = "Visuals",
    description = "Toggle ESP",
    onPress = function()
        if _espEnabled then clearESP() else enableESP() end
    end
})

-- Create keybind UI in Settings
KeybindUI:CreateSettingsUI(SettingsTab)

KeybindUI:SaveKeybinds()

-- ════════════════════════════════════════════════════════════════
-- STEP 9: SETUP PLUGIN SYSTEM (OPTIONAL)
-- ════════════════════════════════════════════════════════════════

-- Register plugins
PluginManager:Register("CustomAimbotPlugin", {
    path = "custom_aimbot.lua",
    version = "1.0",
    description = "Enhanced aimbot with ML predictions",
    dependencies = {"EventHooks"},
    OnLoad = function()
        print("[Plugin] Custom aimbot loaded")
    end,
    OnEnable = function()
        print("[Plugin] Custom aimbot enabled")
    end,
    OnDisable = function()
        print("[Plugin] Custom aimbot disabled")
    end,
})

-- Load and enable plugins
-- PluginManager:Load("CustomAimbotPlugin")
-- PluginManager:Enable("CustomAimbotPlugin")

-- Add plugin management to Settings
local PluginSec = SettingsTab:NewSection({Position="Right", Title="Plugins"})

PluginSec:NewButton({
    Title = "Load All Plugins",
    Callback = function()
        PluginManager:LoadAll()
        Hub:Notify({Title="Plugins", Message="All loaded", Duration=2})
    end
})

-- ════════════════════════════════════════════════════════════════
-- STEP 10: FIRE EVENTS FROM EXISTING FEATURES
-- ════════════════════════════════════════════════════════════════

-- Hook your existing code to fire events

-- In your player respawn code:
LocalPlayer.CharacterAdded:Connect(function(char)
    EventHooks:Fire("OnSpawn", LocalPlayer)
end)

-- In your damage detection code:
-- EventHooks:Fire("OnDamage", targetPlayer, damage)

-- In your player join detection:
Players.PlayerAdded:Connect(function(plr)
    EventHooks:Fire("OnJoin", plr)
end)

-- ════════════════════════════════════════════════════════════════
-- STEP 11: CLEANUP ON PANIC KEY
-- ════════════════════════════════════════════════════════════════

-- Update your _panicShutdown function to include cleanup:

_panicShutdown = function()
    -- ... existing panic code ...
    
    -- New cleanup
    pcall(function() Noclip:Cleanup() end)
    pcall(function() Logger:Cleanup() end)
    pcall(function() AutoKeyPress:StopAll() end)
    pcall(function() Aliases:Save() end)
    pcall(function() KeybindUI:SaveKeybinds() end)
    
    _showDisengagedOverlay()
end

-- ════════════════════════════════════════════════════════════════
-- STEP 12: AUTOSAVE ALL SYSTEMS
-- ════════════════════════════════════════════════════════════════

-- Periodically save all data
task.spawn(function()
    while true do
        task.wait(60)  -- Every 60 seconds
        pcall(function() Aliases:Save() end)
        pcall(function() KeybindUI:SaveKeybinds() end)
        pcall(function() Logger:ExportChatLogs() end)
        pcall(function() Logger:ExportJoinLogs() end)
    end
end)

-- ════════════════════════════════════════════════════════════════
-- EXAMPLE: USING MULTIPLE SYSTEMS TOGETHER
-- ════════════════════════════════════════════════════════════════

--[[ Example: Combat feature using Event Hooks + Keybinds + Logger

local function onAimbotEnable()
    EventHooks:Fire("OnAimbotToggle", true)
    Logger:_logChat(LocalPlayer, "[AIMBOT] Enabled")
end

KeybindUI:Register("Aimbot", Enum.KeyCode.RightAlt, {
    category = "Combat",
    onPress = onAimbotEnable,
})

EventHooks:Listen("OnAimbotToggle", function(enabled)
    if enabled then
        print("[HOOK] Starting aimbot")
        startAimbot()
    end
end, EventHooks.PRIORITY.HIGH)
]]

-- ════════════════════════════════════════════════════════════════
-- FILE STRUCTURE REFERENCE
-- ════════════════════════════════════════════════════════════════

--[[
Your executor folder should look like:
/
├── Hub.lua (main Phantom hub - includes integration)
├── Phantom.lua (UI library)
├── SettingsManager.lua (existing)
├── 1_EventHooks.lua
├── 2_NoclipSystem.lua
├── 3_LoggingSystem.lua
├── 4_AliasSystem.lua
├── 5_AutoKeyPressSystem.lua
├── 6_PluginSystem.lua
└── 7_KeybindUI.lua

Data files (auto-created):
├── phantom_aliases.json
├── phantom_keybinds.json
├── phantom_chat_logs.json
├── phantom_join_logs.json
├── phantom_keyseq.json
└── phantom_plugin_metadata.json
]]

-- ════════════════════════════════════════════════════════════════
-- TROUBLESHOOTING
-- ════════════════════════════════════════════════════════════════

--[[
Problem: Noclip not working?
- Check that RenderStepped is firing (some games disable it)
- Try touch-based noclip fallback
- Ensure CanCollide = false is applied every frame

Problem: Keybinds not triggering?
- Make sure UserInputService isn't blocked
- Check that GUI isn't intercepting input
- Verify callback function exists

Problem: Plugins not loading?
- Check file path is correct
- Verify dependencies are loaded first
- Check for Lua syntax errors in plugin file

Problem: Logs not saving?
- Ensure writefile/readfile available
- Check file paths are correct
- Make sure sufficient disk space

Problem: Event loops not firing?
- Verify Fire() is being called with correct arguments
- Check callback function doesn't error
- Use PrintRegistry() to debug listeners
]]

-- ════════════════════════════════════════════════════════════════
-- END OF INTEGRATION GUIDE
-- ════════════════════════════════════════════════════════════════
