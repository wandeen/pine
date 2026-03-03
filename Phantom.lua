-- ╔══════════════════════════════════════════════════╗
-- ║          PHANTOM UI LIBRARY v1.0                 ║
-- ║   Glassmorphism · Purple Accent · Smooth Anims   ║
-- ╚══════════════════════════════════════════════════╝

local Phantom = {}
Phantom.__index = Phantom

-- ── Services ────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ── Theme ────────────────────────────────────────────
local T = {
    -- Backgrounds
    BG          = Color3.fromRGB(10, 10, 18),
    BGPanel     = Color3.fromRGB(18, 16, 32),
    BGElement   = Color3.fromRGB(26, 22, 44),

    -- Accent (Purple)
    Accent      = Color3.fromRGB(138, 43, 226),
    AccentLight = Color3.fromRGB(170, 90, 255),
    AccentDark  = Color3.fromRGB(90, 20, 160),

    -- Text
    TextPri     = Color3.fromRGB(242, 240, 255),
    TextSec     = Color3.fromRGB(160, 150, 190),
    TextDim     = Color3.fromRGB(90, 80, 120),

    -- Borders
    Border      = Color3.fromRGB(138, 43, 226),
    BorderSub   = Color3.fromRGB(55, 40, 85),

    -- States
    On          = Color3.fromRGB(138, 43, 226),
    Off         = Color3.fromRGB(45, 38, 65),

    -- Transparency values
    BGTrans     = 0.15,
    PanelTrans  = 0.30,
    ElemTrans   = 0.45,
    BorderTrans = 0.35,
}

-- ── Utility ──────────────────────────────────────────
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function New(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in pairs(children or {}) do c.Parent = inst end
    return inst
end

local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function Stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color        = col   or T.Border
    s.Thickness    = thick or 1
    s.Transparency = trans or T.BorderTrans
    s.Parent = p
    return s
end

local function Pad(p, top, bot, left, right)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, top   or 6)
    u.PaddingBottom = UDim.new(0, bot   or 6)
    u.PaddingLeft   = UDim.new(0, left  or 8)
    u.PaddingRight  = UDim.new(0, right or 8)
    u.Parent = p
end

local function ListLayout(p, dir, pad)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding       = UDim.new(0, pad or 5)
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Parent        = p
    return l
end

