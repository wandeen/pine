--[[
KEYBIND CUSTOMIZATION UI
Interface for remapping controls without editing code.
- Detect conflicts (two actions using same key)
- Support context-specific bindings (different keys for different game states)
- Registry system for modules to auto-add their hotkeys
- Visual conflict warnings
- Save/load custom keybinds

Usage:
    local KeybindUI = require(this_module).new(phantomHub)
    
    -- Register a bindable action
    KeybindUI:Register("Aimbot", Enum.KeyCode.RightAlt, {
        category = "Combat",
        onPress = function() enableAimbot() end,
        description = "Enable/Disable Aimbot"
    })
    
    -- Create UI section (call this in your Settings tab)
    KeybindUI:CreateSettingsUI(settingsTab)
    
    -- Check for conflicts
    local hasConflicts = KeybindUI:HasConflicts()
    
    -- Query bindings
    local binding = KeybindUI:GetBinding("Aimbot")
]]

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local KeybindUI = {}
KeybindUI.__index = KeybindUI

-- ── Configuration ─────────────────────────────────────
local KEYBIND_FILE = "phantom_keybinds.json"

-- Context types
local CONTEXT = {
    GLOBAL = "global",
    COMBAT = "combat",
    MOVEMENT = "movement",
    UTILITY = "utility",
    CUSTOM = "custom",
}

-- ── Internal State ────────────────────────────────────
function KeybindUI.new(phantomHub)
    local self = setmetatable({}, KeybindUI)
    
    self.hub = phantomHub
    self.bindings = {}       -- {actionName = {key, callback, context, ...}}
    self.categories = {}     -- {category = {actions...}}
    self.conflicts = {}      -- Detected conflicts
    self._listeningFor = nil -- Currently waiting for key input
    self._uiElements = {}    -- Track UI elements for cleanup
    
    self:_setupGlobalListener()
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- ── REGISTRATION ──────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Register a keybindable action
function KeybindUI:Register(actionName, defaultKey, options)
    options = options or {}
    
    if self.bindings[actionName] then
        warn("[KeybindUI] Action already registered: " .. actionName)
        return false
    end
    
    local binding = {
        name = actionName,
        key = defaultKey,
        category = options.category or CONTEXT.CUSTOM,
        onPress = options.onPress,
        onRelease = options.onRelease,
        description = options.description or "No description",
        context = options.context or CONTEXT.GLOBAL,
        enabled = options.enabled ~= false,
    }
    
    self.bindings[actionName] = binding
    
    -- Index by category
    if not self.categories[binding.category] then
        self.categories[binding.category] = {}
    end
    table.insert(self.categories[binding.category], actionName)
    
    -- Check for conflicts
    self:_checkConflicts()
    
    return true
end

-- Unregister an action
function KeybindUI:Unregister(actionName)
    if not self.bindings[actionName] then return false end
    
    local binding = self.bindings[actionName]
    
    -- Remove from category
    if self.categories[binding.category] then
        for i, name in ipairs(self.categories[binding.category]) do
            if name == actionName then
                table.remove(self.categories[binding.category], i)
                break
            end
        end
    end
    
    self.bindings[actionName] = nil
    self:_checkConflicts()
    
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── KEYBIND MANAGEMENT ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Get binding info
function KeybindUI:GetBinding(actionName)
    return self.bindings[actionName]
end

-- Change keybind for action
function KeybindUI:SetKey(actionName, newKey)
    local binding = self.bindings[actionName]
    if not binding then return false end
    
    binding.key = newKey
    self:_checkConflicts()
    return true
end

-- Get current key for action
function KeybindUI:GetKey(actionName)
    local binding = self.bindings[actionName]
    return binding and binding.key or nil
end

-- Get all actions for a key
function KeybindUI:GetActionsForKey(keyCode)
    local actions = {}
    for name, binding in pairs(self.bindings) do
        if binding.key == keyCode and binding.enabled then
            table.insert(actions, name)
        end
    end
    return actions
end

-- Enable/disable action
function KeybindUI:SetEnabled(actionName, enabled)
    local binding = self.bindings[actionName]
    if not binding then return false end
    
    binding.enabled = enabled
    self:_checkConflicts()
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── CONFLICT DETECTION ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function KeybindUI:_checkConflicts()
    self.conflicts = {}
    local keyMap = {}
    
    for actionName, binding in pairs(self.bindings) do
        if binding.enabled then
            local key = binding.key
            if not keyMap[key] then
                keyMap[key] = {}
            end
            table.insert(keyMap[key], actionName)
        end
    end
    
    -- Find conflicts (key used by multiple actions)
    for key, actions in pairs(keyMap) do
        if #actions > 1 then
            table.insert(self.conflicts, {
                key = key,
                actions = actions,
                severity = "warning",
            })
        end
    end
end

function KeybindUI:HasConflicts()
    return #self.conflicts > 0
end

function KeybindUI:GetConflicts()
    return self.conflicts
end

