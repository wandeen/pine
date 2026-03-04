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
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local LocalPlayer  = Players.LocalPlayer

-- ── Create Window ─────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = GameName ~= "Unknown" and GameName or "hub",
    Keybind  = Enum.KeyCode.J,
})

Hub:SetProfile()
Hub._win.BackgroundTransparency = 0.05  -- 95% opacity by default
-- Initialize SettingsManager (auto-save/load)
local SettingsManager = require(script.Parent.SettingsManager)
local SM = SettingsManager.new(Hub, "phantom")

-- Register Walk Speed persistence
SM:Register("WalkSpeed", 
    function() return _G.PhantomWalkSpeed or 16 end,
    function(v) 
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
        _G.PhantomWalkSpeed = v
    end
)

-- Register Jump Power persistence  
SM:Register("JumpPower",
    function() return _G.PhantomJumpPower or 7 end,
    function(v)
        local hum = getHum()
        if hum then hum.JumpPower = v end
        _G.PhantomJumpPower = v
    end
)

-- Register Fly Speed persistence
SM:Register("FlySpeed",
    function() return _flySpeed end,
    function(v) _flySpeed = v end
)

-- Auto-load on startup and auto-apply on respawn
SM:Load()
SM:StartAutoApply()

-- ════════════════════════════════════════════════════════════════
--  UNIVERSAL TAB  (first tab → opens by default)
-- ════════════════════════════════════════════════════════════════
local UniTab = Hub:NewTab({ Title = "Universal", Icon = "rbxassetid://3926305904" })

-- 2 sections each side for a balanced look
local UniPlayer = UniTab:NewSection({ Position = "Left",  Title = "Player"   })
local UniMove   = UniTab:NewSection({ Position = "Left",  Title = "Movement" })
local UniUtil   = UniTab:NewSection({ Position = "Right", Title = "Utility"  })
local UniESP    = UniTab:NewSection({ Position = "Right", Title = "ESP"      })

-- ── Helpers ───────────────────────────────────────────────────
local function getChar()
    return LocalPlayer.Character
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ════════════════════════════════════════════════════════════════
--  PLAYER SECTION
-- ════════════════════════════════════════════════════════════════

-- Walk Speed
UniPlayer:NewSlider({
    Title    = "Walk Speed",
    Min      = 16,
    Max      = 300,
    Default  = 16,
    Callback = function(v)
        local hum = getHum()
        if hum then hum.WalkSpeed = v end
        _G.PhantomWalkSpeed = v
    end,
})

-- Jump Power
UniPlayer:NewSlider({
    Title    = "Jump Power",
    Min      = 7,
    Max      = 200,
    Default  = 7,
    Callback = function(v)
        local hum = getHum()
        if hum then hum.JumpPower = v end
         _G.PhantomWalkSpeed = v
    end,
})

-- Fly Speed (lives here since it's a speed stat)
local _flySpeed = 60
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
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end,
})

-- ── Fly (WASD + Space/LCtrl) ─────────────────────────────────
local _flyEnabled = false
local _flyConn, _flyCharConn
local _bodyVel, _bodyGyro

local function stopFly()
    _flyEnabled = false
    if _flyConn     then _flyConn:Disconnect();     _flyConn = nil     end
    pcall(function()
        if _bodyVel  then _bodyVel:Destroy();  _bodyVel  = nil end
        if _bodyGyro then _bodyGyro:Destroy(); _bodyGyro = nil end
    end)
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    stopFly()
    _flyEnabled = true
    local char = getChar()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    _bodyVel          = Instance.new("BodyVelocity")
    _bodyVel.Velocity = Vector3.new(0, 0, 0)
    _bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    _bodyVel.Parent   = hrp

    _bodyGyro           = Instance.new("BodyGyro")
    _bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    _bodyGyro.D         = 100
    _bodyGyro.CFrame    = hrp.CFrame
    _bodyGyro.Parent    = hrp

    local cam = workspace.CurrentCamera
    _flyConn = RunService.Heartbeat:Connect(function()
        if not _flyEnabled or not hrp.Parent then return end
        local dir = Vector3.new(0, 0, 0)
        if UIS:IsKeyDown(Enum.KeyCode.W)            then dir = dir + cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)            then dir = dir - cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)            then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)            then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)        then dir = dir + Vector3.new(0, 1, 0)   end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.LeftShift)    then dir = dir - Vector3.new(0, 1, 0)   end
        _bodyVel.Velocity  = dir.Magnitude > 0 and dir.Unit * _flySpeed or Vector3.new(0, 0, 0)
        _bodyGyro.CFrame   = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
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
-- Disables character collision every physics step. Works standalone (no Fly required).
local _noclipConn, _noclipCharConn, _noclipHL