local function Draggable(frame, handle)
    local dragging, dInput, mPos, fPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mPos = i.Position
            fPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - mPos
            frame.Position = UDim2.new(
                fPos.X.Scale, fPos.X.Offset + d.X,
                fPos.Y.Scale, fPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ════════════════════════════════════════════════════
-- WINDOW
-- ════════════════════════════════════════════════════
function Phantom.new(cfg)
    cfg = cfg or {}
    local self      = setmetatable({}, Phantom)
    self.Title      = cfg.Title    or "Phantom"
    self.Subtitle   = cfg.Subtitle or "hub"
    self.Keybind    = cfg.Keybind  or Enum.KeyCode.RightShift
    self.Tabs       = {}
    self.ActiveTab  = nil
    self.Visible    = true

    -- Blur (glassmorphism feel)
    local blur = Instance.new("BlurEffect")
    blur.Size   = 10
    blur.Parent = game.Lighting
    self._blur  = blur

    -- ScreenGui
    local gui = New("ScreenGui", {
        Name            = "PhantomHub",
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset  = true,
    })
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ── Main Window ─────────────────────────────────
    local win = New("Frame", {
        Name                 = "Window",
        Size                 = UDim2.new(0, 540, 0, 380),
        Position             = UDim2.new(0.5, -270, 0.5, -190),
        BackgroundColor3     = T.BG,
        BackgroundTransparency = T.BGTrans,
        BorderSizePixel      = 0,
        ClipsDescendants     = true,
        Parent               = gui,
    })
    Corner(win, 14)
    Stroke(win, T.Border, 1.5, 0.2)

    -- Gradient
    New("UIGradient", {
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(28, 12, 55)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 10, 25)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  8,  18)),
        }),
        Rotation = 140,
        Parent   = win,
    })

    -- Subtle glow border
    local glow = New("ImageLabel", {
        Size                 = UDim2.new(1, 60, 1, 60),
        Position             = UDim2.new(0, -30, 0, -30),
        BackgroundTransparency = 1,
        Image                = "rbxassetid://5028857084",
        ImageColor3          = T.Accent,
        ImageTransparency    = 0.72,
        ScaleType            = Enum.ScaleType.Slice,
        SliceCenter          = Rect.new(24, 24, 276, 276),
        ZIndex               = 0,
        Parent               = win,
    })

    -- ── Title Bar ───────────────────────────────────
    local titleBar = New("Frame", {
        Name                   = "TitleBar",
        Size                   = UDim2.new(1, 0, 0, 48),
        BackgroundColor3       = T.BGPanel,
        BackgroundTransparency = T.PanelTrans,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        Parent                 = win,
    })
    Corner(titleBar, 14)

    -- Fix bottom corners of titlebar
    New("Frame", {
        Size                   = UDim2.new(1, 0, 0.5, 0),
        Position               = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3       = T.BGPanel,
        BackgroundTransparency = T.PanelTrans,
        BorderSizePixel        = 0,
        ZIndex                 = 2,
        Parent                 = titleBar,
    })

    -- Purple accent line
    local accentBar = New("Frame", {
        Size             = UDim2.new(0, 3, 0, 26),
        Position         = UDim2.new(0, 14, 0.5, -13),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = titleBar,
    })
    Corner(accentBar, 2)

    -- Title
    New("TextLabel", {
        Size                 = UDim2.new(0, 200, 1, 0),
        Position             = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text                 = self.Title,
        TextColor3           = T.TextPri,
        TextSize             = 16,
        Font                 = Enum.Font.GothamBold,
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 4,
        Parent               = titleBar,
    })

    -- Subtitle
    New("TextLabel", {
        Size                 = UDim2.new(0, 200, 1, 0),
        Position             = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        Text                 = "  ·  " .. self.Subtitle,
        TextColor3           = T.AccentLight,
        TextSize             = 12,
        Font                 = Enum.Font.Gotham,
        TextXAlignment       = Enum.TextXAlignment.Left,
        ZIndex               = 4,
        -- offset so it appears after title (approximate)
        -- We nudge it right using padding on a frame trick below
        Parent               = titleBar,
    }).Position = UDim2.new(0, 110, 0, 0)

    -- Close button
    local closeBtn = New("TextButton", {
        Size             = UDim2.new(0, 20, 0, 20),
        Position         = UDim2.new(1, -30, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(210, 50, 80),
        Text             = "",
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = titleBar,
    })
    Corner(closeBtn, 10)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(win, {Size = UDim2.new(0, 540, 0, 0), BackgroundTransparency = 1}, 0.35)
        task.delay(0.36, function()
            gui:Destroy()
            blur:Destroy()
        end)
    end)
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(255, 70, 100)}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(210, 50, 80)},  0.15) end)

    Draggable(win, titleBar)

    -- ── Tab Bar ──────────────────────────────────────
    local tabBar = New("Frame", {
        Name                   = "TabBar",
        Size                   = UDim2.new(1, -16, 0, 34),
        Position               = UDim2.new(0, 8, 0, 54),
        BackgroundColor3       = T.BGPanel,
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        Parent                 = win,
    })
    Corner(tabBar, 8)
    Stroke(tabBar, T.BorderSub, 1, 0.5)
    Pad(tabBar, 4, 4, 6, 6)
    ListLayout(tabBar, Enum.FillDirection.Horizontal, 4)

    -- ── Content ──────────────────────────────────────
    local content = New("Frame", {
        Name                   = "Content",
        Size                   = UDim2.new(1, -16, 1, -100),
        Position               = UDim2.new(0, 8, 0, 96),
        BackgroundTransparency = 1,
        ZIndex                 = 2,
        Parent                 = win,
    })

    self._gui     = gui
    self._win     = win
    self._tabBar  = tabBar
    self._content = content

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == self.Keybind then
            self.Visible = not self.Visible
            win.Visible  = self.Visible
            blur.Size    = self.Visible and 10 or 0
        end
    end)

    -- Open animation
    win.Size                   = UDim2.new(0, 540, 0, 0)
    win.BackgroundTransparency = 1
    Tween(win, { Size = UDim2.new(0, 540, 0, 380), BackgroundTransparency = T.BGTrans }, 0.5)

    return self
