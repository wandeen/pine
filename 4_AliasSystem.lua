--[[
ALIAS SYSTEM
Dynamic shortcut expansion without clipboard dependency.
- Define custom aliases that expand to longer text
- Support dynamic variables: %username%, %time%, %date%
- Parameterized aliases: /alias arg1 arg2 -> expanded text with $1, $2
- Inject expanded text into chat or execute as commands
- Persistent alias storage

Usage:
    local Aliases = require(this_module).new()
    
    -- Simple alias
    Aliases:Add("gg", "Good game!")
    Aliases:Add("tnx", "Thanks for the game")
    
    -- Alias with variables
    Aliases:Add("mytime", "Current time: %time%")
    
    -- Alias with parameters
    Aliases:Add("greet", "Hello, $1! I'm %username%")
    Aliases:Add("msg", "To $1: $2")
    
    -- Expand aliases (returns expanded text)
    print(Aliases:Expand("gg"))                    -- "Good game!"
    print(Aliases:Expand("greet John"))           -- "Hello, John! I'm YourUsername"
    print(Aliases:Expand("msg Bob hello there")) -- "To Bob: hello there"
    
    -- Inject into game chat (programmatically)
    Aliases:InjectToChat("gg")
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Alias = {}
Alias.__index = Alias

-- ── Configuration ─────────────────────────────────────
local ALIAS_FILE = "phantom_aliases.json"
local HttpService = game:GetService("HttpService")

-- ── Internal State ────────────────────────────────────
function Alias.new()
    local self = setmetatable({}, Alias)
    
    self.aliases = {}  -- {shortcut = {expansion, description}}
    self._localPlayer = Players.LocalPlayer
    
    return self
end

-- ════════════════════════════════════════════════════════════════
-- ── VARIABLE EXPANSION ────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Alias:_expandVariables(text)
    local player = self._localPlayer
    
    -- %username% -> player name
    text = text:gsub("%%username%%", player.Name)
    
    -- %userid% -> player user id
    text = text:gsub("%%userid%%", tostring(player.UserId))
    
    -- %time% -> HH:MM:SS
    text = text:gsub("%%time%%", os.date("%H:%M:%S"))
    
    -- %date% -> YYYY-MM-DD
    text = text:gsub("%%date%%", os.date("%Y-%m-%d"))
    
    -- %datetime% -> YYYY-MM-DD HH:MM:SS
    text = text:gsub("%%datetime%%", os.date("%Y-%m-%d %H:%M:%S"))
    
    -- Custom: %random% -> random number
    text = text:gsub("%%random%%", tostring(math.random(1000, 9999)))
    
    return text
end

-- ════════════════════════════════════════════════════════════════
-- ── PARAMETER EXPANSION ───────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Alias:_expandParameters(text, args)
    -- Replace $1, $2, $3, etc. with arguments
    for i, arg in ipairs(args) do
        text = text:gsub("%$" .. i, arg)
    end
    
    -- $* = all remaining arguments
    local allArgs = table.concat(args, " ")
    text = text:gsub("%$%*", allArgs)
    
    return text
end

-- ════════════════════════════════════════════════════════════════
-- ── CORE METHODS ──────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Add or update an alias
function Alias:Add(shortcut, expansion, description)
    if not shortcut or shortcut == "" then
        error("Shortcut cannot be empty")
    end
    
    shortcut = shortcut:lower()  -- Case-insensitive
    
    self.aliases[shortcut] = {
        expansion = expansion,
        description = description or "No description",
        created = os.time(),
    }
end

-- Remove an alias
function Alias:Remove(shortcut)
    shortcut = shortcut:lower()
    if self.aliases[shortcut] then
        self.aliases[shortcut] = nil
        return true
    end
    return false
end

-- Get alias info
function Alias:Get(shortcut)
    shortcut = shortcut:lower()
    return self.aliases[shortcut]
end

-- Check if alias exists
function Alias:Exists(shortcut)
    return self:Get(shortcut) ~= nil
end

-- List all aliases
function Alias:ListAll()
    local list = {}
    for shortcut, data in pairs(self.aliases) do
        table.insert(list, {
            shortcut = shortcut,
            expansion = data.expansion,
            description = data.description,
        })
    end
    table.sort(list, function(a, b) return a.shortcut < b.shortcut end)
    return list
end

-- ════════════════════════════════════════════════════════════════
-- ── EXPANSION ENGINE ──────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

-- Core expand function
-- Input: "alias arg1 arg2" or just "alias"
-- Output: expanded text with variables and parameters replaced
function Alias:Expand(input)
    if not input or input == "" then return "" end
    
    local parts = self:_splitInput(input)
    local shortcut = parts[1]:lower()
    local args = {}
    
    -- Extract arguments
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    -- Get alias definition
    local aliasData = self:Get(shortcut)
    if not aliasData then
        return nil  -- Alias not found
    end
    
    local expanded = aliasData.expansion
    
    -- Apply parameter expansion first ($1, $2, etc.)
    if #args > 0 then
        expanded = self:_expandParameters(expanded, args)
    end
    
    -- Apply variable expansion (%username%, %time%, etc.)
    expanded = self:_expandVariables(expanded)
    
    return expanded
end

-- Smart expansion with chain support
-- If expanded text contains another alias, expand recursively (max depth 5)
function Alias:ExpandSmart(input, depth)
    depth = depth or 0
    if depth > 5 then
        warn("[Alias] Max recursion depth reached")
        return input
    end
    
    local result = self:Expand(input)
    if not result then return nil end
    
    -- If result starts with another alias, expand it
    local firstWord = result:match("^(%S+)")
    if firstWord and self:Exists(firstWord) then
        return self:ExpandSmart(result, depth + 1)
    end
    
    return result
end

-- ════════════════════════════════════════════════════════════════
-- ── CHAT INJECTION (No Clipboard) ────────────────────────────
-- ════════════════════════────────────────────────────────────

-- Inject expanded alias into game chat
-- Note: This doesn't use clipboard; instead it simulates typing
-- Requires keypress/keyrelease from executor
function Alias:InjectToChat(input)
    local expanded = self:Expand(input)
    if not expanded then
        warn("[Alias] Alias not found: " .. input)
        return false
    end
    
    -- Try to use native chat API if available
    if _G.InjectChat then
        _G.InjectChat(expanded)
        return true
    end
    
    -- Fallback: return expanded text for manual injection
    return expanded
end

-- Get expanded text for manual use (return instead of inject)
function Alias:GetExpanded(input)
    return self:Expand(input)
end

-- ════════════════════════════════════════════════════════════════
-- ── PERSISTENCE ───────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Alias:Save(filename)
    filename = filename or ALIAS_FILE
    
    -- Build saveable structure
    local toSave = {}
    for shortcut, data in pairs(self.aliases) do
        toSave[shortcut] = {
            expansion = data.expansion,
            description = data.description,
        }
    end
    
    local ok, json = pcall(function()
        return HttpService:JSONEncode(toSave)
    end)
    
    if ok then
        pcall(function()
            writefile(filename, json)
        end)
        return true
    end
    return false
end

function Alias:Load(filename)
    filename = filename or ALIAS_FILE
    
    local ok, content = pcall(function()
        return readfile(filename)
    end)
    
    if not ok or not content then return false end
    
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if ok2 and type(data) == "table" then
        self.aliases = {}
        for shortcut, aliasData in pairs(data) do
            self.aliases[shortcut:lower()] = {
                expansion = aliasData.expansion,
                description = aliasData.description,
                created = aliasData.created or os.time(),
            }
        end
        return true
    end
    return false
end

-- ════════════════════════════════════════════════════════════════
-- ── UTILITY HELPERS ───────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════

function Alias:_splitInput(input)
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part)
    end
    return parts
end

function Alias:PrintAll()
    print("\n=== ALIASES ===")
    for shortcut, data in pairs(self.aliases) do
        print(string.format("  /%s -> %s", shortcut, data.expansion))
        if data.description then
            print(string.format("       (%s)", data.description))
        end
    end
    print("================\n")
end

function Alias:GetCount()
    local count = 0
    for _ in pairs(self.aliases) do
        count = count + 1
    end
    return count
end

function Alias:Clear()
    self.aliases = {}
end

return Alias