local function setCollision(char, state)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

local function applyNoclipHighlight(char)
    pcall(function() if _noclipHL then _noclipHL:Destroy() end end)
    _noclipHL = nil
    if not char then return end
    local hl                  = Instance.new("Highlight")
    hl.Adornee                = char
    hl.FillColor              = Color3.fromRGB(138, 43, 226)
    hl.FillTransparency       = 0.75
    hl.OutlineColor           = Color3.fromRGB(180, 100, 255)
    hl.OutlineTransparency    = 0.3
    hl.DepthMode              = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent                 = workspace
    _noclipHL = hl
end

UniMove:NewToggle({
    Title    = "No Clip",
    Default  = false,
    Callback = function(v)
        if _noclipConn     then _noclipConn:Disconnect();     _noclipConn     = nil end
        if _noclipCharConn then _noclipCharConn:Disconnect(); _noclipCharConn = nil end
        pcall(function() if _noclipHL then _noclipHL:Destroy() end end)
        _noclipHL = nil

        if v then
            setCollision(getChar(), false)
            applyNoclipHighlight(getChar())
            -- Re-apply on respawn
            _noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
                task.wait(0.5)
                pcall(function() if _noclipHL then _noclipHL:Destroy() end end)
                setCollision(char, false)
                applyNoclipHighlight(char)
            end)
            -- Keep disabling every step (games may reset CanCollide server-side)
            _noclipConn = RunService.Stepped:Connect(function()
                local char = getChar()
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        else
            setCollision(getChar(), true)
        end
    end,
})

-- ════════════════════════════════════════════════════════════════
--  UTILITY SECTION
-- ════════════════════════════════════════════════════════════════

-- ── Anti-AFK (timer loop — more reliable than the Idled event) ─
local _afkThread
UniUtil:NewToggle({
    Title    = "Anti-AFK",
    Default  = false,
    Callback = function(v)
        if _afkThread then task.cancel(_afkThread); _afkThread = nil end
        if v then
            _afkThread = task.spawn(function()
                while true do
                    task.wait(60)   -- nudge every 60 s to prevent idle kick
                    pcall(function()
                        local VU = game:GetService("VirtualUser")
                        VU:Button2Down(Vector2.new(0, 0), CFrame.new())
                        task.wait(0.1)
                        VU:Button2Up(Vector2.new(0, 0), CFrame.new())
                    end)
                end
            end)
        end
    end,
})

-- ── Fullbright ────────────────────────────────────────────────
local _origBrightness, _origAmbient, _origOutdoor
UniUtil:NewToggle({
    Title    = "Fullbright",
    Default  = false,
    Callback = function(v)
        if v then
            _origBrightness  = Lighting.Brightness
            _origAmbient     = Lighting.Ambient
            _origOutdoor     = Lighting.OutdoorAmbient
            Lighting.Brightness     = 2
            Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            Lighting.Brightness     = _origBrightness or 1
            Lighting.Ambient        = _origAmbient    or Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = _origOutdoor    or Color3.fromRGB(127, 127, 127)
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
            _origFogEnd      = Lighting.FogEnd
            _origFogStart    = Lighting.FogStart
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
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end,
})

-- ── Time of Day ───────────────────────────────────────────────
UniUtil:NewSlider({
    Title    = "Time of Day",
    Min      = 0,
    Max      = 24,
    Default  = 14,
    Callback = function(v)
        Lighting.ClockTime = v
    end,
})

UniUtil:NewSeparator()

