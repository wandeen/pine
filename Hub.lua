-- ╔══════════════════════════════════════════════════╗
-- ║              PHANTOM HUB  v3.0                   ║
-- ║         Universal  —  no game-specific code      ║
-- ╚══════════════════════════════════════════════════╝
--
-- COLLAB ARCHITECTURE
-- ═══════════════════
-- This file (yours, obfuscated) provides:
--   • Phantom UI library  (loadstringed from your GitHub)
--   • Universal tab       (player, movement, utility, ESP, combat)
--   • Clean API exposed via _G.PhantomHub for your friend's scripts
--
-- Your friend's game script does ONE line to attach:
--   local PH = _G.PhantomHub:Await()
--   local MyTab = PH.Hub:NewTab({ Title = "DaHood", Icon = "..." })
--   ... build sections/toggles/etc on MyTab ...
--
-- API exposed on _G.PhantomHub:
--   :Await()          → blocks until Hub is ready, returns the API table
--   .Hub              → the Phantom window object  (Hub:NewTab, Hub:Notify, etc.)
--   .Phantom          → the raw Phantom library    (Phantom.Theme, etc.)
--   .Players          → game:GetService("Players")
--   .RunService       → game:GetService("RunService")
--   .UIS              → game:GetService("UserInputService")
--   .LocalPlayer      → Players.LocalPlayer
--   .getChar()        → LocalPlayer.Character
--   .getHum()         → current Humanoid or nil
--   .getHRP()         → current HumanoidRootPart or nil
--   .startAimbot()    → enable aimbot programmatically
--   .stopAimbot()     → disable aimbot programmatically
--   .enableESP()      → enable ESP programmatically
--   .clearESP()       → clear ESP programmatically
--   .PlaceId          → game.PlaceId
-- ═══════════════════════════════════════════════════

-- ── Load UI Library ───────────────────────────────────────────
local _phantomUrl = "https://raw.githubusercontent.com/wandeen/pine/main/Phantom.lua"
local _loaded, _result = pcall(function()
    return loadstring(game:HttpGet(_phantomUrl))()
end)
if not _loaded or not _result then
    -- Fallback error so your friend sees something useful
    local sg = Instance.new("ScreenGui"); sg.ResetOnSpawn = false
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    sg.Parent = ok and cg or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,80); lbl.Position = UDim2.new(0,0,0.4,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(255,80,80)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 18; lbl.TextWrapped = true
    lbl.Text = "Phantom: failed to load UI library.\nURL: " .. _phantomUrl
    lbl.Parent = sg
    error("Phantom Hub: could not load Phantom.lua — " .. tostring(_result))
end
local Phantom = _result

-- ── Services ──────────────────────────────────────────────────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UIS            = game:GetService("UserInputService")
local Lighting       = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer    = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────
local function getChar() return LocalPlayer.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ════════════════════════════════════════════════════════════════
--  PANIC KEY  (Delete)
-- ════════════════════════════════════════════════════════════════
local _panicShutdown  -- forward declared

local function _showDisengagedOverlay()
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PhantomPanicOverlay"; sg.ResetOnSpawn = false
        local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
        sg.Parent = ok and cg or LocalPlayer:WaitForChild("PlayerGui")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,0,0,60); lbl.Position = UDim2.new(0,0,0.5,-30)
        lbl.BackgroundTransparency = 1; lbl.Text = "DISENGAGED"
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 36
        lbl.TextColor3 = Color3.fromRGB(255,65,65); lbl.TextStrokeTransparency = 0.4
        lbl.Parent = sg
        task.delay(1, function() pcall(function() sg:Destroy() end) end)
    end)
end

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Delete and _panicShutdown then
        _panicShutdown()
    end
end)

-- ── Create Window ─────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = "hub",
    Keybind  = Enum.KeyCode.J,
})
Hub:SetProfile()
Hub._win.BackgroundTransparency = 0.05

-- ════════════════════════════════════════════════════════════════
--  SETTINGS MANAGER (inlined — `script` is nil in executors)
-- ════════════════════════════════════════════════════════════════
local _smHS = game:GetService("HttpService")
local SettingsManager = {}; SettingsManager.__index = SettingsManager
function SettingsManager.new(hub, name)
    return setmetatable({_hub=hub,_name=name or "default",_entries={},_charConn=nil}, SettingsManager)
end
function SettingsManager:Register(key, getter, setter)
    self._entries[key] = {get=getter, set=setter}
end
local function _smEncode(v)
    if typeof(v)=="Color3" then
        return {__type="Color3",r=math.round(v.R*255),g=math.round(v.G*255),b=math.round(v.B*255)}
    end; return v
end
local function _smDecode(v)
    if type(v)=="table" and v.__type=="Color3" then
        return Color3.fromRGB(v.r or 0,v.g or 0,v.b or 0)
    end; return v
end
function SettingsManager:Save()
    local data={}
    for k,e in pairs(self._entries) do local ok,val=pcall(e.get); if ok then data[k]=_smEncode(val) end end
    local ok,json=pcall(function() return _smHS:JSONEncode(data) end)
    if ok then pcall(function() writefile("phantom_sm_"..self._name..".json",json) end) end
end
function SettingsManager:Load()
    local ok,content=pcall(function() return readfile("phantom_sm_"..self._name..".json") end)
    if not ok or not content or content=="" then return false end
    local ok2,data=pcall(function() return _smHS:JSONDecode(content) end)
    if not ok2 or type(data)~="table" then return false end
    for k,e in pairs(self._entries) do
        if data[k]~=nil then pcall(function() e.set(_smDecode(data[k])) end) end
    end; return true
end
function SettingsManager:StartAutoApply()
    if self._charConn then self._charConn:Disconnect() end
    self._charConn = Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1); self:Load()
    end)
end

local _flySpeed = 60
local SM = SettingsManager.new(Hub, "phantom")
SM:Register("WalkSpeed",
    function() return _G.PhantomWalkSpeed or 16 end,
    function(v) _G.PhantomWalkSpeed=v; local h=getHum(); if h then h.WalkSpeed=v end end)
SM:Register("JumpPower",
    function() return _G.PhantomJumpPower or 7 end,
    function(v) _G.PhantomJumpPower=v; local h=getHum(); if h then h.JumpPower=v end end)
SM:Register("FlySpeed",
    function() return _flySpeed end,
    function(v) _flySpeed=v end)
