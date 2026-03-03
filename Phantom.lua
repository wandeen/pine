-- Phantom UI Library v2
-- Dark glassmorphism | Purple accent | Smooth animations

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local PLR = game:GetService("Players")
local HS  = game:GetService("HttpService")

local Phantom = {}
Phantom.__index = Phantom

-- ── Theme ─────────────────────────────────────────────────────
-- Modify Phantom.Theme BEFORE calling Phantom.new() to customise globally,
-- or pass opts.Theme = { Accent = ... } to override per-instance.
Phantom.Theme = {
    BG          = Color3.fromRGB(11, 11, 11),
    BG2         = Color3.fromRGB(18, 18, 18),
    BG3         = Color3.fromRGB(24, 24, 24),
    BG4         = Color3.fromRGB(32, 32, 32),
    Accent      = Color3.fromRGB(110, 75, 255),
    AccentDim   = Color3.fromRGB(70,  50, 170),
    AccentBright= Color3.fromRGB(140, 105, 255),
    Text        = Color3.fromRGB(238, 238, 238),
    TextDim     = Color3.fromRGB(180, 180, 180),
    Muted       = Color3.fromRGB(100, 100, 100),
    Off         = Color3.fromRGB(40,  40,  40),
    Danger      = Color3.fromRGB(255, 65,  65),
    BGTrans     = 0.10,
    Font        = Enum.Font.GothamBold,
    FontReg     = Enum.Font.Gotham,
}

-- Window dimensions
local W, H   = 580, 400
local TOPBAR = 40
local SIDE   = 116
local FOOTER = 26

-- Notification constants
local NOTIF_H   = 62
local NOTIF_W   = 244
local NOTIF_X   = -256
local NOTIF_GAP = 6
local NOTIF_BM  = 10  -- bottom margin
local function getNotifY(slot)
    return -(NOTIF_BM + (NOTIF_H + NOTIF_GAP) * slot - NOTIF_GAP)
end

-- ── Helpers ───────────────────────────────────────────────────
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

local function makePillBtn(parent, posX, symbol, hoverBg, hoverText, T)
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

-- ── Window ────────────────────────────────────────────────────
function Phantom.new(opts)
    local self   = setmetatable({}, Phantom)
    -- Merge global theme + per-instance theme overrides into a local T copy
    local T = {}
    for k, v in pairs(Phantom.Theme) do T[k] = v end
    if opts.Theme then
        for k, v in pairs(opts.Theme) do T[k] = v end
    end

    self.Keybind      = opts.Keybind or Enum.KeyCode.J
    self.Visible      = true
    self._tabs        = {}
    self._active      = nil
    self._tabN        = 0
    self._notifs      = {}   -- active notification entries {_frame}
    self._cfgState    = {}   -- config: key → current value
    self._cfgSetters  = {}   -- config: key → function(value)

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name           = "PhantomHub"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder   = 100
    local ok, cg = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    gui.Parent = ok and cg or PLR.LocalPlayer:WaitForChild("PlayerGui")

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
    stroke(win, T.Accent, 0.80)  -- intentional purple border, not the faint-white artifact

    local winScale  = Instance.new("UIScale")
    winScale.Scale  = 0.85
    winScale.Parent = win

    -- ── Top bar ───────────────────────────────────────────────
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

    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 7, 0, 7)
    dot.Position         = UDim2.new(0, 14, 0.5, -3)
    dot.BackgroundColor3 = T.Accent
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 3
    dot.Parent           = topBar
    corner(dot, 4)

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

    local minBtn   = makePillBtn(topBar, -68, "−", T.Accent,  Color3.new(1,1,1), T)
    local closeBtn = makePillBtn(topBar, -36, "✕", T.Danger,  Color3.new(1,1,1), T)

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

    -- ── Content area ──────────────────────────────────────────
    local content = Instance.new("Frame")
    content.Name                   = "Content"
    content.Size                   = UDim2.new(1, -(SIDE + 1), 1, -(TOPBAR + FOOTER))
    content.Position               = UDim2.new(0, SIDE + 1, 0, TOPBAR)
    content.BackgroundTransparency = 1
    content.BorderSizePixel        = 0
    content.ClipsDescendants       = true
    content.ZIndex                 = 2
    content.Parent                 = win

    -- ── Footer ────────────────────────────────────────────────
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

    -- ── Drag ──────────────────────────────────────────────────
    local dragging, dStart, wStart
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dStart = i.Position; wStart = win.Position
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

    -- ── Animations ────────────────────────────────────────────
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
        self.Visible = false; hideAnim()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        hideAnim(function() blur:Destroy(); gui:Destroy() end)
    end)
    UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == self.Keybind then
            self.Visible = not self.Visible
            if self.Visible then showAnim() else hideAnim() end
        end
    end)

    showAnim()

    self._gui     = gui
    self._win     = win
    self._shadow  = shadow
    self._winScale= winScale
    self._blur    = blur
    self._sidebar = sidebar
    self._content = content
    self._T       = T       -- store local theme copy for use in methods

    return self
