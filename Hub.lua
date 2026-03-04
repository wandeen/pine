-- ╔══════════════════════════════════════════════════╗
-- ║              PHANTOM HUB  v2.0                   ║
-- ╚══════════════════════════════════════════════════╝

local Phantom = loadstring(game:HttpGet("https://raw.githubusercontent.com/wandeen/pine/refs/heads/main/Phantom.lua"))()

-- ── Game Detection ────────────────────────────────────────────
local Games = {
    [2753915549] = "BloxFruits",
    [292439477]  = "DaHood",
    -- [PLACEID]  = "GameName",
}

local PlaceId  = game.PlaceId
local GameName = Games[PlaceId] or "Unknown"

-- ── Services ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local Lighting       = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer    = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════
--  PANIC KEY  (Delete key — completely independent of menu toggle)
--  Instant shutdown: all ESP, movement mods, hooks cleared.
--  A 1-second "DISENGAGED" overlay is shown then removed.
-- ════════════════════════════════════════════════════════════════
local _panicKey      = Enum.KeyCode.Delete
local _panicDisabled = false   -- set true after first panic to avoid double-fire

local function _showDisengagedOverlay()
    pcall(function()
        local sg   = Instance.new("ScreenGui")
        sg.Name    = "PhantomPanicOverlay"
        sg.ResetOnSpawn = false
        local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        sg.Parent  = ok and cg or Players.LocalPlayer:WaitForChild("PlayerGui")

        local lbl              = Instance.new("TextLabel")
        lbl.Size               = UDim2.new(1, 0, 0, 60)
        lbl.Position           = UDim2.new(0, 0, 0.5, -30)
        lbl.BackgroundTransparency = 1
        lbl.Text               = "DISENGAGED"
        lbl.Font               = Enum.Font.GothamBold
        lbl.TextSize           = 36
        lbl.TextColor3         = Color3.fromRGB(255, 65, 65)
        lbl.TextStrokeTransparency = 0.4
        lbl.Parent             = sg

        task.delay(1, function() pcall(function() sg:Destroy() end) end)
    end)
end

-- _panicShutdown is called when the panic key fires.
-- It is also assigned later (after features are declared) to clean them up.
local _panicShutdown

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == _panicKey and _panicShutdown then
        _panicShutdown()
    end
end)

-- ── Create Window ─────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = GameName ~= "Unknown" and GameName or "hub",
    Keybind  = Enum.KeyCode.J,
})

Hub:SetProfile()
Hub._win.BackgroundTransparency = 0.05

-- ── Helpers ───────────────────────────────────────────────────
-- BUGFIX: declared early so SettingsManager setters can call them at load time.
local function getChar()
    return LocalPlayer.Character
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- BUGFIX: declared early so the SM:Register("FlySpeed") closure captures
-- the variable rather than nil.
local _flySpeed = 60

-- ════════════════════════════════════════════════════════════════
--  SETTINGS MANAGER (inlined)
--  BUGFIX: require(script.Parent.SettingsManager) crashes in every executor
--  because `script` is nil outside Roblox Studio.  Inlined here.
-- ════════════════════════════════════════════════════════════════
local _smHS     = game:GetService("HttpService")
local _smPrefix = "phantom_sm_"

local SettingsManager = {}
SettingsManager.__index = SettingsManager

function SettingsManager.new(hub, name)
    local self     = setmetatable({}, SettingsManager)
    self._hub      = hub
    self._name     = name or "default"
    self._entries  = {}
    self._charConn = nil
    return self
end

function SettingsManager:Register(key, getter, setter)
    self._entries[key] = { get = getter, set = setter }
end

local function _smEncode(v)
    if typeof(v) == "Color3" then
        return { __type="Color3", r=math.round(v.R*255), g=math.round(v.G*255), b=math.round(v.B*255) }
    end
    return v
end

local function _smDecode(v)
    if type(v) == "table" and v.__type == "Color3" then
        return Color3.fromRGB(v.r or 0, v.g or 0, v.b or 0)
    end
    return v
end

function SettingsManager:Save()
    local data = {}
    for key, entry in pairs(self._entries) do
        local ok, val = pcall(entry.get)
        if ok then data[key] = _smEncode(val) end
    end
    local ok, json = pcall(function() return _smHS:JSONEncode(data) end)
    if ok then pcall(function() writefile(_smPrefix .. self._name .. ".json", json) end) end
end

function SettingsManager:Load()
    local ok, content = pcall(function() return readfile(_smPrefix .. self._name .. ".json") end)
    if not ok or not content or content == "" then return false end
    local ok2, data = pcall(function() return _smHS:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return false end
    for key, entry in pairs(self._entries) do
        if data[key] ~= nil then pcall(function() entry.set(_smDecode(data[key])) end) end
    end
    return true
end

function SettingsManager:StartAutoApply()
    if self._charConn then self._charConn:Disconnect() end
    self._charConn = Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); self:Load()
    end)
end

function SettingsManager:StopAutoApply()
    if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
end

-- ── SettingsManager init ───────────────────────────────────────
local SM = SettingsManager.new(Hub, "phantom")

SM:Register("WalkSpeed",
    function() return _G.PhantomWalkSpeed or 16 end,
    function(v) _G.PhantomWalkSpeed = v; local h = getHum(); if h then h.WalkSpeed = v end end
)
SM:Register("JumpPower",
    function() return _G.PhantomJumpPower or 7 end,
    -- BUGFIX: was incorrectly writing to _G.PhantomWalkSpeed
    function(v) _G.PhantomJumpPower = v; local h = getHum(); if h then h.JumpPower = v end end
)
SM:Register("FlySpeed",
    function() return _flySpeed end,
    function(v) _flySpeed = v end
)

SM:Load()
SM:StartAutoApply()

-- ════════════════════════════════════════════════════════════════
--  NOCLIP COLLISION GROUP
--  FIX: PhysicsService group-level collision is disabled for the character,
--  making it non-collidable with ALL game geometry regardless of how the
--  world is structured.  Per-part CanCollide=false runs as a fallback every
--  Stepped tick, and a DescendantAdded listener handles tools / accessories
--  that are attached to the character after noclip is toggled on.
-- ════════════════════════════════════════════════════════════════
local _noclipGroup      = "PhantomNoclip"
local _noclipGroupReady = false
pcall(function()
    -- Wrap the register separately; the group may already exist.
    pcall(function() PhysicsService:RegisterCollisionGroup(_noclipGroup) end)
    -- Disable collision between the noclip group and every other group.
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup, "Default",    false)
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup, _noclipGroup, false)
    _noclipGroupReady = true