SM:Load(); SM:StartAutoApply()

-- ════════════════════════════════════════════════════════════════
--  NOCLIP
--  Primary layer: RenderStepped CanCollide=false (runs before physics
--  solver, always wins even when server overrides CollisionGroup).
-- ════════════════════════════════════════════════════════════════
local _noclipEnabled=false
local _noclipConn,_noclipPartConn,_noclipCharConn,_noclipHL

local _noclipGroup="PhantomNoclip"; local _noclipGroupReady=false
pcall(function()
    pcall(function() PhysicsService:RegisterCollisionGroup(_noclipGroup) end)
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup,"Default",false)
    PhysicsService:CollisionGroupSetCollidable(_noclipGroup,_noclipGroup,false)
    _noclipGroupReady=true
end)

local function _ncPart(part,on)
    part.CanCollide=not on
    if _noclipGroupReady then pcall(function() part.CollisionGroup=on and _noclipGroup or "Default" end) end
end
local function _ncChar(char,on)
    if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d:IsA("BasePart") then _ncPart(d,on) end end
end
local function _applyNoclipHL(char)
    pcall(function() if _noclipHL then _noclipHL:Destroy() end end); _noclipHL=nil
    if not char then return end
    local hl=Instance.new("Highlight"); hl.Adornee=char
    hl.FillColor=Color3.fromRGB(138,43,226); hl.FillTransparency=0.75
    hl.OutlineColor=Color3.fromRGB(180,100,255); hl.OutlineTransparency=0.3
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=workspace; _noclipHL=hl
end

local function _enableNoclip()
    _noclipEnabled=true
    local char=getChar(); _ncChar(char,true); _applyNoclipHL(char)
    -- PRIMARY: RenderStepped before physics reads CanCollide
    if _noclipConn then _noclipConn:Disconnect() end
    _noclipConn=RunService.RenderStepped:Connect(function()
        if not _noclipEnabled then return end
        local c=getChar(); if not c then return end
        for _,d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then d.CanCollide=false end
        end
    end)
    if char then
        if _noclipPartConn then _noclipPartConn:Disconnect() end
        _noclipPartConn=char.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and _noclipEnabled then
                task.defer(function() pcall(function() _ncPart(d,true) end) end)
            end
        end)
    end
    if _noclipCharConn then _noclipCharConn:Disconnect() end
    _noclipCharConn=LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.3); if not _noclipEnabled then return end
        _ncChar(newChar,true); _applyNoclipHL(newChar)
        if _noclipPartConn then _noclipPartConn:Disconnect() end
        _noclipPartConn=newChar.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") and _noclipEnabled then
                task.defer(function() pcall(function() _ncPart(d,true) end) end)
            end
        end)
    end)
end

local function _disableNoclip()
    _noclipEnabled=false
    if _noclipConn     then _noclipConn:Disconnect();     _noclipConn=nil     end
    if _noclipPartConn then _noclipPartConn:Disconnect(); _noclipPartConn=nil end
    if _noclipCharConn then _noclipCharConn:Disconnect(); _noclipCharConn=nil end
    pcall(function() if _noclipHL then _noclipHL:Destroy() end end); _noclipHL=nil
    _ncChar(getChar(),false)
end

-- ════════════════════════════════════════════════════════════════
--  WALK SPEED ENFORCER
-- ════════════════════════════════════════════════════════════════
local _wsTarget=16; local _wsConn=nil
local function startWsEnforcer(speed)
    _wsTarget=speed; if _wsConn then _wsConn:Disconnect() end
    _wsConn=RunService.Heartbeat:Connect(function()
        local h=getHum(); if h and h.WalkSpeed~=_wsTarget then h.WalkSpeed=_wsTarget end
    end)
end
local function stopWsEnforcer()
    if _wsConn then _wsConn:Disconnect(); _wsConn=nil end
end

-- ════════════════════════════════════════════════════════════════
--  AIMBOT
-- ════════════════════════════════════════════════════════════════
local _abEnabled=false; local _abMode="Toggle"; local _abKey=Enum.KeyCode.RightAlt
local _abFov=120; local _abSmoothing=40; local _abBone="Head"; local _abPriority="Distance"
local _abVisCheck=true; local _abAutoWall=false; local _abRCS=false; local _abRCSStrength=50
local _abHumanize=true; local _abFovColor=Color3.fromRGB(255,255,255)
local _abFovCircle=nil; local _abConn=nil; local _abTarget=nil

local _boneMapR15={Head="Head",Neck="UpperTorso",Chest="UpperTorso",Pelvis="LowerTorso"}
local _boneMapR6 ={Head="Head",Neck="Torso",Chest="Torso",Pelvis="Torso"}
local _randomR15={"Head","UpperTorso","LowerTorso"}; local _randomR6={"Head","Torso"}

