-- Phantom UI Library v2
-- Dark glassmorphism | Purple accent | Smooth animations

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Phantom = {}
Phantom.__index = Phantom

-- ── Theme ────────────────────────────────────────────────────
local T = {
    BG       = Color3.fromRGB(11, 11, 11),
    BG2      = Color3.fromRGB(18, 18, 18),
    BG3      = Color3.fromRGB(24, 24, 24),
    Accent   = Color3.fromRGB(110, 75, 255),
    AccentDim= Color3.fromRGB(70, 50, 170),
    Text     = Color3.fromRGB(238, 238, 238),
    Muted    = Color3.fromRGB(110, 110, 110),
    Off      = Color3.fromRGB(40, 40, 40),
    BGTrans  = 0.10,
    Font     = Enum.Font.GothamBold,
    FontReg  = Enum.Font.Gotham,
}

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

local function stroke(p, col, tr)
    local s = Instance.new("UIStroke")
    s.Color        = col or Color3.new(1, 1, 1)
    s.Transparency = tr  or 0.9
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
    shadow.Size                   = UDim2.new(0, 468, 0, 328)
    shadow.Position               = UDim2.new(0.5, -232, 0.5, -162)
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 1
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 0
    shadow.Parent                 = gui
    corner(shadow, 14)

    -- Main window
    local win = Instance.new("Frame")
    win.Name                   = "Win"
    win.Size                   = UDim2.new(0, 460, 0, 320)
    win.Position               = UDim2.new(0.5, -230, 0.5, -160)
    win.BackgroundColor3       = T.BG
    win.BackgroundTransparency = 1
    win.BorderSizePixel        = 0
    win.ZIndex                 = 1
    win.Parent                 = gui
    corner(win, 12)
    stroke(win, Color3.fromRGB(255, 255, 255), 0.92)

    -- UIScale — used for open/close animation (no Size tweening!)
    local winScale  = Instance.new("UIScale")
    winScale.Scale  = 0.85
    winScale.Parent = win

    -- ── Top bar ──────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size                   = UDim2.new(1, 0, 0, 38)
    topBar.BackgroundColor3       = T.BG2
    topBar.BackgroundTransparency = 0
    topBar.BorderSizePixel        = 0
    topBar.ZIndex                 = 2
    topBar.Parent                 = win
    corner(topBar, 12)

    -- Square off the bottom corners of topBar
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
    dot.Size             = UDim2.new(0, 6, 0, 6)
    dot.Position         = UDim2.new(0, 13, 0.5, -3)
    dot.BackgroundColor3 = T.Accent
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 3
    dot.Parent           = topBar
    corner(dot, 3)

    -- Title
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Text                 = opts.Title or "Phantom"
    titleLbl.Font                 = T.Font
    titleLbl.TextSize             = 14
    titleLbl.TextColor3           = T.Text
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size                 = UDim2.new(0, 120, 1, 0)
    titleLbl.Position             = UDim2.new(0, 25, 0, 0)
    titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
    titleLbl.ZIndex               = 3
    titleLbl.Parent               = topBar

    -- Subtitle
    local subLbl = Instance.new("TextLabel")
    subLbl.Text                   = opts.Subtitle or ""
    subLbl.Font                   = T.FontReg
    subLbl.TextSize               = 12
    subLbl.TextColor3             = T.Muted
    subLbl.BackgroundTransparency = 1
    subLbl.Size                   = UDim2.new(0, 150, 1, 0)
    subLbl.Position               = UDim2.new(0, 140, 0, 0)
    subLbl.TextXAlignment         = Enum.TextXAlignment.Left
    subLbl.ZIndex                 = 3
    subLbl.Parent                 = topBar

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Text                   = "✕"
    closeBtn.Font                   = T.Font
    closeBtn.TextSize               = 13
    closeBtn.TextColor3             = T.Muted
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size                   = UDim2.new(0, 30, 1, 0)
    closeBtn.Position               = UDim2.new(1, -32, 0, 0)
    closeBtn.AutoButtonColor        = false
    closeBtn.ZIndex                 = 3
    closeBtn.Parent                 = topBar
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, {TextColor3 = Color3.fromRGB(255, 70, 70)}, 0.12) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, {TextColor3 = T.Muted}, 0.12) end)

    -- ── Sidebar ───────────────────────────────────────────────
    local sidebar = Instance.new("Frame")
    sidebar.Name                   = "Sidebar"
    sidebar.Size                   = UDim2.new(0, 108, 1, -38)
    sidebar.Position               = UDim2.new(0, 0, 0, 38)
    sidebar.BackgroundColor3       = T.BG2
    sidebar.BackgroundTransparency = 0
    sidebar.BorderSizePixel        = 0
    sidebar.ZIndex                 = 2
    sidebar.Parent                 = win
    corner(sidebar, 12)

    -- Square off the right corners of sidebar
    local sideFix = Instance.new("Frame")
    sideFix.Size                   = UDim2.new(0.5, 0, 1, 0)
    sideFix.Position               = UDim2.new(0.5, 0, 0, 0)
    sideFix.BackgroundColor3       = T.BG2
    sideFix.BackgroundTransparency = 0
    sideFix.BorderSizePixel        = 0
    sideFix.ZIndex                 = 1
    sideFix.Parent                 = sidebar

    listLayout(sidebar, 4)
    padding(sidebar, 8, 6, 8, 6)

    -- Divider line
    local sideDiv = Instance.new("Frame")
    sideDiv.Size                   = UDim2.new(0, 1, 1, -38)
    sideDiv.Position               = UDim2.new(0, 108, 0, 38)
    sideDiv.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    sideDiv.BackgroundTransparency = 0.92
    sideDiv.BorderSizePixel        = 0
    sideDiv.ZIndex                 = 3
    sideDiv.Parent                 = win

    -- ── Content area ─────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name                   = "Content"
    content.Size                   = UDim2.new(1, -109, 1, -38)
    content.Position               = UDim2.new(0, 109, 0, 38)
    content.BackgroundTransparency = 1
    content.BorderSizePixel        = 0
    content.ClipsDescendants       = true
    content.ZIndex                 = 2
    content.Parent                 = win

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
            shadow.Position = UDim2.new(wStart.X.Scale, wStart.X.Offset + d.X + 2, wStart.Y.Scale, wStart.Y.Offset + d.Y + 2)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ── Animations ───────────────────────────────────────────
    local function showAnim()
        win.Visible                    = true
        shadow.Visible                 = true
        win.BackgroundTransparency     = 1
        shadow.BackgroundTransparency  = 1
        winScale.Scale                 = 0.85
        blur.Size                      = 8
        tw(win,      {BackgroundTransparency = T.BGTrans}, 0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
        tw(shadow,   {BackgroundTransparency = 0.65},      0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
        tw(winScale, {Scale = 1},                          0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
    end

    local function hideAnim()
        blur.Size = 0
        tw(win,      {BackgroundTransparency = 1},   0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tw(shadow,   {BackgroundTransparency = 1},   0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        tw(winScale, {Scale = 0.88},                 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.27, function()
            win.Visible    = false
            shadow.Visible = false
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        self.Visible = false
        hideAnim()
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

    -- Sidebar button
    local btn = Instance.new("TextButton")
    btn.Text                   = opts.Title or "Tab"
    btn.Font                   = T.FontReg
    btn.TextSize               = 12
    btn.TextColor3             = T.Muted
    btn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Size                   = UDim2.new(1, 0, 0, 28)
    btn.LayoutOrder            = self._tabN
    btn.AutoButtonColor        = false
    btn.Parent                 = self._sidebar
    corner(btn, 6)
    local btnSt = stroke(btn, T.Accent, 1)

    -- Tab frame (holds two scroll columns)
    local tabFrame = Instance.new("Frame")
    tabFrame.Size                   = UDim2.new(1, 0, 1, 0)
    tabFrame.BackgroundTransparency = 1
    tabFrame.BorderSizePixel        = 0
    tabFrame.Visible                = false
    tabFrame.Parent                 = self._content

    local function makeScrollCol(pos, size)
        local sf = Instance.new("ScrollingFrame")
        sf.Size                  = size
        sf.Position              = pos
        sf.BackgroundTransparency = 1
        sf.BorderSizePixel       = 0
        sf.ScrollBarThickness    = 2
        sf.ScrollBarImageColor3  = T.Accent
        sf.CanvasSize            = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        sf.Parent                = tabFrame
        listLayout(sf, 5)
        padding(sf, 6, 4, 6, 4)
        return sf
    end

    local leftCol  = makeScrollCol(UDim2.new(0, 0, 0, 0),   UDim2.new(0.5, -1, 1, 0))
    local rightCol = makeScrollCol(UDim2.new(0.5, 1, 0, 0),  UDim2.new(0.5, -1, 1, 0))

    -- Activate logic
    local tabData = {_frame = tabFrame, _btn = btn, _btnSt = btnSt}

    local function activate()
        if self._active then
            self._active._frame.Visible = false
            tw(self._active._btn,   {TextColor3 = T.Muted, BackgroundTransparency = 1}, 0.15)
            tw(self._active._btnSt, {Transparency = 1}, 0.15)
        end
        self._active      = tabData
        tabFrame.Visible  = true
        tw(btn,   {TextColor3 = T.Text, BackgroundTransparency = 0.88}, 0.18)
        tw(btnSt, {Transparency = 0.72}, 0.18)
    end

    btn.MouseButton1Click:Connect(activate)
    if #self._tabs == 0 then task.defer(activate) end
    table.insert(self._tabs, tabData)

    -- ── Tab object ───────────────────────────────────────────
    local Tab = {}

    function Tab:NewSection(sopts)
        local col = (sopts.Position == "Right") and rightCol or leftCol
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
        padding(secFrame, 7, 7, 8, 7)

        -- Section title
        local secTitle = Instance.new("TextLabel")
        secTitle.Text                   = sopts.Title or "Section"
        secTitle.Font                   = T.Font
        secTitle.TextSize               = 11
        secTitle.TextColor3             = T.Accent
        secTitle.BackgroundTransparency = 1
        secTitle.Size                   = UDim2.new(1, 0, 0, 16)
        secTitle.TextXAlignment         = Enum.TextXAlignment.Left
        secTitle.LayoutOrder            = 0
        secTitle.Parent                 = secFrame

        -- Accent divider
        local divider = Instance.new("Frame")
        divider.Size                   = UDim2.new(1, 0, 0, 1)
        divider.BackgroundColor3       = T.Accent
        divider.BackgroundTransparency = 0.72
        divider.BorderSizePixel        = 0
        divider.LayoutOrder            = 1
        divider.Parent                 = secFrame

        local elemN = {v = 2}

        -- ── Section object ────────────────────────────────────
        local Sec = {}

        function Sec:NewToggle(topts)
            local row = Instance.new("Frame")
            row.Size                   = UDim2.new(1, 0, 0, 28)
            row.BackgroundTransparency = 1
            row.LayoutOrder            = elemN.v; elemN.v += 1
            row.Parent                 = secFrame

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = topts.Title or "Toggle"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 12
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -44, 1, 0)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = row

            local pill = Instance.new("Frame")
            pill.Size             = UDim2.new(0, 34, 0, 18)
            pill.Position         = UDim2.new(1, -34, 0.5, -9)
            pill.BackgroundColor3 = T.Off
            pill.BorderSizePixel  = 0
            pill.Parent           = row
            corner(pill, 9)

            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 12, 0, 12)
            knob.Position         = UDim2.new(0, 3, 0.5, -6)
            knob.BackgroundColor3 = T.Muted
            knob.BorderSizePixel  = 0
            knob.Parent           = pill
            corner(knob, 6)

            local state = topts.Default or false
            local function set(v, fire)
                state = v
                if v then
                    tw(pill, {BackgroundColor3 = T.Accent}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 19, 0.5, -6), BackgroundColor3 = Color3.new(1,1,1)}, 0.18)
                else
                    tw(pill, {BackgroundColor3 = T.Off}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = T.Muted}, 0.18)
                end
                if fire and topts.Callback then topts.Callback(v) end
            end
            if state then set(true, false) end

            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Parent = row
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
        end

        function Sec:NewSlider(sopts2)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 44)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame

            local mn = sopts2.Min     or 0
            local mx = sopts2.Max     or 100
            local df = sopts2.Default or mn

            local lbl = Instance.new("TextLabel")
            lbl.Text                   = (sopts2.Title or "Slider") .. ": " .. tostring(df)
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 12
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, 0, 0, 20)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = wrap

            local track = Instance.new("Frame")
            track.Size             = UDim2.new(1, 0, 0, 6)
            track.Position         = UDim2.new(0, 0, 0, 30)
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
            thumb.Size             = UDim2.new(0, 12, 0, 12)
            thumb.AnchorPoint      = Vector2.new(1, 0.5)
            thumb.Position         = UDim2.new(1, 0, 0.5, 0)
            thumb.BackgroundColor3 = Color3.new(1, 1, 1)
            thumb.BorderSizePixel  = 0
            thumb.Parent           = fill
            corner(thumb, 6)

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
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.Parent = wrap
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

        function Sec:NewButton(bopts)
            local b = Instance.new("TextButton")
            b.Text              = bopts.Title or "Button"
            b.Font              = T.FontReg
            b.TextSize          = 12
            b.TextColor3        = T.Text
            b.BackgroundColor3  = T.BG2
            b.BorderSizePixel   = 0
            b.AutoButtonColor   = false
            b.Size              = UDim2.new(1, 0, 0, 26)
            b.LayoutOrder       = elemN.v; elemN.v += 1
            b.Parent            = secFrame
            corner(b, 6)
            stroke(b, Color3.fromRGB(255, 255, 255), 0.9)
            b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = T.AccentDim}, 0.15) end)
            b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = T.BG2}, 0.15) end)
            b.MouseButton1Click:Connect(function()
                if bopts.Callback then bopts.Callback() end
            end)
        end

        return Sec
    end

    return Tab