-- ── Auto Rejoin ────────────────────────────────────────────────
-- Detects kick via CoreGui prompt overlay and teleports back after 3s.
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
local _tpTarget = ""

UniUtil:NewInput({
    Title       = "Teleport to Player",
    Placeholder = "Username or display name...",
    Callback    = function(text) _tpTarget = text end,
})

UniUtil:NewButton({
    Title    = "Teleport →",
    Callback = function()
        local target = _tpTarget:lower()
        if target == "" then
            Hub:Notify({ Title = "Teleport", Message = "Enter a player name first", Duration = 2 })
            return
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local matchName = plr.Name:lower():find(target, 1, true)
                local matchDisp = plr.DisplayName:lower():find(target, 1, true)
                if matchName or matchDisp then
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
-- Fetches a public server list and joins a random one with open slots.
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
                    if srv.playing < srv.maxPlayers then
                        table.insert(candidates, srv.id)
                    end
                end
                if #candidates == 0 then
                    Hub:Notify({ Title = "Server Hop", Message = "No open servers found", Duration = 3 })
                    return
                end
                local target = candidates[math.random(1, #candidates)]
                Hub:Notify({ Title = "Server Hop", Message = "Joining server...", Duration = 3 })
                TeleSvc:TeleportToPlaceInstance(PlaceId, target, LocalPlayer)
            end)
        end)
    end,
})

-- ════════════════════════════════════════════════════════════════
--  ESP SECTION  (Highlight-based, works in every game)
-- ════════════════════════════════════════════════════════════════

local _espActive    = false
local _espShowNames = true
local _espTeamCheck = false
local _espFillColor = Color3.fromRGB(255, 50, 50)
local _espFillTrans = 0.65
local _espConns     = {}
local _espObjs      = {}   -- [player] = { hl = Highlight, tag = BillboardGui }

local function makeNameTag(plr, char)
    if not _espShowNames then return nil end
    local head = char:FindFirstChild("Head")
    if not head then return nil end

    local bill         = Instance.new("BillboardGui")
    bill.Name          = "PhantomESPTag"
    bill.Size          = UDim2.new(0, 100, 0, 22)
    bill.StudsOffset   = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop   = true
    bill.Adornee       = head
    bill.Parent        = workspace

    local lbl                   = Instance.new("TextLabel")
    lbl.Text                    = plr.DisplayName
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = 12
    lbl.TextColor3              = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency  = 0.4
    lbl.BackgroundTransparency  = 1
    lbl.Size                    = UDim2.new(1, 0, 1, 0)
    lbl.Parent                  = bill
    return bill
end

local function addPlayerESP(plr)
    if plr == LocalPlayer then return end
    if _espTeamCheck and plr.Team == LocalPlayer.Team then return end
    local char = plr.Character
    if not char then return end

    -- Remove stale objects for this player
    if _espObjs[plr] then
        pcall(function()
            if _espObjs[plr].hl  then _espObjs[plr].hl:Destroy()  end
            if _espObjs[plr].tag then _espObjs[plr].tag:Destroy() end
        end)
    end

    local hl                   = Instance.new("Highlight")
    hl.Adornee                 = char
    hl.FillColor               = _espFillColor
    hl.FillTransparency        = _espFillTrans
    hl.OutlineColor            = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency     = 0
    hl.DepthMode               = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent                  = workspace

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
    _espConns  = {}
    _espActive = false
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
    table.insert(_espConns, Players.PlayerRemoving:Connect(function(plr)
        removePlayerESP(plr)
    end))
end

local function refreshESP()
    if not _espActive then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        addPlayerESP(plr)
    end
end

-- Controls
UniESP:NewToggle({
    Title    = "Player ESP",
    Default  = false,
    Callback = function(v)
        if v then enableESP() else clearESP() end
    end,
})

UniESP:NewToggle({
    Title    = "Show Names",
    Default  = true,
    Callback = function(v)
        _espShowNames = v; refreshESP()
    end,
})

UniESP:NewToggle({
    Title    = "Team Check",
    Default  = false,
    Callback = function(v)
        _espTeamCheck = v; refreshESP()
    end,
})

UniESP:NewSeparator()

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

