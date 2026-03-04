--[[
PLUGIN SYSTEM
Runtime module loader with dependency management and error isolation.
- Load external scripts dynamically without restarting
- Enable/disable modules on the fly
- Dependency checking (Plugin A requires Plugin B)
- Isolation so one crashing plugin doesn't break everything
- Lifecycle hooks: OnLoad, OnEnable, OnDisable, OnUnload
- Plugin metadata and versioning

Usage:
    local PluginManager = require(this_module).new()
    
    -- Register a plugin
    PluginManager:Register("MyPlugin", {
        path = "my_plugin.lua",
        version = "1.0",
        dependencies = {"EventHooks"},
        description = "My awesome plugin",
        OnLoad = function() print("Loaded!") end,
        OnEnable = function() print("Enabled!") end,
        OnDisable = function() print("Disabled!") end,
    })
    
    -- Load and enable
    PluginManager:Load("MyPlugin")
    PluginManager:Enable("MyPlugin")
    
    -- Manage
    PluginManager:Disable("MyPlugin")
    PluginManager:Unload("MyPlugin")
    PluginManager:ListPlugins()
]]

local HttpService = game:GetService("HttpService")

local PluginManager = {}
PluginManager.__index = PluginManager

-- ── Configuration ─────────────────────────────────────
local PLUGIN_DIR = "phantom_plugins/"
local PLUGIN_METADATA_FILE = "phantom_plugin_metadata.json"

-- ── Plugin States ─────────────────────────────────────
local STATE_UNLOADED = "unloaded"
local STATE_LOADED = "loaded"
local STATE_ENABLED = "enabled"
local STATE_ERROR = "error"

-- ── Internal State ────────────────────────────────────
function PluginManager.new()
    local self = setmetatable({}, PluginManager)
    
    self.plugins = {}           -- {name = {metadata, state, instance, ...}}
    self.loadedModules = {}     -- {name = module}
    self.dependencyGraph = {}   -- {name = {dependencies...}}
    self.eventHooks = nil       -- Reference to event system (optional)
    
    self:_setupPluginDir()
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- ── INITIALIZATION ────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function PluginManager:SetEventHooks(eventHooks)
    self.eventHooks = eventHooks
end