end

-- ── Notify ───────────────────────────────────────────────────
function Phantom:Notify(nopts)
    local notif = Instance.new("Frame")
    notif.Size                   = UDim2.new(0, 230, 0, 58)
    notif.Position               = UDim2.new(1, -240, 1, 10)
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
    tLbl.Size                   = UDim2.new(1, -14, 0, 20)
    tLbl.Position               = UDim2.new(0, 11, 0, 8)
    tLbl.TextXAlignment         = Enum.TextXAlignment.Left
    tLbl.ZIndex                 = 21
    tLbl.Parent                 = notif

    local mLbl = Instance.new("TextLabel")
    mLbl.Text                   = nopts.Message or ""
    mLbl.Font                   = T.FontReg
    mLbl.TextSize               = 11
    mLbl.TextColor3             = T.Muted
    mLbl.BackgroundTransparency = 1
    mLbl.Size                   = UDim2.new(1, -14, 0, 18)
    mLbl.Position               = UDim2.new(0, 11, 0, 30)
    mLbl.TextXAlignment         = Enum.TextXAlignment.Left
    mLbl.TextWrapped            = true
    mLbl.ZIndex                 = 21
    mLbl.Parent                 = notif

    -- Slide up from bottom-right
    tw(notif, {Position = UDim2.new(1, -240, 1, -68), BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(nopts.Duration or 3, function()
        tw(notif, {Position = UDim2.new(1, -240, 1, 10), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.35, function() notif:Destroy() end)
    end)
end

return Phantom
