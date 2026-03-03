-- ╔══════════════════════════════════════════════════╗
-- ║              PHANTOM HUB  v2.0                   ║
-- ║         Powered by NOTHING UI Library            ║
-- ╚══════════════════════════════════════════════════╝

-- Load NOTHING UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NOTHING/main/source.lua"))()
local Notifier = Library.Notification()

-- ── Game Detection ────────────────────────────────────────────
-- Add games here: [PlaceId] = "Name"
local Games = {
    [2753915549] = "BloxFruits",
    [292439477]  = "DaHood",
    -- [PLACEID]  = "GameName",  <-- add more here
}

local PlaceId  = game.PlaceId
local GameName = Games[PlaceId] or "Unknown"

-- ── Create Window ─────────────────────────────────────────────
local Window = Library.new({
    Title       = "Phantom Hub",
    Description = GameName ~= "Unknown" and GameName or "Universal Hub",
    Keybind     = Enum.KeyCode.RightShift,
    Size        = UDim2.new(0.1, 445, 0.1, 315),
})

-- ── Universal Tab ─────────────────────────────────────────────
local UniTab = Window:NewTab({ Title = "Universal" })
local UniSec = UniTab:NewSection({ Position = "Left", Title = "Universal Scripts" })

UniSec:NewButton({
    Title    = "Your friend adds scripts here",
    Callback = function() end,
})

-- ── Game-Specific Tabs ────────────────────────────────────────
if GameName ~= "Unknown" then
    local GameTab = Window:NewTab({ Title = GameName })

    -- ── BLOX FRUITS ──────────────────────────────────────────
    if GameName == "BloxFruits" then
        local Combat = GameTab:NewSection({ Position = "Left",  Title = "Combat" })
        local Farm   = GameTab:NewSection({ Position = "Left",  Title = "Farm"   })
        local Player = GameTab:NewSection({ Position = "Right", Title = "Player" })

        -- Kill Aura
        local killAura = false
        Combat:NewToggle({
            Title    = "Kill Aura",
            Default  = false,
            Callback = function(v)
                killAura = v
                -- add kill aura logic here
            end,
        })

        -- Auto Farm
        local autoFarm = false
        Farm:NewToggle({
            Title    = "Auto Farm",
            Default  = false,
            Callback = function(v)
                autoFarm = v
                Notifier.new({
                    Title       = "Auto Farm",
                    Description = v and "Enabled" or "Disabled",
                    Duration    = 3,
                })
            end,
        })

        -- Fruit Notifier
        Farm:NewToggle({
            Title    = "Fruit Notifier",
            Default  = false,
            Callback = function(v)
                -- add fruit notifier logic here
            end,
        })

        -- Walk Speed
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

        -- Jump Power
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

        -- Aimbot
        Combat:NewToggle({
            Title    = "Aimbot",
            Default  = false,
            Callback = function(v)
                -- add aimbot logic here
            end,
        })

        -- Silent Aim
        Combat:NewToggle({
            Title    = "Silent Aim",
            Default  = false,
            Callback = function(v)
                -- add silent aim logic here
            end,
        })

        -- FOV slider (for aimbot)
        Combat:NewSlider({
            Title    = "Aimbot FOV",
            Min      = 10,
            Max      = 500,
            Default  = 150,
            Callback = function(v)
                -- set aimbot FOV here
            end,
        })

        -- Walk Speed
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

        -- Jump Power
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

        -- ESP toggle
        Visual:NewToggle({
            Title    = "Player ESP",
            Default  = false,
            Callback = function(v)
                -- add ESP logic here
            end,
        })

    -- ── ADD MORE GAMES BELOW ─────────────────────────────────
    -- elseif GameName == "YourGame" then
    --     local Sec = GameTab:NewSection({ Position = "Left", Title = "Features" })
    --     Sec:NewToggle({ Title = "Feature", Callback = function(v) end })

    end
else
    -- Unknown game — show PlaceId so you can add it
    local UnkTab = Window:NewTab({ Title = "Unknown Game" })
    local UnkSec = UnkTab:NewSection({ Position = "Left", Title = "Info" })
    UnkSec:NewButton({ Title = "No scripts for this game yet.", Callback = function() end })
    UnkSec:NewButton({ Title = "PlaceId: " .. tostring(PlaceId),  Callback = function() end })
end

-- ── Startup notification ──────────────────────────────────────
Notifier.new({
    Title       = "Phantom Hub Loaded",
    Description = "Game: " .. GameName .. " | RightShift to toggle",
    Duration    = 5,
})
