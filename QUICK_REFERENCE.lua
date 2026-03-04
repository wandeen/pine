--[[
QUICK REFERENCE - PHANTOM HUB ENHANCEMENT SYSTEMS
API Documentation and Usage Examples

All 7 systems with their key methods and usage patterns.
]]

-- ════════════════════════════════════════════════════════════════
-- 1. EVENT HOOKS SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Creates a centralized event bus for inter-component communication.

Key Methods:
  :Listen(eventName, callback, priority) -> listenerId
    Register a listener. Returns ID for later removal.
    Priority: HIGHEST(1000) > HIGH(100) > NORMAL(0) > LOW(-100) > LOWEST(-1000)
    
  :Fire(eventName, ...) -> (success, cancelled, returnValue)
    Fire an event with arguments. Listeners execute in priority order.
    Listener can return "CANCEL" string to stop propagation.
    
  :Unlisten(eventName, listenerId) -> bool
    Remove a specific listener.
    
  :Once(eventName, callback, priority) -> listenerId
    Register listener that auto-removes after first fire.
    
  :ListenIf(eventName, predicate, callback, priority) -> listenerId
    Register listener with predicate filter.
    
  :GetListeners(eventName) -> {listeners}
    Get all listeners for an event.
    
  :ListenerCount(eventName) -> number
    Get count of listeners.

Usage Example:
  local EH = EventHooks.new()
  
  -- Register
  local id = EH:Listen("PlayerDied", function(victim, killer)
    print(victim .. " was killed by " .. killer)
  end, EH.PRIORITY.HIGH)
  
  -- Fire
  EH:Fire("PlayerDied", "John", "Bob")
  
  -- Remove
  EH:Unlisten("PlayerDied", id)
]]

-- ════════════════════════════════════════════════════════════════
-- 2. NOCLIP SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Robust collision bypass with multiple fallback methods.

Key Methods:
  :Enable()
    Start noclip. Auto-applies on respawn.
    
  :Disable()
    Stop noclip and restore collisions.
    
  :Toggle() -> bool
    Toggle noclip on/off. Returns new state.
    
  :SetSpeed(number)
    Set noclip speed (1-500). Default: 50.
    
  :GetSpeed() -> number
    Get current speed.
    
  :IsEnabled() -> bool
    Check if noclip is active.
    
  :Cleanup()
    Cleanup all connections on disconnect.

Usage Example:
  local NC = Noclip.new()
  
  -- Enable with custom speed
  NC:Enable()
  NC:SetSpeed(100)
  
  -- Later
  NC:Disable()
]]

-- ════════════════════════════════════════════════════════════════
-- 3. LOGGING SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Track chat messages, player joins/leaves with full metadata.

Chat Logging:
  :StartChatLogging()
    Begin capturing chat messages.
    
  :StopChatLogging()
    Stop capturing chat.
    
  :GetChatLog(playerNameFilter) -> {logs}
    Get logs, optionally filtered by player.
    
  :QueryChatByKeyword(keyword) -> {logs}
    Search chat by keyword.
    
  :QueryChatByTimeRange(startTime, endTime) -> {logs}
    Get logs within time range.
    
  :ExportChatLogs(filename) -> bool
    Save chat logs to JSON file.
    
  :LoadChatLogs(filename) -> bool
    Load chat logs from JSON file.
    
  :ClearChatLog()
    Clear all chat logs.

Join/Leave Logging:
  :StartJoinLogging()
    Begin tracking joins/leaves.
    
  :StopJoinLogging()
    Stop tracking.
    
  :GetJoinLog(playerNameFilter) -> {logs}
    Get join/leave history, optionally filtered.
    
  :ExportJoinLogs(filename) -> bool
    Save to JSON file.
    
  :LoadJoinLogs(filename) -> bool
    Load from JSON file.
    
  :ClearJoinLog()
    Clear join logs.

Maintenance:
  :CleanupOldLogs(retentionDays)
    Remove logs older than N days. Default: 30.
    
  :GetStats() -> {chatLogCount, joinLogCount, activePlayers}
    Get statistics.

Usage Example:
  local Log = Logger.new()
  
  Log:StartChatLogging()
  Log:StartJoinLogging()
  
  -- Later
  Log:ExportChatLogs("chats.json")
  Log:CleanupOldLogs(7)  -- Keep last 7 days
]]

-- ════════════════════════════════════════════════════════════════
-- 4. ALIAS SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Text expansion for common phrases and commands.
NO clipboard dependency.

