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

-- ── Create Window ─────────────────────────────────────────────
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = GameName ~= "Unknown" and GameName or "hub",
    Keybind  = Enum.KeyCode.J,
})

Hub:SetProfile()

-- ── Settings Tab (always first so it sits at the top of the sidebar) ──
local SetTab    = Hub:NewTab({ Title = "Settings", Icon = "rbxassetid://3926307641" })
local AppearSec = SetTab:NewSection({ Position = "Left",  Title = "Appearance" })
local DataSec   = SetTab:NewSection({ Position = "Right", Title = "Config"     })
local KbSec     = SetTab:NewSection({ Position = "Right", Title = "Keybind"    })

-- Accent colour
AppearSec:NewColorPicker({
    Title    = "Accent Color",
    Default  = Color3.fromRGB(110, 75, 255),
    Callback = function(c) Hub:SetAccent(c) end,
})

-- Window opacity
AppearSec:NewSlider({
    Title    = "Window Opacity %",
    Min      = 30,
    Max      = 100,
    Default  = 85,
    Callback = function(v)
        Hub._win.BackgroundTransparency = 1 - (v / 100)
    end,
})

-- Config
DataSec:NewButton({
    Title    = "Save Config",
    Callback = function()
        Hub:SaveConfig("phantom")
        Hub:Notify({ Title = "Config", Message = "Saved", Duration = 2 })
    end,
})
DataSec:NewButton({
    Title    = "Load Config",
    Callback = function()
        Hub:LoadConfig("phantom")
        Hub:Notify({ Title = "Config", Message = "Loaded", Duration = 2 })
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
    Title    = "Auto Save (seconds)",
    Min      = 15,
    Max      = 300,
    Default  = 60,
    Callback = function(v)
        Hub._autoSaveInterval = v
        Hub:AutoSave("phantom", v)
    end,
})

-- Keybind
KbSec:NewKeybind({
    Title    = "Toggle Keybind",
    Default  = Enum.KeyCode.J,
    Callback = function(key) Hub.Keybind = key end,
})

Hub:AutoSave("phantom", 60)  -- start default auto-save

-- Hide Settings tab from the sidebar (still reachable via the ⚙ topbar button)
SetTab._btn.Visible = false

-- ── Universal Tab ─────────────────────────────────────────────
local UniTab     = Hub:NewTab({ Title = "Universal", Icon = "rbxassetid://3926305904" })
local UniPlayer  = UniTab:NewSection({ Position = "Left",  Title = "Player"  })
local UniMove    = UniTab:NewSection({ Position = "Left",  Title = "Movement" })
local UniUtil    = UniTab:NewSection({ Position = "Right", Title = "Utility"  })
local UniVisual  = UniTab:NewSection({ Position = "Right", Title = "Visual"   })

-- ── Player: Walk Speed ────────────────────────────────────────
local function applySpeed(v)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = v
    end
end
UniPlayer:NewSlider({
    Title    = "Walk Speed",
    Min      = 16,
    Max      = 500,
    Default  = 16,
    Callback = applySpeed,
})

-- ── Player: Jump Power ────────────────────────────────────────
local function applyJump(v)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = v
    end
end
UniPlayer:NewSlider({
    Title    = "Jump Power",
    Min      = 7,
    Max      = 300,
    Default  = 7,
    Callback = applyJump,
})

-- ── Movement: Infinite Jump ───────────────────────────────────
local _infJumpConn
UniMove:NewToggle({
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v)
        if _infJumpConn then _infJumpConn:Disconnect(); _infJumpConn = nil end
        if v then
            _infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                local char = game.Players.LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    end,
})