end

-- ════════════════════════════════════════════════════
-- TAB
-- ════════════════════════════════════════════════════
function Phantom:NewTab(cfg)
    cfg = cfg or {}
    local name = cfg.Title or "Tab"

    -- Tab button
    local btn = New("TextButton", {
        Name                   = name,
        Size                   = UDim2.new(0, 0, 1, 0),
        AutomaticSize          = Enum.AutomaticSize.X,
        BackgroundColor3       = T.BGElement,
        BackgroundTransparency = 0.55,
        Text                   = "",
        BorderSizePixel        = 0,
        ZIndex                 = 4,
        Parent                 = self._tabBar,
    })
    Corner(btn, 6)
    Pad(btn, 4, 4, 12, 12)

    local btnText = New("TextLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = name,
        TextColor3             = T.TextSec,
        TextSize               = 13,
        Font                   = Enum.Font.GothamSemibold,
        ZIndex                 = 5,
        Parent                 = btn,
    })

    -- Bottom indicator
    local indicator = New("Frame", {
        Name             = "Indicator",
        Size             = UDim2.new(0.7, 0, 0, 2),
        Position         = UDim2.new(0.15, 0, 1, -3),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = btn,
    })
    Corner(indicator, 1)

    -- Tab scroll frame
    local tabFrame = New("ScrollingFrame", {
        Name                   = name .. "_Frame",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = T.Accent,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Visible                = false,
        ZIndex                 = 2,
        Parent                 = self._content,
    })
    ListLayout(tabFrame, Enum.FillDirection.Vertical, 8)
    Pad(tabFrame, 4, 4, 0, 4)

    local tab = {
        _btn       = btn,
        _text      = btnText,
        _indicator = indicator,
        _frame     = tabFrame,
        _hub       = self,
    }

    btn.MouseButton1Click:Connect(function() self:_Select(tab) end)
    btn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btnText, {TextColor3 = T.TextPri}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(btnText, {TextColor3 = T.TextSec}, 0.15)
        end
    end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then self:_Select(tab) end

    function tab:NewSection(c) return Phantom._Section(tabFrame, c) end

    return tab
end

function Phantom:_Select(tab)
    for _, t in pairs(self.Tabs) do
        t._frame.Visible = false
        Tween(t._btn,       {BackgroundTransparency = 0.55}, 0.2)
        Tween(t._text,      {TextColor3 = T.TextSec},         0.2)
        Tween(t._indicator, {BackgroundTransparency = 1},      0.2)
    end
    tab._frame.Visible = true
    Tween(tab._btn,       {BackgroundTransparency = 0.15}, 0.2)
    Tween(tab._text,      {TextColor3 = T.Accent},          0.2)
    Tween(tab._indicator, {BackgroundTransparency = 0},      0.2)
    self.ActiveTab = tab
end