local function _getTargetPart(char)
    local isR15=char:FindFirstChild("UpperTorso")~=nil; local bone=_abBone
    if bone=="Random" then local p=isR15 and _randomR15 or _randomR6; bone=p[math.random(1,#p)] end
    return char:FindFirstChild((isR15 and _boneMapR15 or _boneMapR6)[bone] or "HumanoidRootPart")
end

local function _abVisible(origin,targetPos)
    if _abAutoWall then return true end
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={getChar()}; params.FilterType=Enum.RaycastFilterType.Exclude
    local result=workspace:Raycast(origin,targetPos-origin,params); if not result then return true end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            if result.Instance:IsDescendantOf(plr.Character) then return true end
        end
    end; return false
end

local function _abScore(plr,char,camPos,fovPx)
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
    local cam=workspace.CurrentCamera; local sp,inView=cam:WorldToViewportPoint(hrp.Position)
    if not inView or sp.Z<=0 then return nil end
    if (Vector2.new(sp.X,sp.Y)-cam.ViewportSize/2).Magnitude>fovPx then return nil end
    if _abVisCheck and not _abVisible(camPos,hrp.Position) then return nil end
    local dist=(hrp.Position-camPos).Magnitude
    local hp=(char:FindFirstChildOfClass("Humanoid") or {Health=100}).Health
    if _abPriority=="Distance" then return -dist
    elseif _abPriority=="Health" then return -hp
    elseif _abPriority=="Threat" then return -dist+hp*0.5 end
    return -(Vector2.new(sp.X,sp.Y)-workspace.CurrentCamera.ViewportSize/2).Magnitude
end

local function _runAimbot()
    local cam=workspace.CurrentCamera; local camCF=cam.CFrame; local camPos=camCF.Position
    local fovPx=(cam.ViewportSize.X/2)*math.tan(math.rad(_abFov/2))/math.tan(math.rad(cam.FieldOfView/2))
    local bestScore=-math.huge; local bestPart=nil; local bestPlr=nil
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local char=plr.Character; if char then
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health>0 then
                    local s=_abScore(plr,char,camPos,fovPx)
                    if s and s>bestScore then bestScore=s; bestPlr=plr; bestPart=_getTargetPart(char) end
                end
            end
        end
    end
    _abTarget=bestPlr; if not bestPlr or not bestPart then return end
    local tPos=bestPart.Position
    if _abHumanize then
        tPos=tPos+Vector3.new((math.random()-0.5)*0.10,(math.random()-0.5)*0.10,(math.random()-0.5)*0.10)
    end
    local tCF=CFrame.new(camPos,tPos)
    local camPitch=math.asin(math.clamp(camCF.LookVector.Y,-1,1))
    local tgtPitch=math.asin(math.clamp(tCF.LookVector.Y,-1,1))
    local _,camYaw,_=camCF:ToEulerAnglesYXZ(); local _,tgtYaw,_=tCF:ToEulerAnglesYXZ()
    local dPitch=math.deg(tgtPitch-camPitch); local dYaw=math.deg(tgtYaw-camYaw)
    if dYaw> 180 then dYaw=dYaw-360 end; if dYaw<-180 then dYaw=dYaw+360 end
    local alpha=math.clamp(1-(_abSmoothing/100),0.01,1)
    local eased=function(d) return d*(1-(1-alpha)^3) end
    local maxDeg=_abHumanize and 15 or 360
    local moveX=math.clamp(eased(dYaw),-maxDeg,maxDeg)
    local moveY=math.clamp(eased(dPitch),-maxDeg,maxDeg)
    if _abHumanize and math.random(1,20)==1 then return end
    local sens=cam.ViewportSize.X/cam.FieldOfView
    pcall(function() mousemoverel(moveX*sens*0.85,-moveY*sens*0.85) end)
    if _abRCS then
        local rcs=(_abRCSStrength/100)*1.8
        if _abHumanize then rcs=rcs+(math.random()-0.5)*0.4 end
        pcall(function() mousemoverel(0,rcs) end)
    end
end

local function _abUpdateFovCircle(show)
    if not Drawing then return end
    if not show then if _abFovCircle then pcall(function() _abFovCircle:Remove() end); _abFovCircle=nil end; return end
    if not _abFovCircle then
        _abFovCircle=Drawing.new("Circle"); _abFovCircle.Thickness=1
        _abFovCircle.Filled=false; _abFovCircle.NumSides=64
    end
    local cam=workspace.CurrentCamera
    local fovPx=(cam.ViewportSize.X/2)*math.tan(math.rad(_abFov/2))/math.tan(math.rad(cam.FieldOfView/2))
    _abFovCircle.Radius=fovPx; _abFovCircle.Position=cam.ViewportSize/2
    _abFovCircle.Color=_abTarget and Color3.fromRGB(255,80,80) or _abFovColor; _abFovCircle.Visible=true
end

local function _startAimbot()
    if _abConn then _abConn:Disconnect() end
    _abConn=RunService.RenderStepped:Connect(function()
        local active=_abEnabled
        if _abMode=="Hold" then active=active and UIS:IsKeyDown(_abKey) end
        if UIS:GetFocusedTextBox() then active=false end
        if active then _runAimbot() else _abTarget=nil end
        _abUpdateFovCircle(_abEnabled)
    end)
end

local function _stopAimbot()
    _abEnabled=false; if _abConn then _abConn:Disconnect(); _abConn=nil end
    _abTarget=nil; _abUpdateFovCircle(false)
end

-- ════════════════════════════════════════════════════════════════
--  TRIGGERBOT
-- ════════════════════════════════════════════════════════════════
local _tbActive=false; local _tbMode="Toggle"; local _tbKey=Enum.KeyCode.T
local _tbDelay=80; local _tbVariance=20; local _tbFilter="Any visible"
local _tbConn=nil; local _tbFiring=false

local function _tbRaycast(char)
    local cam=workspace.CurrentCamera; local vp=cam.ViewportSize
    local ray=cam:ScreenPointToRay(vp.X*0.5,vp.Y*0.5)
    local params=RaycastParams.new()
    params.FilterDescendantsInstances={char}; params.FilterType=Enum.RaycastFilterType.Exclude
    local result=workspace:Raycast(ray.Origin,ray.Direction*2000,params); if not result then return false end
    local hit=result.Instance
    if _tbFilter=="Head only" then return hit.Name=="Head" end
    if _tbFilter=="Body" then
        for _,n in ipairs({"Torso","UpperTorso","LowerTorso","HumanoidRootPart"}) do
            if hit.Name==n then return true end end; return false
    end
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            if hit:IsDescendantOf(plr.Character) then return true end
        end
    end; return false
end

local function _tbFire()
    if _tbFiring then return end; _tbFiring=true
    task.spawn(function()
        local char=getChar(); if not char then _tbFiring=false; return end
        if not _tbRaycast(char) then _tbFiring=false; return end
        task.wait(math.max(0,(_tbDelay+math.random(-_tbVariance,_tbVariance))/1000))
        if not _tbActive then _tbFiring=false; return end
        pcall(function()
            local VU=game:GetService("VirtualUser")
            VU:Button1Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame); task.wait(0.05)
            VU:Button1Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end); _tbFiring=false
    end)
end

local function _startTriggerLoop()
    if _tbConn then _tbConn:Disconnect() end
    _tbConn=RunService.Heartbeat:Connect(function()
        if not _tbActive then return end
        if UIS:GetFocusedTextBox() then return end
        if _tbMode=="Hold" and not UIS:IsKeyDown(_tbKey) then return end
        _tbFire()
    end)
end

local function _stopTrigger()
    _tbActive=false; if _tbConn then _tbConn:Disconnect(); _tbConn=nil end
end

-- ════════════════════════════════════════════════════════════════
--  ESP
-- ════════════════════════════════════════════════════════════════
local _espActive=false; local _espShowNames=true; local _espTeamCheck=false
local _espFillColor=Color3.fromRGB(255,50,50); local _espFillTrans=0.65
local _espConns={}; local _espObjs={}

local function makeNameTag(plr,char)
    if not _espShowNames then return nil end
    local head=char:FindFirstChild("Head"); if not head then return nil end
    local bill=Instance.new("BillboardGui"); bill.Name="PhantomESPTag"
    bill.Size=UDim2.new(0,100,0,22); bill.StudsOffset=Vector3.new(0,3,0)
    bill.AlwaysOnTop=true; bill.Adornee=head; bill.Parent=workspace
    local lbl=Instance.new("TextLabel"); lbl.Text=plr.DisplayName
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextColor3=Color3.new(1,1,1)
    lbl.TextStrokeTransparency=0.4; lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
    lbl.Parent=bill; return bill
end

local function addPlayerESP(plr)
    if plr==LocalPlayer then return end
    if _espTeamCheck then
        local myT,hisT=LocalPlayer.Team,plr.Team
        if myT and hisT and myT==hisT then return end
        if not myT and not hisT then return end
    end
    local char=plr.Character; if not char then return end
    if _espObjs[plr] then
        pcall(function()
            if _espObjs[plr].hl  then _espObjs[plr].hl:Destroy()  end
            if _espObjs[plr].tag then _espObjs[plr].tag:Destroy() end
        end)
    end
    local hl=Instance.new("Highlight"); hl.Adornee=char; hl.FillColor=_espFillColor
    hl.FillTransparency=_espFillTrans; hl.OutlineColor=Color3.fromRGB(255,255,255)
    hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=workspace
    _espObjs[plr]={hl=hl,tag=makeNameTag(plr,char)}
end

local function removePlayerESP(plr)
    if not _espObjs[plr] then return end
    pcall(function()
        if _espObjs[plr].hl  then _espObjs[plr].hl:Destroy()  end
        if _espObjs[plr].tag then _espObjs[plr].tag:Destroy() end
    end); _espObjs[plr]=nil
end

local function clearESP()
    for plr in pairs(_espObjs) do removePlayerESP(plr) end
    for _,c in ipairs(_espConns) do c:Disconnect() end
    _espConns={}; _espActive=false
end

local function enableESP()
    _espActive=true
    for _,plr in ipairs(Players:GetPlayers()) do
        addPlayerESP(plr)
        table.insert(_espConns,plr.CharacterAdded:Connect(function() task.wait(0.1); addPlayerESP(plr) end))
    end
    table.insert(_espConns,Players.PlayerAdded:Connect(function(plr)
        table.insert(_espConns,plr.CharacterAdded:Connect(function() task.wait(0.1); addPlayerESP(plr) end))
    end))
    table.insert(_espConns,Players.PlayerRemoving:Connect(removePlayerESP))
end

local function refreshESP()
    if not _espActive then return end
    for _,plr in ipairs(Players:GetPlayers()) do addPlayerESP(plr) end
end

-- Skeleton ESP
local _skelActive=false; local _skelConn=nil; local _skelDrawings={}
local function getBonePos(char,partName,attachName)
    local part=char:FindFirstChild(partName); if not part then return nil end
    if attachName then local att=part:FindFirstChild(attachName)
        if att then return (part.CFrame*att.CFrame).Position end end
    return part.Position
end
local R15_BONES={
    {"Head","NeckAttachment","UpperTorso","NeckAttachment"},
    {"UpperTorso","WaistCenterAttachment","LowerTorso","WaistCenterAttachment"},
    {"UpperTorso","LeftShoulderAttachment","LeftUpperArm","LeftShoulderAttachment"},
    {"LeftUpperArm","LeftElbowAttachment","LeftLowerArm","LeftElbowAttachment"},
    {"LeftLowerArm","LeftWristAttachment","LeftHand","LeftWristAttachment"},
    {"UpperTorso","RightShoulderAttachment","RightUpperArm","RightShoulderAttachment"},
    {"RightUpperArm","RightElbowAttachment","RightLowerArm","RightElbowAttachment"},
    {"RightLowerArm","RightWristAttachment","RightHand","RightWristAttachment"},
    {"LowerTorso","LeftHipAttachment","LeftUpperLeg","LeftHipAttachment"},
    {"LeftUpperLeg","LeftKneeAttachment","LeftLowerLeg","LeftKneeAttachment"},
    {"LeftLowerLeg","LeftAnkleAttachment","LeftFoot","LeftAnkleAttachment"},
    {"LowerTorso","RightHipAttachment","RightUpperLeg","RightHipAttachment"},
    {"RightUpperLeg","RightKneeAttachment","RightLowerLeg","RightKneeAttachment"},
    {"RightLowerLeg","RightAnkleAttachment","RightFoot","RightAnkleAttachment"},
}
local R6_BONES={
    {"Head","NeckAttachment","Torso","NeckAttachment"},
    {"Torso","LeftShoulderAttachment","Left Arm","LeftShoulderAttachment"},
    {"Torso","RightShoulderAttachment","Right Arm","RightShoulderAttachment"},
    {"Torso","LeftHipAttachment","Left Leg","LeftHipAttachment"},
    {"Torso","RightHipAttachment","Right Leg","RightHipAttachment"},
}
local function clearSkelPlayer(plr)
    if not _skelDrawings[plr] then return end
    for _,ln in ipairs(_skelDrawings[plr]) do pcall(function() ln:Remove() end) end
    _skelDrawings[plr]=nil
end

-- ESP Lines
local _espLinesActive=false; local _espLineOrigin="Bottom"
local _espLinesConn=nil; local _espLineDrawings={}

-- ════════════════════════════════════════════════════════════════
--  SPECTATOR LIST
-- ════════════════════════════════════════════════════════════════
local _spectActive=false; local _spectAlert=true; local _spectStreamer=false
local _spectLastCount=0; local _spectConn=nil; local _spectGui=nil

local function _makeSpectGui()
    if _spectGui then pcall(function() _spectGui:Destroy() end); _spectGui=nil end
    local sg=Instance.new("ScreenGui"); sg.Name="PhantomSpectList"; sg.ResetOnSpawn=false; sg.DisplayOrder=99
    local ok,cg=pcall(function() return cloneref(game:GetService("CoreGui")) end)
    sg.Parent=ok and cg or LocalPlayer:WaitForChild("PlayerGui")
    local frame=Instance.new("Frame"); frame.Size=UDim2.new(0,180,0,20); frame.Position=UDim2.new(0,10,0,10)
    frame.BackgroundColor3=Color3.fromRGB(14,14,14); frame.BackgroundTransparency=0.15
    frame.BorderSizePixel=0; frame.AutomaticSize=Enum.AutomaticSize.Y; frame.Parent=sg
    local c2=Instance.new("UICorner"); c2.CornerRadius=UDim.new(0,6); c2.Parent=frame
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,2); l.Parent=frame
    local p=Instance.new("UIPadding")
    p.PaddingTop=UDim.new(0,4); p.PaddingBottom=UDim.new(0,4)
    p.PaddingLeft=UDim.new(0,6); p.PaddingRight=UDim.new(0,6); p.Parent=frame
    _spectGui=sg; return frame