function PluginManager:_setupPluginDir()
    pcall(function()
        if not isfolder(PLUGIN_DIR) then
            makefolder(PLUGIN_DIR)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- ── REGISTRATION ──────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Register a plugin with metadata
function PluginManager:Register(pluginName, metadata)
    if self.plugins[pluginName] then
        warn("[PluginManager] Plugin " .. pluginName .. " already registered")
        return false
    end
    
    if not metadata.path then
        error("[PluginManager] Plugin " .. pluginName .. " must have a path")
    end
    
    self.plugins[pluginName] = {
        name = pluginName,
        metadata = metadata,
        state = STATE_UNLOADED,
        instance = nil,
        error = nil,
    }
    
    -- Store dependencies
    if metadata.dependencies then
        self.dependencyGraph[pluginName] = metadata.dependencies
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── LOADING ───────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Check if all dependencies are loaded
function PluginManager:_checkDependencies(pluginName)
    local deps = self.dependencyGraph[pluginName]
    if not deps then return true end
    
    for _, depName in ipairs(deps) do
        local depPlugin = self.plugins[depName]
        if not depPlugin then
            return false, "Dependency not found: " .. depName
        end
        if depPlugin.state == STATE_UNLOADED or depPlugin.state == STATE_ERROR then
            return false, "Dependency not loaded: " .. depName
        end
    end
    
    return true
end

-- Load a plugin
function PluginManager:Load(pluginName)
    local plugin = self.plugins[pluginName]
    if not plugin then
        warn("[PluginManager] Plugin not registered: " .. pluginName)
        return false
    end
    
    if plugin.state ~= STATE_UNLOADED then
        return true  -- Already loaded
    end
    
    -- Check dependencies first
    local depOk, depMsg = self:_checkDependencies(pluginName)
    if not depOk then
        plugin.state = STATE_ERROR
        plugin.error = depMsg
        warn("[PluginManager] " .. depMsg)
        return false
    end
    
    -- Try to load the plugin file
    local ok, result = pcall(function()
        local filePath = PLUGIN_DIR .. plugin.metadata.path
        local content = readfile(filePath)
        local pluginFunc = loadstring(content)
        
        if pluginFunc then
            local instance = pluginFunc()
            return instance
        end
        
        error("Plugin returned nil")
    end)
    
    if not ok then
        plugin.state = STATE_ERROR
        plugin.error = tostring(result)
        warn("[PluginManager] Error loading plugin " .. pluginName .. ": " .. tostring(result))
        return false
    end
    
    -- Plugin loaded successfully
    plugin.instance = result
    plugin.state = STATE_LOADED
    plugin.error = nil
    self.loadedModules[pluginName] = result
    
    -- Call OnLoad hook
    if plugin.metadata.OnLoad then
        pcall(function() plugin.metadata.OnLoad(result) end)
    end
    
    -- Fire event
    if self.eventHooks then
        self.eventHooks:Fire("OnPluginLoaded", pluginName)
    end
    
    return true
end

-- Load all plugins in directory
function PluginManager:LoadAll()
    local loadOrder = self:_calculateLoadOrder()
    
    for _, pluginName in ipairs(loadOrder) do
        self:Load(pluginName)
    end
end

-- ════════════════════════════════════════════════════════════════
-- ── ENABLING ──────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Enable a loaded plugin
function PluginManager:Enable(pluginName)
    local plugin = self.plugins[pluginName]
    if not plugin then
        warn("[PluginManager] Plugin not registered: " .. pluginName)
        return false
    end
    
    if plugin.state == STATE_UNLOADED then
        self:Load(pluginName)
    end
    
    if plugin.state == STATE_ERROR then
        warn("[PluginManager] Cannot enable plugin in error state")
        return false
    end
    
    if plugin.state == STATE_ENABLED then
        return true  -- Already enabled
    end
    
    -- Call OnEnable hook
    if plugin.metadata.OnEnable then
        local ok, err = pcall(function()
            plugin.metadata.OnEnable(plugin.instance)
        end)
        if not ok then
            plugin.state = STATE_ERROR
            plugin.error = tostring(err)
            warn("[PluginManager] Error enabling " .. pluginName .. ": " .. tostring(err))
            return false
        end
    end
    
    plugin.state = STATE_ENABLED
    
    -- Fire event
    if self.eventHooks then
        self.eventHooks:Fire("OnPluginEnabled", pluginName)
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── DISABLING ─────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Disable a plugin
function PluginManager:Disable(pluginName)
    local plugin = self.plugins[pluginName]
    if not plugin then
        warn("[PluginManager] Plugin not registered: " .. pluginName)
        return false
    end
    
    if plugin.state == STATE_UNLOADED or plugin.state == STATE_LOADED then
        return true  -- Not enabled
    end
    
    -- Call OnDisable hook
    if plugin.metadata.OnDisable then
        pcall(function()
            plugin.metadata.OnDisable(plugin.instance)
        end)
    end
    
    plugin.state = STATE_LOADED
    
    -- Fire event
    if self.eventHooks then
        self.eventHooks:Fire("OnPluginDisabled", pluginName)
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── UNLOADING ─────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Unload a plugin completely
function PluginManager:Unload(pluginName)
    local plugin = self.plugins[pluginName]
    if not plugin then return false end
    
    -- Disable first if enabled
    if plugin.state == STATE_ENABLED then
        self:Disable(pluginName)
    end
    
    -- Call OnUnload hook
    if plugin.metadata.OnUnload then
        pcall(function()
            plugin.metadata.OnUnload(plugin.instance)
        end)
    end
    
    plugin.instance = nil
    plugin.state = STATE_UNLOADED
    plugin.error = nil
    self.loadedModules[pluginName] = nil
    
    -- Fire event
    if self.eventHooks then
        self.eventHooks:Fire("OnPluginUnloaded", pluginName)
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════
-- ── MANAGEMENT ────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Get plugin info
function PluginManager:GetPluginInfo(pluginName)
    local plugin = self.plugins[pluginName]
    if not plugin then return nil end
    
    return {
        name = plugin.name,
        state = plugin.state,
        version = plugin.metadata.version,
        description = plugin.metadata.description,
        dependencies = plugin.metadata.dependencies,
        error = plugin.error,
    }
end

-- List all plugins
function PluginManager:ListPlugins()
    local list = {}
    for name, plugin in pairs(self.plugins) do
        table.insert(list, {
            name = name,
            state = plugin.state,
            version = plugin.metadata.version,
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Get plugin by name
function PluginManager:GetPlugin(pluginName)
    local plugin = self.plugins[pluginName]
    return plugin and plugin.instance or nil
end

-- Check if plugin is enabled
function PluginManager:IsEnabled(pluginName)
    local plugin = self.plugins[pluginName]
    return plugin and plugin.state == STATE_ENABLED
end

-- ════════════════════════════════════════════════════════════════
-- ── DEPENDENCY RESOLUTION ─────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Calculate optimal load order using topological sort
function PluginManager:_calculateLoadOrder()
    local order = {}
    local visited = {}
    local visiting = {}
    
    local function visit(name)
        if visited[name] then return end
        if visiting[name] then
            error("[PluginManager] Circular dependency detected: " .. name)
        end
        
        visiting[name] = true
        
        local deps = self.dependencyGraph[name]
        if deps then
            for _, dep in ipairs(deps) do
                if self.plugins[dep] then
                    visit(dep)
                end
            end
        end
        
        visiting[name] = nil
        visited[name] = true
        table.insert(order, name)
    end
    
    for name in pairs(self.plugins) do
        visit(name)
    end
    
    return order
end

-- ════════════════════════════════════════════════════════════════
-- ── PERSISTENCE ───────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function PluginManager:SavePluginMetadata()
    local data = {}
    for name, plugin in pairs(self.plugins) do
        data[name] = {
            version = plugin.metadata.version,
            enabled = plugin.state == STATE_ENABLED,
        }
    end
    
    local ok, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if ok then
        pcall(function()
            writefile(PLUGIN_METADATA_FILE, json)
        end)
    end
end

-- ════════════════════════════════════════════════════════════════
-- ── DEBUG ─────────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function PluginManager:PrintDebug()
    print("\n=== PLUGIN MANAGER DEBUG ===")
    for name, plugin in pairs(self.plugins) do
        print(string.format(
            "%s: %s (v%s)",
            name, plugin.state, plugin.metadata.version
        ))
        if plugin.error then
            print("  Error: " .. plugin.error)
        end
    end
    print("=============================\n")
end

return PluginManager