-- ════════════════════════════════════════════════════
-- SECTION
-- ════════════════════════════════════════════════════
function Phantom._Section(parent, cfg)
    cfg = cfg or {}
    local title = cfg.Title or "Section"

    local sec = New("Frame", {
        Name                   = title,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = T.BGPanel,
        BackgroundTransparency = T.PanelTrans,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        Parent                 = parent,
    })
    Corner(sec, 10)
    Stroke(sec, T.BorderSub, 1, 0.5)
    Pad(sec, 8, 10, 10, 10)

    -- Section header
    local hdr = New("Frame", {
        Name                   = "Header",
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        ZIndex                 = 4,
        LayoutOrder            = -2,
        Parent                 = sec,
    })

    New("TextLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = title:upper(),
        TextColor3             = T.Accent,
        TextSize               = 10,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 4,
        Parent                 = hdr,
    })

    -- Divider
    New("Frame", {
        Name                   = "Divider",
        Size                   = UDim2.new(1, 0, 0, 1),
        BackgroundColor3       = T.Border,
        BackgroundTransparency = 0.65,
        BorderSizePixel        = 0,
        LayoutOrder            = -1,
        ZIndex                 = 4,
        Parent                 = sec,
    })

    ListLayout(sec, Enum.FillDirection.Vertical, 5)

    local S = { _frame = sec }

    -- ── TOGGLE ──────────────────────────────────────
    function S:NewToggle(c)
        c = c or {}
        local state = c.Default or false

        local row = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 34),
            BackgroundColor3       = T.BGElement,
            BackgroundTransparency = T.ElemTrans,
            BorderSizePixel        = 0,
            ZIndex                 = 4,
            Parent                 = sec,
        })
        Corner(row, 7)

        New("TextLabel", {
            Size                   = UDim2.new(1, -56, 1, 0),
            Position               = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                   = c.Title or "Toggle",
            TextColor3             = T.TextPri,
            TextSize               = 13,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 5,
            Parent                 = row,
        })

        local track = New("Frame", {
            Size             = UDim2.new(0, 38, 0, 20),
            Position         = UDim2.new(1, -48, 0.5, -10),
            BackgroundColor3 = state and T.On or T.Off,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            Parent           = row,
        })
        Corner(track, 10)

        local knob = New("Frame", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(0, state and 21 or 3, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = track,
        })
        Corner(knob, 7)

        local hitbox = New("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 7,
            Parent                 = row,
        })

        local function update()
            Tween(track, {BackgroundColor3 = state and T.On or T.Off},                   0.2)
            Tween(knob,  {Position = UDim2.new(0, state and 21 or 3, 0.5, -7)},          0.2)
            if c.Callback then c.Callback(state) end
        end

        hitbox.MouseButton1Click:Connect(function()
            state = not state
            update()
        end)
        hitbox.MouseEnter:Connect(function() Tween(row, {BackgroundTransparency = 0.25}, 0.15) end)
        hitbox.MouseLeave:Connect(function() Tween(row, {BackgroundTransparency = T.ElemTrans}, 0.15) end)

        update()
        return {
            SetValue = function(_, v) state = v; update() end,
            GetValue = function(_) return state end,
        }
    end

    -- ── BUTTON ──────────────────────────────────────
    function S:NewButton(c)
        c = c or {}

        local btn = New("TextButton", {
            Size                   = UDim2.new(1, 0, 0, 34),
            BackgroundColor3       = T.AccentDark,
            BackgroundTransparency = 0.35,
            Text                   = "",
            BorderSizePixel        = 0,
            ZIndex                 = 4,
            Parent                 = sec,
        })
        Corner(btn, 7)
        Stroke(btn, T.Accent, 1, 0.4)

        New("UIGradient", {
            Color    = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 75, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(95,  25, 170)),
            }),
            Rotation = 90,
            Parent   = btn,
        })

        New("TextLabel", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = c.Title or "Button",
            TextColor3             = T.TextPri,
            TextSize               = 13,
            Font                   = Enum.Font.GothamSemibold,
            ZIndex                 = 5,
            Parent                 = btn,
        })

        btn.MouseButton1Click:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.05}, 0.08)
            task.delay(0.12, function() Tween(btn, {BackgroundTransparency = 0.35}, 0.2) end)
            if c.Callback then c.Callback() end
        end)
        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 0.35}, 0.15) end)
    end

    -- ── SLIDER ──────────────────────────────────────
    function S:NewSlider(c)
        c = c or {}
        local min   = c.Min     or 0
        local max   = c.Max     or 100
        local value = c.Default or min

        local row = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 52),
            BackgroundColor3       = T.BGElement,
            BackgroundTransparency = T.ElemTrans,
            BorderSizePixel        = 0,
            ZIndex                 = 4,
            Parent                 = sec,
        })
        Corner(row, 7)

        New("TextLabel", {
            Size                   = UDim2.new(0.65, 0, 0, 24),
            Position               = UDim2.new(0, 10, 0, 4),
            BackgroundTransparency = 1,
            Text                   = c.Title or "Slider",
            TextColor3             = T.TextPri,
            TextSize               = 13,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 5,
            Parent                 = row,
        })

        local valLbl = New("TextLabel", {
            Size                   = UDim2.new(0.35, -10, 0, 24),
            Position               = UDim2.new(0.65, 0, 0, 4),
            BackgroundTransparency = 1,
            Text                   = tostring(value),
            TextColor3             = T.AccentLight,
            TextSize               = 12,
            Font                   = Enum.Font.GothamBold,
            TextXAlignment         = Enum.TextXAlignment.Right,
            ZIndex                 = 5,
            Parent                 = row,
        })

        local track = New("Frame", {
            Size             = UDim2.new(1, -20, 0, 4),
            Position         = UDim2.new(0, 10, 0, 36),
            BackgroundColor3 = T.Off,
            BorderSizePixel  = 0,
            ZIndex           = 5,
            Parent           = row,
        })
        Corner(track, 2)

        local fill = New("Frame", {
            Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = track,
        })
        Corner(fill, 2)

        local knob = New("Frame", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel  = 0,
            ZIndex           = 7,
            Parent           = track,
        })
        Corner(knob, 7)
        Stroke(knob, T.Accent, 2, 0.25)

        local dragging = false

        local function update(x)
            local ratio  = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(min + (max - min) * ratio)
            value        = newVal
            valLbl.Text  = tostring(newVal)
            Tween(fill, {Size     = UDim2.new(ratio, 0, 1, 0)},        0.05)
            Tween(knob, {Position = UDim2.new(ratio, -7, 0.5, -7)},    0.05)
            if c.Callback then c.Callback(newVal) end
        end

        track.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; update(i.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                update(i.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        return {
            SetValue = function(_, v)
                value = math.clamp(v, min, max)
                local r = (value - min) / (max - min)
                valLbl.Text = tostring(value)
                Tween(fill, {Size     = UDim2.new(r, 0, 1, 0)},     0.15)
                Tween(knob, {Position = UDim2.new(r, -7, 0.5, -7)}, 0.15)
            end,
            GetValue = function(_) return value end,
        }
    end

    -- ── DROPDOWN ────────────────────────────────────
    function S:NewDropdown(c)
        c = c or {}
        local options  = c.Options  or {}
        local selected = c.Default  or (options[1] or "Select...")
        local open     = false

        local wrapper = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            ZIndex                 = 10,
            ClipsDescendants       = false,
            Parent                 = sec,
        })

        local header = New("TextButton", {
            Size                   = UDim2.new(1, 0, 0, 34),
            BackgroundColor3       = T.BGElement,
            BackgroundTransparency = T.ElemTrans,
            Text                   = "",
            BorderSizePixel        = 0,
            ZIndex                 = 10,
            Parent                 = wrapper,
        })
        Corner(header, 7)

        New("TextLabel", {
            Size                   = UDim2.new(0.55, 0, 1, 0),
            Position               = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                   = c.Title or "Dropdown",
            TextColor3             = T.TextPri,
            TextSize               = 13,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 11,
            Parent                 = header,
        })

        local selLbl = New("TextLabel", {
            Size                   = UDim2.new(0.4, 0, 1, 0),
            Position               = UDim2.new(0.55, 0, 0, 0),
            BackgroundTransparency = 1,
            Text                   = selected,
            TextColor3             = T.AccentLight,
            TextSize               = 12,
            Font                   = Enum.Font.GothamSemibold,
            TextXAlignment         = Enum.TextXAlignment.Right,
            ZIndex                 = 11,
            Parent                 = header,
        })

        local arrow = New("TextLabel", {
            Size                   = UDim2.new(0, 22, 1, 0),
            Position               = UDim2.new(1, -24, 0, 0),
            BackgroundTransparency = 1,
            Text                   = "▾",
            TextColor3             = T.Accent,
            TextSize               = 14,
            Font                   = Enum.Font.GothamBold,
            ZIndex                 = 11,
            Parent                 = header,
        })

        local list = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            Position               = UDim2.new(0, 0, 1, 4),
            BackgroundColor3       = T.BGPanel,
            BackgroundTransparency = 0.05,
            BorderSizePixel        = 0,
            ZIndex                 = 20,
            ClipsDescendants       = true,
            Parent                 = wrapper,
        })
        Corner(list, 8)
        Stroke(list, T.Border, 1, 0.4)
        Pad(list, 4, 4, 4, 4)
        ListLayout(list, Enum.FillDirection.Vertical, 3)

        for _, opt in ipairs(options) do
            local ob = New("TextButton", {
                Size                   = UDim2.new(1, 0, 0, 28),
                BackgroundColor3       = T.BGElement,
                BackgroundTransparency = 0.6,
                Text                   = opt,
                TextColor3             = T.TextPri,
                TextSize               = 12,
                Font                   = Enum.Font.Gotham,
                BorderSizePixel        = 0,
                ZIndex                 = 21,
                Parent                 = list,
            })
            Corner(ob, 5)

            ob.MouseButton1Click:Connect(function()
                selected    = opt
                selLbl.Text = opt
                open        = false
                Tween(list,  {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                Tween(arrow, {Rotation = 0},                  0.2)
                if c.Callback then c.Callback(opt) end
            end)
            ob.MouseEnter:Connect(function() Tween(ob, {BackgroundTransparency = 0.1, TextColor3 = T.Accent}, 0.15) end)
            ob.MouseLeave:Connect(function() Tween(ob, {BackgroundTransparency = 0.6, TextColor3 = T.TextPri}, 0.15) end)
        end

        header.MouseButton1Click:Connect(function()
            open = not open
            local h = #options * 31 + 8
            Tween(list,  {Size = UDim2.new(1, 0, 0, open and h or 0)}, 0.25)
            Tween(arrow, {Rotation = open and 180 or 0},                0.2)
        end)

        return {
            SetSelected = function(_, v) selected = v; selLbl.Text = v end,
            GetSelected = function(_) return selected end,
        }
    end

    -- ── LABEL ────────────────────────────────────────
    function S:NewLabel(text)
        local lbl = New("TextLabel", {
            Size                   = UDim2.new(1, 0, 0, 22),
            BackgroundTransparency = 1,
            Text                   = text or "",
            TextColor3             = T.TextSec,
            TextSize               = 12,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            ZIndex                 = 4,
            Parent                 = sec,
        })
        return { SetText = function(_, t) lbl.Text = t end }
    end

    -- ── KEYBIND ─────────────────────────────────────
    function S:NewKeybind(c)
        c = c or {}
        local key     = c.Default or Enum.KeyCode.E
        local waiting = false

        local row = New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 34),
            BackgroundColor3       = T.BGElement,
            BackgroundTransparency = T.ElemTrans,
            BorderSizePixel        = 0,
            ZIndex                 = 4,
            Parent                 = sec,
        })
        Corner(row, 7)

        New("TextLabel", {
            Size                   = UDim2.new(1, -90, 1, 0),
            Position               = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text                   = c.Title or "Keybind",
            TextColor3             = T.TextPri,
            TextSize               = 13,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 5,
            Parent                 = row,
        })

        local keyBtn = New("TextButton", {
            Size                   = UDim2.new(0, 75, 0, 22),
            Position               = UDim2.new(1, -83, 0.5, -11),
            BackgroundColor3       = T.BGPanel,
            BackgroundTransparency = 0.3,
            Text                   = key.Name,
            TextColor3             = T.AccentLight,
            TextSize               = 11,
            Font                   = Enum.Font.GothamBold,
            BorderSizePixel        = 0,
            ZIndex                 = 5,
            Parent                 = row,
        })
        Corner(keyBtn, 5)
        Stroke(keyBtn, T.Accent, 1, 0.5)

        keyBtn.MouseButton1Click:Connect(function()
            waiting         = true
            keyBtn.Text     = "..."
            keyBtn.TextColor3 = T.TextSec
        end)

        UserInputService.InputBegan:Connect(function(i, gpe)
            if waiting and not gpe then
                waiting           = false
                key               = i.KeyCode
                keyBtn.Text       = key.Name
                keyBtn.TextColor3 = T.AccentLight
                if c.Callback then c.Callback(key) end
            end
        end)

        return { GetKey = function(_) return key end }
    end

    return S