end

local function _rebuildSpectList()
    if not _spectActive then return end
    local container=_makeSpectGui(); local spectNames={}
    pcall(function()
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local char=plr.Character
                if char and not char:FindFirstChild("HumanoidRootPart") then
                    table.insert(spectNames,plr.Name)
                end
            end
        end
    end)
    local count=#spectNames; local isAlert=count>_spectLastCount
    local header=Instance.new("TextLabel"); header.Size=UDim2.new(1,0,0,16); header.BackgroundTransparency=1
    header.Font=Enum.Font.GothamBold; header.TextSize=11
    header.TextColor3=isAlert and Color3.fromRGB(255,220,50) or Color3.fromRGB(180,180,180)
    header.TextXAlignment=Enum.TextXAlignment.Left; header.Text="Spectators: "..count; header.Parent=container
    for _,name in ipairs(spectNames) do
        local row=Instance.new("TextLabel"); row.Size=UDim2.new(1,0,0,13); row.BackgroundTransparency=1
        row.Font=Enum.Font.Gotham; row.TextSize=10; row.TextColor3=Color3.fromRGB(200,200,200)
        row.TextXAlignment=Enum.TextXAlignment.Left; row.Text="  - "..name; row.Parent=container
    end
    if isAlert and _spectAlert then Hub:Notify({Title="Spectator Alert",Message="Someone is watching!",Duration=3}) end
    if _spectStreamer and count>0 then if _abEnabled then _stopAimbot() end; if _tbActive then _stopTrigger() end end
    _spectLastCount=count
