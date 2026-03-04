--[[
EVENT HOOK SYSTEM
Centralized event manager for inter-component communication.
Supports priority-based execution, event cancellation, and filtering.

Usage:
    local EventHooks = require(this_module)
    
    -- Register listener
    EventHooks:Listen("OnDeath", function(player, killedBy)
        print(player.Name .. " died to " .. (killedBy and killedBy.Name or "suicide"))
    end, priority)
    
    -- Fire event
    EventHooks:Fire("OnDeath", player, killedBy)
    
    -- Cancel an event mid-propagation
    EventHooks:Fire("SomeEvent", arg1) -- cancelled event doesn't reach remaining listeners
]]

local EventHooks = {}
EventHooks.__index = EventHooks

-- ── Configuration ─────────────────────────────────────
local PRIORITY_HIGHEST = 1000
local PRIORITY_HIGH = 100
local PRIORITY_NORMAL = 0
local PRIORITY_LOW = -100
local PRIORITY_LOWEST = -1000

-- ── Internal State ────────────────────────────────────
local listeners = {}  -- {eventName = {{callback, priority, id}, ...}, ...}
local nextListenerId = 1
local eventStack = {}  -- track event firing for circular dependency detection
local maxStackDepth = 20

function EventHooks.new()
    return setmetatable({}, EventHooks)
end

-- ── Core: Register Listener ───────────────────────────
-- Register a callback to listen for an event.
-- Returns listener ID for later removal/management.
function EventHooks:Listen(eventName, callback, priority)
    if type(callback) ~= "function" then error("Callback must be a function") end
    
    priority = priority or PRIORITY_NORMAL
    
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    
    local listenerId = nextListenerId
    nextListenerId = nextListenerId + 1
    
    table.insert(listeners[eventName], {
        callback = callback,
        priority = priority,
        id = listenerId
    })
    
    -- Sort by priority descending (highest executes first)
    table.sort(listeners[eventName], function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        return a.id < b.id  -- FIFO for same priority
    end)
    
    return listenerId
end

-- ── Core: Fire Event ──────────────────────────────────
-- Fire an event with arguments. Listeners execute in priority order.
-- Returns (success, cancelledFlag, lastReturnValue)
function EventHooks:Fire(eventName, ...)
    -- Circular dependency detection
    if #eventStack >= maxStackDepth then
        warn("[EventHooks] Max event stack depth reached. Possible circular event loop.")
        return false, false, nil
    end
    
    table.insert(eventStack, eventName)
    
    local eventListeners = listeners[eventName]
    local cancelled = false
    local lastReturn = nil
    
    if eventListeners then
        for _, listener in ipairs(eventListeners) do
            if cancelled then break end
            
            local ok, result = pcall(function()
                return listener.callback(...)
            end)
            
            if ok then
                lastReturn = result
                -- Event cancellation: callback returns "CANCEL" string
                if result == "CANCEL" then
                    cancelled = true
                end
            else
                warn("[EventHooks] Listener error in " .. eventName .. ": " .. tostring(result))
            end
        end
    end
    
    table.remove(eventStack)
    
    return not cancelled, cancelled, lastReturn
end

-- ── Unlisten: Remove specific listener ─────────────────
function EventHooks:Unlisten(eventName, listenerId)
    if not listeners[eventName] then return end
    
    for i, listener in ipairs(listeners[eventName]) do
        if listener.id == listenerId then
            table.remove(listeners[eventName], i)
            return true
        end
    end
    
    return false
end

-- ── Clear all listeners for an event ──────────────────
function EventHooks:ClearEvent(eventName)
    listeners[eventName] = nil
end

-- ── Conditional Listener: Auto-unlisten after first fire ──
function EventHooks:Once(eventName, callback, priority)
    local listenerId = nil
    listenerId = self:Listen(eventName, function(...)
        self:Unlisten(eventName, listenerId)
        return callback(...)
    end, priority)
    return listenerId
end

-- ── Filtered Listener: Only fire if predicate returns true ──
function EventHooks:ListenIf(eventName, predicate, callback, priority)
    return self:Listen(eventName, function(...)
        if predicate(...) then
            return callback(...)
        end
    end, priority)
end

-- ── Get all listeners for an event ────────────────────
function EventHooks:GetListeners(eventName)
    return listeners[eventName] or {}
end

-- ── Get listener count ────────────────────────────────
function EventHooks:ListenerCount(eventName)
    return #(listeners[eventName] or {})
end

-- ── Debug: Print all registered events ─────────────────
function EventHooks:PrintRegistry()
    print("\n=== EVENT HOOKS REGISTRY ===")
    for eventName, eventListeners in pairs(listeners) do
        print(string.format("%s (%d listeners):", eventName, #eventListeners))
        for _, listener in ipairs(eventListeners) do
            print(string.format("  [%d] Priority: %d", listener.id, listener.priority))
        end
    end
    print("============================\n")
end

-- ── Export constants ──────────────────────────────────
EventHooks.PRIORITY = {
    HIGHEST = PRIORITY_HIGHEST,
    HIGH = PRIORITY_HIGH,
    NORMAL = PRIORITY_NORMAL,
    LOW = PRIORITY_LOW,
    LOWEST = PRIORITY_LOWEST,
}

return EventHooks
