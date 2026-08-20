--[[
    ════════════════════════════════════════════════════════════════════════
    YINYANG EXTERNAL SCRIPT — FOVAdjust
    ════════════════════════════════════════════════════════════════════════
    Panel arrastrable para ajustar el FOV de la cámara en vivo.
    Mismo estilo visual que HideGuis / la librería (pill, glassy gradient,
    stroke animado). Sigue la misma convención de scripts externos:
    registra _G["_YY_STOP_FOVAdjust"] al final para poder desactivarse
    desde Tab:CreateScriptToggle() sin dejar residuos.
    ════════════════════════════════════════════════════════════════════════
]]

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local lp            = Players.LocalPlayer
local pg            = lp:WaitForChild("PlayerGui")

-- Limpiar instancia previa (si el script se re-ejecuta o la librería lo recarga)
if _G["_YY_STOP_FOVAdjust"] then
    _G["_YY_STOP_FOVAdjust"]()
end
local prevGui = pg:FindFirstChild("_FOVAdjust")
if prevGui then prevGui:Destroy() end

-- ── Config ────────────────────────────────────────────────────
local DEFAULT_FOV = 70
local MIN_FOV     = 10
local MAX_FOV     = 120
local STEP        = 5
local currentFov  = DEFAULT_FOV

-- ── Paleta Dark (idéntica al tema Dark de la librería) ──────────
local BG        = Color3.fromRGB(40,  40,  45)    -- Secondary
local ACCENT    = Color3.fromRGB(15,  15,  15)    -- Accent (negro)
local BTN_BG    = Color3.fromRGB(58,  58,  64)    -- botones, un poco más claro que el panel

-- ── ScreenGui ─────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "_FOVAdjust"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 9999
gui.Parent         = pg

-- ── Panel principal ──────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Size                   = UDim2.fromOffset(190, 52)
panel.Position                = UDim2.new(0, 20, 0, 110)
panel.BackgroundColor3        = BG
panel.BackgroundTransparency  = 0.30
panel.BorderSizePixel         = 0
panel.ZIndex                  = 2
panel.Parent                  = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent       = panel

-- UIGradient glassy (idéntico al FloatingToggle de la librería)
local glassy = Instance.new("UIGradient")
glassy.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(180, 185, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 243, 250)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(180, 185, 200)),
})
glassy.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.45),
    NumberSequenceKeypoint.new(0.5, 0.15),
    NumberSequenceKeypoint.new(1,   0.45),
})
glassy.Rotation = 90
glassy.Parent   = panel

-- UIStroke animado (el efecto de borde de la librería)
local stroke = Instance.new("UIStroke")
stroke.Thickness    = 2.5
stroke.Color        = ACCENT
stroke.Transparency = 0.20
stroke.LineJoinMode  = Enum.LineJoinMode.Round
stroke.Parent        = panel

-- UIGradient en el stroke (sweep animado) — mismos valores que HideGuis
local h, s, v     = Color3.toHSV(ACCENT)
local accentLight = Color3.fromHSV(h, math.max(0, s - 0.3), math.min(1, v + 0.25))
local accentDark  = Color3.fromHSV(h, math.min(1, s + 0.1), math.max(0, v - 0.25))

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   accentDark),
    ColorSequenceKeypoint.new(0.5, accentLight),
    ColorSequenceKeypoint.new(1,   accentDark),
})
strokeGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.4),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1,   0.4),
})
strokeGrad.Offset = Vector2.new(-1.5, 0)
strokeGrad.Parent = stroke

TweenService:Create(
    strokeGrad,
    TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
    { Offset = Vector2.new(1.5, 0) }
):Play()

TweenService:Create(
    stroke,
    TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.0 }
):Play()