end

-- ── Profile (call after Phantom.new, before NewTab) ───────────
function Phantom:SetProfile()
    local T  = self._T
    local lp = PLR.LocalPlayer

    local profileFrame = Instance.new("Frame")
    profileFrame.Size                   = UDim2.new(1, 0, 0, 78)
    profileFrame.BackgroundTransparency = 1
    profileFrame.LayoutOrder            = 0
    profileFrame.Parent                 = self._sidebar

    -- Avatar circle
    local avatarRing = Instance.new("Frame")
    avatarRing.Size             = UDim2.new(0, 46, 0, 46)
    avatarRing.Position         = UDim2.new(0.5, -23, 0, 2)
    avatarRing.BackgroundColor3 = T.BG3
    avatarRing.BorderSizePixel  = 0
    avatarRing.Parent           = profileFrame
    corner(avatarRing, 23)
    stroke(avatarRing, T.Accent, 0.60)

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size                   = UDim2.new(1, 0, 1, 0)
    avatarImg.BackgroundTransparency = 1
    avatarImg.Image                  = ""
    avatarImg.Parent                 = avatarRing
    corner(avatarImg, 23)

    -- Load avatar asynchronously
    task.spawn(function()
        local ok, url = pcall(function()
            return PLR:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and url then avatarImg.Image = url end
    end)

    -- Online indicator dot
    local onlineDot = Instance.new("Frame")
    onlineDot.Size             = UDim2.new(0, 10, 0, 10)
    onlineDot.Position         = UDim2.new(0.5, 13, 0, 36)
    onlineDot.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
    onlineDot.BorderSizePixel  = 0
    onlineDot.ZIndex           = 3
    onlineDot.Parent           = profileFrame
    corner(onlineDot, 5)
    stroke(onlineDot, T.BG2, 0, 2)

    -- Display name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text                   = lp.DisplayName
    nameLbl.Font                   = T.Font
    nameLbl.TextSize               = 11
    nameLbl.TextColor3             = T.Text
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size                   = UDim2.new(1, 0, 0, 14)
    nameLbl.Position               = UDim2.new(0, 0, 0, 52)
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
    nameLbl.Parent                 = profileFrame

    -- @username (if differs from display name)
    if lp.Name ~= lp.DisplayName then
        local userLbl = Instance.new("TextLabel")
        userLbl.Text                   = "@" .. lp.Name
        userLbl.Font                   = T.FontReg
        userLbl.TextSize               = 10
        userLbl.TextColor3             = T.Muted
        userLbl.BackgroundTransparency = 1
        userLbl.Size                   = UDim2.new(1, 0, 0, 12)
        userLbl.Position               = UDim2.new(0, 0, 0, 65)
        userLbl.TextXAlignment         = Enum.TextXAlignment.Center
        userLbl.Parent                 = profileFrame
        profileFrame.Size = UDim2.new(1, 0, 0, 88)
    end

    -- Divider below profile
    local div = Instance.new("Frame")
    div.Size                   = UDim2.new(1, 0, 0, 1)
    div.Position               = UDim2.new(0, 0, 1, -4)
    div.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    div.BackgroundTransparency = 0.88
    div.BorderSizePixel        = 0
    div.Parent                 = profileFrame
end

-- ── Config ────────────────────────────────────────────────────
-- Hub:SaveConfig("myconfig") → writes phantom_myconfig.json
-- Hub:LoadConfig("myconfig") → reads and applies
-- Hub:AutoSave("myconfig", 30) → saves every 30s in background
function Phantom:SaveConfig(name)
    local ok, json = pcall(function() return HS:JSONEncode(self._cfgState) end)
    if not ok then return end
    pcall(function() writefile("phantom_" .. (name or "default") .. ".json", json) end)
end

function Phantom:LoadConfig(name)
    local ok, content = pcall(function() return readfile("phantom_" .. (name or "default") .. ".json") end)
    if not ok then return end
    local ok2, data = pcall(function() return HS:JSONDecode(content) end)
    if not ok2 then return end
    for key, value in pairs(data) do
        self._cfgState[key] = value
        if self._cfgSetters[key] then self._cfgSetters[key](value) end
    end
end

function Phantom:AutoSave(name, interval)
    task.spawn(function()
        while self._gui and self._gui.Parent do
            task.wait(interval or 30)
            self:SaveConfig(name)
        end
    end)
end

-- ── Notify (stacked) ──────────────────────────────────────────
function Phantom:_repositionNotifs()
    for i, nd in ipairs(self._notifs) do
        tw(nd._frame, {Position = UDim2.new(1, NOTIF_X, 1, getNotifY(i))}, 0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end
end

function Phantom:Notify(nopts)
    local T = self._T

    local notif = Instance.new("Frame")
    notif.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
    notif.Position               = UDim2.new(1, NOTIF_X, 1, 10)  -- start hidden below
    notif.BackgroundColor3       = T.BG2
    notif.BackgroundTransparency = 1
    notif.BorderSizePixel        = 0
    notif.ZIndex                 = 20
    notif.Parent                 = self._gui
    corner(notif, 8)
    stroke(notif, T.Accent, 0.60)

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

    -- Insert as the new topmost slot
    local nd = {_frame = notif}
    table.insert(self._notifs, nd)
    local slot = #self._notifs

    tw(notif, {Position = UDim2.new(1, NOTIF_X, 1, getNotifY(slot)), BackgroundTransparency = 0},
        0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(nopts.Duration or 3, function()
        -- Remove from stack
        for i, n in ipairs(self._notifs) do
            if n == nd then table.remove(self._notifs, i); break end
        end
        -- Animate out downward, reposition rest
        tw(notif, {Position = UDim2.new(1, NOTIF_X, 1, 10), BackgroundTransparency = 1},
            0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        self:_repositionNotifs()
        task.delay(0.32, function() notif:Destroy() end)
    end)
end

-- ── Tab ───────────────────────────────────────────────────────
function Phantom:NewTab(opts)
    local T   = self._T
    local hub = self           -- capture Phantom instance for nested closures
    self._tabN = self._tabN + 1

    local tabTitle = opts.Title or "Tab"

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
    btnLbl.Text                   = tabTitle
    btnLbl.Font                   = T.FontReg
    btnLbl.TextSize               = 13
    btnLbl.TextColor3             = T.Muted
    btnLbl.BackgroundTransparency = 1
    btnLbl.Size                   = UDim2.new(1, -(txtX + 4), 1, 0)
    btnLbl.Position               = UDim2.new(0, txtX, 0, 0)
    btnLbl.TextXAlignment         = Enum.TextXAlignment.Left
    btnLbl.ZIndex                 = 3
    btnLbl.Parent                 = btn

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
            if self._active._btnIco then tw(self._active._btnIco, {ImageColor3 = T.Muted}, 0.15) end
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

    -- ── Tab object ────────────────────────────────────────────
    local Tab = {}

    function Tab:NewSection(sopts)
        local col      = (sopts.Position == "Right") and rightCol or leftCol
        local secTitle = sopts.Title or "Section"
        local order    = #col:GetChildren()

        local secFrame = Instance.new("Frame")
        secFrame.Name             = secTitle
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

        local secTitleLbl = Instance.new("TextLabel")
        secTitleLbl.Text                   = secTitle
        secTitleLbl.Font                   = T.Font
        secTitleLbl.TextSize               = 12
        secTitleLbl.TextColor3             = T.Accent
        secTitleLbl.BackgroundTransparency = 1
        secTitleLbl.Size                   = UDim2.new(1, 0, 0, 18)
        secTitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
        secTitleLbl.LayoutOrder            = 0
        secTitleLbl.Parent                 = secFrame

        local divider = Instance.new("Frame")
        divider.Size                   = UDim2.new(1, 0, 0, 1)
        divider.BackgroundColor3       = T.Accent
        divider.BackgroundTransparency = 0.70
        divider.BorderSizePixel        = 0
        divider.LayoutOrder            = 1
        divider.Parent                 = secFrame

        local elemN = {v = 2}

        -- ── Section object ─────────────────────────────────────
        local Sec = {}

        -- Helper: register component with config system
        local function cfgReg(title, default, setter)
            local key = tabTitle .. ">" .. secTitle .. ">" .. title
            hub._cfgState[key]   = default
            hub._cfgSetters[key] = setter
            return key
        end

        -- Toggle ────────────────────────────────────────────────
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
                hub._cfgState[cfgReg(topts.Title or "Toggle", state, function(val) set(val, false) end)] = v
                if v then
                    tw(pill, {BackgroundColor3 = T.Accent}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 19, 0.5, -7), BackgroundColor3 = Color3.new(1,1,1)}, 0.18)
                else
                    tw(pill, {BackgroundColor3 = T.Off}, 0.18)
                    tw(knob, {Position = UDim2.new(0, 3, 0.5, -7), BackgroundColor3 = T.Muted}, 0.18)
                end
                if fire and topts.Callback then topts.Callback(v) end
            end
            cfgReg(topts.Title or "Toggle", state, function(v) set(v, false) end)
            if state then set(true, false) end

            local hit = Instance.new("TextButton")
            hit.Size               = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text               = ""
            hit.Parent             = row
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
        end

        -- Slider ────────────────────────────────────────────────
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
                hub._cfgState[tabTitle .. ">" .. secTitle .. ">" .. (sopts2.Title or "Slider")] = v
                if fire and sopts2.Callback then sopts2.Callback(v) end
            end
            cfgReg(sopts2.Title or "Slider", df, function(v) setVal(v, false) end)
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

        -- Button ────────────────────────────────────────────────
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
            b.MouseEnter:Connect(function() tw(b, {BackgroundColor3 = T.AccentDim}, 0.15) end)
            b.MouseLeave:Connect(function() tw(b, {BackgroundColor3 = T.BG2},       0.15) end)
            b.MouseButton1Click:Connect(function()
                tw(b, {BackgroundColor3 = T.Accent}, 0.08)
                task.delay(0.12, function() tw(b, {BackgroundColor3 = T.AccentDim}, 0.15) end)
                if bopts.Callback then bopts.Callback() end
            end)
        end

        -- Label ─────────────────────────────────────────────────
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

        -- Separator ─────────────────────────────────────────────
        function Sec:NewSeparator()
            local sep = Instance.new("Frame")
            sep.Size                   = UDim2.new(1, 0, 0, 1)
            sep.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
            sep.BackgroundTransparency = 0.88
            sep.BorderSizePixel        = 0
            sep.LayoutOrder            = elemN.v; elemN.v += 1
            sep.Parent                 = secFrame
        end

        -- Dropdown ──────────────────────────────────────────────
        -- Popup is parented to the ScreenGui so it renders above everything
        -- and is not clipped by the ScrollingFrame.
        function Sec:NewDropdown(dopts)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 52)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame

            local titleLbl2 = Instance.new("TextLabel")
            titleLbl2.Text                   = dopts.Title or "Dropdown"
            titleLbl2.Font                   = T.FontReg
            titleLbl2.TextSize               = 13
            titleLbl2.TextColor3             = T.Text
            titleLbl2.BackgroundTransparency = 1
            titleLbl2.Size                   = UDim2.new(1, 0, 0, 18)
            titleLbl2.TextXAlignment         = Enum.TextXAlignment.Left
            titleLbl2.Parent                 = wrap

            local selected = dopts.Default or (dopts.Options and dopts.Options[1]) or ""

            local dropBox = Instance.new("Frame")
            dropBox.Size             = UDim2.new(1, 0, 0, 28)
            dropBox.Position         = UDim2.new(0, 0, 0, 22)
            dropBox.BackgroundColor3 = T.BG2
            dropBox.BorderSizePixel  = 0
            dropBox.ZIndex           = 2
            dropBox.Parent           = wrap
            corner(dropBox, 6)
            local dropSt = stroke(dropBox, Color3.fromRGB(255, 255, 255), 0.9)

            local dropLbl = Instance.new("TextLabel")
            dropLbl.Text                   = selected
            dropLbl.Font                   = T.FontReg
            dropLbl.TextSize               = 12
            dropLbl.TextColor3             = T.TextDim
            dropLbl.BackgroundTransparency = 1
            dropLbl.Size                   = UDim2.new(1, -26, 1, 0)
            dropLbl.Position               = UDim2.new(0, 8, 0, 0)
            dropLbl.TextXAlignment         = Enum.TextXAlignment.Left
            dropLbl.ZIndex                 = 3
            dropLbl.Parent                 = dropBox

            local arrow = Instance.new("TextLabel")
            arrow.Text                   = "▾"
            arrow.Font                   = T.Font
            arrow.TextSize               = 12
            arrow.TextColor3             = T.Muted
            arrow.BackgroundTransparency = 1
            arrow.Size                   = UDim2.new(0, 20, 1, 0)
            arrow.Position               = UDim2.new(1, -22, 0, 0)
            arrow.TextXAlignment         = Enum.TextXAlignment.Center
            arrow.ZIndex                 = 3
            arrow.Parent                 = dropBox

            -- Popup lives in the ScreenGui (avoids scroll-frame clipping)
            local optionCount = dopts.Options and #dopts.Options or 0
            local popup = Instance.new("Frame")
            popup.Size             = UDim2.new(0, 10, 0, optionCount * 26 + 6)
            popup.BackgroundColor3 = T.BG3
            popup.BorderSizePixel  = 0
            popup.ZIndex           = 60
            popup.Visible          = false
            popup.Parent           = hub._gui
            corner(popup, 6)
            stroke(popup, Color3.fromRGB(255, 255, 255), 0.88)
            listLayout(popup, 2)
            padding(popup, 3, 3, 3, 3)

            local isOpen = false

            local function closePopup()
                isOpen = false; popup.Visible = false
                tw(arrow, {Rotation = 0}, 0.15)
                tw(dropSt, {Color = Color3.fromRGB(255,255,255), Transparency = 0.9}, 0.15)
            end

            for _, opt in ipairs(dopts.Options or {}) do
                local optBtn = Instance.new("TextButton")
                optBtn.Text                   = opt
                optBtn.Font                   = T.FontReg
                optBtn.TextSize               = 12
                optBtn.TextColor3             = opt == selected and T.Accent or T.TextDim
                optBtn.BackgroundColor3       = T.AccentDim
                optBtn.BackgroundTransparency = 1
                optBtn.AutoButtonColor        = false
                optBtn.Size                   = UDim2.new(1, 0, 0, 24)
                optBtn.ZIndex                 = 61
                optBtn.Parent                 = popup
                corner(optBtn, 4)
                optBtn.MouseEnter:Connect(function()
                    tw(optBtn, {BackgroundTransparency = 0.65, TextColor3 = T.Text}, 0.1)
                end)
                optBtn.MouseLeave:Connect(function()
                    tw(optBtn, {BackgroundTransparency = 1, TextColor3 = optBtn.Text == selected and T.Accent or T.TextDim}, 0.1)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt; dropLbl.Text = opt
                    for _, child in ipairs(popup:GetChildren()) do
                        if child:IsA("TextButton") then
                            tw(child, {TextColor3 = child.Text == selected and T.Accent or T.TextDim}, 0.1)
                        end
                    end
                    hub._cfgState[tabTitle .. ">" .. secTitle .. ">" .. (dopts.Title or "Dropdown")] = opt
                    closePopup()
                    if dopts.Callback then dopts.Callback(opt) end
                end)
            end

            cfgReg(dopts.Title or "Dropdown", selected, function(v)
                selected = v; dropLbl.Text = v
            end)

            -- Hit area on dropBox
            local hit = Instance.new("TextButton")
            hit.Size               = UDim2.new(1, 0, 1, 0)
            hit.BackgroundTransparency = 1
            hit.Text               = ""
            hit.ZIndex             = 4
            hit.Parent             = dropBox
            hit.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local absPos  = dropBox.AbsolutePosition
                    local absSize = dropBox.AbsoluteSize
                    popup.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 3)
                    popup.Size     = UDim2.new(0, absSize.X, 0, optionCount * 26 + 6)
                    tw(dropSt, {Color = T.Accent, Transparency = 0.60}, 0.15)
                    tw(arrow, {Rotation = 180}, 0.15)
                else
                    closePopup()
                end
                popup.Visible = isOpen
            end)
        end

        -- TextInput ─────────────────────────────────────────────
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
            box.Size              = UDim2.new(1, 0, 0, 28)
            box.Position          = UDim2.new(0, 0, 0, 22)
            box.BackgroundColor3  = T.BG2
            box.BorderSizePixel   = 0
            box.PlaceholderText   = iopts.Placeholder or ""
            box.PlaceholderColor3 = T.Muted
            box.Text              = iopts.Default or ""
            box.Font              = T.FontReg
            box.TextSize          = 12
            box.TextColor3        = T.Text
            box.ClearTextOnFocus  = iopts.ClearOnFocus ~= false
            box.Parent            = wrap
            corner(box, 6)
            local boxSt = stroke(box, Color3.fromRGB(255, 255, 255), 0.9)
            padding(box, 0, 8, 0, 8)

            cfgReg(iopts.Title or "Input", box.Text, function(v) box.Text = v end)

            box.Focused:Connect(function()
                tw(boxSt, {Color = T.Accent, Transparency = 0.55}, 0.15)
            end)
            box.FocusLost:Connect(function(entered)
                tw(boxSt, {Color = Color3.fromRGB(255,255,255), Transparency = 0.9}, 0.15)
                hub._cfgState[tabTitle .. ">" .. secTitle .. ">" .. (iopts.Title or "Input")] = box.Text
                if iopts.Callback then iopts.Callback(box.Text, entered) end
            end)
        end

        -- Keybind ───────────────────────────────────────────────
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

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size             = UDim2.new(0, 62, 0, 22)
            keyBtn.Position         = UDim2.new(1, -62, 0.5, -11)
            keyBtn.BackgroundColor3 = T.BG2
            keyBtn.BorderSizePixel  = 0
            keyBtn.AutoButtonColor  = false
            keyBtn.Text             = tostring(bound):gsub("Enum.KeyCode.", "")
            keyBtn.Font             = T.FontReg
            keyBtn.TextSize         = 11
            keyBtn.TextColor3       = T.Accent
            keyBtn.Parent           = row
            corner(keyBtn, 4)
            stroke(keyBtn, T.Accent, 0.75)

            cfgReg(kopts.Title or "Keybind", keyBtn.Text, function(v)
                local kc = pcall(function() return Enum.KeyCode[v] end)
                if kc then bound = Enum.KeyCode[v] end
                keyBtn.Text = v
            end)

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true; keyBtn.Text = "..."; keyBtn.TextColor3 = T.TextDim
            end)
            UIS.InputBegan:Connect(function(i, gpe)
                if not listening then return end
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    listening         = false
                    bound             = i.KeyCode
                    local name        = tostring(bound):gsub("Enum.KeyCode.", "")
                    keyBtn.Text       = name
                    keyBtn.TextColor3 = T.Accent
                    hub._cfgState[tabTitle .. ">" .. secTitle .. ">" .. (kopts.Title or "Keybind")] = name
                    if kopts.Callback then kopts.Callback(bound) end
                end
            end)
        end

        -- ColorPicker ───────────────────────────────────────────
        -- SV square (saturation on X, value on Y) + vertical hue strip.
        -- Requires UIGradient support (available in all modern executors).
        function Sec:NewColorPicker(copts)
            local wrap = Instance.new("Frame")
            wrap.Size                   = UDim2.new(1, 0, 0, 104)
            wrap.BackgroundTransparency = 1
            wrap.LayoutOrder            = elemN.v; elemN.v += 1
            wrap.Parent                 = secFrame

            -- Label + swatch row
            local lbl = Instance.new("TextLabel")
            lbl.Text                   = copts.Title or "Color"
            lbl.Font                   = T.FontReg
            lbl.TextSize               = 13
            lbl.TextColor3             = T.Text
            lbl.BackgroundTransparency = 1
            lbl.Size                   = UDim2.new(1, -28, 0, 18)
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.Parent                 = wrap

            local defColor = copts.Default or T.Accent
            local h, s, v  = Color3.toHSV(defColor)

            local swatch = Instance.new("Frame")
            swatch.Size             = UDim2.new(0, 22, 0, 18)
            swatch.Position         = UDim2.new(1, -22, 0, 0)
            swatch.BackgroundColor3 = defColor
            swatch.BorderSizePixel  = 0
            swatch.Parent           = wrap
            corner(swatch, 4)
            stroke(swatch, Color3.fromRGB(255,255,255), 0.82)

            -- SV square: base (hue color) + white saturation overlay + black value overlay
            local svBox = Instance.new("Frame")
            svBox.Size             = UDim2.new(1, -20, 0, 80)
            svBox.Position         = UDim2.new(0, 0, 0, 22)
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svBox.BorderSizePixel  = 0
            svBox.ClipsDescendants = true
            svBox.ZIndex           = 2
            svBox.Parent           = wrap
            corner(svBox, 4)

            -- Saturation overlay: left = opaque white (no saturation), right = transparent (full saturation)
            local satOv = Instance.new("Frame")
            satOv.Size                   = UDim2.new(1, 0, 1, 0)
            satOv.BackgroundColor3       = Color3.new(1, 1, 1)
            satOv.BackgroundTransparency = 0
            satOv.BorderSizePixel        = 0
            satOv.ZIndex                 = 3
            satOv.Parent                 = svBox
            local satUIG = Instance.new("UIGradient")
            satUIG.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),   -- left: fully white (desaturated)
                NumberSequenceKeypoint.new(1, 1),   -- right: transparent (full saturation)
            })
            satUIG.Rotation = 0   -- 0° = left→right
            satUIG.Parent   = satOv

            -- Value overlay: top = transparent (bright), bottom = opaque black (dark)
            local valOv = Instance.new("Frame")
            valOv.Size                   = UDim2.new(1, 0, 1, 0)
            valOv.BackgroundColor3       = Color3.new(0, 0, 0)
            valOv.BackgroundTransparency = 0
            valOv.BorderSizePixel        = 0
            valOv.ZIndex                 = 4
            valOv.Parent                 = svBox
            local valUIG = Instance.new("UIGradient")
            valUIG.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),   -- top: transparent (full brightness)
                NumberSequenceKeypoint.new(1, 0),   -- bottom: opaque black (zero brightness)
            })
            valUIG.Rotation = 90  -- 90° = top→bottom
            valUIG.Parent   = valOv

            -- SV crosshair cursor
            local svCursor = Instance.new("Frame")
            svCursor.Size             = UDim2.new(0, 10, 0, 10)
            svCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
            svCursor.Position         = UDim2.new(s, 0, 1 - v, 0)
            svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            svCursor.BorderSizePixel  = 0
            svCursor.ZIndex           = 5
            svCursor.Parent           = svBox
            corner(svCursor, 5)
            stroke(svCursor, Color3.new(0, 0, 0), 0.4)

            -- Hue strip (vertical rainbow): parented to wrap, to the right of svBox
            local hueBar = Instance.new("Frame")
            hueBar.Size             = UDim2.new(0, 14, 0, 80)
            hueBar.Position         = UDim2.new(1, -14, 0, 22)
            hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
            hueBar.BorderSizePixel  = 0
            hueBar.ZIndex           = 2
            hueBar.Parent           = wrap
            corner(hueBar, 4)
            local hueUIG = Instance.new("UIGradient")
            hueUIG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,      1, 1)),
                ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166,  1, 1)),
                ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,  1, 1)),
                ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5,    1, 1)),
                ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666,  1, 1)),
                ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,  1, 1)),
                ColorSequenceKeypoint.new(1,     Color3.fromHSV(0,      1, 1)),
            })
            hueUIG.Rotation = 90  -- 90° = top (H=0/red) → bottom (H=1/red again)
            hueUIG.Parent   = hueBar

            -- Hue cursor (horizontal bar across the strip)
            local hueCursor = Instance.new("Frame")
            hueCursor.Size             = UDim2.new(1, 4, 0, 4)
            hueCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
            hueCursor.Position         = UDim2.new(0.5, 0, h, 0)
            hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            hueCursor.BorderSizePixel  = 0
            hueCursor.ZIndex           = 3
            hueCursor.Parent           = hueBar
            corner(hueCursor, 2)
            stroke(hueCursor, Color3.new(0, 0, 0), 0.4)

            local function updateColor(fire)
                local color = Color3.fromHSV(h, s, v)
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svCursor.Position      = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position     = UDim2.new(0.5, 0, h, 0)
                swatch.BackgroundColor3 = color
                hub._cfgState[tabTitle .. ">" .. secTitle .. ">" .. (copts.Title or "Color")] = {
                    r = math.round(color.R * 255),
                    g = math.round(color.G * 255),
                    b = math.round(color.B * 255),
                }
                if fire and copts.Callback then copts.Callback(color) end
            end

            cfgReg(copts.Title or "Color",
                {r = math.round(defColor.R*255), g = math.round(defColor.G*255), b = math.round(defColor.B*255)},
                function(tbl)
                    if type(tbl) == "table" then
                        local c = Color3.fromRGB(tbl.r or 255, tbl.g or 255, tbl.b or 255)
                        h, s, v = Color3.toHSV(c)
                        updateColor(false)
                    end
                end
            )

            -- Hit areas for dragging
            local svDrag, hueDrag = false, false

            local svHit = Instance.new("TextButton")
            svHit.Size               = UDim2.new(1, 0, 1, 0)
            svHit.BackgroundTransparency = 1
            svHit.Text               = ""
            svHit.ZIndex             = 6
            svHit.Parent             = svBox
            svHit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
            end)

            local hueHit = Instance.new("TextButton")
            hueHit.Size               = UDim2.new(1, 0, 1, 0)
            hueHit.BackgroundTransparency = 1
            hueHit.Text               = ""
            hueHit.ZIndex             = 4
            hueHit.Parent             = hueBar
            hueHit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
            end)

            UIS.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if svDrag then
                    local abs = svBox.AbsolutePosition
                    local sz  = svBox.AbsoluteSize
                    s = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
                    v = 1 - math.clamp((i.Position.Y - abs.Y) / sz.Y, 0, 1)
                    updateColor(true)
                elseif hueDrag then
                    local abs = hueBar.AbsolutePosition
                    local sz  = hueBar.AbsoluteSize
                    h = math.clamp((i.Position.Y - abs.Y) / sz.Y, 0, 0.9999)
                    updateColor(true)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    svDrag = false; hueDrag = false
                end
            end)
        end

        return Sec
    end

    return Tab
end

return Phantom