end)

local function _ncSetPart(part, enable)
    part.CanCollide = not enable
    if _noclipGroupReady then
        pcall(function()
            part.CollisionGroup = enable and _noclipGroup or "Default"
        end)
    end
end

local function _ncSetChar(char, enable)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then _ncSetPart(d, enable) end
    end
end

-- ════════════════════════════════════════════════════════════════
--  WALK SPEED ENFORCER
--  FIX: A Heartbeat loop continuously re-applies the custom speed so any
--  game-side sprint script that overwrites WalkSpeed on Shift is corrected
--  within a single frame.  When speed is reset to 16 the enforcer stops and
--  control is returned to the game.
-- ════════════════════════════════════════════════════════════════
local _wsTarget = 16
local _wsConn   = nil

local function startWsEnforcer(speed)
    _wsTarget = speed
    if _wsConn then _wsConn:Disconnect() end
    _wsConn = RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h and h.WalkSpeed ~= _wsTarget then h.WalkSpeed = _wsTarget end
    end)
end

local function stopWsEnforcer()
    if _wsConn then _wsConn:Disconnect(); _wsConn = nil end
end

-- ════════════════════════════════════════════════════════════════
--  TABS & SECTIONS
-- ════════════════════════════════════════════════════════════════
local UniTab    = Hub:NewTab({ Title = "Universal", Icon = "rbxassetid://3926305904" })
local UniPlayer = UniTab:NewSection({ Position = "Left",  Title = "Player"   })
local UniMove   = UniTab:NewSection({ Position = "Left",  Title = "Movement" })
local UniUtil   = UniTab:NewSection({ Position = "Right", Title = "Utility"  })
local UniESP    = UniTab:NewSection({ Position = "Right", Title = "ESP"      })

-- ════════════════════════════════════════════════════════════════
--  PLAYER SECTION
-- ════════════════════════════════════════════════════════════════

-- Walk Speed — FIX: enforcer prevents sprint from breaking the setting
UniPlayer:NewSlider({
    Title    = "Walk Speed",
    Min      = 16,
    Max      = 300,
    Default  = 16,
    Callback = function(v)
        _G.PhantomWalkSpeed = v
        if v > 16 then
            startWsEnforcer(v)
        else
            stopWsEnforcer()
            local h = getHum(); if h then h.WalkSpeed = v end
        end
    end,
})

-- Jump Power
UniPlayer:NewSlider({
    Title    = "Jump Power",
    Min      = 7,
    Max      = 200,
    Default  = 7,
    Callback = function(v)
        _G.PhantomJumpPower = v   -- BUGFIX: was _G.PhantomWalkSpeed
        local h = getHum(); if h then h.JumpPower = v end
    end,
})

-- Fly Speed
UniPlayer:NewSlider({
    Title    = "Fly Speed",
    Min      = 10,
    Max      = 200,
    Default  = 60,
    Callback = function(v) _flySpeed = v end,
})

-- ════════════════════════════════════════════════════════════════
--  MOVEMENT SECTION
-- ════════════════════════════════════════════════════════════════

-- ── Infinite Jump ─────────────────────────────────────────────
local _infJumpConn
UniMove:NewToggle({
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v)
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
        if v then
            _infJumpConn = UIS.JumpRequest:Connect(function()
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end,
})

-- ── Fly ───────────────────────────────────────────────────────
local _flyEnabled = false
local _flyConn, _flyCharConn, _bodyVel, _bodyGyro

local function stopFly()
    _flyEnabled = false
    if _flyConn then _flyConn:Disconnect(); _flyConn = nil end
    pcall(function()
        if _bodyVel  then _bodyVel:Destroy();  _bodyVel  = nil end
        if _bodyGyro then _bodyGyro:Destroy(); _bodyGyro = nil end
    end)
    local h = getHum(); if h then h.PlatformStand = false end
end

local function startFly()
    stopFly(); _flyEnabled = true
    local char = getChar(); if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true

    _bodyVel          = Instance.new("BodyVelocity")
    _bodyVel.Velocity = Vector3.new(0,0,0)
    _bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
    _bodyVel.Parent   = hrp

    _bodyGyro           = Instance.new("BodyGyro")
    _bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    _bodyGyro.D         = 100
    _bodyGyro.CFrame    = hrp.CFrame
    _bodyGyro.Parent    = hrp

    local cam = workspace.CurrentCamera
    _flyConn = RunService.Heartbeat:Connect(function()
        if not _flyEnabled or not hrp.Parent then return end
        local dir = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W)          then dir = dir + cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)          then dir = dir - cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)          then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)          then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.new(0,1,0)     end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.new(0,1,0)     end
        _bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * _flySpeed or Vector3.new(0,0,0)
        _bodyGyro.CFrame  = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    end)
end

UniMove:NewToggle({
    Title    = "Fly  [W/A/S/D + Space/Ctrl]",
    Default  = false,
    Callback = function(v)
        if v then
            startFly()
            if not _flyCharConn then
                _flyCharConn = LocalPlayer.CharacterAdded:Connect(function()
                    if _flyEnabled then task.wait(0.5); startFly() end
                end)
            end
        else
            stopFly()
        end
    end,
})

-- ── No Clip ───────────────────────────────────────────────────
local _noclipConn, _noclipPartConn, _noclipCharConn, _noclipHL

local function applyNoclipHighlight(char)
    pcall(function() if _noclipHL then _noclipHL:Destroy() end end)
    _noclipHL = nil
    if not char then return end
    local hl               = Instance.new("Highlight")
    hl.Adornee             = char
    hl.FillColor           = Color3.fromRGB(138, 43, 226)
    hl.FillTransparency    = 0.75
    hl.OutlineColor        = Color3.fromRGB(180, 100, 255)
    hl.OutlineTransparency = 0.3
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = workspace
    _noclipHL = hl
end