-- ── Movement: No Clip ─────────────────────────────────────────
local _noclipConn
UniMove:NewToggle({
    Title    = "No Clip",
    Default  = false,
    Callback = function(v)
        if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
        if v then
            _noclipConn = game:GetService("RunService").Stepped:Connect(function()
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    end,
})

-- ── Utility: Anti-AFK ────────────────────────────────────────
local _afkConn
UniUtil:NewToggle({
    Title    = "Anti-AFK",
    Default  = false,
    Callback = function(v)
        if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
        if v then
            local VU = game:GetService("VirtualUser")
            _afkConn = game.Players.LocalPlayer.Idled:Connect(function()
                VU:Button2Down(Vector2.new(0, 0), CFrame.new())
                task.wait()
                VU:Button2Up(Vector2.new(0, 0), CFrame.new())
            end)
        end
    end,
})

-- ── Visual: Fullbright ────────────────────────────────────────
local _origBrightness, _origAmbient, _origOutdoor
UniVisual:NewToggle({
    Title    = "Fullbright",
    Default  = false,
    Callback = function(v)
        local L = game:GetService("Lighting")
        if v then
            _origBrightness = L.Brightness
            _origAmbient    = L.Ambient
            _origOutdoor    = L.OutdoorAmbient
            L.Brightness     = 2
            L.Ambient        = Color3.fromRGB(178, 178, 178)
            L.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        else
            L.Brightness     = _origBrightness or 1
            L.Ambient        = _origAmbient    or Color3.fromRGB(127, 127, 127)
            L.OutdoorAmbient = _origOutdoor    or Color3.fromRGB(127, 127, 127)
        end
    end,
})

-- ── Game-Specific Tabs ────────────────────────────────────────
if GameName ~= "Unknown" then
    local gameIcon = GameName == "BloxFruits" and "rbxassetid://3926307959" or "rbxassetid://3926307433"
    local GameTab = Hub:NewTab({ Title = GameName, Icon = gameIcon })

    -- ── BLOX FRUITS ──────────────────────────────────────────
    if GameName == "BloxFruits" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat" })
        local Farm   = GameTab:NewSection({ Position = "Left",  Title = "Farm"   })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player" })

        local killAura = false
        Combat:NewToggle({
            Title    = "Kill Aura",
            Default  = false,
            Callback = function(v)
                killAura = v
            end,
        })

        local autoFarm = false
        Farm:NewToggle({
            Title    = "Auto Farm",
            Default  = false,
            Callback = function(v)
                autoFarm = v
                Hub:Notify({
                    Title    = "Auto Farm",
                    Message  = v and "Enabled" or "Disabled",
                    Duration = 3,
                })
            end,
        })

        Farm:NewToggle({
            Title    = "Fruit Notifier",
            Default  = false,
            Callback = function(v)
                -- add fruit notifier logic here
            end,
        })

        Player:NewSlider({
            Title    = "Walk Speed",
            Min      = 16,
            Max      = 500,
            Default  = 16,
            Callback = function(v)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = v
                end
            end,
        })

        Player:NewSlider({
            Title    = "Jump Power",
            Min      = 7,
            Max      = 300,
            Default  = 7,
            Callback = function(v)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.JumpPower = v
                end
            end,
        })

    -- ── DA HOOD ──────────────────────────────────────────────
    elseif GameName == "DaHood" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat"  })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player"  })
        local Visual = GameTab:NewSection({ Position = "Right", Title = "Visuals" })

        Combat:NewToggle({
            Title    = "Aimbot",
            Default  = false,
            Callback = function(v)
                -- add aimbot logic here
            end,
        })

        Combat:NewToggle({
            Title    = "Silent Aim",
            Default  = false,
            Callback = function(v)
                -- add silent aim logic here
            end,
        })

        Combat:NewSlider({
            Title    = "Aimbot FOV",
            Min      = 10,
            Max      = 500,
            Default  = 150,
            Callback = function(v)
                -- set aimbot FOV here
            end,
        })

        Player:NewSlider({
            Title    = "Walk Speed",
            Min      = 16,
            Max      = 500,
            Default  = 16,
            Callback = function(v)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = v
                end
            end,
        })

        Player:NewSlider({
            Title    = "Jump Power",
            Min      = 7,
            Max      = 300,
            Default  = 7,
            Callback = function(v)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.JumpPower = v
                end
            end,
        })

        Visual:NewToggle({
            Title    = "Player ESP",
            Default  = false,
            Callback = function(v)
                -- add ESP logic here
            end,
        })
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
