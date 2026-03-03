-- Phantom UI Library v2
-- Dark glassmorphism | Purple accent | Smooth animations

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Phantom = {}
Phantom.__index = Phantom

-- ── Theme ────────────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(11, 11, 11),
    BG2         = Color3.fromRGB(18, 18, 18),
    BG3         = Color3.fromRGB(24, 24, 24),
    BG4         = Color3.fromRGB(32, 32, 32),
    Accent      = Color3.fromRGB(110, 75, 255),
    AccentDim   = Color3.fromRGB(70, 50, 170),
    AccentBright= Color3.fromRGB(140, 105, 255),
    Text        = Color3.fromRGB(238, 238, 238),
    TextDim     = Color3.fromRGB(180, 180, 180),
    Muted       = Color3.fromRGB(100, 100, 100),
    Off         = Color3.fromRGB(40, 40, 40),
    Danger      = Color3.fromRGB(255, 65, 65),
    BGTrans     = 0.10,
    Font        = Enum.Font.GothamBold,
    FontReg     = Enum.Font.Gotham,
}

-- Window dimensions
local W, H   = 580, 400
local TOPBAR = 40
local SIDE   = 116
local FOOTER = 26

-- ── Helpers ──────────────────────────────────────────────────
local function tw(obj, props, t, s, d)
    TS:Create(obj, TweenInfo.new(
        t or 0.2,
        s or Enum.EasingStyle.Quint,
        d or Enum.EasingDirection.Out
    ), props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, col, tr, thick)
    local s = Instance.new("UIStroke")
    s.Color        = col   or Color3.new(1, 1, 1)
    s.Transparency = tr    or 0.9
    s.Thickness    = thick or 1
    s.Parent       = p
    return s
end

local function listLayout(p, gap)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding   = UDim.new(0, gap or 4)
    l.Parent    = p
end

local function padding(p, top, right, bottom, left)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, top    or 0)
    u.PaddingRight  = UDim.new(0, right  or 0)
    u.PaddingBottom = UDim.new(0, bottom or 0)
    u.PaddingLeft   = UDim.new(0, left   or 0)
    u.Parent = p
end

-- Pill button used for close/minimize in the top bar
local function makePillBtn(parent, posX, symbol, hoverBg, hoverText)
    local pill = Instance.new("Frame")
    pill.Size                   = UDim2.new(0, 26, 0, 26)
    pill.Position               = UDim2.new(1, posX, 0.5, -13)
    pill.BackgroundColor3       = hoverBg
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel        = 0
    pill.ZIndex                 = 3
    pill.Parent                 = parent
    corner(pill, 6)

    local btn = Instance.new("TextButton")
    btn.Text                   = symbol
    btn.Font                   = T.Font
    btn.TextSize               = 12
    btn.TextColor3             = T.Muted
    btn.BackgroundTransparency = 1
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.AutoButtonColor        = false
    btn.ZIndex                 = 4
    btn.Parent                 = pill

    btn.MouseEnter:Connect(function()
        tw(pill, {BackgroundTransparency = 0.15}, 0.14)
        tw(btn,  {TextColor3 = hoverText},         0.14)
    end)
    btn.MouseLeave:Connect(function()
        tw(pill, {BackgroundTransparency = 1},   0.14)
        tw(btn,  {TextColor3 = T.Muted},          0.14)
    end)

    return btn
end