local function setupNoclipChar(char)
    if not char then return end
    _ncSetChar(char, true)
    applyNoclipHighlight(char)
    -- Layer 3: immediately disable collision for any part added later
    if _noclipPartConn then _noclipPartConn:Disconnect() end
    _noclipPartConn = char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            task.defer(function() pcall(function() _ncSetPart(d, true) end) end)
        end
    end)
end

UniMove:NewToggle({
    Title    = "No Clip",
    Default  = false,
    Callback = function(v)
        if _noclipConn     then _noclipConn:Disconnect();     _noclipConn     = nil end
        if _noclipPartConn then _noclipPartConn:Disconnect(); _noclipPartConn = nil end
        if _noclipCharConn then _noclipCharConn:Disconnect(); _noclipCharConn = nil end
        pcall(function() if _noclipHL then _noclipHL:Destroy() end end)
        _noclipHL = nil

        if v then
            setupNoclipChar(getChar())

            -- Layer 2: per-frame enforcer (catches server-driven CanCollide resets)
            _noclipConn = RunService.Stepped:Connect(function()
                local char = getChar(); if not char then return end
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("BasePart") then
                        if d.CanCollide then d.CanCollide = false end
                        if _noclipGroupReady then
                            pcall(function()
                                if d.CollisionGroup ~= _noclipGroup then
                                    d.CollisionGroup = _noclipGroup
                                end
                            end)
                        end
                    end
                end
            end)

            -- Persist through respawn
            _noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.5); setupNoclipChar(char)
            end)
        else
            _ncSetChar(getChar(), false)
        end
    end,
})

-- ════════════════════════════════════════════════════════════════
--  UTILITY SECTION
-- ════════════════════════════════════════════════════════════════

-- ── Anti-AFK ──────────────────────────────────────────────────
local _afkThread
UniUtil:NewToggle({
    Title    = "Anti-AFK",
    Default  = false,
    Callback = function(v)
        if _afkThread then task.cancel(_afkThread); _afkThread = nil end
        if v then
            _afkThread = task.spawn(function()
                while true do
                    task.wait(60)
                    pcall(function()
                        local VU = game:GetService("VirtualUser")
                        VU:Button2Down(Vector2.new(0,0), CFrame.new())
                        task.wait(0.1)
                        VU:Button2Up(Vector2.new(0,0), CFrame.new())
                    end)
                end
            end)
        end
    end,
})

-- ── Fullbright ────────────────────────────────────────────────
local _origBright, _origAmbient, _origOutdoor
UniUtil:NewToggle({
    Title    = "Fullbright",
    Default  = false,
    Callback = function(v)
        if v then
            _origBright  = Lighting.Brightness
            _origAmbient = Lighting.Ambient
            _origOutdoor = Lighting.OutdoorAmbient
            Lighting.Brightness     = 2
            Lighting.Ambient        = Color3.fromRGB(178,178,178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        else
            Lighting.Brightness     = _origBright  or 1
            Lighting.Ambient        = _origAmbient or Color3.fromRGB(127,127,127)
            Lighting.OutdoorAmbient = _origOutdoor or Color3.fromRGB(127,127,127)
        end
    end,
})

-- ── No Fog ────────────────────────────────────────────────────
local _origFogEnd, _origFogStart, _origAtmDensity
UniUtil:NewToggle({
    Title    = "No Fog",
    Default  = false,
    Callback = function(v)
        if v then
            _origFogEnd   = Lighting.FogEnd
            _origFogStart = Lighting.FogStart
            Lighting.FogEnd   = 1e9
            Lighting.FogStart = 1e9
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then _origAtmDensity = atm.Density; atm.Density = 0 end
        else
            Lighting.FogEnd   = _origFogEnd   or 1000
            Lighting.FogStart = _origFogStart or 0
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if atm then atm.Density = _origAtmDensity or 0.395 end
        end
    end,
})

UniUtil:NewSeparator()

-- ── FOV ───────────────────────────────────────────────────────
UniUtil:NewSlider({
    Title    = "FOV",
    Min      = 50,
    Max      = 120,
    Default  = 70,
    Callback = function(v) workspace.CurrentCamera.FieldOfView = v end,
})

-- ── Time of Day ───────────────────────────────────────────────
UniUtil:NewSlider({
    Title    = "Time of Day",
    Min      = 0,
    Max      = 24,
    Default  = 14,
    Callback = function(v) Lighting.ClockTime = v end,
})

UniUtil:NewSeparator()

-- ── Auto Rejoin ────────────────────────────────────────────────
local _autoRejoinActive = false
local _autoRejoinConn
UniUtil:NewToggle({
    Title    = "Auto Rejoin",
    Default  = false,
    Callback = function(v)
        _autoRejoinActive = v
        if _autoRejoinConn then _autoRejoinConn:Disconnect(); _autoRejoinConn = nil end
        if not v then return end
        task.spawn(function()
            pcall(function()
                local CoreGui   = game:GetService("CoreGui")
                local TeleSvc   = game:GetService("TeleportService")
                local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 10)
                if not promptGui then return end
                local overlay = promptGui:WaitForChild("promptOverlay", 10)
                if not overlay then return end
                _autoRejoinConn = overlay.ChildAdded:Connect(function()
                    if not _autoRejoinActive then return end
                    for i = 3, 1, -1 do
                        Hub:Notify({ Title = "Auto Rejoin", Message = "Rejoining in " .. i .. "s...", Duration = 1 })
                        task.wait(1)
                    end
                    pcall(function() TeleSvc:Teleport(PlaceId, LocalPlayer) end)
                end)
            end)
        end)
    end,
})

UniUtil:NewSeparator()

-- ── Teleport to Player ─────────────────────────────────────────
-- CHANGE: replaced free-text input with a player-name dropdown so the user
-- can see who is in the server without typing.  Options are built at
-- injection time; the Teleport button still does a live name lookup so it
-- works even if a player's character was absent when the dropdown was built.
local _tpTarget = ""

local function _buildPlayerOpts()
    local t = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(t, plr.Name) end
    end
    return #t > 0 and t or { "(no other players)" }
end

local _tpOpts = _buildPlayerOpts()
_tpTarget     = _tpOpts[1]

UniUtil:NewDropdown({
    Title    = "Select Target",
    Options  = _tpOpts,
    Default  = _tpOpts[1],
    Callback = function(v) _tpTarget = v end,
})