Key Methods:
  :Add(shortcut, expansion, description)
    Create an alias. Expansion can contain variables and parameters.
    Variables: %username%, %userid%, %time%, %date%, %datetime%, %random%
    Parameters: $1, $2, $3... for arg substitution
    
  :Remove(shortcut) -> bool
    Delete an alias.
    
  :Get(shortcut) -> {expansion, description}
    Get alias info.
    
  :Exists(shortcut) -> bool
    Check if alias exists.
    
  :Expand(input) -> string
    Expand alias with args. Returns nil if not found.
    Input: "gg" or "greet John" or "msg Bob hello"
    
  :ExpandSmart(input) -> string
    Expand recursively (max depth 5).
    
  :InjectToChat(input) -> text
    Get expanded text (no clipboard needed).
    
  :ListAll() -> {list}
    Get all aliases.
    
  :Save(filename) -> bool
    Persist to JSON.
    
  :Load(filename) -> bool
    Load from JSON.
    
  :GetCount() -> number
    Total number of aliases.

Usage Example:
  local A = Aliases.new()
  
  -- Simple
  A:Add("gg", "Good game!")
  
  -- With variables
  A:Add("time", "It is %time%")
  
  -- With parameters
  A:Add("greet", "Hello $1! I'm %username%")
  
  -- Expand
  print(A:Expand("gg"))          -- "Good game!"
  print(A:Expand("greet Alice")) -- "Hello Alice! I'm YourName"
  
  A:Save()
]]

-- ════════════════════════════════════════════════════════════════
-- 5. AUTO KEY PRESS SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Keyboard/mouse input automation with sequences.

Key Methods:
  :PressKey(keyCode) -> bool
    Press and release a key once.
    
  :HoldKey(keyCode, duration) -> bool
    Hold key for N seconds.
    
  :PressSequence(keyCodes, interval) -> bool
    Press multiple keys with interval between.
    
  :StartRepeat(keyCode, pressTime, releaseTime) -> bool
    Continuously press key with specified timing.
    
  :StopRepeat() -> bool
    Stop repeating.
    
  :IsRepeating() -> bool
    Check if currently repeating.
    
  :StartRecording()
    Begin recording key presses.
    
  :StopRecording() -> sequence
    Stop and return recorded sequence.
    
  :PlaySequence(sequence, speed, loopCount) -> bool
    Playback recorded sequence.
    speed: 1.0=normal, 2.0=double speed
    
  :StopPlayback() -> bool
    Stop playback.
    
  :IsPlayingBack() -> bool
    Check if playing.
    
  :SaveSequence(filename, sequence) -> bool
    Save to JSON.
    
  :LoadSequence(filename) -> sequence
    Load from JSON.
    
  :StopAll()
    Emergency stop all automation.
    
  :GetStatus() -> {isRepeating, isPlayingBack, isRecording, ...}
    Get current state.

Usage Example:
  local AKP = AutoKeyPress.new()
  
  -- Simple press
  AKP:PressKey(Enum.KeyCode.Space)
  
  -- Hold
  AKP:HoldKey(Enum.KeyCode.W, 3)  -- Hold W for 3 seconds
  
  -- Auto-repeat
  AKP:StartRepeat(Enum.KeyCode.Space, 0.1, 0.1)
  task.wait(5)
  AKP:StopRepeat()
  
  -- Record and play
  AKP:StartRecording()
  -- player presses keys...
  local seq = AKP:StopRecording()
  AKP:PlaySequence(seq)
]]

-- ════════════════════════════════════════════════════════════════
-- 6. PLUGIN SYSTEM
-- ════════════════════════════════════════════════════════════════

--[[
Dynamic module loading with dependency management.

Key Methods:
  :Register(pluginName, metadata)
    Register a plugin with metadata:
    {
      path = "plugin.lua",
      version = "1.0",
      description = "...",
      dependencies = {"OtherPlugin"},
      OnLoad = function(instance) end,
      OnEnable = function(instance) end,
      OnDisable = function(instance) end,
      OnUnload = function(instance) end,
    }
    
  :Load(pluginName) -> bool
    Load plugin from file. Auto-loads dependencies.
    
  :LoadAll()
    Load all registered plugins in dependency order.
    
  :Enable(pluginName) -> bool
    Enable a loaded plugin.
    
  :Disable(pluginName) -> bool
    Disable plugin.
    
  :Unload(pluginName) -> bool
    Unload plugin completely.
    
  :GetPlugin(pluginName) -> instance
    Get plugin instance.
    
  :GetPluginInfo(pluginName) -> {info}
    Get plugin metadata.
    
  :ListPlugins() -> {list}
    Get all plugins and states.
    
  :IsEnabled(pluginName) -> bool
    Check if enabled.
    
  :SetEventHooks(eventHooks)
    Wire up event system for lifecycle hooks.

Usage Example:
  local PM = PluginManager.new()
  PM:SetEventHooks(EventHooks)
  
  PM:Register("MyPlugin", {
    path = "my_plugin.lua",
    version = "1.0",
    dependencies = {"EventHooks"},
    OnLoad = function() print("Loaded") end,
    OnEnable = function() print("Enabled") end,
  })
  
  PM:Load("MyPlugin")
  PM:Enable("MyPlugin")
]]