end

-- ════════════════════════════════════════════════════
-- NOTIFICATION
-- ════════════════════════════════════════════════════
function Phantom:Notify(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "Phantom"
    local message  = cfg.Message  or ""
    local duration = cfg.Duration or 4

    -- Notification container
    local holder = self._gui:FindFirstChild("__NotifHolder")
    if not holder then
        holder = New("Frame", {
            Name                   = "__NotifHolder",
            Size                   = UDim2.new(0, 290, 1, -20),
            Position               = UDim2.new(1, -300, 0, 10),
            BackgroundTransparency = 1,
            ZIndex                 = 100,
            Parent                 = self._gui,
        })
        local nl = ListLayout(holder, Enum.FillDirection.Vertical, 8)
        nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
        Pad(holder, 8, 8, 0, 0)
    end

    local notif = New("Frame", {
        Name                   = "Notif",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = T.BGPanel,
        BackgroundTransparency = 0.08,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        ZIndex                 = 100,
        Parent                 = holder,
    })
    Corner(notif, 10)
    Stroke(notif, T.Accent, 1.5, 0.25)
    Pad(notif, 10, 10, 14, 12)

    -- Purple left bar
    local bar = New("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 101,
        Parent           = notif,
    })
    Corner(bar, 2)

    local nl2 = ListLayout(notif, Enum.FillDirection.Vertical, 3)

    New("TextLabel", {
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = T.AccentLight,
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 101,
        Parent                 = notif,
    })

    if message ~= "" then
        New("TextLabel", {
            Size                   = UDim2.new(1, 0, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text                   = message,
            TextColor3             = T.TextSec,
            TextSize               = 12,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            ZIndex                 = 101,
            Parent                 = notif,
        })
    end

    -- Progress bar
    local pbg = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Off,
        BorderSizePixel  = 0,
        ZIndex           = 101,
        Parent           = notif,
    })
    Corner(pbg, 1)

    local pfill = New("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 102,
        Parent           = pbg,
    })
    Corner(pfill, 1)

    -- Slide in
    notif.Position = UDim2.new(1, 20, 0, 0)
    Tween(notif, {Position = UDim2.new(0, 0, 0, 0)}, 0.4)

    -- Drain progress
    Tween(pfill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    -- Slide out
    task.delay(duration, function()
        Tween(notif, {Position = UDim2.new(1, 20, 0, 0)}, 0.35)
        task.delay(0.36, function() notif:Destroy() end)
    end)
end

return Phantom