-- ── Label de título + valor ──────────────────────────────────
local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(1, -20, 0, 18)
titleLabel.Position              = UDim2.new(0, 10, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "FOV"
titleLabel.TextColor3            = Color3.fromRGB(200, 200, 205)
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.TextSize              = 10
titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
titleLabel.ZIndex                = 3
titleLabel.Parent                = panel

local valueLabel = Instance.new("TextLabel")
valueLabel.Size                   = UDim2.new(1, -20, 0, 20)
valueLabel.Position               = UDim2.new(0, 10, 0, 4)
valueLabel.BackgroundTransparency = 1
valueLabel.Text                   = tostring(DEFAULT_FOV)
valueLabel.TextColor3             = Color3.fromRGB(240, 240, 245)
valueLabel.Font                   = Enum.Font.GothamBlack
valueLabel.TextSize               = 13
valueLabel.TextXAlignment         = Enum.TextXAlignment.Right
valueLabel.ZIndex                 = 3
valueLabel.Parent                 = panel

-- ── Fila de botones ───────────────────────────────────────────
local function makeButton(text, xOffset, width)
    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.fromOffset(width, 24)
    btn.Position            = UDim2.new(0, xOffset, 0, 24)
    btn.BackgroundColor3    = BTN_BG
    btn.Text                = text
    btn.TextColor3          = Color3.fromRGB(235, 235, 240)
    btn.Font                = Enum.Font.GothamBold
    btn.TextSize            = 14
    btn.AutoButtonColor     = false
    btn.ZIndex               = 3
    btn.Parent               = panel

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(72, 72, 80) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = BTN_BG }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(90, 90, 98) }):Play()
    end)

    return btn
end

local minusBtn = makeButton("−", 8, 36)
local plusBtn  = makeButton("+", 50, 36)
local resetBtn = makeButton("Reset", 92, 90)
resetBtn.TextSize = 11

-- ── Lógica de FOV ─────────────────────────────────────────────
local function applyFov()
    local camera = Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = currentFov
    end
    valueLabel.Text = tostring(currentFov)
end

local function setFov(newFov)
    currentFov = math.clamp(newFov, MIN_FOV, MAX_FOV)
    applyFov()
end

minusBtn.MouseButton1Click:Connect(function() setFov(currentFov - STEP) end)
plusBtn.MouseButton1Click:Connect(function()  setFov(currentFov + STEP) end)
resetBtn.MouseButton1Click:Connect(function() setFov(DEFAULT_FOV) end)

-- Reaplicar si la cámara se reemplaza (respawn, cambio de cámara, etc.)
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyFov)
applyFov()

-- ── Drag (mismo patrón que HideGuis: threshold para distinguir tap de drag) ──
local dragging   = false
local moved      = false
local dragOrigin = Vector2.zero
local panelOrigin = UDim2.new()
local THRESHOLD  = 6

local function pointInsideButton(pos, btn)
    local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
    return pos.X >= bp.X and pos.X <= bp.X + bs.X
       and pos.Y >= bp.Y and pos.Y <= bp.Y + bs.Y
end

panel.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        -- No iniciar drag si el toque empezó sobre un botón (deja que el botón haga lo suyo)
        if pointInsideButton(inp.Position, minusBtn)
        or pointInsideButton(inp.Position, plusBtn)
        or pointInsideButton(inp.Position, resetBtn) then
            return
        end
        dragging    = true
        moved       = false
        dragOrigin  = inp.Position
        panelOrigin = panel.Position
    end
end)

UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragOrigin
        if not moved and (math.abs(d.X) > THRESHOLD or math.abs(d.Y) > THRESHOLD) then
            moved = true
        end
        if moved then
            panel.Position = UDim2.new(
                panelOrigin.X.Scale, panelOrigin.X.Offset + d.X,
                panelOrigin.Y.Scale, panelOrigin.Y.Offset + d.Y
            )
        end
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        moved    = false
    end
end)

-- ════════════════════════════════════════════════════════════════════════
-- REGISTRO DE FUNCIÓN DE PARADA — requerido por el sistema de scripts externos
-- ════════════════════════════════════════════════════════════════════════
_G["_YY_STOP_FOVAdjust"] = function()
    local camera = Workspace.CurrentCamera
    if camera then camera.FieldOfView = DEFAULT_FOV end
    pcall(function() gui:Destroy() end)
    _G["_YY_STOP_FOVAdjust"] = nil
end