UniESP:NewSeparator()

-- ── ESP Lines (Drawing API — line from screen bottom to player) ──
local _espLinesActive  = false
local _espLinesConn
local _espLineDrawings = {}  -- [player] = Drawing.Line

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
        Hub:Notify({Title="ESP Lines", Message="Drawing API not supported", Duration=3})
        return 
    end
        _espLinesConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local cx  = cam.ViewportSize.X / 2
            local cy  = cam.ViewportSize.Y
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local sp, vis = cam:WorldToViewportPoint(hrp.Position)
                        if not _espLineDrawings[plr] then
                            local ln       = Drawing.new("Line")
                            ln.Thickness   = 1
                            ln.Color       = _espFillColor
                            ln.Visible     = false
                            _espLineDrawings[plr] = ln
                        end
                        local ln   = _espLineDrawings[plr]
                        ln.From    = Vector2.new(cx, cy)
                        ln.To      = Vector2.new(sp.X, sp.Y)
                        ln.Color   = _espFillColor
                        ln.Visible = vis and (sp.Z > 0)
                    elseif _espLineDrawings[plr] then
                        _espLineDrawings[plr].Visible = false
                    end
                end
            end
            -- Clean up lines for gone players
            for plr, ln in pairs(_espLineDrawings) do
                if not Players:FindFirstChild(plr.Name) then
                    pcall(function() ln:Remove() end)
                    _espLineDrawings[plr] = nil
                end
            end
        end)
    end,
})

-- ── Skeleton ESP (bone lines via Drawing API) ───────────────────
local _skelActive   = false
local _skelConn
local _skelDrawings = {}  -- [player] = {Drawing.Line, ...}

local R6_LINKS = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local R15_LINKS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}

local function clearSkelPlayer(plr)
    if _skelDrawings[plr] then
        for _, ln in ipairs(_skelDrawings[plr]) do pcall(function() ln:Remove() end) end
        _skelDrawings[plr] = nil
    end
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
        Hub:Notify({Title="Skeleton ESP", Message="Drawing API not supported", Duration=3})
             return 
         end
        _skelConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    if not char then clearSkelPlayer(plr) else
                        local links = char:FindFirstChild("UpperTorso") and R15_LINKS or R6_LINKS
                        if not _skelDrawings[plr] or #_skelDrawings[plr] ~= #links then
                            clearSkelPlayer(plr)
                            local pool = {}
                            for _ = 1, #links do
                                local ln     = Drawing.new("Line")
                                ln.Thickness = 1
                                ln.Color     = _espFillColor
                                ln.Visible   = false
                                table.insert(pool, ln)
                            end
                            _skelDrawings[plr] = pool
                        end
                        for i, link in ipairs(links) do
                            local p1 = char:FindFirstChild(link[1])
                            local p2 = char:FindFirstChild(link[2])
                            local ln = _skelDrawings[plr][i]
                            if p1 and p2 then
                                local s1, v1 = cam:WorldToViewportPoint(p1.Position)
                                local s2, v2 = cam:WorldToViewportPoint(p2.Position)
                                ln.From    = Vector2.new(s1.X, s1.Y)
                                ln.To      = Vector2.new(s2.X, s2.Y)
                                ln.Color   = _espFillColor
                                ln.Visible = v1 and v2 and (s1.Z > 0)
                            else
                                ln.Visible = false
                            end
                        end
                    end
                end
            end
            -- Clean up drawings for disconnected players
            for plr in pairs(_skelDrawings) do
                if not Players:FindFirstChild(plr.Name) then
                    clearSkelPlayer(plr)
                end
            end
        end)
    end,
})

-- ════════════════════════════════════════════════════════════════
--  SETTINGS TAB  (hidden from sidebar; open via ⚙ topbar button)
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
    Callback = function(v)
        Hub._win.BackgroundTransparency = 1 - (v / 100)
    end,
})