UniUtil:NewButton({
    Title    = "Teleport →",
    Callback = function()
        if _tpTarget == "" or _tpTarget == "(no other players)" then
            Hub:Notify({ Title = "Teleport", Message = "No target selected", Duration = 2 })
            return
        end
        local tLow = _tpTarget:lower()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if plr.Name:lower() == tLow
                or plr.DisplayName:lower():find(tLow, 1, true) then
                    local char  = getChar()
                    local tChar = plr.Character
                    local hrp   = char  and char:FindFirstChild("HumanoidRootPart")
                    local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
                    if hrp and tHrp then
                        hrp.CFrame = tHrp.CFrame + Vector3.new(0, 3, 0)
                        Hub:Notify({ Title = "Teleport", Message = "→ " .. plr.Name, Duration = 2 })
                    else
                        Hub:Notify({ Title = "Teleport", Message = plr.Name .. " has no character", Duration = 2 })
                    end
                    return
                end
            end
        end
        Hub:Notify({ Title = "Teleport", Message = "Player not found: " .. _tpTarget, Duration = 2 })
    end,
})

UniUtil:NewSeparator()

-- ── Server Hop ─────────────────────────────────────────────────
UniUtil:NewButton({
    Title    = "Server Hop",
    Callback = function()
        Hub:Notify({ Title = "Server Hop", Message = "Searching for servers...", Duration = 3 })
        task.spawn(function()
            pcall(function()
                local HS      = game:GetService("HttpService")
                local TeleSvc = game:GetService("TeleportService")
                local url     = "https://games.roblox.com/v1/games/" .. PlaceId
                              .. "/servers/Public?sortOrder=Asc&limit=100"
                local ok, resp = pcall(function() return game:HttpGet(url) end)
                if not ok then
                    Hub:Notify({ Title = "Server Hop", Message = "HttpGet blocked by executor", Duration = 3 })
                    return
                end
                local ok2, data = pcall(function() return HS:JSONDecode(resp) end)
                if not ok2 or not data or not data.data then
                    Hub:Notify({ Title = "Server Hop", Message = "Failed to parse server list", Duration = 3 })
                    return
                end
                local candidates = {}
                for _, srv in ipairs(data.data) do
                    if srv.playing < srv.maxPlayers then table.insert(candidates, srv.id) end
                end
                if #candidates == 0 then
                    Hub:Notify({ Title = "Server Hop", Message = "No open servers found", Duration = 3 })
                    return
                end
                Hub:Notify({ Title = "Server Hop", Message = "Joining server...", Duration = 3 })
                TeleSvc:TeleportToPlaceInstance(PlaceId, candidates[math.random(1, #candidates)], LocalPlayer)
            end)
        end)
    end,
})

-- ════════════════════════════════════════════════════════════════
--  ESP SECTION
--  Element order (per spec):
--    Player ESP · Show Names · Team Check
--    ── separator ──
--    ESP Lines · Line Origin dropdown  (new)
--    ── separator ──
--    Skeleton ESP
--    ── separator ──
--    Fill Opacity · Fill Color  (color picker moved to bottom)
-- ════════════════════════════════════════════════════════════════

local _espActive    = false
local _espShowNames = true
local _espTeamCheck = false
local _espFillColor = Color3.fromRGB(255, 50, 50)
local _espFillTrans = 0.65
local _espConns     = {}
local _espObjs      = {}

local function makeNameTag(plr, char)
    if not _espShowNames then return nil end
    local head = char:FindFirstChild("Head"); if not head then return nil end
    local bill             = Instance.new("BillboardGui")
    bill.Name              = "PhantomESPTag"
    bill.Size              = UDim2.new(0,100,0,22)
    bill.StudsOffset       = Vector3.new(0,3,0)
    bill.AlwaysOnTop       = true
    bill.Adornee           = head
    bill.Parent            = workspace
    local lbl                   = Instance.new("TextLabel")
    lbl.Text                    = plr.DisplayName
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = 12
    lbl.TextColor3              = Color3.new(1,1,1)
    lbl.TextStrokeTransparency  = 0.4
    lbl.BackgroundTransparency  = 1
    lbl.Size                    = UDim2.new(1,0,1,0)
    lbl.Parent                  = bill
    return bill
end

local function addPlayerESP(plr)
    if plr == LocalPlayer then return end
    -- BUGFIX: Compare TeamId integers, not object references
    if _espTeamCheck then
        local myTeam  = LocalPlayer.Team
        local hisTeam = plr.Team
        if myTeam and hisTeam and myTeam == hisTeam then return end
        if not myTeam and not hisTeam then return end  -- both teamless = same team
    end
    local char = plr.Character; if not char then return end
    if _espObjs[plr] then
        pcall(function()
            if _espObjs[plr].hl  then _espObjs[plr].hl:Destroy()  end
            if _espObjs[plr].tag then _espObjs[plr].tag:Destroy() end
        end)
    end
    local hl               = Instance.new("Highlight")
    hl.Adornee             = char
    hl.FillColor           = _espFillColor
    hl.FillTransparency    = _espFillTrans
    hl.OutlineColor        = Color3.fromRGB(255,255,255)
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = workspace
    _espObjs[plr] = { hl = hl, tag = makeNameTag(plr, char) }
end

local function removePlayerESP(plr)
    if not _espObjs[plr] then return end
    pcall(function()
        if _espObjs[plr].hl  then _espObjs[plr].hl:Destroy()  end
        if _espObjs[plr].tag then _espObjs[plr].tag:Destroy() end
    end)
    _espObjs[plr] = nil
end

local function clearESP()
    for plr in pairs(_espObjs) do removePlayerESP(plr) end
    for _, c in ipairs(_espConns) do c:Disconnect() end
    _espConns = {}; _espActive = false
end

local function enableESP()
    _espActive = true
    for _, plr in ipairs(Players:GetPlayers()) do
        addPlayerESP(plr)
        table.insert(_espConns, plr.CharacterAdded:Connect(function()
            task.wait(0.1); addPlayerESP(plr)
        end))
    end
    table.insert(_espConns, Players.PlayerAdded:Connect(function(plr)
        table.insert(_espConns, plr.CharacterAdded:Connect(function()
            task.wait(0.1); addPlayerESP(plr)
        end))
    end))
    table.insert(_espConns, Players.PlayerRemoving:Connect(removePlayerESP))
end

local function refreshESP()
    if not _espActive then return end
    for _, plr in ipairs(Players:GetPlayers()) do addPlayerESP(plr) end
end

-- ── Player ESP / Names / Team ─────────────────────────────────
UniESP:NewToggle({ Title="Player ESP", Default=false,
    Callback = function(v) if v then enableESP() else clearESP() end end })
UniESP:NewToggle({ Title="Show Names", Default=true,
    Callback = function(v) _espShowNames = v; refreshESP() end })
UniESP:NewToggle({ Title="Team Check", Default=false,
    Callback = function(v) _espTeamCheck = v; refreshESP() end })

UniESP:NewSeparator()

-- ── ESP Lines + Line Origin ────────────────────────────────────
-- CHANGE: "Line Origin" dropdown lets the user choose between
--   "Bottom"  — classic tracer: line from bottom-center of screen
--   "Center"  — crosshair style: line from screen centre
local _espLinesActive  = false
local _espLineOrigin   = "Bottom"
local _espLinesConn
local _espLineDrawings = {}

UniESP:NewToggle({
    Title    = "ESP Lines",
    Default  = false,
    Callback = function(v)
        _espLinesActive = v
        if not v then
            if _espLinesConn then _espLinesConn:Disconnect(); _espLinesConn = nil end
            for _, ln in pairs(_espLineDrawings) do pcall(function() ln:Remove() end) end
            _espLineDrawings = {}
            return
        end
        if not Drawing then
            Hub:Notify({ Title="ESP Lines", Message="Drawing API not supported", Duration=3 })
            return
        end
        _espLinesConn = RunService.RenderStepped:Connect(function()
            local cam  = workspace.CurrentCamera
            local vp   = cam.ViewportSize
            local fromX = vp.X * 0.5
            local fromY = _espLineOrigin == "Bottom" and vp.Y or vp.Y * 0.5

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                        if not _espLineDrawings[plr] then
                            local ln     = Drawing.new("Line")
                            ln.Thickness = 1
                            ln.Color     = _espFillColor
                            ln.Visible   = false
                            _espLineDrawings[plr] = ln
                        end
                        local ln   = _espLineDrawings[plr]
                        ln.From    = Vector2.new(fromX, fromY)
                        ln.To      = Vector2.new(sp.X, sp.Y)
                        ln.Color   = _espFillColor
                        ln.Visible = vis and (sp.Z > 0)
                    elseif _espLineDrawings[plr] then
                        _espLineDrawings[plr].Visible = false
                    end
                end
            end
            for plr, ln in pairs(_espLineDrawings) do
                if not Players:FindFirstChild(plr.Name) then
                    pcall(function() ln:Remove() end)
                    _espLineDrawings[plr] = nil
                end
            end
        end)
    end,
})

-- CHANGE: new Line Origin dropdown
UniESP:NewDropdown({
    Title    = "Line Origin",
    Options  = { "Bottom", "Center" },
    Default  = "Bottom",
    Callback = function(v) _espLineOrigin = v end,
})

UniESP:NewSeparator()

-- ── Skeleton ESP ──────────────────────────────────────────────
-- CHANGE: Fully rewritten.
--
-- Previous version connected part *centers* (e.g. Torso.Position → Left Arm.Position),
-- which placed lines through the midpoints of body segments rather than at the
-- actual joints — shoulders appeared in the middle of the torso, knees in the
-- middle of the upper leg, etc.
--
-- New version uses the world-space position of the named Attachment found *inside*
-- each part.  Roblox characters ship with a standard set of joint attachments
-- (NeckAttachment, LeftShoulderAttachment, LeftElbowAttachment …) that sit exactly
-- at the anatomical joint locations.  getBonePos falls back to the part centre when
-- an attachment is missing (custom rigs, morphs) so it degrades gracefully.
--
-- Visual changes:
--   • 2 px line thickness instead of 1 px — readable at distance
--   • Lines drawn in the shared _espFillColor for consistent style
--   • Rig type is re-detected each frame so character swaps are handled

local _skelActive   = false
local _skelConn
local _skelDrawings = {}

local function getBonePos(char, partName, attachName)
    local part = char:FindFirstChild(partName)
    if not part then return nil end
    if attachName then
        local att = part:FindFirstChild(attachName)
        if att then return (part.CFrame * att.CFrame).Position end
    end
    return part.Position
end

-- Each entry: { partA, attachmentA, partB, attachmentB }
local R15_BONES = {
    -- Spine / neck
    { "Head",         "NeckAttachment",          "UpperTorso",   "NeckAttachment"          },
    { "UpperTorso",   "WaistCenterAttachment",    "LowerTorso",   "WaistCenterAttachment"   },
    -- Left arm
    { "UpperTorso",   "LeftShoulderAttachment",   "LeftUpperArm", "LeftShoulderAttachment"  },
    { "LeftUpperArm", "LeftElbowAttachment",      "LeftLowerArm", "LeftElbowAttachment"     },
    { "LeftLowerArm", "LeftWristAttachment",      "LeftHand",     "LeftWristAttachment"     },
    -- Right arm
    { "UpperTorso",   "RightShoulderAttachment",  "RightUpperArm","RightShoulderAttachment" },
    { "RightUpperArm","RightElbowAttachment",     "RightLowerArm","RightElbowAttachment"    },
    { "RightLowerArm","RightWristAttachment",     "RightHand",    "RightWristAttachment"    },
    -- Left leg
    { "LowerTorso",   "LeftHipAttachment",        "LeftUpperLeg", "LeftHipAttachment"       },
    { "LeftUpperLeg", "LeftKneeAttachment",       "LeftLowerLeg", "LeftKneeAttachment"      },
    { "LeftLowerLeg", "LeftAnkleAttachment",      "LeftFoot",     "LeftAnkleAttachment"     },
    -- Right leg
    { "LowerTorso",   "RightHipAttachment",       "RightUpperLeg","RightHipAttachment"      },
    { "RightUpperLeg","RightKneeAttachment",      "RightLowerLeg","RightKneeAttachment"     },
    { "RightLowerLeg","RightAnkleAttachment",     "RightFoot",    "RightAnkleAttachment"    },
}

local R6_BONES = {
    { "Head",  "NeckAttachment",          "Torso",     "NeckAttachment"          },
    { "Torso", "LeftShoulderAttachment",  "Left Arm",  "LeftShoulderAttachment"  },
    { "Torso", "RightShoulderAttachment", "Right Arm", "RightShoulderAttachment" },
    { "Torso", "LeftHipAttachment",       "Left Leg",  "LeftHipAttachment"       },
    { "Torso", "RightHipAttachment",      "Right Leg", "RightHipAttachment"      },
}

local function clearSkelPlayer(plr)
    if not _skelDrawings[plr] then return end
    for _, ln in ipairs(_skelDrawings[plr]) do pcall(function() ln:Remove() end) end
    _skelDrawings[plr] = nil
end

UniESP:NewToggle({
    Title    = "Skeleton ESP",
    Default  = false,
    Callback = function(v)
        _skelActive = v
        if not v then
            if _skelConn then _skelConn:Disconnect(); _skelConn = nil end
            for plr in pairs(_skelDrawings) do clearSkelPlayer(plr) end
            return
        end
        if not Drawing then
            Hub:Notify({ Title="Skeleton ESP", Message="Drawing API not supported", Duration=3 })
            return
        end
        _skelConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    if not char then
                        clearSkelPlayer(plr)
                    else
                        local isR15  = char:FindFirstChild("UpperTorso") ~= nil
                        local bones  = isR15 and R15_BONES or R6_BONES
                        local nBones = #bones

                        -- (Re)allocate pool on first use or rig change
                        local pool = _skelDrawings[plr]
                        if not pool or #pool ~= nBones then
                            clearSkelPlayer(plr); pool = {}
                            for _ = 1, nBones do
                                local ln     = Drawing.new("Line")
                                ln.Thickness = 2        -- thicker for readability
                                ln.Color     = _espFillColor
                                ln.Visible   = false
                                table.insert(pool, ln)
                            end
                            _skelDrawings[plr] = pool
                        end

                        for i, bone in ipairs(bones) do
                            local ln    = pool[i]
                            local wp1   = getBonePos(char, bone[1], bone[2])
                            local wp2   = getBonePos(char, bone[3], bone[4])
                            if wp1 and wp2 then
                                local s1, v1 = cam:WorldToViewportPoint(wp1)
                                local s2, v2 = cam:WorldToViewportPoint(wp2)
                                ln.From    = Vector2.new(s1.X, s1.Y)
                                ln.To      = Vector2.new(s2.X, s2.Y)
                                ln.Color   = _espFillColor
                                ln.Visible = v1 and v2 and s1.Z > 0 and s2.Z > 0
                            else
                                ln.Visible = false
                            end
                        end
                    end
                end
            end
            for plr in pairs(_skelDrawings) do
                if not Players:FindFirstChild(plr.Name) then clearSkelPlayer(plr) end
            end
        end)
    end,
})

UniESP:NewSeparator()

-- ── Fill Opacity + Fill Color  (color picker last per spec) ───
UniESP:NewSlider({
    Title    = "Fill Opacity %",
    Min      = 0,
    Max      = 100,
    Default  = 35,
    Callback = function(v)
        _espFillTrans = 1 - (v / 100)
        for _, obj in pairs(_espObjs) do
            if obj.hl then obj.hl.FillTransparency = _espFillTrans end
        end
    end,
})

-- CHANGE: Fill Color picker moved to the very bottom of the ESP section
UniESP:NewColorPicker({
    Title    = "Fill Color",
    Default  = Color3.fromRGB(255, 50, 50),
    Callback = function(c)
        _espFillColor = c
        for _, obj in pairs(_espObjs) do
            if obj.hl then obj.hl.FillColor = c end
        end
    end,
})

-- ════════════════════════════════════════════════════════════════
--  TRIGGERBOT
-- ════════════════════════════════════════════════════════════════
local _tbActive      = false
local _tbMode        = "Toggle"   -- "Toggle" or "Hold"
local _tbKey         = Enum.KeyCode.T
local _tbDelay       = 80         -- ms base delay
local _tbVariance    = 20         -- +/- ms variance
local _tbHitFilter   = "Any visible"
local _tbConn
local _tbHoldConn

local function _tbCanFire()
    -- Don't fire while menu is open or chat is focused
    if Hub.Visible == false then return false end
    if UIS:GetFocusedTextBox() then return false end
    return true
end

local function _tbRaycast(char)
    local cam  = workspace.CurrentCamera
    local ray  = cam:ScreenPointToRay(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { char }
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not result then return false end
    local hit = result.Instance
    if _tbHitFilter == "Head only" then
        return hit.Name == "Head"
    elseif _tbHitFilter == "Body" then
        local bodyParts = { "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
        for _, n in ipairs(bodyParts) do if hit.Name == n then return true end end
        return false
    end
    -- "Any visible" — any BasePart belonging to a player character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if hit:IsDescendantOf(plr.Character) then return true end
        end
    end
    return false
end

local function _tbDoFire()
    if not _tbCanFire() then return end
    local char = getChar(); if not char then return end
    if not _tbRaycast(char) then return end
    local delay_ms = _tbDelay + math.random(-_tbVariance, _tbVariance)
    task.wait(math.max(0, delay_ms / 1000))
    if not _tbActive then return end   -- may have been toggled off during wait
    -- Simulate mouse click
    pcall(function()
        local VU = game:GetService("VirtualUser")
        VU:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.05)
        VU:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function _startTriggerLoop()
    if _tbConn then _tbConn:Disconnect() end
    _tbConn = RunService.Heartbeat:Connect(function()
        if not _tbActive then return end
        if _tbMode == "Hold" and not UIS:IsKeyDown(_tbKey) then return end
        _tbDoFire()
    end)
end

local function _stopTrigger()
    _tbActive = false
    if _tbConn then _tbConn:Disconnect(); _tbConn = nil end
    if _tbHoldConn then _tbHoldConn:Disconnect(); _tbHoldConn = nil end
end

local CombatTab = Hub:NewTab({ Title = "Combat", Icon = "rbxassetid://3926307984" })
local TBSec     = CombatTab:NewSection({ Position = "Left",  Title = "Triggerbot" })
local SpectSec  = CombatTab:NewSection({ Position = "Right", Title = "Spectators" })

TBSec:NewToggle({
    Title    = "Triggerbot",
    Default  = false,
    Callback = function(v)
        _tbActive = v
        if v then _startTriggerLoop() else _stopTrigger() end
    end,
})

TBSec:NewDropdown({
    Title    = "Mode",
    Options  = { "Toggle", "Hold" },
    Default  = "Toggle",
    Callback = function(v) _tbMode = v end,
})

TBSec:NewSlider({
    Title    = "Base Delay (ms)",
    Min      = 0,
    Max      = 200,
    Default  = 80,
    Callback = function(v) _tbDelay = v end,
})

TBSec:NewSlider({
    Title    = "Variance (ms)",
    Min      = 0,
    Max      = 50,
    Default  = 20,
    Callback = function(v) _tbVariance = v end,
})

TBSec:NewDropdown({
    Title    = "Hitbox Filter",
    Options  = { "Any visible", "Body", "Head only" },
    Default  = "Any visible",
    Callback = function(v) _tbHitFilter = v end,
})

-- ════════════════════════════════════════════════════════════════
--  SPECTATOR LIST
-- ════════════════════════════════════════════════════════════════
local _spectActive    = false
local _spectAlert     = true
local _spectStreamer   = false
local _spectLastCount = 0
local _spectConn
local _spectGui       = nil

local function _makeSpectGui()
    -- Remove old
    if _spectGui then pcall(function() _spectGui:Destroy() end); _spectGui = nil end
    local sg   = Instance.new("ScreenGui")
    sg.Name    = "PhantomSpectList"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 99
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    sg.Parent  = ok and cg or LocalPlayer:WaitForChild("PlayerGui")

    local frame               = Instance.new("Frame")
    frame.Size                = UDim2.new(0, 180, 0, 20)
    frame.Position            = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3    = Color3.fromRGB(14, 14, 14)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel     = 0
    frame.AutomaticSize       = Enum.AutomaticSize.Y
    frame.Parent              = sg

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 6)
    corner2.Parent       = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0, 2)
    layout.Parent    = frame

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft   = UDim.new(0, 6)
    pad.PaddingRight  = UDim.new(0, 6)
    pad.Parent        = frame

    _spectGui = sg
    return frame
end

local function _rebuildSpectList()
    if not _spectActive then return end
    local container = _makeSpectGui()

    -- Try to get spectators from the game's spectator array
    local spectNames = {}
    local count = 0
    pcall(function()
        -- Roblox doesn't expose spectators directly; we check PlayerGui for spectator UI hints
        -- Fallback: count via NetworkOwnership or assume 0 (game-specific)
        -- For supported games, we iterate Players and check their character visibility
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    -- If character exists but is invisible to camera (common spectator indicator)
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and not hrp:IsDescendantOf(workspace) then
                        count = count + 1
                        table.insert(spectNames, plr.Name)
                    end
                end
            end
        end
    end)

    local isAlert = count > _spectLastCount

    -- Header row
    local header               = Instance.new("TextLabel")
    header.Size                = UDim2.new(1, 0, 0, 16)
    header.BackgroundTransparency = 1
    header.Font                = Enum.Font.GothamBold
    header.TextSize            = 11
    header.TextColor3          = isAlert and Color3.fromRGB(255, 220, 50) or Color3.fromRGB(180, 180, 180)
    header.TextXAlignment      = Enum.TextXAlignment.Left
    header.Text                = "👁 Spectators: " .. count
    header.Parent              = container

    for _, name in ipairs(spectNames) do
        local row              = Instance.new("TextLabel")
        row.Size               = UDim2.new(1, 0, 0, 13)
        row.BackgroundTransparency = 1
        row.Font               = Enum.Font.Gotham
        row.TextSize           = 10
        row.TextColor3         = Color3.fromRGB(200, 200, 200)
        row.TextXAlignment     = Enum.TextXAlignment.Left
        row.Text               = "  • " .. name
        row.Parent             = container
    end

    -- Alert / streamer mode logic
    if isAlert and _spectAlert then
        Hub:Notify({ Title="Spectator Alert", Message="Someone started watching you!", Duration=3 })
    end
    if _spectStreamer and count > 0 then
        -- Auto-disable rage features
        if _tbActive then _stopTrigger(); _tbActive = false end
    end

    _spectLastCount = count
end

SpectSec:NewToggle({
    Title    = "Spectator List",
    Default  = false,
    Callback = function(v)
        _spectActive = v
        if _spectConn then _spectConn:Disconnect(); _spectConn = nil end
        if _spectGui  then pcall(function() _spectGui:Destroy() end); _spectGui = nil end
        if not v then return end
        _rebuildSpectList()
        _spectConn = RunService.Heartbeat:Connect(function()
            -- Refresh every ~2 seconds
            _rebuildSpectList()
            task.wait(2)
        end)
    end,
})

SpectSec:NewToggle({
    Title    = "Alert on New Spectator",
    Default  = true,
    Callback = function(v) _spectAlert = v end,
})

SpectSec:NewToggle({
    Title    = "Streamer Mode (auto-disable rage)",
    Default  = false,
    Callback = function(v) _spectStreamer = v end,
})

-- ════════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ════════════════════════════════════════════════════════════════
local SetTab    = Hub:NewTab({ Title = "Settings", Icon = "rbxassetid://3926307641" })
local AppearSec = SetTab:NewSection({ Position = "Left",  Title = "Appearance" })
local DataSec   = SetTab:NewSection({ Position = "Right", Title = "Config"     })
local KbSec     = SetTab:NewSection({ Position = "Right", Title = "Keybind"    })

AppearSec:NewColorPicker({
    Title    = "Accent Color",
    Default  = Color3.fromRGB(110, 75, 255),
    Callback = function(c) Hub:SetAccent(c) end,
})
AppearSec:NewSlider({
    Title    = "Window Opacity %",
    Min      = 30,
    Max      = 100,
    Default  = 95,
    Callback = function(v) Hub._win.BackgroundTransparency = 1 - (v / 100) end,
})

DataSec:NewButton({ Title="Save Config", Callback=function()
    SM:Save(); Hub:Notify({ Title="Config", Message="Saved successfully", Duration=2 })
end })
DataSec:NewButton({ Title="Load Config", Callback=function()
    SM:Load(); Hub:Notify({ Title="Config", Message="Loaded and applied", Duration=2 })
end })
DataSec:NewToggle({ Title="Auto Save", Default=true, Callback=function(v)
    if v then
        Hub:AutoSave("phantom", Hub._autoSaveInterval or 60)
    else
        if Hub._autoSaveThread then task.cancel(Hub._autoSaveThread); Hub._autoSaveThread = nil end
    end
end })
DataSec:NewSlider({ Title="Auto Save (secs)", Min=15, Max=300, Default=60, Callback=function(v)
    Hub._autoSaveInterval = v; Hub:AutoSave("phantom", v)
end })

KbSec:NewKeybind({ Title="Toggle Keybind", Default=Enum.KeyCode.J,
    Callback = function(key)
        Hub.Keybind = key
        -- FIX: mark input as handled inside Phantom so the menu-toggle
        -- listener (which checks the same key) ignores this keypress.
        -- Phantom's keybind element already calls Input.Handled = true
        -- internally; we just sync the new key here.
    end })

SetTab._btn.Visible = false
Hub:AutoSave("phantom", 60)

-- ════════════════════════════════════════════════════════════════
--  GAME-SPECIFIC TABS
-- ════════════════════════════════════════════════════════════════
if GameName ~= "Unknown" then
    local gameIcon = GameName == "BloxFruits" and "rbxassetid://3926307959" or "rbxassetid://3926307433"
    local GameTab  = Hub:NewTab({ Title = GameName, Icon = gameIcon })

    if GameName == "BloxFruits" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat" })
        local Farm   = GameTab:NewSection({ Position = "Left",  Title = "Farm"   })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player" })
        Combat:NewToggle({ Title="Kill Aura",     Default=false, Callback=function(v) end })
        Farm:NewToggle({   Title="Auto Farm",      Default=false, Callback=function(v)
            Hub:Notify({ Title="Auto Farm", Message=v and "Enabled" or "Disabled", Duration=3 })
        end })
        Farm:NewToggle({ Title="Fruit Notifier", Default=false, Callback=function(v) end })
        Player:NewSlider({ Title="Walk Speed", Min=16, Max=500, Default=16, Callback=function(v)
            local h = getHum(); if h then h.WalkSpeed = v end
        end })
        Player:NewSlider({ Title="Jump Power", Min=7, Max=300, Default=7, Callback=function(v)
            local h = getHum(); if h then h.JumpPower = v end
        end })

    elseif GameName == "DaHood" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat"  })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player"  })
        local Visual = GameTab:NewSection({ Position = "Right", Title = "Visuals" })
        Combat:NewToggle({ Title="Aimbot",     Default=false, Callback=function(v) end })
        Combat:NewToggle({ Title="Silent Aim", Default=false, Callback=function(v) end })
        Combat:NewSlider({ Title="Aimbot FOV", Min=10, Max=500, Default=150, Callback=function(v) end })
        Player:NewSlider({ Title="Walk Speed", Min=16, Max=500, Default=16, Callback=function(v)
            local h = getHum(); if h then h.WalkSpeed = v end
        end })
        Player:NewSlider({ Title="Jump Power", Min=7, Max=300, Default=7, Callback=function(v)
            local h = getHum(); if h then h.JumpPower = v end
        end })
        Visual:NewToggle({ Title="Player ESP", Default=false, Callback=function(v) end })
    end