end

-- ════════════════════════════════════════════════════════════════
--  BUILD TABS
-- ════════════════════════════════════════════════════════════════

-- ── Universal Tab ─────────────────────────────────────────────
local UniTab    = Hub:NewTab({ Title="Universal", Icon="rbxassetid://3926305904" })
local UniPlayer = UniTab:NewSection({ Position="Left",  Title="Player"   })
local UniMove   = UniTab:NewSection({ Position="Left",  Title="Movement" })
local UniUtil   = UniTab:NewSection({ Position="Right", Title="Utility"  })
local UniESP    = UniTab:NewSection({ Position="Right", Title="ESP"      })

-- Player
UniPlayer:NewSlider({ Title="Walk Speed", Min=16, Max=300, Default=16,
    Callback=function(v)
        _G.PhantomWalkSpeed=v
        if v>16 then startWsEnforcer(v) else stopWsEnforcer(); local h=getHum(); if h then h.WalkSpeed=v end end
    end,
})
UniPlayer:NewSlider({ Title="Jump Power", Min=7, Max=200, Default=7,
    Callback=function(v) _G.PhantomJumpPower=v; local h=getHum(); if h then h.JumpPower=v end end,
})
UniPlayer:NewSlider({ Title="Fly Speed", Min=10, Max=200, Default=60,
    Callback=function(v) _flySpeed=v end,
})

-- Movement
local _infJumpConn
UniMove:NewToggle({ Title="Infinite Jump", Default=false,
    Callback=function(v)
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn=nil end
        if v then _infJumpConn=UIS.JumpRequest:Connect(function()
            local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end) end
    end,
})

local _flyEnabled=false; local _flyConn,_flyCharConn,_bodyVel,_bodyGyro
local function stopFly()
    _flyEnabled=false; if _flyConn then _flyConn:Disconnect(); _flyConn=nil end
    pcall(function() if _bodyVel then _bodyVel:Destroy(); _bodyVel=nil end; if _bodyGyro then _bodyGyro:Destroy(); _bodyGyro=nil end end)
    local h=getHum(); if h then h.PlatformStand=false end
end
local function startFly()
    stopFly(); _flyEnabled=true
    local char=getChar(); if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand=true
    _bodyVel=Instance.new("BodyVelocity"); _bodyVel.Velocity=Vector3.new(0,0,0); _bodyVel.MaxForce=Vector3.new(1e5,1e5,1e5); _bodyVel.Parent=hrp
    _bodyGyro=Instance.new("BodyGyro"); _bodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5); _bodyGyro.D=100; _bodyGyro.CFrame=hrp.CFrame; _bodyGyro.Parent=hrp
    local cam=workspace.CurrentCamera
    _flyConn=RunService.Heartbeat:Connect(function()
        if not _flyEnabled or not hrp.Parent then return end
        local dir=Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W)           then dir=dir+cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)           then dir=dir-cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)           then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)           then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir=dir+Vector3.new(0,1,0)     end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        or UIS:IsKeyDown(Enum.KeyCode.LeftShift)   then dir=dir-Vector3.new(0,1,0)     end
        _bodyVel.Velocity=dir.Magnitude>0 and dir.Unit*_flySpeed or Vector3.new(0,0,0)
        _bodyGyro.CFrame=CFrame.new(hrp.Position,hrp.Position+cam.CFrame.LookVector)
    end)
end

UniMove:NewToggle({ Title="Fly  [WASD + Space / Ctrl]", Default=false,
    Callback=function(v)
        if v then startFly()
            if not _flyCharConn then _flyCharConn=LocalPlayer.CharacterAdded:Connect(function()
                if _flyEnabled then task.wait(0.5); startFly() end end) end
        else stopFly() end
    end,
})
UniMove:NewToggle({ Title="No Clip", Default=false,
    Callback=function(v) if v then _enableNoclip() else _disableNoclip() end end,
})

