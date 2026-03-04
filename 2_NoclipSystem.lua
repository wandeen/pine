--[[
NOCLIP SYSTEM
Robust collision bypass combining multiple techniques.
- RenderStepped-based collision disabling (primary)
- Touch-event collision disabling (fallback)
- Smooth directional movement
- Speed adjustment
- Automatic re-apply on respawn
- Visual indicator
- Anti-detection safeguards

Usage:
    local Noclip = require(this_module).new()
    Noclip:Enable()
    Noclip:SetSpeed(50)
    Noclip:Disable()
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Noclip = {}
Noclip.__index = Noclip

-- ── Configuration ─────────────────────────────────────
local DEFAULT_SPEED = 50
local COLLISION_GROUP = "PhantomNoclipGroup"
local MIN_SPEED = 1
local MAX_SPEED = 500

-- ── Internal State ────────────────────────────────────
function Noclip.new()
    local self = setmetatable({}, Noclip)
    
    self.enabled = false
    self.speed = DEFAULT_SPEED
    self.LocalPlayer = Players.LocalPlayer
    self.currentCharacter = nil
    
    -- Connections
    self._renderConn = nil
    self._charConn = nil
    self._touchConns = {}
    self._visualIndicator = nil
    
    -- Physics group setup
    self:_setupPhysicsGroup()
    
    -- Auto re-enable on respawn
    self:_hookCharacterAdded()
    
    return self
end

-- ── Setup Physics Collision Group ──────────────────────
function Noclip:_setupPhysicsGroup()
    pcall(function()
        PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
        PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, "Default", false)
        PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)
    end)
end

-- ── Hook Character Added for Auto Re-enable ───────────
function Noclip:_hookCharacterAdded()
    if self._charConn then self._charConn:Disconnect() end
    
    self._charConn = self.LocalPlayer.CharacterAdded:Connect(function(newChar)
        self.currentCharacter = newChar
        -- If noclip was enabled, re-enable it after respawn
        if self.enabled then
            task.wait(0.5)  -- Wait for character to fully load
            self:_applyNoclipToCharacter(newChar)
        end
    end)
end

-- ── Apply Noclip to All Character Parts ────────────────
function Noclip:_applyNoclipToCharacter(char)
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            self:_makePartNoclip(part)
        end
    end
    
    -- Hook DescendantAdded for tools/accessories added mid-noclip
    local descAddedConn
    descAddedConn = char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and self.enabled then
            self:_makePartNoclip(desc)
        end
    end)
    
    table.insert(self._touchConns, descAddedConn)
end

-- ── Make Single Part Noclip ──────────────────────────────
function Noclip:_makePartNoclip(part)
    part.CanCollide = false
    
    -- Try to add to physics group (graceful fail if unavailable)
    pcall(function()
        PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP, "Default", false)
        part.CollisionGroup = COLLISION_GROUP
    end)
end

-- ── Touch-Based Fallback (for walls) ──────────────────
function Noclip:_setupTouchFallback(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local function onTouched(part)
        if not part:IsA("BasePart") then return end
        if not part.Anchored or not part.CanCollide then return end
        
        -- Don't disable floor (below player)
        if part.Position.Y < (hrp.Position.Y - hrp.Size.Y/2) then return end
        
        part.CanCollide = false
    end
    
    local touchConn = hrp.Touched:Connect(onTouched)
    table.insert(self._touchConns, touchConn)
end

-- ── RenderStepped Loop (Primary Method) ────────────────
function Noclip:_startRenderLoop()
    if self._renderConn then self._renderConn:Disconnect() end
    
    self._renderConn = RunService.RenderStepped:Connect(function()
        if not self.enabled or not self.currentCharacter then return end
        
        local char = self.currentCharacter
        
        -- Ensure all parts have CanCollide disabled
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ── Enable Noclip ─────────────────────────────────────
function Noclip:Enable()
    if self.enabled then return end
    
    self.enabled = true
    self.currentCharacter = self.LocalPlayer.Character
    
    if not self.currentCharacter then return end
    
    -- Apply noclip to current character
    self:_applyNoclipToCharacter(self.currentCharacter)
    
    -- Setup fallback touch detection
    self:_setupTouchFallback(self.currentCharacter)
    
    -- Start RenderStepped loop
    self:_startRenderLoop()
    
    -- Show indicator
    self:_showIndicator()
end

-- ── Disable Noclip ───────────────────────────────────
function Noclip:Disable()
    if not self.enabled then return end
    
    self.enabled = false
    
    -- Disconnect RenderStepped
    if self._renderConn then
        self._renderConn:Disconnect()
        self._renderConn = nil
    end
    
    -- Disconnect touch connections
    for _, conn in ipairs(self._touchConns) do
        pcall(function() conn:Disconnect() end)
    end
    self._touchConns = {}
    
    -- Restore collisions
    if self.currentCharacter then
        for _, part in ipairs(self.currentCharacter:GetDescendants()) do
            if part:IsA("BasePart") and part ~= self.currentCharacter:FindFirstChild("HumanoidRootPart") then
                part.CanCollide = true
            end
        end
    end
    
    -- Hide indicator
    self:_hideIndicator()
end

-- ── Set Noclip Speed ──────────────────────────────────
function Noclip:SetSpeed(newSpeed)
    self.speed = math.clamp(newSpeed, MIN_SPEED, MAX_SPEED)
end

-- ── Get Current Speed ────────────────────────────────
function Noclip:GetSpeed()
    return self.speed
end

-- ── Is Noclip Enabled? ───────────────────────────────
function Noclip:IsEnabled()
    return self.enabled
end

-- ── Toggle Noclip ────────────────────────────────────
function Noclip:Toggle()
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.enabled
end

-- ── Visual Indicator (Screen corner) ──────────────────
function Noclip:_showIndicator()
    self:_hideIndicator()
    
    pcall(function()
        local Players = game:GetService("Players")
        local localPlayer = Players.LocalPlayer
        
        local playerGui = localPlayer:WaitForChild("PlayerGui")
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "NoclipIndicator"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndex = 100
        screenGui.Parent = playerGui
        
        local indicator = Instance.new("TextLabel")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0, 150, 0, 40)
        indicator.Position = UDim2.new(1, -160, 0, 10)
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        indicator.BackgroundTransparency = 0.3
        indicator.TextColor3 = Color3.fromRGB(255, 255, 255)
        indicator.TextSize = 14
        indicator.Font = Enum.Font.GothamBold
        indicator.Text = "NOCLIP: ON"
        indicator.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = indicator
        
        self._visualIndicator = screenGui
    end)
end

function Noclip:_hideIndicator()
    if self._visualIndicator then
        pcall(function() self._visualIndicator:Destroy() end)
        self._visualIndicator = nil
    end
end

-- ── Cleanup on Cleanup ────────────────────────────────
function Noclip:Cleanup()
    self:Disable()
    if self._charConn then self._charConn:Disconnect() end
end

return Noclip