-- ════════════════════════════════════════════════════════════════
-- 7. KEYBIND CUSTOMIZATION UI
-- ════════════════════════════════════════════════════════════════

--[[
Configure hotkeys without editing code.

Key Methods:
  :Register(actionName, defaultKey, options)
    Register a bindable action.
    options: {category, description, onPress, onRelease, context, enabled}
    
  :Unregister(actionName) -> bool
    Remove action.
    
  :SetKey(actionName, newKey) -> bool
    Change keybind.
    
  :GetKey(actionName) -> keyCode
    Get current key.
    
  :GetActionsForKey(keyCode) -> {actions}
    Get all actions bound to key.
    
  :SetEnabled(actionName, enabled) -> bool
    Enable/disable action.
    
  :HasConflicts() -> bool
    Check if multiple actions share keys.
    
  :GetConflicts() -> {conflicts}
    Get conflict details.
    
  :CreateSettingsUI(phantomTab)
    Generate UI in Phantom Settings tab.
    
  :ListBindings() -> {list}
    Get all bindings.
    
  :SaveKeybinds(filename) -> bool
    Persist to JSON.
    
  :LoadKeybinds(filename) -> bool
    Load from JSON.
    
  :GetStats() -> {totalBindings, enabledBindings, conflictCount, ...}
    Get statistics.

Usage Example:
  local KUI = KeybindUI.new(Hub)
  
  KUI:Register("MyFeature", Enum.KeyCode.F, {
    category = "Combat",
    description = "Enable my feature",
    onPress = function() print("Enabled!") end,
  })
  
  KUI:CreateSettingsUI(SettingsTab)
  KUI:SaveKeybinds()
]]

-- ════════════════════════════════════════════════════════════════
-- COMMON PATTERNS
-- ════════════════════════════════════════════════════════════════

--[[
Pattern 1: Initialization
  local EH = EventHooks.new()
  local NC = Noclip.new()
  local Log = Logger.new()
  local A = Aliases.new()
  local AKP = AutoKeyPress.new()
  local PM = PluginManager.new()
  local KUI = KeybindUI.new(Hub)
  
  PM:SetEventHooks(EH)
  Log:StartChatLogging()
  Log:StartJoinLogging()
  A:Load()
  KUI:LoadKeybinds()

Pattern 2: Feature with Event + Keybind + Log
  KUI:Register("Aimbot", Enum.KeyCode.RightAlt, {
    category = "Combat",
    onPress = function()
      _abEnabled = not _abEnabled
      EH:Fire("AimbotToggled", _abEnabled)
      Log:_logChat(LocalPlayer, _abEnabled and "[AIMBOT ON]" or "[AIMBOT OFF]")
    end
  })
  
  EH:Listen("AimbotToggled", function(enabled)
    if enabled then startAimbot() else stopAimbot() end
  end, EH.PRIORITY.HIGH)

Pattern 3: Cleanup on Panic Key
  function _panicShutdown()
    NC:Cleanup()
    Log:Cleanup()
    AKP:StopAll()
    A:Save()
    KUI:SaveKeybinds()
  end

Pattern 4: Auto-Save Loop
  task.spawn(function()
    while true do
      task.wait(60)
      A:Save()
      KUI:SaveKeybinds()
      Log:ExportChatLogs()
    end
  end)
]]

-- ════════════════════════════════════════════════════════════════
-- ERROR HANDLING
-- ════════════════════════════════════════════════════════════════

--[[
All systems use pcall() internally for safety.
Errors are logged but don't crash the script.

If a system fails:
  1. Check file paths are correct
  2. Verify executor has readfile/writefile (for persistence)
  3. Check Lua syntax in callback functions
  4. Use PrintDebug() methods to diagnose

Example debug output:
  EH:PrintRegistry()
  PM:PrintDebug()
  KUI:GetStats()
  Log:GetStats()
]]

-- ════════════════════════════════════════════════════════════════
-- SYSTEM DEPENDENCIES
-- ════════════════════════════════════════════════════════════════

--[[
EventHooks:
  - No dependencies
  
Noclip:
  - RunService (always available)
  - PhysicsService (optional, graceful fail if not available)
  
Logger:
  - Players service (always available)
  - HttpService (for JSON encode/decode)
  
Aliases:
  - HttpService (optional, for persistence)
  - Players service (for %username% variable)
  
AutoKeyPress:
  - UserInputService (required)
  - keypress/keyrelease (executor-specific, graceful fail)
  
PluginManager:
  - HttpService (for JSON)
  - readfile/loadstring (executor-specific)
  
KeybindUI:
  - UserInputService (required)
  - HttpService (optional, for persistence)
  - Phantom Hub (required)
]]

print("Quick Reference loaded. See file for detailed API documentation.")