-- Utility
local _afkThread
UniUtil:NewToggle({ Title="Anti-AFK", Default=false,
    Callback=function(v)
        if _afkThread then task.cancel(_afkThread); _afkThread=nil end
        if v then _afkThread=task.spawn(function() while true do task.wait(60)
            pcall(function() local VU=game:GetService("VirtualUser")
                VU:Button2Down(Vector2.new(0,0),CFrame.new()); task.wait(0.1); VU:Button2Up(Vector2.new(0,0),CFrame.new())
            end) end end) end
    end,
})
local _origBright,_origAmbient,_origOutdoor
UniUtil:NewToggle({ Title="Fullbright", Default=false,
    Callback=function(v)
        if v then _origBright=Lighting.Brightness; _origAmbient=Lighting.Ambient; _origOutdoor=Lighting.OutdoorAmbient
            Lighting.Brightness=2; Lighting.Ambient=Color3.fromRGB(178,178,178); Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
        else Lighting.Brightness=_origBright or 1; Lighting.Ambient=_origAmbient or Color3.fromRGB(127,127,127); Lighting.OutdoorAmbient=_origOutdoor or Color3.fromRGB(127,127,127) end
    end,
})
local _origFogEnd,_origFogStart,_origAtmDensity
UniUtil:NewToggle({ Title="No Fog", Default=false,
    Callback=function(v)
        if v then _origFogEnd=Lighting.FogEnd; _origFogStart=Lighting.FogStart; Lighting.FogEnd=1e9; Lighting.FogStart=1e9
            local atm=Lighting:FindFirstChildOfClass("Atmosphere"); if atm then _origAtmDensity=atm.Density; atm.Density=0 end
        else Lighting.FogEnd=_origFogEnd or 1000; Lighting.FogStart=_origFogStart or 0
            local atm=Lighting:FindFirstChildOfClass("Atmosphere"); if atm then atm.Density=_origAtmDensity or 0.395 end end
    end,
})
UniUtil:NewSeparator()
UniUtil:NewSlider({ Title="FOV", Min=50, Max=120, Default=70,
    Callback=function(v) workspace.CurrentCamera.FieldOfView=v end })
UniUtil:NewSlider({ Title="Time of Day", Min=0, Max=24, Default=14,
    Callback=function(v) Lighting.ClockTime=v end })
UniUtil:NewSeparator()
local _autoRejoinActive=false; local _autoRejoinConn
UniUtil:NewToggle({ Title="Auto Rejoin", Default=false,
    Callback=function(v)
        _autoRejoinActive=v
        if _autoRejoinConn then _autoRejoinConn:Disconnect(); _autoRejoinConn=nil end
        if not v then return end
        task.spawn(function() pcall(function()
            local CG2=game:GetService("CoreGui"); local TS2=game:GetService("TeleportService")
            local pGui=CG2:WaitForChild("RobloxPromptGui",10); if not pGui then return end
            local ov=pGui:WaitForChild("promptOverlay",10); if not ov then return end
            _autoRejoinConn=ov.ChildAdded:Connect(function()
                if not _autoRejoinActive then return end
                for i=3,1,-1 do Hub:Notify({Title="Auto Rejoin",Message="Rejoining in "..i.."s...",Duration=1}); task.wait(1) end
                pcall(function() TS2:Teleport(game.PlaceId,LocalPlayer) end)
            end)
        end) end)
    end,
})
UniUtil:NewSeparator()
local _tpTarget=""; local _tpOpts
local function _buildPlayerOpts()
    local t={}; for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer then table.insert(t,plr.Name) end end
    return #t>0 and t or {"(no other players)"}
