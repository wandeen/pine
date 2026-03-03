-- ╔══════════════════════════════════════════════════╗
-- ║              PHANTOM HUB  v1.0                   ║
-- ║   Paste the raw GitHub URL of Phantom.lua below  ║
-- ╚══════════════════════════════════════════════════╝

-- Load Phantom UI Library
-- Replace the URL below with your raw GitHub link once uploaded
local Phantom = loadstring(game:HttpGet("https://raw.githubusercontent.com/wandeen/pine/refs/heads/main/Phantom.lua"))()

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
local Hub = Phantom.new({
    Title    = "Phantom",
    Subtitle = GameName ~= "Unknown" and GameName or "hub",
    Keybind  = Enum.KeyCode.RightShift,
})

-- ── Universal Tab (your friend fills this in) ─────────────────
local UniTab = Hub:NewTab({ Title = "Universal" })
local UniSec = UniTab:NewSection({ Title = "Universal Scripts" })

UniSec:NewLabel("Your friend adds scripts here")

-- ── Game-Specific Tabs ────────────────────────────────────────
if GameName ~= "Unknown" then
    local GameTab = Hub:NewTab({ Title = GameName })

    -- ── BLOX FRUITS ──────────────────────────────────────────
    if GameName == "BloxFruits" then
        local Combat = GameTab:NewSection({ Title = "Combat" })
        local Farm   = GameTab:NewSection({ Title = "Farm"   })
        local Player = GameTab:NewSection({ Title = "Player" })

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
                Hub:Notify({
                    Title   = "Auto Farm",
                    Message = v and "Enabled" or "Disabled",
                    Duration = 3,
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
        local Combat = GameTab:NewSection({ Title = "Combat" })
        local Player = GameTab:NewSection({ Title = "Player" })
        local Visual = GameTab:NewSection({ Title = "Visuals" })

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
    --     local Sec = GameTab:NewSection({ Title = "Features" })
    --     Sec:NewToggle({ Title = "Feature", Callback = function(v) end })

    end
else
    -- Unknown game — show PlaceId so you can add it
    local UnkTab = Hub:NewTab({ Title = "Unknown Game" })
    local UnkSec = UnkTab:NewSection({ Title = "Info" })
    UnkSec:NewLabel("No scripts for this game yet.")
    UnkSec:NewLabel("PlaceId: " .. tostring(PlaceId))
end

-- ── Startup notification ──────────────────────────────────────
Hub:Notify({
    Title    = "Phantom Hub Loaded",
    Message  = "Game: " .. GameName .. " | RightShift to toggle",
    Duration = 5,
})