DataSec:NewButton({
    Title    = "Save Config",
    Callback = function()
        SM:Save()
        Hub:Notify({ Title = "Config", Message = "Saved successfully", Duration = 2 })
    end,
})
DataSec:NewButton({
    Title    = "Load Config", 
    Callback = function()
        SM:Load()
        Hub:Notify({ Title = "Config", Message = "Loaded and applied", Duration = 2 })
    end,
})
DataSec:NewToggle({
    Title    = "Auto Save",
    Default  = true,
    Callback = function(v)
        if v then
            Hub:AutoSave("phantom", Hub._autoSaveInterval or 60)
        else
            if Hub._autoSaveThread then
                task.cancel(Hub._autoSaveThread)
                Hub._autoSaveThread = nil
            end
        end
    end,
})
DataSec:NewSlider({
    Title    = "Auto Save (secs)",
    Min      = 15,
    Max      = 300,
    Default  = 60,
    Callback = function(v)
        Hub._autoSaveInterval = v
        Hub:AutoSave("phantom", v)
    end,
})

KbSec:NewKeybind({
    Title    = "Toggle Keybind",
    Default  = Enum.KeyCode.J,
    Callback = function(key) Hub.Keybind = key end,
})

-- Hide Settings from sidebar (reachable only via the ⚙ topbar button)
SetTab._btn.Visible = false

Hub:AutoSave("phantom", 60)

-- ════════════════════════════════════════════════════════════════
--  GAME-SPECIFIC TABS  (your friend fills these in)
-- ════════════════════════════════════════════════════════════════
if GameName ~= "Unknown" then
    local gameIcon = GameName == "BloxFruits" and "rbxassetid://3926307959" or "rbxassetid://3926307433"
    local GameTab  = Hub:NewTab({ Title = GameName, Icon = gameIcon })

    -- ── BLOX FRUITS ──────────────────────────────────────────
    if GameName == "BloxFruits" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat" })
        local Farm   = GameTab:NewSection({ Position = "Left",  Title = "Farm"   })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player" })

        Combat:NewToggle({ Title = "Kill Aura",      Default = false, Callback = function(v) end })
        Farm:NewToggle({   Title = "Auto Farm",       Default = false, Callback = function(v)
            Hub:Notify({ Title = "Auto Farm", Message = v and "Enabled" or "Disabled", Duration = 3 })
        end })
        Farm:NewToggle({   Title = "Fruit Notifier",  Default = false, Callback = function(v) end })
        Player:NewSlider({ Title = "Walk Speed", Min = 16, Max = 500, Default = 16, Callback = function(v)
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end })
        Player:NewSlider({ Title = "Jump Power", Min = 7,  Max = 300, Default = 7,  Callback = function(v)
            local hum = getHum()
            if hum then hum.JumpPower = v end
        end })

    -- ── DA HOOD ──────────────────────────────────────────────
    elseif GameName == "DaHood" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat"  })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player"  })
        local Visual = GameTab:NewSection({ Position = "Right", Title = "Visuals" })

        Combat:NewToggle({ Title = "Aimbot",    Default = false, Callback = function(v) end })
        Combat:NewToggle({ Title = "Silent Aim", Default = false, Callback = function(v) end })
        Combat:NewSlider({ Title = "Aimbot FOV", Min = 10, Max = 500, Default = 150, Callback = function(v) end })
        Player:NewSlider({ Title = "Walk Speed", Min = 16, Max = 500, Default = 16, Callback = function(v)
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end })
        Player:NewSlider({ Title = "Jump Power", Min = 7,  Max = 300, Default = 7,  Callback = function(v)
            local hum = getHum()
            if hum then hum.JumpPower = v end
        end })
        Visual:NewToggle({ Title = "Player ESP", Default = false, Callback = function(v) end })
    end

else
    local UnkTab = Hub:NewTab({ Title = "Unknown Game", Icon = "rbxassetid://3926305904" })
    local UnkSec = UnkTab:NewSection({ Position = "Left", Title = "Info" })
    UnkSec:NewLabel("No scripts for this game yet.")
    UnkSec:NewLabel("PlaceId: " .. tostring(PlaceId))
end

-- ── Startup Notification ──────────────────────────────────────
Hub:Notify({
    Title    = "Phantom Loaded",
    Message  = "Game: " .. GameName .. " | J to toggle",
    Duration = 5,
})