-- ── Window ───────────────────────────────────────────────────
function Phantom.new(opts)
    local self     = setmetatable({}, Phantom)
    self.Keybind   = opts.Keybind or Enum.KeyCode.J
    self.Visible   = true
    self._tabs     = {}
    self._active   = nil
    self._tabN     = 0

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name           = "PhantomHub"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder   = 100
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    gui.Parent = ok and cg or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- Blur
    local blur = Instance.new("BlurEffect")
    blur.Size   = 0
    blur.Parent = game:GetService("Lighting")

    -- Drop shadow
    local shadow = Instance.new("Frame")
    shadow.AnchorPoint            = Vector2.new(0.5, 0.5)
    shadow.Size                   = UDim2.new(0, W + 20, 0, H + 20)
    shadow.Position               = UDim2.new(0.5, 0, 0.5, 8)
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 1
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 0
    shadow.Parent                 = gui
    corner(shadow, 18)

    -- Main window
    local win = Instance.new("Frame")
    win.Name                   = "Win"
    win.AnchorPoint            = Vector2.new(0.5, 0.5)
    win.Size                   = UDim2.new(0, W, 0, H)
    win.Position               = UDim2.new(0.5, 0, 0.5, 0)
    win.BackgroundColor3       = T.BG
    win.BackgroundTransparency = T.BGTrans
    win.BorderSizePixel        = 0
    win.ZIndex                 = 1
    win.Parent                 = gui
    corner(win, 12)
    -- Accent-tinted border — intentionally purple, not the black artifact from a faint white stroke
    stroke(win, T.Accent, 0.80)

    -- UIScale — scales from center (AnchorPoint 0.5,0.5)
    local winScale  = Instance.new("UIScale")
    winScale.Scale  = 0.85
    winScale.Parent = win

    -- ── Top bar ──────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size                   = UDim2.new(1, 0, 0, TOPBAR)
    topBar.BackgroundColor3       = T.BG2
    topBar.BackgroundTransparency = 0
    topBar.BorderSizePixel        = 0
    topBar.ZIndex                 = 2
    topBar.Parent                 = win
    corner(topBar, 12)

    local topFix = Instance.new("Frame")
    topFix.Size                   = UDim2.new(1, 0, 0.5, 0)
    topFix.Position               = UDim2.new(0, 0, 0.5, 0)
    topFix.BackgroundColor3       = T.BG2
    topFix.BackgroundTransparency = 0
    topFix.BorderSizePixel        = 0
    topFix.ZIndex                 = 1
    topFix.Parent                 = topBar

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 14, 0.5, -3)
    dot.BackgroundColor3 = T.Accent
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 3
    dot.Parent           = topBar
    corner(dot, 4)

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text                   = opts.Title or "Phantom"
    titleLbl.Font                   = T.Font
    titleLbl.TextSize               = 15
    titleLbl.TextColor3             = T.Text
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                   = UDim2.new(0, 140, 1, 0)
    titleLbl.Position               = UDim2.new(0, 28, 0, 0)
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
    titleLbl.ZIndex                 = 3
    titleLbl.Parent                 = topBar

    -- Subtitle
    local subLbl = Instance.new("TextLabel")
    subLbl.Text                   = opts.Subtitle or ""
    subLbl.Font                   = T.FontReg
    subLbl.TextSize               = 12
    subLbl.TextColor3             = T.Muted
    subLbl.BackgroundTransparency = 1
    subLbl.Size                   = UDim2.new(0, 180, 1, 0)
    subLbl.Position               = UDim2.new(0, 165, 0, 0)
    subLbl.TextXAlignment         = Enum.TextXAlignment.Left
    subLbl.ZIndex                 = 3
    subLbl.Parent                 = topBar

    -- Pill buttons: minimize (−) and close (✕)
    local minBtn   = makePillBtn(topBar, -68, "−", T.Accent,  Color3.new(1,1,1))
    local closeBtn = makePillBtn(topBar, -36, "✕", T.Danger,  Color3.new(1,1,1))

    -- ── Sidebar ───────────────────────────────────────────────
    local sidebar = Instance.new("Frame")
    sidebar.Name                   = "Sidebar"
    sidebar.Size                   = UDim2.new(0, SIDE, 1, -(TOPBAR + FOOTER))
    sidebar.Position               = UDim2.new(0, 0, 0, TOPBAR)
    sidebar.BackgroundColor3       = T.BG2
    sidebar.BackgroundTransparency = 0
    sidebar.BorderSizePixel        = 0
    sidebar.ZIndex                 = 2
    sidebar.Parent                 = win
    corner(sidebar, 12)
    listLayout(sidebar, 5)
    padding(sidebar, 10, 7, 10, 7)

    local sideFix = Instance.new("Frame")
    sideFix.Size                   = UDim2.new(0, 14, 1, -(TOPBAR + FOOTER))
    sideFix.Position               = UDim2.new(0, SIDE - 14, 0, TOPBAR)
    sideFix.BackgroundColor3       = T.BG2
    sideFix.BackgroundTransparency = 0
    sideFix.BorderSizePixel        = 0
    sideFix.ZIndex                 = 1
    sideFix.Parent                 = win

    local sideDiv = Instance.new("Frame")
    sideDiv.Size                   = UDim2.new(0, 1, 1, -(TOPBAR + FOOTER))
    sideDiv.Position               = UDim2.new(0, SIDE, 0, TOPBAR)
    sideDiv.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    sideDiv.BackgroundTransparency = 0.92
    sideDiv.BorderSizePixel        = 0
    sideDiv.ZIndex                 = 3
    sideDiv.Parent                 = win

    -- ── Content area ─────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name                   = "Content"
    content.Size                   = UDim2.new(1, -(SIDE + 1), 1, -(TOPBAR + FOOTER))
    content.Position               = UDim2.new(0, SIDE + 1, 0, TOPBAR)
    content.BackgroundTransparency = 1
    content.BorderSizePixel        = 0
    content.ClipsDescendants       = true
    content.ZIndex                 = 2
    content.Parent                 = win

    -- ── Footer ───────────────────────────────────────────────
    local footer = Instance.new("Frame")
    footer.Size                   = UDim2.new(1, 0, 0, FOOTER)
    footer.Position               = UDim2.new(0, 0, 1, -FOOTER)
    footer.BackgroundColor3       = T.BG2
    footer.BackgroundTransparency = 0
    footer.BorderSizePixel        = 0
    footer.ZIndex                 = 2
    footer.Parent                 = win
    corner(footer, 12)

    local footFix = Instance.new("Frame")
    footFix.Size                   = UDim2.new(1, 0, 0.5, 0)
    footFix.Position               = UDim2.new(0, 0, 0, 0)
    footFix.BackgroundColor3       = T.BG2
    footFix.BackgroundTransparency = 0
    footFix.BorderSizePixel        = 0
    footFix.ZIndex                 = 1
    footFix.Parent                 = footer

    local keybindName = tostring(self.Keybind):gsub("Enum.KeyCode.", "")
    local footerLbl = Instance.new("TextLabel")
    footerLbl.Text                   = "[" .. keybindName .. "] to toggle  ·  Phantom v2"
    footerLbl.Font                   = T.FontReg
    footerLbl.TextSize               = 11
    footerLbl.TextColor3             = T.Muted
    footerLbl.BackgroundTransparency = 1
    footerLbl.Size                   = UDim2.new(1, -12, 1, 0)
    footerLbl.Position               = UDim2.new(0, 12, 0, 0)
    footerLbl.TextXAlignment         = Enum.TextXAlignment.Left
    footerLbl.ZIndex                 = 3
    footerLbl.Parent                 = footer

    -- ── Drag ─────────────────────────────────────────────────
    local dragging, dStart, wStart
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dStart   = i.Position
            wStart   = win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            win.Position    = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X, wStart.Y.Scale, wStart.Y.Offset + d.Y)
            shadow.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X, wStart.Y.Scale, wStart.Y.Offset + d.Y + 8)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ── Animations ───────────────────────────────────────────
    local function showAnim()
        win.Visible    = true
        shadow.Visible = true
        shadow.BackgroundTransparency = 1
        winScale.Scale = 0
        blur.Size      = 10
        tw(shadow,   {BackgroundTransparency = 0.65}, 0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tw(winScale, {Scale = 1},                     0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
    end

    local function hideAnim(onDone)
        blur.Size = 0
        tw(shadow,   {BackgroundTransparency = 1}, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tw(winScale, {Scale = 0},                  0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.30, function()
            win.Visible    = false
            shadow.Visible = false
            if onDone then onDone() end
        end)
    end

    minBtn.MouseButton1Click:Connect(function()
        self.Visible = false
        hideAnim()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        hideAnim(function()
            blur:Destroy()
            gui:Destroy()
        end)
    end)

    UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == self.Keybind then
            self.Visible = not self.Visible
            if self.Visible then showAnim() else hideAnim() end
        end
    end)

    -- Animate in on load
    showAnim()

    self._gui      = gui
    self._win      = win
    self._shadow   = shadow
    self._winScale = winScale
    self._blur     = blur
    self._sidebar  = sidebar
    self._content  = content

    return self
end

-- ── Tab ──────────────────────────────────────────────────────
function Phantom:NewTab(opts)
    self._tabN = self._tabN + 1

    local btn = Instance.new("TextButton")
    btn.Text                   = ""
    btn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Size                   = UDim2.new(1, 0, 0, 30)
    btn.LayoutOrder            = self._tabN
    btn.AutoButtonColor        = false
    btn.Parent                 = self._sidebar
    corner(btn, 6)
    local btnSt = stroke(btn, T.Accent, 1)

    -- Optional icon
    local btnIco = nil
    local txtX   = 8
    if opts.Icon then
        btnIco = Instance.new("ImageLabel")
        btnIco.Image                  = opts.Icon
        btnIco.Size                   = UDim2.new(0, 14, 0, 14)
        btnIco.Position               = UDim2.new(0, 8, 0.5, -7)
        btnIco.BackgroundTransparency = 1
        btnIco.ImageColor3            = T.Muted
        btnIco.ZIndex                 = 3
        btnIco.Parent                 = btn
        txtX = 26
    end

    local btnLbl = Instance.new("TextLabel")
    btnLbl.Text                   = opts.Title or "Tab"
    btnLbl.Font                   = T.FontReg
    btnLbl.TextSize               = 13
    btnLbl.TextColor3             = T.Muted
    btnLbl.BackgroundTransparency = 1
    btnLbl.Size                   = UDim2.new(1, -(txtX + 4), 1, 0)
    btnLbl.Position               = UDim2.new(0, txtX, 0, 0)
    btnLbl.TextXAlignment         = Enum.TextXAlignment.Left
    btnLbl.ZIndex                 = 3
    btnLbl.Parent                 = btn

    -- Tab frame
    local tabFrame = Instance.new("Frame")
    tabFrame.Size                   = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.BorderSizePixel        = 0
    tabFrame.Visible                = false
    tabFrame.Parent                 = self._content

    local function makeScrollCol(pos, size)
        local sf = Instance.new("ScrollingFrame")
        sf.Size                   = size
        sf.Position               = pos
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel        = 0
        sf.ScrollBarThickness     = 2
        sf.ScrollBarImageColor3   = T.Accent
        sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        sf.Parent                 = tabFrame
        listLayout(sf, 6)
        padding(sf, 7, 5, 7, 5)
        return sf
    end

    local leftCol  = makeScrollCol(UDim2.new(0, 0, 0, 0),  UDim2.new(0.5, -1, 1, 0))
    local rightCol = makeScrollCol(UDim2.new(0.5, 1, 0, 0), UDim2.new(0.5, -1, 1, 0))

    local tabData = {_frame = tabFrame, _btn = btn, _btnSt = btnSt, _btnLbl = btnLbl, _btnIco = btnIco}

    local function activate()
        if self._active then
            self._active._frame.Visible = false
            tw(self._active._btn,    {BackgroundTransparency = 1},  0.15)
            tw(self._active._btnSt,  {Transparency = 1},            0.15)
            tw(self._active._btnLbl, {TextColor3 = T.Muted},        0.15)
            if self._active._btnIco then
                tw(self._active._btnIco, {ImageColor3 = T.Muted}, 0.15)
            end
        end
        self._active     = tabData
        tabFrame.Visible = true
        tw(btn,    {BackgroundTransparency = 0.86}, 0.18)
        tw(btnSt,  {Transparency = 0.7},            0.18)
        tw(btnLbl, {TextColor3 = T.Text},           0.18)
        if btnIco then tw(btnIco, {ImageColor3 = T.Text}, 0.18) end
    end

    btn.MouseButton1Click:Connect(activate)
    if #self._tabs == 0 then task.defer(activate) end
    table.insert(self._tabs, tabData)

    -- ── Tab object ───────────────────────────────────────────
    local Tab = {}

    function Tab:NewSection(sopts)
        local col   = (sopts.Position == "Right") and rightCol or leftCol
        local order = #col:GetChildren()

        local secFrame = Instance.new("Frame")
        secFrame.Name             = sopts.Title or "Section"
        secFrame.Size             = UDim2.new(1, 0, 0, 0)
        secFrame.AutomaticSize    = Enum.AutomaticSize.Y
        secFrame.BackgroundColor3 = T.BG3
        secFrame.BorderSizePixel  = 0
        secFrame.LayoutOrder      = order
        secFrame.Parent           = col
        corner(secFrame, 8)
        stroke(secFrame, Color3.fromRGB(255, 255, 255), 0.92)
        listLayout(secFrame, 5)
        padding(secFrame, 8, 8, 10, 8)

        local secTitle = Instance.new("TextLabel")
        secTitle.Text                   = sopts.Title or "Section"
        secTitle.Font                   = T.Font
        secTitle.TextSize               = 12
        secTitle.TextColor3             = T.Accent
        secTitle.BackgroundTransparency = 1
        secTitle.Size                   = UDim2.new(1, 0, 0, 18)
        secTitle.TextXAlignment         = Enum.TextXAlignment.Left
        secTitle.LayoutOrder            = 0
        secTitle.Parent                 = secFrame

        local divider = Instance.new("Frame")
        divider.Size                   = UDim2.new(1, 0, 0, 1)
        divider.BackgroundColor3       = T.Accent
        divider.BackgroundTransparency = 0.70
        divider.BorderSizePixel        = 0
        divider.LayoutOrder            = 1
        divider.Parent                 = secFrame

        local elemN = {v = 2}

        -- ── Section object ────────────────────────────────────
        local Sec = {}

        -- Toggle ──────────────────────────────────────────────
        function Sec:NewToggle(topts)
            local row = Instance.new("Frame")
            row.Size                   = UDim2.new(1, 0, 0, 30)
            row.BackgroundTransparency = 1
            row.LayoutOrder            = elemN.v; elemN.v += 1
            row.Parent                 = secFrame

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = topts.Title or "Toggle"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -46, 1, 0)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = row

            local pill = Instance.new("Frame")
            pill.Size             = UDim2.new(0, 36, 0, 20)
            pill.Position         = UDim2.new(1, -36, 0.5, -10)
            pill.BackgroundColor3 = T.Off
            pill.BorderSizePixel  = 0
            pill.Parent           = row
            corner(pill, 10)

            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 14, 0, 14)
            knob.Position         = UDim2.new(0, 3, 0.5, -7)
            knob.BackgroundColor3 = T.Muted
            knob.BorderSizePixel  = 0
            knob.Parent           = pill
            corner(knob, 7)

            local state = topts.Default or false
            local function set(v, fire)
                state = v
                if v then
                    tw(pill, {BackgroundColor3 = T.Accent}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 19, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1)}, 0.18)
                else
                    tw(pill, {BackgroundColor3 = T.Off}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = T.Muted}, 0.18)
                end
                if fire and topts.Callback then topts.Callback(v) end
            end
            if state then set(true, false) end

            local hit = Instance.new("TextButton")
            hit.Size               = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text               = ""
            hit.Parent             = row
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
        end

        -- Slider ──────────────────────────────────────────────
        function Sec:NewSlider(sopts2)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 46)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame

            local mn = sopts2.Min     or 0
            local mx = sopts2.Max     or 100
            local df = sopts2.Default or mn

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = (sopts2.Title or "Slider") .. ": " .. tostring(df)
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, 0, 0, 20)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = wrap

            local track = Instance.new("Frame")
            track.Size             = UDim2.new(1, 0, 0, 6)
            track.Position         = UDim2.new(0, 0, 0, 32)
            track.BackgroundColor3 = T.Off
            track.BorderSizePixel  = 0
            track.Parent           = wrap
            corner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size             = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = T.Accent
            fill.BorderSizePixel  = 0
            fill.Parent           = track
            corner(fill, 3)

            local thumb = Instance.new("Frame")
            thumb.Size             = UDim2.new(0, 14, 0, 14)
            thumb.AnchorPoint      = Vector2.new(1, 0.5)
            thumb.Position         = UDim2.new(1, 0, 0.5, 0)
            thumb.BackgroundColor3 = Color3.new(1, 1, 1)
            thumb.BorderSizePixel  = 0
            thumb.Parent           = fill
            corner(thumb, 7)

            local function setVal(v, fire)
                v = math.clamp(math.round(v), mn, mx)
                local pct = (v - mn) / (mx - mn)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                lbl.Text  = (sopts2.Title or "Slider") .. ": " .. tostring(v)
                if fire and sopts2.Callback then sopts2.Callback(v) end
            end
            setVal(df, false)

            local sliding = false
            local hit = Instance.new("TextButton")
            hit.Size               = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text               = ""
            hit.Parent             = wrap
            hit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
            end)
            UIS.InputChanged:Connect(function(i)
                if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
                    local abs = track.AbsolutePosition
                    local sz  = track.AbsoluteSize
                    local pct = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
                    setVal(mn + (mx - mn) * pct, true)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)
        end

        -- Button ──────────────────────────────────────────────
        function Sec:NewButton(bopts)
            local b = Instance.new("TextButton")
            b.Text             = bopts.Title or "Button"
            b.Font             = T.FontReg
            b.TextSize         = 13
            b.TextColor3       = T.Text
            b.BackgroundColor3 = T.BG2
            b.BorderSizePixel  = 0
            b.AutoButtonColor  = false
            b.Size             = UDim2.new(1, 0, 0, 28)
            b.LayoutOrder      = elemN.v; elemN.v += 1
            b.Parent           = secFrame
            corner(b, 6)
            stroke(b, Color3.fromRGB(255, 255, 255), 0.9)
            b.MouseEnter:Connect(function()  tw(b, {BackgroundColor3 = T.AccentDim}, 0.15) end)
            b.MouseLeave:Connect(function()  tw(b, {BackgroundColor3 = T.BG2},       0.15) end)
            b.MouseButton1Click:Connect(function()
                -- Brief press flash
                tw(b, {BackgroundColor3 = T.Accent}, 0.08)
                task.delay(0.12, function() tw(b, {BackgroundColor3 = T.AccentDim}, 0.15) end)
                if bopts.Callback then bopts.Callback() end
            end)
        end

        -- Label ───────────────────────────────────────────────
        function Sec:NewLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Text                   = text or ""
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 12
            lbl.TextColor3             = T.Muted
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, 0, 0, 18)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.TextWrapped            = true
            lbl.LayoutOrder            = elemN.v; elemN.v += 1
            lbl.Parent                 = secFrame
        end

        -- Separator ───────────────────────────────────────────
        function Sec:NewSeparator()
            local sep = Instance.new("Frame")
            sep.Size                   = UDim2.new(1, 0, 0, 1)
            sep.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
            sep.BackgroundTransparency = 0.88
            sep.BorderSizePixel        = 0
            sep.LayoutOrder            = elemN.v; elemN.v += 1
            sep.Parent                 = secFrame
        end

        -- Dropdown ────────────────────────────────────────────
        function Sec:NewDropdown(dopts)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 52)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame
            wrap.ClipsDescendants       = false

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = dopts.Title or "Dropdown"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, 0, 0, 18)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = wrap

            local selected = dopts.Default or (dopts.Options and dopts.Options[1]) or ""

            local dropBtn = Instance.new("Frame")
            dropBtn.Size             = UDim2.new(1, 0, 0, 28)
            dropBtn.Position         = UDim2.new(0, 0, 0, 22)
            dropBtn.BackgroundColor3 = T.BG2
            dropBtn.BorderSizePixel  = 0
            dropBtn.ZIndex           = 5
            dropBtn.Parent           = wrap
            corner(dropBtn, 6)
            local dropSt = stroke(dropBtn, Color3.fromRGB(255, 255, 255), 0.9)

            local dropLbl = Instance.new("TextLabel")
            dropLbl.Text                   = selected
            dropLbl.Font                   = T.FontReg
            dropLbl.TextSize               = 12
            dropLbl.TextColor3             = T.TextDim
            dropLbl.BackgroundTransparency = 1
            dropLbl.Size                   = UDim2.new(1, -28, 1, 0)
            dropLbl.Position               = UDim2.new(0, 8, 0, 0)
            dropLbl.TextXAlignment         = Enum.TextXAlignment.Left
            dropLbl.ZIndex                 = 6
            dropLbl.Parent                 = dropBtn

            local arrow = Instance.new("TextLabel")
            arrow.Text                   = "▾"
            arrow.Font                   = T.Font
            arrow.TextSize               = 12
            arrow.TextColor3             = T.Muted
            arrow.BackgroundTransparency = 1
            arrow.Size                   = UDim2.new(0, 22, 1, 0)
            arrow.Position               = UDim2.new(1, -22, 0, 0)
            arrow.TextXAlignment         = Enum.TextXAlignment.Center
            arrow.ZIndex                 = 6
            arrow.Parent                 = dropBtn

            -- Popup (child of dropBtn so it moves with it; ZIndex keeps it on top)
            local optionCount = dopts.Options and #dopts.Options or 0
            local popup = Instance.new("Frame")
            popup.Size             = UDim2.new(1, 0, 0, optionCount * 26 + 6)
            popup.Position         = UDim2.new(0, 0, 1, 3)
            popup.BackgroundColor3 = T.BG3
            popup.BorderSizePixel  = 0
            popup.ZIndex           = 10
            popup.Visible          = false
            popup.ClipsDescendants = true
            popup.Parent           = dropBtn
            corner(popup, 6)
            stroke(popup, Color3.fromRGB(255, 255, 255), 0.88)
            listLayout(popup, 2)
            padding(popup, 3, 3, 3, 3)

            local isOpen = false

            local function closePopup()
                isOpen = false
                popup.Visible = false
                tw(arrow, {Rotation = 0}, 0.15)
                tw(dropSt, {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9}, 0.15)
            end

            for _, opt in ipairs(dopts.Options or {}) do
                local optBtn = Instance.new("TextButton")
                optBtn.Text                   = opt
                optBtn.Font                   = T.FontReg
                optBtn.TextSize               = 12
                optBtn.TextColor3             = opt == selected and T.Accent or T.TextDim
                optBtn.BackgroundColor3       = T.BG4
                optBtn.BackgroundTransparency = 1
                optBtn.AutoButtonColor        = false
                optBtn.Size                   = UDim2.new(1, 0, 0, 24)
                optBtn.ZIndex                 = 11
                optBtn.Parent                 = popup
                corner(optBtn, 4)

                optBtn.MouseEnter:Connect(function()
                    tw(optBtn, {BackgroundTransparency = 0.3, TextColor3 = T.Text}, 0.1)
                end)
                optBtn.MouseLeave:Connect(function()
                    local col = optBtn.Text == selected and T.Accent or T.TextDim
                    tw(optBtn, {BackgroundTransparency = 1, TextColor3 = col}, 0.1)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected   = opt
                    dropLbl.Text = opt
                    -- Update option colors
                    for _, child in ipairs(popup:GetChildren()) do
                        if child:IsA("TextButton") then
                            tw(child, {TextColor3 = child.Text == selected and T.Accent or T.TextDim}, 0.1)
                        end
                    end
                    closePopup()
                    if dopts.Callback then dopts.Callback(opt) end
                end)
            end

            -- Hit area on the dropBtn frame to open/close
            local hit = Instance.new("TextButton")
            hit.Size               = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text               = ""
            hit.ZIndex             = 7
            hit.Parent             = dropBtn
            hit.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                popup.Visible = isOpen
                tw(arrow, {Rotation = isOpen and 180 or 0}, 0.15)
                if isOpen then
                    tw(dropSt, {Color = T.Accent, Transparency = 0.65}, 0.15)
                else
                    tw(dropSt, {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9}, 0.15)
                end
            end)
        end

        -- TextInput ───────────────────────────────────────────
        function Sec:NewInput(iopts)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 52)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = iopts.Title or "Input"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, 0, 0, 18)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = wrap

            local box = Instance.new("TextBox")
            box.Size               = UDim2.new(1, 0, 0, 28)
            box.Position           = UDim2.new(0, 0, 0, 22)
            box.BackgroundColor3   = T.BG2
            box.BorderSizePixel    = 0
            box.PlaceholderText    = iopts.Placeholder or ""
            box.PlaceholderColor3  = T.Muted
            box.Text               = iopts.Default or ""
            box.Font               = T.FontReg
            box.TextSize           = 12
            box.TextColor3         = T.Text
            box.ClearTextOnFocus   = iopts.ClearOnFocus ~= false
            box.Parent             = wrap
            corner(box, 6)
            local boxSt = stroke(box, Color3.fromRGB(255, 255, 255), 0.9)
            padding(box, 0, 8, 0, 8)

            box.Focused:Connect(function()
                tw(boxSt, {Color = T.Accent, Transparency = 0.60}, 0.15)
            end)
            box.FocusLost:Connect(function(entered)
                tw(boxSt, {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9}, 0.15)
                if iopts.Callback then iopts.Callback(box.Text, entered) end
            end)
        end

        -- Keybind ─────────────────────────────────────────────
        function Sec:NewKeybind(kopts)
            local row = Instance.new("Frame")
            row.Size                   = UDim2.new(1, 0, 0, 30)
            row.BackgroundTransparency = 1
            row.LayoutOrder            = elemN.v; elemN.v += 1
            row.Parent                 = secFrame

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = kopts.Title or "Keybind"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -72, 1, 0)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = row

            local bound    = kopts.Default or Enum.KeyCode.Unknown
            local listening = false

            local keyName = tostring(bound):gsub("Enum.KeyCode.", "")
            local keyBtn  = Instance.new("TextButton")
            keyBtn.Size             = UDim2.new(0, 62, 0, 22)
            keyBtn.Position         = UDim2.new(1, -62, 0.5, -11)
            keyBtn.BackgroundColor3 = T.BG2
            keyBtn.BorderSizePixel  = 0
            keyBtn.AutoButtonColor  = false
            keyBtn.Text             = keyName
            keyBtn.Font             = T.FontReg
            keyBtn.TextSize         = 11
            keyBtn.TextColor3       = T.Accent
            keyBtn.Parent           = row
            corner(keyBtn, 4)
            stroke(keyBtn, T.Accent, 0.75)

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text      = "..."
                keyBtn.TextColor3 = T.TextDim
            end)

            UIS.InputBegan:Connect(function(i, gpe)
                if not listening then return end
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    listening         = false
                    bound             = i.KeyCode
                    keyBtn.Text       = tostring(bound):gsub("Enum.KeyCode.", "")
                    keyBtn.TextColor3 = T.Accent
                    if kopts.Callback then kopts.Callback(bound) end
                end
            end)
        end

        return Sec
    end

    return Tab