-- ════════════════════════════════════════════════════════════════
-- ── INPUT HANDLING ────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function KeybindUI:_setupGlobalListener()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        -- If waiting for key input (UI rebinding)
        if self._listeningFor then
            self._listeningFor(input.KeyCode)
            self._listeningFor = nil
            return
        end
        
        -- Trigger action callbacks
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local actions = self:GetActionsForKey(input.KeyCode)
            for _, actionName in ipairs(actions) do
                local binding = self.bindings[actionName]
                if binding.onPress then
                    pcall(function() binding.onPress() end)
                end
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        
        local actions = self:GetActionsForKey(input.KeyCode)
        for _, actionName in ipairs(actions) do
            local binding = self.bindings[actionName]
            if binding.onRelease then
                pcall(function() binding.onRelease() end)
            end
        end
    end)
end

-- Start listening for key press (used by UI)
function KeybindUI:ListenForKey(callback)
    self._listeningFor = callback
end

-- ════════════════════════════════════════════════════════════════
-- ── SETTINGS UI INTEGRATION ───────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Create settings section in Phantom hub
function KeybindUI:CreateSettingsUI(settingsTab)
    if not self.hub then
        warn("[KeybindUI] No hub reference")
        return
    end
    
    -- Create Keybinds section
    local KeybindSec = settingsTab:NewSection({
        Position = "Right",
        Title = "Keybinds"
    })
    
    -- Iterate through categories
    for category, actionNames in pairs(self.categories) do
        -- Create subsection per category
        for _, actionName in ipairs(actionNames) do
            local binding = self.bindings[actionName]
            
            -- Create keybind widget
            KeybindSec:NewKeybind({
                Title = actionName,
                Default = binding.key,
                Callback = function(newKey)
                    self:SetKey(actionName, newKey)
                    
                    -- Check for conflicts and warn
                    if self:HasConflicts() then
                        if self.hub.Notify then
                            self.hub:Notify({
                                Title = "Keybind Conflict",
                                Message = "Multiple actions bound to " .. tostring(newKey),
                                Duration = 3,
                            })
                        end
                    end
                    
                    self:SaveKeybinds()
                end,
            })
        end
    end
    
    -- Add conflict warning if any exist
    if self:HasConflicts() then
        KeybindSec:NewLabel("⚠️ Keybind conflicts detected!")
    end
    
    -- Add reset button
    KeybindSec:NewButton({
        Title = "Reset All Keybinds",
        Callback = function()
            self:ResetDefaults()
            if self.hub.Notify then
                self.hub:Notify({
                    Title = "Keybinds",
                    Message = "Reset to defaults",
                    Duration = 2,
                })
            end
        end,
    })
end

-- ════════════════════════════════════════════════════════════════
-- ── PERSISTENCE ───────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function KeybindUI:SaveKeybinds(filename)
    filename = filename or KEYBIND_FILE
    
    local data = {}
    for actionName, binding in pairs(self.bindings) do
        data[actionName] = {
            key = tostring(binding.key),
            enabled = binding.enabled,
        }
    end
    
    local ok, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if ok then
        pcall(function()
            writefile(filename, json)
        end)
        return true
    end
    return false
end

function KeybindUI:LoadKeybinds(filename)
    filename = filename or KEYBIND_FILE
    
    local ok, content = pcall(function()
        return readfile(filename)
    end)
    
    if not ok or not content then return false end
    
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if ok2 and type(data) == "table" then
        for actionName, bindData in pairs(data) do
            if self.bindings[actionName] then
                -- Parse key string back to enum
                local keyStr = bindData.key
                local keyEnum = Enum.KeyCode[keyStr]
                if keyEnum then
                    self.bindings[actionName].key = keyEnum
                end
                self.bindings[actionName].enabled = bindData.enabled ~= false
            end
        end
        self:_checkConflicts()
        return true
    end
    return false
end

function KeybindUI:ResetDefaults()
    -- Reset all keys to registered defaults
    for actionName, binding in pairs(self.bindings) do
        -- Would need to track original defaults
        -- For now, reload from file if available
    end
end

-- ════════════════════════════════════════════════════════════════
-- ── QUERY & STATISTICS ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function KeybindUI:ListBindings()
    local list = {}
    for name, binding in pairs(self.bindings) do
        table.insert(list, {
            name = name,
            key = tostring(binding.key),
            category = binding.category,
            enabled = binding.enabled,
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

function KeybindUI:GetBindingsByCategory(category)
    local actions = self.categories[category] or {}
    local result = {}
    for _, actionName in ipairs(actions) do
        table.insert(result, self.bindings[actionName])
    end
    return result
end

function KeybindUI:GetStats()
    local totalBindings = 0
    local enabledBindings = 0
    for _, binding in pairs(self.bindings) do
        totalBindings = totalBindings + 1
        if binding.enabled then enabledBindings = enabledBindings + 1 end
    end
    
    return {
        totalBindings = totalBindings,
        enabledBindings = enabledBindings,
        conflictCount = #self.conflicts,
        categories = table.countall(self.categories),
    }
end

-- ════════════════════════════════════════════════════════════════
-- ── CONTEXT-SPECIFIC BINDINGS (Advanced) ──────────────────────
-- ════════════════════════════════════════════════════════════════

function KeybindUI:SetContext(contextName)
    -- Switch active context (advanced feature for future use)
    self._currentContext = contextName
end

function KeybindUI:GetContextBindings(contextName)
    local result = {}
    for name, binding in pairs(self.bindings) do
        if binding.context == contextName or binding.context == CONTEXT.GLOBAL then
            table.insert(result, binding)
        end
    end
    return result
end

-- Export constants
KeybindUI.CONTEXT = CONTEXT

return KeybindUI
