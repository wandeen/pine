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

-- ── Universal Tab ─────────────────────────────────────────────
local UniTab = Hub:NewTab({ Title = "Universal", Icon = "rbxassetid://3926305904" })
local UniSec = UniTab:NewSection({ Position = "Left", Title = "Universal Scripts" })

UniSec:NewLabel("Your friend adds scripts here")

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
    local UnkTab = Hub:NewTab({ Title = "Unknown Game" })
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