end

-- ── Notify ───────────────────────────────────────────────────
function Phantom:Notify(nopts)
    local notif = Instance.new("Frame")
    notif.Size                   = UDim2.new(0, 240, 0, 62)
    notif.Position               = UDim2.new(1, -252, 1, 10)
    notif.BackgroundColor3       = T.BG2
    notif.BackgroundTransparency = 1
    notif.BorderSizePixel        = 0
    notif.ZIndex                 = 20
    notif.Parent                 = self._gui
    corner(notif, 8)
    stroke(notif, T.Accent, 0.62)

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = T.Accent
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 21
    bar.Parent           = notif
    corner(bar, 2)

    local tLbl = Instance.new("TextLabel")
    tLbl.Text                   = nopts.Title or ""
    tLbl.Font                   = T.Font
    tLbl.TextSize               = 13
    tLbl.TextColor3             = T.Text
    tLbl.BackgroundTransparency = 1
    tLbl.Size                   = UDim2.new(1, -16, 0, 22)
    tLbl.Position               = UDim2.new(0, 13, 0, 9)
    tLbl.TextXAlignment         = Enum.TextXAlignment.Left
    tLbl.ZIndex                 = 21
    tLbl.Parent                 = notif

    local mLbl = Instance.new("TextLabel")
    mLbl.Text                   = nopts.Message or ""
    mLbl.Font                   = T.FontReg
    mLbl.TextSize               = 11
    mLbl.TextColor3             = T.Muted
    mLbl.BackgroundTransparency = 1
    mLbl.Size                   = UDim2.new(1, -16, 0, 18)
    mLbl.Position               = UDim2.new(0, 13, 0, 33)
    mLbl.TextXAlignment         = Enum.TextXAlignment.Left
    mLbl.TextWrapped            = true
    mLbl.ZIndex                 = 21
    mLbl.Parent                 = notif

    tw(notif, {Position = UDim2.new(1, -252, 1, -74), BackgroundTransparency = 0}, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(nopts.Duration or 3, function()
        tw(notif, {Position = UDim2.new(1, -252, 1, 10), BackgroundTransparency = 1}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.32, function() notif:Destroy() end)
    end)
end

return Phantom