end
_tpOpts=_buildPlayerOpts(); _tpTarget=_tpOpts[1]
UniUtil:NewDropdown({ Title="Select Target", Options=_tpOpts, Default=_tpOpts[1], Callback=function(v) _tpTarget=v end })
UniUtil:NewButton({ Title="Teleport",
    Callback=function()
        if _tpTarget=="" or _tpTarget=="(no other players)" then Hub:Notify({Title="Teleport",Message="No target selected",Duration=2}); return end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer and (plr.Name:lower()==_tpTarget:lower() or plr.DisplayName:lower():find(_tpTarget:lower(),1,true)) then
                local hrp=getHRP(); local tHrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp and tHrp then hrp.CFrame=tHrp.CFrame+Vector3.new(0,3,0); Hub:Notify({Title="Teleport",Message="-> "..plr.Name,Duration=2})
                else Hub:Notify({Title="Teleport",Message=plr.Name.." has no character",Duration=2}) end; return
            end
        end; Hub:Notify({Title="Teleport",Message="Not found: ".._tpTarget,Duration=2})
    end,
})
UniUtil:NewSeparator()
UniUtil:NewButton({ Title="Server Hop",
    Callback=function()
        Hub:Notify({Title="Server Hop",Message="Searching...",Duration=3})
        task.spawn(function() pcall(function()
            local HS2=game:GetService("HttpService"); local TS2=game:GetService("TeleportService")
            local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            local ok,resp=pcall(function() return game:HttpGet(url) end)
            if not ok then Hub:Notify({Title="Server Hop",Message="HttpGet blocked",Duration=3}); return end
            local ok2,data=pcall(function() return HS2:JSONDecode(resp) end)
            if not ok2 or not data or not data.data then Hub:Notify({Title="Server Hop",Message="Failed to parse",Duration=3}); return end
            local cands={}; for _,srv in ipairs(data.data) do if srv.playing<srv.maxPlayers then table.insert(cands,srv.id) end end
            if #cands==0 then Hub:Notify({Title="Server Hop",Message="No open servers",Duration=3}); return end
            TS2:TeleportToPlaceInstance(game.PlaceId,cands[math.random(1,#cands)],LocalPlayer)
        end) end)
    end,
})

-- ESP
UniESP:NewToggle({ Title="Player ESP", Default=false,
    Callback=function(v) if v then enableESP() else clearESP() end end })
UniESP:NewToggle({ Title="Show Names", Default=true,
    Callback=function(v) _espShowNames=v; refreshESP() end })
UniESP:NewToggle({ Title="Team Check", Default=false,
    Callback=function(v) _espTeamCheck=v; refreshESP() end })
UniESP:NewSeparator()
UniESP:NewToggle({ Title="ESP Lines", Default=false,
    Callback=function(v)
        _espLinesActive=v
        if not v then if _espLinesConn then _espLinesConn:Disconnect(); _espLinesConn=nil end
            for _,ln in pairs(_espLineDrawings) do pcall(function() ln:Remove() end) end; _espLineDrawings={}; return end
        if not Drawing then Hub:Notify({Title="ESP Lines",Message="Drawing API not supported",Duration=3}); return end
        _espLinesConn=RunService.RenderStepped:Connect(function()
            local cam=workspace.CurrentCamera; local vp=cam.ViewportSize
            local fromX=vp.X*0.5; local fromY=_espLineOrigin=="Bottom" and vp.Y or vp.Y*0.5
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LocalPlayer then
                    local char=plr.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local sp,vis=cam:WorldToViewportPoint(hrp.Position)
                        if not _espLineDrawings[plr] then
                            local ln=Drawing.new("Line"); ln.Thickness=1; ln.Color=_espFillColor; ln.Visible=false; _espLineDrawings[plr]=ln
                        end
                        local ln=_espLineDrawings[plr]; ln.From=Vector2.new(fromX,fromY); ln.To=Vector2.new(sp.X,sp.Y)
                        ln.Color=_espFillColor; ln.Visible=vis and (sp.Z>0)
                    elseif _espLineDrawings[plr] then _espLineDrawings[plr].Visible=false end
                end
            end
            for plr,ln in pairs(_espLineDrawings) do
                if not Players:FindFirstChild(plr.Name) then pcall(function() ln:Remove() end); _espLineDrawings[plr]=nil end
            end
        end)
    end,
})
UniESP:NewDropdown({ Title="Line Origin", Options={"Bottom","Center"}, Default="Bottom",
    Callback=function(v) _espLineOrigin=v end })
UniESP:NewSeparator()
UniESP:NewToggle({ Title="Skeleton ESP", Default=false,
    Callback=function(v)
        _skelActive=v
        if not v then if _skelConn then _skelConn:Disconnect(); _skelConn=nil end
            for plr in pairs(_skelDrawings) do clearSkelPlayer(plr) end; return end
        if not Drawing then Hub:Notify({Title="Skeleton ESP",Message="Drawing API not supported",Duration=3}); return end
        _skelConn=RunService.RenderStepped:Connect(function()
            local cam=workspace.CurrentCamera
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr~=LocalPlayer then
                    local char=plr.Character
                    if not char then clearSkelPlayer(plr)
                    else
                        local isR15=char:FindFirstChild("UpperTorso")~=nil; local bones=isR15 and R15_BONES or R6_BONES; local nb=#bones
                        local pool=_skelDrawings[plr]
                        if not pool or #pool~=nb then clearSkelPlayer(plr); pool={}
                            for _=1,nb do local ln=Drawing.new("Line"); ln.Thickness=2; ln.Color=_espFillColor; ln.Visible=false; table.insert(pool,ln) end
                            _skelDrawings[plr]=pool
                        end
                        for i,bone in ipairs(bones) do
                            local ln=pool[i]; local wp1=getBonePos(char,bone[1],bone[2]); local wp2=getBonePos(char,bone[3],bone[4])
                            if wp1 and wp2 then
                                local s1,v1=cam:WorldToViewportPoint(wp1); local s2,v2=cam:WorldToViewportPoint(wp2)
                                ln.From=Vector2.new(s1.X,s1.Y); ln.To=Vector2.new(s2.X,s2.Y); ln.Color=_espFillColor; ln.Visible=v1 and v2 and s1.Z>0 and s2.Z>0
                            else ln.Visible=false end
                        end
                    end
                end
            end
            for plr in pairs(_skelDrawings) do if not Players:FindFirstChild(plr.Name) then clearSkelPlayer(plr) end end
        end)
    end,
})
UniESP:NewSeparator()
UniESP:NewSlider({ Title="Fill Opacity %", Min=0, Max=100, Default=35,
    Callback=function(v) _espFillTrans=1-(v/100); for _,obj in pairs(_espObjs) do if obj.hl then obj.hl.FillTransparency=_espFillTrans end end end })
UniESP:NewColorPicker({ Title="Fill Color", Default=Color3.fromRGB(255,50,50),
    Callback=function(c) _espFillColor=c; for _,obj in pairs(_espObjs) do if obj.hl then obj.hl.FillColor=c end end end })

-- ── Combat Tab ────────────────────────────────────────────────
local CombatTab = Hub:NewTab({ Title="Combat", Icon="rbxassetid://3926307984" })
local AimSec    = CombatTab:NewSection({ Position="Left",  Title="Aimbot"        })
local AimCfgSec = CombatTab:NewSection({ Position="Left",  Title="Aimbot Config" })
local TBSec     = CombatTab:NewSection({ Position="Right", Title="Triggerbot"    })
local SpectSec  = CombatTab:NewSection({ Position="Right", Title="Spectators"    })

AimSec:NewToggle({ Title="Aimbot", Default=false,
    Callback=function(v) _abEnabled=v; if v then _startAimbot() else _stopAimbot() end end })
AimSec:NewDropdown({ Title="Mode", Options={"Toggle","Hold"}, Default="Toggle",
    Callback=function(v) _abMode=v end })
AimSec:NewSlider({ Title="FOV (degrees)", Min=1, Max=360, Default=120,
    Callback=function(v) _abFov=v end })
AimSec:NewSlider({ Title="Smoothing", Min=0, Max=100, Default=40,
    Callback=function(v) _abSmoothing=v end })
AimSec:NewDropdown({ Title="Target Bone", Options={"Head","Neck","Chest","Pelvis","Random"}, Default="Head",
    Callback=function(v) _abBone=v end })
AimSec:NewDropdown({ Title="Target Priority", Options={"Distance","Health","Threat"}, Default="Distance",
    Callback=function(v) _abPriority=v end })
AimCfgSec:NewToggle({ Title="Visibility Check", Default=true,
    Callback=function(v) _abVisCheck=v end })
AimCfgSec:NewToggle({ Title="Auto-Wall", Default=false,
    Callback=function(v) _abAutoWall=v end })
AimCfgSec:NewToggle({ Title="Humanization", Default=true,
    Callback=function(v) _abHumanize=v end })
AimCfgSec:NewToggle({ Title="RCS (Recoil Control)", Default=false,
    Callback=function(v) _abRCS=v end })
AimCfgSec:NewSlider({ Title="RCS Strength", Min=0, Max=100, Default=50,
    Callback=function(v) _abRCSStrength=v end })
AimCfgSec:NewColorPicker({ Title="FOV Circle Color", Default=Color3.fromRGB(255,255,255),
    Callback=function(c) _abFovColor=c; if _abFovCircle then _abFovCircle.Color=c end end })

TBSec:NewToggle({ Title="Triggerbot", Default=false,
    Callback=function(v) _tbActive=v; if v then _startTriggerLoop() else _stopTrigger() end end })
TBSec:NewDropdown({ Title="Mode", Options={"Toggle","Hold"}, Default="Toggle",
    Callback=function(v) _tbMode=v end })
TBSec:NewSlider({ Title="Base Delay (ms)", Min=0, Max=200, Default=80,
    Callback=function(v) _tbDelay=v end })
TBSec:NewSlider({ Title="Variance (ms)", Min=0, Max=50, Default=20,
    Callback=function(v) _tbVariance=v end })
TBSec:NewDropdown({ Title="Hitbox Filter", Options={"Any visible","Body","Head only"}, Default="Any visible",
    Callback=function(v) _tbFilter=v end })

SpectSec:NewToggle({ Title="Spectator List", Default=false,
    Callback=function(v)
        _spectActive=v
        if _spectConn then _spectConn:Disconnect(); _spectConn=nil end
        if _spectGui  then pcall(function() _spectGui:Destroy() end); _spectGui=nil end
        if not v then return end
        _rebuildSpectList()
        _spectConn=RunService.Heartbeat:Connect(function() _rebuildSpectList(); task.wait(2) end)
    end })
SpectSec:NewToggle({ Title="Alert on New Spectator", Default=true,
    Callback=function(v) _spectAlert=v end })
SpectSec:NewToggle({ Title="Streamer Mode", Default=false,
    Callback=function(v) _spectStreamer=v end })

-- ── Settings Tab ──────────────────────────────────────────────
local SetTab    = Hub:NewTab({ Title="Settings", Icon="rbxassetid://3926307641" })
local AppearSec = SetTab:NewSection({ Position="Left",  Title="Appearance" })
local DataSec   = SetTab:NewSection({ Position="Right", Title="Config"     })
local KbSec     = SetTab:NewSection({ Position="Right", Title="Keybind"    })

AppearSec:NewColorPicker({ Title="Accent Color", Default=Color3.fromRGB(110,75,255),
    Callback=function(c) Hub:SetAccent(c) end })
AppearSec:NewSlider({ Title="Window Opacity %", Min=30, Max=100, Default=95,
    Callback=function(v) Hub._win.BackgroundTransparency=1-(v/100) end })
DataSec:NewButton({ Title="Save Config",
    Callback=function() SM:Save(); Hub:Notify({Title="Config",Message="Saved",Duration=2}) end })
DataSec:NewButton({ Title="Load Config",
    Callback=function() SM:Load(); Hub:Notify({Title="Config",Message="Loaded",Duration=2}) end })
DataSec:NewToggle({ Title="Auto Save", Default=true,
    Callback=function(v)
        if v then Hub:AutoSave("phantom",Hub._autoSaveInterval or 60)
        else if Hub._autoSaveThread then task.cancel(Hub._autoSaveThread); Hub._autoSaveThread=nil end end
    end })
DataSec:NewSlider({ Title="Auto Save (secs)", Min=15, Max=300, Default=60,
    Callback=function(v) Hub._autoSaveInterval=v; Hub:AutoSave("phantom",v) end })
KbSec:NewKeybind({ Title="Toggle Keybind", Default=Enum.KeyCode.J,
    Callback=function(key) Hub.Keybind=key end })
SetTab._btn.Visible=false
Hub:AutoSave("phantom",60)

-- ════════════════════════════════════════════════════════════════
--  PANIC KEY WIRING
-- ════════════════════════════════════════════════════════════════
_panicShutdown = function()
    pcall(stopWsEnforcer); pcall(stopFly); pcall(_disableNoclip)
    pcall(clearESP); pcall(_stopAimbot); pcall(_stopTrigger)
    pcall(function()
        if _skelConn then _skelConn:Disconnect(); _skelConn=nil end
        for plr in pairs(_skelDrawings) do clearSkelPlayer(plr) end
        if _espLinesConn then _espLinesConn:Disconnect(); _espLinesConn=nil end
        for _,ln in pairs(_espLineDrawings) do pcall(function() ln:Remove() end) end; _espLineDrawings={}
    end)
    pcall(function()
        _spectActive=false; if _spectConn then _spectConn:Disconnect(); _spectConn=nil end
        if _spectGui then _spectGui:Destroy(); _spectGui=nil end
    end)
    pcall(function() if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn=nil end end)
    pcall(function()
        Lighting.Brightness=_origBright or 1; Lighting.Ambient=_origAmbient or Color3.fromRGB(127,127,127)
        Lighting.OutdoorAmbient=_origOutdoor or Color3.fromRGB(127,127,127)
        Lighting.FogEnd=_origFogEnd or 1000; Lighting.FogStart=_origFogStart or 0
        local atm=Lighting:FindFirstChildOfClass("Atmosphere"); if atm then atm.Density=_origAtmDensity or 0.395 end
    end)
    pcall(function() local h=getHum(); if h then h.WalkSpeed=16; h.JumpPower=50; h.PlatformStand=false end end)
    _showDisengagedOverlay()
end

-- ════════════════════════════════════════════════════════════════
--  PUBLIC API  —  exposed on _G so your friend's scripts attach
-- ════════════════════════════════════════════════════════════════
_G.PhantomHub = {
    -- Core objects
    Hub         = Hub,
    Phantom     = Phantom,
    -- Services (saves your friend from re-getting them)
    Players     = Players,
    RunService  = RunService,
    UIS         = UIS,
    LocalPlayer = LocalPlayer,
    PlaceId     = game.PlaceId,
    -- Helpers
    getChar     = getChar,
    getHum      = getHum,
    getHRP      = getHRP,
    -- Combat API
    startAimbot = _startAimbot,
    stopAimbot  = _stopAimbot,
    enableESP   = enableESP,
    clearESP    = clearESP,
    -- Await: blocks until this line executes (Hub is always ready by here)
    Await       = function(self) return self end,
}

-- ── Startup Notification ──────────────────────────────────────
Hub:Notify({
    Title    = "Phantom v3.0",
    Message  = "J = menu  |  RAlt = aimbot  |  Del = PANIC",
    Duration = 5,
})