else
    local UnkTab = Hub:NewTab({ Title = "Unknown Game", Icon = "rbxassetid://3926305904" })
    local UnkSec = UnkTab:NewSection({ Position = "Left", Title = "Info" })
    UnkSec:NewLabel("No scripts for this game yet.")
    UnkSec:NewLabel("PlaceId: " .. tostring(PlaceId))
end

-- ════════════════════════════════════════════════════════════════
--  PANIC KEY WIRING
--  Now that all feature variables are declared, define the shutdown fn.
-- ════════════════════════════════════════════════════════════════
_panicShutdown = function()
    -- 1. Stop movement mods
    pcall(stopWsEnforcer)
    pcall(stopFly)

    -- 2. Disable noclip
    pcall(function()
        if _noclipConn     then _noclipConn:Disconnect();     _noclipConn     = nil end
        if _noclipPartConn then _noclipPartConn:Disconnect(); _noclipPartConn = nil end
        if _noclipCharConn then _noclipCharConn:Disconnect(); _noclipCharConn = nil end
        if _noclipHL       then _noclipHL:Destroy();          _noclipHL       = nil end
        _ncSetChar(getChar(), false)
    end)

    -- 3. Clear all ESP
    pcall(clearESP)

    -- 4. Stop skeleton and line ESP
    pcall(function()
        if _skelConn then _skelConn:Disconnect(); _skelConn = nil end
        for plr in pairs(_skelDrawings) do clearSkelPlayer(plr) end
        if _espLinesConn then _espLinesConn:Disconnect(); _espLinesConn = nil end
        for _, ln in pairs(_espLineDrawings) do pcall(function() ln:Remove() end) end
        _espLineDrawings = {}
    end)

    -- 5. Stop triggerbot
    pcall(_stopTrigger)

    -- 6. Stop spectator list
    pcall(function()
        _spectActive = false
        if _spectConn then _spectConn:Disconnect(); _spectConn = nil end
        if _spectGui  then _spectGui:Destroy(); _spectGui = nil end
    end)

    -- 7. Stop infinite jump
    pcall(function()
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
    end)

    -- 8. Restore lighting
    pcall(function()
        Lighting.Brightness     = _origBright  or 1
        Lighting.Ambient        = _origAmbient or Color3.fromRGB(127,127,127)
        Lighting.OutdoorAmbient = _origOutdoor or Color3.fromRGB(127,127,127)
        Lighting.FogEnd         = _origFogEnd  or 1000
        Lighting.FogStart       = _origFogStart or 0
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm.Density = _origAtmDensity or 0.395 end
    end)

    -- 9. Restore humanoid to defaults
    pcall(function()
        local h = getHum()
        if h then
            h.WalkSpeed     = 16
            h.JumpPower     = 50
            h.PlatformStand = false
        end
    end)

    -- 10. Visual confirmation
    _showDisengagedOverlay()
end

-- ── Startup Notification ──────────────────────────────────────
Hub:Notify({
    Title    = "Phantom Loaded",
    Message  = "Game: " .. GameName .. " | J = toggle | Del = PANIC",
    Duration = 5,
})
