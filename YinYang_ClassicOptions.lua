--[[
    YINYANG EXTERNAL SCRIPT — ClassicOptions
    ==========================================
    Archivo único para la pestaña Classic.

    Cada módulo se registra en ModuleFactories con una clave propia y devuelve
    su función de parada. El manifest puede crear un toggle por módulo usando
    el mismo archivo y una clave distinta. La librería coloca
    _G["_YY_CLASSIC_LOADING_KEY"] antes de ejecutar este archivo.

    Para agregar una opción futura:
      1. Crear local function registerNuevaOpcion() ... return stop end.
      2. Añadir NuevaOpcion = registerNuevaOpcion a ModuleFactories.
      3. Añadir al manifest la entrada con key = "NuevaOpcion".
    La librería no necesita modificarse.
]]

local requestedModule = rawget(_G, "_YY_CLASSIC_LOADING_KEY")

-- Detener la instancia anterior del módulo que se va a recargar.
if requestedModule and requestedModule ~= "" then
    local previousStop = _G["_YY_STOP_" .. tostring(requestedModule)]
    if previousStop then pcall(previousStop) end
else
    if _G["_YY_STOP_ClassicOptions"] then
        pcall(_G["_YY_STOP_ClassicOptions"])
    end
end

local function registerHideGuis()
--[[
    ════════════════════════════════════════════════════════════════════════
    YINYANG EXTERNAL SCRIPT — HideGuis
    ════════════════════════════════════════════════════════════════════════

    QUÉ HACE:
        Muestra una pill arrastrable (HIDE / SHOW) que oculta y restaura
        todas las GUIs del jugador y la top bar de Roblox.

    ────────────────────────────────────────────────────────────────────────
    SISTEMA DE SCRIPTS EXTERNOS — CÓMO FUNCIONA
    ────────────────────────────────────────────────────────────────────────
    La librería Yin Yang carga este script con:
        loadstring(game:HttpGet(URL))()

    El botón en la pestaña Classic es un Tab:CreateScriptToggle():
        • Primer toque  → loadstring(game:HttpGet(url))()   (ejecuta este script)
        • Segundo toque → llama _G["_YY_STOP_<scriptKey>"]() y lo pone en nil

    CONVENCIÓN OBLIGATORIA para todo script externo nuevo:
    ──────────────────────────────────────────────────────
    Al FINAL de cada script, registrar siempre:

        _G["_YY_STOP_<scriptKey>"] = function()
            -- restaurar estado si corresponde
            -- destruir la GUI propia del script
            _G["_YY_STOP_<scriptKey>"] = nil
        end

    Donde <scriptKey> coincide exactamente con el 4to argumento de:
        Tab:CreateScriptToggle("ES", "EN", url, "<scriptKey>")

    Cada script es 100% autónomo: maneja su propia GUI y su propio
    estado interno. La librería NO conoce nombres de GUI ni estado.

    ────────────────────────────────────────────────────────────────────────
    PARA AGREGAR UN NUEVO SCRIPT EXTERNO:
    ────────────────────────────────────────────────────────────────────────
    1. Crear el script siguiendo esta misma estructura.
    2. Registrar _G["_YY_STOP_<scriptKey>"] al final (ver convención).
    3. Subir el script al repositorio yin-classic.
    4. Agregar una entrada a manifest.lua con los campos es, en, file y key.
       La librería carga ese manifest en memoria; no es necesario editarla.

    ════════════════════════════════════════════════════════════════════════
]]

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local lp            = Players.LocalPlayer
local pg            = lp:WaitForChild("PlayerGui")

-- Limpiar instancia previa (si el script se re-ejecuta o la librería lo recarga)
local prev = pg:FindFirstChild("_HideGuis")
if prev then prev:Destroy() end

-- ── Paleta Dark (idéntica al tema Dark de la librería) ────────
local BG        = Color3.fromRGB(40,  40,  45)   -- Secondary
local ACCENT    = Color3.fromRGB(255, 255, 255)   -- Accent (blanco)
local ON_COLOR  = Color3.fromRGB(52,  199, 89)    -- ToggleOn

-- ── ScreenGui ─────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "_HideGuis"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 9999
gui.Parent         = pg

-- ── Pill principal ────────────────────────────────────────────
local pill = Instance.new("Frame")
pill.Size                 = UDim2.fromOffset(100, 36)
pill.Position             = UDim2.new(0, 20, 0, 60)
pill.BackgroundColor3     = BG
pill.BackgroundTransparency = 0.30
pill.BorderSizePixel      = 0
pill.ZIndex               = 2
pill.Parent               = gui

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(1, 0)
pillCorner.Parent       = pill

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
glassy.Parent   = pill

-- UIStroke animado (el efecto de borde de la librería)
local stroke = Instance.new("UIStroke")
stroke.Thickness    = 2.5
stroke.Color        = ACCENT
stroke.Transparency = 0.20
stroke.LineJoinMode = Enum.LineJoinMode.Round
stroke.Parent       = pill

-- UIGradient en el stroke (sweep animado)
local h, s, v    = Color3.toHSV(ACCENT)
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

-- Tween sweep: barre de -1.5 a 1.5 en 1.4s, infinito
TweenService:Create(
    strokeGrad,
    TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
    { Offset = Vector2.new(1.5, 0) }
):Play()

-- Tween pulse: opacidad del stroke pulsa en 1.6s, infinito con reversa
TweenService:Create(
    stroke,
    TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.0 }
):Play()

-- ── Label ─────────────────────────────────────────────────────
local label = Instance.new("TextLabel")
label.Size               = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text               = "HIDE"
label.TextColor3         = Color3.fromRGB(240, 240, 240)
label.Font               = Enum.Font.GothamBlack
label.TextSize           = 13
label.TextXAlignment     = Enum.TextXAlignment.Center
label.ZIndex             = 3
label.Parent             = pill

-- ── Botón clickeable (encima de todo) ─────────────────────────
local btn = Instance.new("TextButton")
btn.Size                 = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text                 = ""
btn.ZIndex               = 4
btn.Parent               = pill

-- ── Estado y lógica hide/show ─────────────────────────────────
local hidden      = false
local savedState  = {}
local savedTopBar = {}

local function hideAll()
    savedState  = {}
    savedTopBar = {}

    for _, g in ipairs(pg:GetChildren()) do
        if g ~= gui and g:IsA("ScreenGui") and g.Name ~= "TouchGui" then
            savedState[g] = g.Enabled
            g.Enabled = false
        end
    end

    local folder = game:GetService("CoreGui"):FindFirstChild("TopBarApp")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("ScreenGui") then
                savedTopBar[child] = child.Enabled
                child.Enabled = false
            end
        end
    end

    TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundColor3 = ON_COLOR }):Play()
    label.Text = "SHOW"
    hidden = true
end

local function showAll()
    for g, was in pairs(savedState) do
        if g and g.Parent then g.Enabled = was end
    end
    savedState = {}

    for g, was in pairs(savedTopBar) do
        if g and g.Parent then g.Enabled = was end
    end
    savedTopBar = {}

    TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundColor3 = BG }):Play()
    label.Text = "HIDE"
    hidden = false
end

-- ── Drag con threshold (tap vs drag) ─────────────────────────
local dragging   = false
local moved      = false
local dragOrigin = Vector2.zero
local pillOrigin = UDim2.new()
local THRESHOLD  = 6

btn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging   = true
        moved      = false
        dragOrigin = inp.Position
        pillOrigin = pill.Position
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
            pill.Position = UDim2.new(
                pillOrigin.X.Scale, pillOrigin.X.Offset + d.X,
                pillOrigin.Y.Scale, pillOrigin.Y.Offset + d.Y
            )
        end
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging and not moved then
            if hidden then showAll() else hideAll() end
        end
        dragging = false
        moved    = false
    end
end)

-- ════════════════════════════════════════════════════════════════════════
-- REGISTRO DE FUNCIÓN DE PARADA — requerido por el sistema de scripts externos
-- La librería llama a _G["_YY_STOP_HideGuis"]() al presionar el botón por segunda vez.
-- Restaura las GUIs si estaban ocultas, destruye esta GUI y limpia el registro.
-- ════════════════════════════════════════════════════════════════════════
return function()
    if hidden then showAll() end
    pcall(function() gui:Destroy() end)
end

end

local function registerFOVAdjust()
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
return function()
    local camera = Workspace.CurrentCamera
    if camera then camera.FieldOfView = DEFAULT_FOV end
    pcall(function() gui:Destroy() end)
end

end

local function registerWaypoint()
-- Waypoint — estilo HideGuis-7.lua
-- GUI local, movible y visualmente consistente con el pill/glass Yin Yang.
-- Guarda el CFrame del HumanoidRootPart actual y permite volver al último punto.
-- No modifica HideGuis ni la librería Yin Yang.

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local lp            = Players.LocalPlayer
local pg            = lp:WaitForChild("PlayerGui")

local GUI_NAME = "_WaypointHideGuisStyle"
local MARKER_NAME = "__YY_LocalWaypointMarker"

-- Limpiar únicamente una ejecución anterior de este script.
local previousGui = pg:FindFirstChild(GUI_NAME)
if previousGui then
    pcall(function() previousGui:Destroy() end)
end
local previousMarker = workspace:FindFirstChild(MARKER_NAME)
if previousMarker then
    pcall(function() previousMarker:Destroy() end)
end

-- Paleta oscurecida (más contraste, menos gris medio).
local BG        = Color3.fromRGB(16, 16, 20)
local ACCENT    = Color3.fromRGB(255, 255, 255)
local ON_COLOR  = Color3.fromRGB(52, 199, 89)
local TEXT      = Color3.fromRGB(240, 240, 240)
local DIM_TEXT  = Color3.fromRGB(190, 193, 202)
local SAVE_BLUE = Color3.fromRGB(35, 50, 85)
local RETURN_RED = Color3.fromRGB(65, 32, 42)
local AUTOTP_COLOR = Color3.fromRGB(45, 35, 70)

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = pg

local panel = Instance.new("Frame")
panel.Name = "WaypointPanel"
panel.Size = UDim2.fromOffset(200, 142)
panel.Position = UDim2.new(0, 20, 0, 105)
panel.BackgroundColor3 = BG
panel.BackgroundTransparency = 0.22
panel.BorderSizePixel = 0
panel.ZIndex = 2
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 13)
panelCorner.Parent = panel

local glassy = Instance.new("UIGradient")
glassy.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 185, 200)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 243, 250)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 185, 200)),
})
glassy.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.58),
    NumberSequenceKeypoint.new(0.5, 0.30),
    NumberSequenceKeypoint.new(1, 0.58),
})
glassy.Rotation = 90
glassy.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Name = "AnimatedBorder"
panelStroke.Thickness = 2.5
panelStroke.Color = ACCENT
panelStroke.Transparency = 0.20
panelStroke.LineJoinMode = Enum.LineJoinMode.Round
panelStroke.Parent = panel

local h, s, v = Color3.toHSV(ACCENT)
local accentLight = Color3.fromHSV(h, math.max(0, s - 0.3), math.min(1, v + 0.25))
local accentDark = Color3.fromHSV(h, math.min(1, s + 0.1), math.max(0, v - 0.25))

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Name = "AnimatedSweep"
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, accentDark),
    ColorSequenceKeypoint.new(0.5, accentLight),
    ColorSequenceKeypoint.new(1, accentDark),
})
strokeGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.4),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 0.4),
})
strokeGrad.Offset = Vector2.new(-1.5, 0)
strokeGrad.Parent = panelStroke

TweenService:Create(
    strokeGrad,
    TweenInfo.new(1.4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
    {Offset = Vector2.new(1.5, 0)}
):Play()
TweenService:Create(
    panelStroke,
    TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Transparency = 0.0}
):Play()

-- Barra superior: también funciona como zona de arrastre.
local dragBar = Instance.new("Frame")
dragBar.Name = "DragBar"
dragBar.Size = UDim2.new(1, -12, 0, 25)
dragBar.Position = UDim2.fromOffset(6, 6)
dragBar.BackgroundColor3 = BG
dragBar.BackgroundTransparency = 0.08
dragBar.BorderSizePixel = 0
dragBar.ZIndex = 3
dragBar.Parent = panel

local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 9)
dragCorner.Parent = dragBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "WAYPOINT"
title.TextColor3 = TEXT
title.Font = Enum.Font.GothamBlack
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 4
title.Parent = dragBar

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -20, 0, 16)
status.Position = UDim2.fromOffset(10, 34)
status.BackgroundTransparency = 1
status.Text = "Sin waypoint guardado"
status.TextColor3 = DIM_TEXT
status.Font = Enum.Font.Gotham
status.TextSize = 9
status.TextTruncate = Enum.TextTruncate.AtEnd
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 3
status.Parent = panel

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createAction(name, text, color, position, width)
    local holder = Instance.new("Frame")
    holder.Name = name .. "Holder"
    holder.Size = UDim2.fromOffset(width, 37)
    holder.Position = position
    holder.BackgroundColor3 = color
    holder.BackgroundTransparency = 0.16
    holder.BorderSizePixel = 0
    holder.ZIndex = 3
    holder.Parent = panel
    addCorner(holder, 9)

    local holderStroke = Instance.new("UIStroke")
    holderStroke.Name = "Stroke"
    holderStroke.Color = ACCENT
    holderStroke.Thickness = 1.2
    holderStroke.Transparency = 0.52
    holderStroke.LineJoinMode = Enum.LineJoinMode.Round
    holderStroke.Parent = holder

    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = text
    button.TextColor3 = TEXT
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 10
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.ZIndex = 4
    button.Parent = holder

    button.MouseEnter:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.12), {
            BackgroundTransparency = 0.02,
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.16), {
            BackgroundTransparency = 0.16,
        }):Play()
    end)

    return button, holder
end

local saveButton = createAction(
    "SaveWaypoint",
    "SAVE",
    SAVE_BLUE,
    UDim2.fromOffset(10, 56),
    82
)
local returnButton = createAction(
    "ReturnWaypoint",
    "RETURN",
    RETURN_RED,
    UDim2.fromOffset(100, 56),
    82
)
local autoTPButton, autoTPHolder = createAction(
    "AutoTeleport",
    "AUTO TP: OFF",
    AUTOTP_COLOR,
    UDim2.fromOffset(10, 96),
    172
)

local waypointCFrame = nil
local waypointMarker = nil

local function getCharacterRoot()
    local character = lp.Character
    if not character then return nil, nil end
    local root = character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    return character, root
end

local function setStatus(text, color)
    status.Text = tostring(text)
    status.TextColor3 = color or DIM_TEXT
end

local function removeMarker()
    if waypointMarker then
        pcall(function() waypointMarker:Destroy() end)
        waypointMarker = nil
    end
end

local function createMarker(cframe)
    removeMarker()

    local marker = Instance.new("Part")
    marker.Name = MARKER_NAME
    marker.Shape = Enum.PartType.Ball
    marker.Size = Vector3.new(1.35, 1.35, 1.35)
    marker.CFrame = cframe + Vector3.new(0, 1.1, 0)
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanTouch = false
    marker.CanQuery = false
    marker.Material = Enum.Material.Neon
    marker.Color = ACCENT
    marker.Transparency = 0.18
    marker.CastShadow = false
    marker.Parent = workspace

    local light = Instance.new("PointLight")
    light.Name = "WaypointGlow"
    light.Color = ACCENT
    light.Brightness = 1.5
    light.Range = 8
    light.Parent = marker

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WaypointLabel"
    billboard.Size = UDim2.fromOffset(120, 28)
    billboard.StudsOffset = Vector3.new(0, 1.3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150
    billboard.Parent = marker

    local markerText = Instance.new("TextLabel")
    markerText.Size = UDim2.fromScale(1, 1)
    markerText.BackgroundTransparency = 1
    markerText.Text = "WAYPOINT"
    markerText.TextColor3 = TEXT
    markerText.TextStrokeTransparency = 0.45
    markerText.Font = Enum.Font.GothamBlack
    markerText.TextSize = 10
    markerText.Parent = billboard

    waypointMarker = marker
end

saveButton.Activated:Connect(function()
    local character, root = getCharacterRoot()
    if not character or not root then
        setStatus("No se encontró el personaje", Color3.fromRGB(255, 150, 150))
        return
    end

    waypointCFrame = root.CFrame
    createMarker(waypointCFrame)
    TweenService:Create(panel, TweenInfo.new(0.15), {
        BackgroundColor3 = ON_COLOR,
    }):Play()
    setStatus("Waypoint guardado", Color3.fromRGB(220, 255, 225))
end)

returnButton.Activated:Connect(function()
    if not waypointCFrame then
        setStatus("Primero guarda un waypoint", Color3.fromRGB(255, 210, 135))
        return
    end

    local character, root = getCharacterRoot()
    if not character or not root then
        setStatus("No se encontró el personaje", Color3.fromRGB(255, 150, 150))
        return
    end

    local ok, err = pcall(function()
        character:PivotTo(waypointCFrame)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    if ok then
        setStatus("Volviste al waypoint", Color3.fromRGB(220, 255, 225))
    else
        setStatus("No se pudo volver: " .. tostring(err), Color3.fromRGB(255, 150, 150))
    end
end)

-- Auto TP: mientras está activo, teletransporta al waypoint cada 0.5s.
local autoTPEnabled = false

local function autoTPLoop()
    while autoTPEnabled do
        if waypointCFrame then
            local character, root = getCharacterRoot()
            if character and root then
                pcall(function()
                    character:PivotTo(waypointCFrame)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
        task.wait(0.5)
    end
end

autoTPButton.Activated:Connect(function()
    if not autoTPEnabled then
        if not waypointCFrame then
            setStatus("Primero guarda un waypoint", Color3.fromRGB(255, 210, 135))
            return
        end
        autoTPEnabled = true
        autoTPHolder.BackgroundColor3 = ON_COLOR
        autoTPButton.Text = "AUTO TP: ON"
        setStatus("Auto TP activado (cada 0.5s)", Color3.fromRGB(220, 255, 225))
        task.spawn(autoTPLoop)
    else
        autoTPEnabled = false
        autoTPHolder.BackgroundColor3 = AUTOTP_COLOR
        autoTPButton.Text = "AUTO TP: OFF"
        setStatus("Auto TP desactivado", DIM_TEXT)
    end
end)

-- Arrastre con threshold, igual que HideGuis-7.lua: tocar no mueve; arrastrar sí.
local dragging = false
local moved = false
local dragOrigin = Vector2.zero
local panelOrigin = UDim2.new()
local THRESHOLD = 6

dragBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        moved = false
        dragOrigin = input.Position
        panelOrigin = panel.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragOrigin
        if not moved and (math.abs(delta.X) > THRESHOLD or math.abs(delta.Y) > THRESHOLD) then
            moved = true
        end
        if moved then
            panel.Position = UDim2.new(
                panelOrigin.X.Scale, panelOrigin.X.Offset + delta.X,
                panelOrigin.Y.Scale, panelOrigin.Y.Offset + delta.Y
            )
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        moved = false
    end
end)

lp.CharacterRemoving:Connect(function()
    -- El punto se mantiene guardado durante respawns; solo se elimina el marcador
    -- si el workspace lo destruye. RETURN informará si el personaje aún no existe.
end)

-- ════════════════════════════════════════════════════════════════════════
-- REGISTRO DE FUNCIÓN DE PARADA — requerido por el sistema de scripts externos
-- Al desactivar: apaga el auto-teleport, borra el marcador del mundo y la GUI.
-- ════════════════════════════════════════════════════════════════════════
return function()
    autoTPEnabled = false
    removeMarker()
    pcall(function() gui:Destroy() end)
end

end

local function registerPerformanceOptimizer()
--[[
    ════════════════════════════════════════════════════════════════════════
    YINYANG EXTERNAL SCRIPT — PerformanceOptimizer
    ════════════════════════════════════════════════════════════════════════
    Optimización visual local y reversible (particulas, luces, trails,
    sombras, texturas, etc). Panel PRO con rail de iconos + escaneo.
    Sigue la misma convención de scripts externos: al final registra su
    "return function() ... end" de parada, que reutiliza el propio
    GEN[API_NAME].Shutdown ya implementado por el script (restaura todos
    los valores originales, desconecta watchers y destruye su GUI).
    ════════════════════════════════════════════════════════════════════════
]]

--[[
    Yin Yang Performance Optimizer
    Optimización visual local y reversible para experiencias Roblox grandes.

    Seguridad de alcance:
    - No modifica Anchored, CanCollide, CFrame, AssemblyLinearVelocity ni remotes.
    - No destruye instancias.
    - Procesa Workspace por lotes para no bloquear el frame.
    - Guarda los valores originales y permite restaurarlos.

    Uso:
      getgenv().YinYangPerformance.Apply("Ultra")
      getgenv().YinYangPerformance.Restore()
      getgenv().YinYangPerformance.Toggle()

    En PC: F6 = aplicar, F7 = restaurar, F8 = alternar.
    En móvil se aplica automáticamente si AutoApply = true.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService") -- añadido: necesario para las animaciones de la GUI nueva (no estaba en el original)

local GEN = (getgenv and getgenv()) or _G
local API_NAME = "YinYangPerformance"

if GEN[API_NAME] and type(GEN[API_NAME].Shutdown) == "function" then
    pcall(GEN[API_NAME].Shutdown)
end

local CONFIG = {
    AutoApply = false,
    DefaultProfile = "Ultra",
    BatchSize = 80,
    YieldSeconds = 0.01,
    WatchNewInstances = true,

    Profiles = {
        Balanced = {
            DisableParticles = true,
            DisableTrailsBeams = true,
            DisableLights = true,
            DisablePostEffects = true,
            DisableHighlights = true,
            HideAccessories = false,
            HideClothing = false,
            HideWorldTextures = false,
            DisableShadows = false,
            SimplifyBodyColors = false,
            DisableTerrainDecoration = false,
        },
        Performance = {
            DisableParticles = true,
            DisableTrailsBeams = true,
            DisableLights = true,
            DisablePostEffects = true,
            DisableHighlights = true,
            HideAccessories = true,
            HideClothing = true,
            HideWorldTextures = false,
            DisableShadows = true,
            SimplifyBodyColors = true,
            DisableTerrainDecoration = true,
        },
        Ultra = {
            DisableParticles = true,
            DisableTrailsBeams = true,
            DisableLights = true,
            DisablePostEffects = true,
            DisableHighlights = true,
            HideAccessories = true,
            HideClothing = true,
            HideWorldTextures = true,
            DisableShadows = true,
            SimplifyBodyColors = true,
            DisableTerrainDecoration = true,
        },
    },
}

local state = {
    Enabled = false,
    ProfileName = nil,
    Profile = nil,
    Records = {},
    Queue = {},
    QueueHead = 1,
    QueueTail = 0,
    QueueCount = 0,
    QueueSet = {},
    Processing = false,
    Token = 0,
    Connections = {},
    Stats = {
        Processed = 0,
        Changed = 0,
        Restored = 0,
    },
    -- Contadores por categoría, solo para alimentar el resumen del LOG (no afecta la lógica de optimización)
    CategoryChanged = {
        Particles = 0, TrailsBeams = 0, Lights = 0, PostEffects = 0, Highlights = 0,
        Textures = 0, Clothing = 0, Accessories = 0, Shadows = 0, Terrain = 0,
    },
}

local function safeGet(instance, property)
    local ok, value = pcall(function()
        return instance[property]
    end)
    if ok then
        return true, value
    end
    return false, nil
end

local function safeSet(instance, property, value)
    return pcall(function()
        instance[property] = value
    end)
end

local function remember(instance, property)
    local record = state.Records[instance]
    if not record then
        record = {}
        state.Records[instance] = record
    end

    if record[property] == nil then
        local ok, value = safeGet(instance, property)
        if ok then
            record[property] = value
        end
    end

    return record[property]
end

local function setIfDifferent(instance, property, value)
    local currentOk, current = safeGet(instance, property)
    if not currentOk or current == value then
        return false
    end

    remember(instance, property)
    if safeSet(instance, property, value) then
        state.Stats.Changed = state.Stats.Changed + 1
        return true
    end

    return false
end

local function bumpCategory(category)
    state.CategoryChanged[category] = (state.CategoryChanged[category] or 0) + 1
end

local function hasAncestorOfClass(instance, className)
    local ok, result = pcall(function()
        return instance:FindFirstAncestorWhichIsA(className) ~= nil
    end)
    return ok and result
end

local function isCharacterAccessoryPart(instance)
    local ok, result = pcall(function()
        local accessory = instance:FindFirstAncestorWhichIsA("Accessory")
        local model = accessory and accessory:FindFirstAncestorWhichIsA("Model")
        return accessory ~= nil and model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
    end)
    return ok and result
end

local function isHumanoidCharacter(instance)
    return hasAncestorOfClass(instance, "Humanoid")
end

local function processPostEffect(instance, profile)
    if not profile.DisablePostEffects then
        return
    end

    if instance:IsA("PostEffect") then
        if setIfDifferent(instance, "Enabled", false) then bumpCategory("PostEffects") end
    elseif instance:IsA("Atmosphere") then
        local a = setIfDifferent(instance, "Density", 0)
        local b = setIfDifferent(instance, "Haze", 0)
        local c = setIfDifferent(instance, "Glare", 0)
        if a or b or c then bumpCategory("PostEffects") end
    end
end

local function processVisualInstance(instance, profile)
    if not instance or not instance.Parent then
        return
    end

    state.Stats.Processed = state.Stats.Processed + 1
    processPostEffect(instance, profile)

    if profile.DisableParticles then
        if instance:IsA("ParticleEmitter") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
            if setIfDifferent(instance, "Enabled", false) then bumpCategory("Particles") end
        end
    end

    if profile.DisableTrailsBeams then
        if instance:IsA("Trail") or instance:IsA("Beam") then
            if setIfDifferent(instance, "Enabled", false) then bumpCategory("TrailsBeams") end
        end
    end

    if profile.DisableLights and (instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight")) then
        if setIfDifferent(instance, "Enabled", false) then bumpCategory("Lights") end
    end

    if profile.DisableHighlights and instance:IsA("Highlight") then
        if setIfDifferent(instance, "Enabled", false) then bumpCategory("Highlights") end
    end

    if profile.HideWorldTextures and (instance:IsA("Decal") or instance:IsA("Texture")) then
        if setIfDifferent(instance, "Transparency", 1) then bumpCategory("Textures") end
    end

    if profile.HideClothing and (instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("ShirtGraphic")) then
        local changed = false
        if instance:IsA("Shirt") then
            changed = setIfDifferent(instance, "ShirtTemplate", "")
        elseif instance:IsA("Pants") then
            changed = setIfDifferent(instance, "PantsTemplate", "")
        elseif instance:IsA("ShirtGraphic") then
            changed = setIfDifferent(instance, "Graphic", "")
        end
        if changed then bumpCategory("Clothing") end
    end

    if profile.SimplifyBodyColors and instance:IsA("BodyColors") then
        local neutral = BrickColor.new("Medium stone grey")
        setIfDifferent(instance, "HeadColor", neutral)
        setIfDifferent(instance, "LeftArmColor", neutral)
        setIfDifferent(instance, "RightArmColor", neutral)
        setIfDifferent(instance, "LeftLegColor", neutral)
        setIfDifferent(instance, "RightLegColor", neutral)
        setIfDifferent(instance, "TorsoColor", neutral)
    end

    if instance:IsA("BasePart") then
        if profile.DisableShadows then
            if setIfDifferent(instance, "CastShadow", false) then bumpCategory("Shadows") end
        end

        if profile.HideAccessories and isCharacterAccessoryPart(instance) then
            if setIfDifferent(instance, "LocalTransparencyModifier", 1) then bumpCategory("Accessories") end
        end
    end
end

local function processTerrain(profile)
    if not profile.DisableTerrainDecoration then
        return
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        if setIfDifferent(terrain, "Decoration", false) then bumpCategory("Terrain") end
    end
end

local function enqueue(instance)
    if not instance or state.QueueSet[instance] then
        return
    end
    state.QueueSet[instance] = true
    state.QueueTail = state.QueueTail + 1
    state.Queue[state.QueueTail] = instance
    state.QueueCount = state.QueueCount + 1
end

local function disconnectConnections()
    for _, connection in ipairs(state.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    state.Connections = {}
end

local function processQueue(token)
    if state.Processing then
        return
    end

    state.Processing = true
    task.spawn(function()
        while state.Enabled and token == state.Token and state.QueueCount > 0 do
            local batch = math.max(1, tonumber(CONFIG.BatchSize) or 80)
            local processedInBatch = 0

            while state.Enabled and token == state.Token and processedInBatch < batch and state.QueueCount > 0 do
                local instance = state.Queue[state.QueueHead]
                state.Queue[state.QueueHead] = nil
                state.QueueHead = state.QueueHead + 1
                state.QueueCount = state.QueueCount - 1
                state.QueueSet[instance] = nil
                processVisualInstance(instance, state.Profile)
                processedInBatch = processedInBatch + 1
            end

            if state.Enabled and token == state.Token and state.QueueCount > 0 then
                task.wait(CONFIG.YieldSeconds)
            end
        end

        state.Processing = false
    end)
end

local function enqueueWorkspaceSnapshot()
    local descendants = Workspace:GetDescendants()
    for index, instance in ipairs(descendants) do
        enqueue(instance)
        if index % math.max(1, CONFIG.BatchSize) == 0 then
            task.wait(CONFIG.YieldSeconds)
        end
    end
end

local function installWatchers(token)
    if not CONFIG.WatchNewInstances then
        return
    end

    state.Connections[#state.Connections + 1] = Workspace.DescendantAdded:Connect(function(instance)
        if state.Enabled and token == state.Token then
            enqueue(instance)
            processQueue(token)
        end
    end)

    state.Connections[#state.Connections + 1] = Lighting.DescendantAdded:Connect(function(instance)
        if state.Enabled and token == state.Token then
            enqueue(instance)
            processQueue(token)
        end
    end)
end

local function restoreAll()
    state.Token = state.Token + 1
    state.Enabled = false
    disconnectConnections()
    state.Queue = {}
    state.QueueHead = 1
    state.QueueTail = 0
    state.QueueCount = 0
    state.QueueSet = {}
    state.Processing = false

    for instance, record in pairs(state.Records) do
        for property, originalValue in pairs(record) do
            if instance and instance.Parent then
                if safeSet(instance, property, originalValue) then
                    state.Stats.Restored = state.Stats.Restored + 1
                end
            end
        end
    end

    state.Records = {}
    state.Profile = nil
    state.ProfileName = nil
    for category in pairs(state.CategoryChanged) do
        state.CategoryChanged[category] = 0
    end
end

local function applyProfile(profileName)
    local profile = CONFIG.Profiles[profileName] or CONFIG.Profiles[CONFIG.DefaultProfile]
    if not profile then
        warn("YinYang Performance: perfil inexistente")
        return false
    end

    restoreAll()
    state.Token = state.Token + 1
    local token = state.Token
    state.Enabled = true
    state.ProfileName = profileName or CONFIG.DefaultProfile
    state.Profile = profile
    state.Stats.Processed = 0
    state.Stats.Changed = 0
    state.Stats.Restored = 0

    processTerrain(profile)
    installWatchers(token)

    task.spawn(function()
        enqueueWorkspaceSnapshot()
        processQueue(token)
    end)

    print("YinYang Performance: perfil " .. tostring(state.ProfileName) .. " aplicado por lotes")
    return true
end

local function toggle()
    if state.Enabled then
        restoreAll()
        print("YinYang Performance: restaurado")
        return false
    end

    return applyProfile(state.ProfileName or CONFIG.DefaultProfile)
end

local function getStats()
    return {
        Enabled = state.Enabled,
        Profile = state.ProfileName,
        Processed = state.Stats.Processed,
        Changed = state.Stats.Changed,
        Restored = state.Stats.Restored,
        Pending = state.QueueCount,
    }
end

local CATEGORY_ORDER = {
    "Particles",
    "TrailsBeams",
    "Lights",
    "PostEffects",
    "Highlights",
    "Textures",
    "Clothing",
    "Accessories",
    "Shadows",
    "Terrain",
}

local CATEGORY_LABELS = {
    Particles = "Partículas / humo / fuego",
    TrailsBeams = "Trails y beams",
    Lights = "Luces dinámicas",
    PostEffects = "Postprocesado y atmósfera",
    Highlights = "Highlights",
    Textures = "Decals y texturas",
    Clothing = "Ropa y camisetas",
    Accessories = "Accesorios de personajes",
    Shadows = "Sombras",
    Terrain = "Decoración del terreno",
}

local diagnostic = {
    Running = false,
    Token = 0,
    Counts = {},
    Samples = {},
    Total = 0,
    Selected = {},
}

for _, category in ipairs(CATEGORY_ORDER) do
    diagnostic.Counts[category] = 0
    diagnostic.Samples[category] = {}
    diagnostic.Selected[category] = true
end

local ui = {
    ScreenGui = nil,
    Panel = nil,
    Rows = {},
    Status = nil,
    ScanButton = nil,
    ApplyButton = nil,
    RestoreButton = nil,
    Scale = nil,
}

local function classify(instance)
    if instance:IsA("ParticleEmitter") or instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
        return "Particles"
    elseif instance:IsA("Trail") or instance:IsA("Beam") then
        return "TrailsBeams"
    elseif instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
        return "Lights"
    elseif instance:IsA("PostEffect") or instance:IsA("Atmosphere") then
        return "PostEffects"
    elseif instance:IsA("Highlight") then
        return "Highlights"
    elseif instance:IsA("Decal") or instance:IsA("Texture") then
        return "Textures"
    elseif instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("ShirtGraphic") then
        return "Clothing"
    elseif instance:IsA("BasePart") and isCharacterAccessoryPart(instance) then
        return "Accessories"
    elseif instance:IsA("BasePart") then
        local ok, casts = safeGet(instance, "CastShadow")
        if ok and casts then
            return "Shadows"
        end
    end
    return nil
end

local function formatNumber(value)
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(value)
end

local function refreshRows()
    for _, category in ipairs(CATEGORY_ORDER) do
        local row = ui.Rows[category]
        if row then
            local mark = diagnostic.Selected[category] and "☑" or "☐"
            row.Text = mark .. "  " .. CATEGORY_LABELS[category] .. "  [" .. formatNumber(diagnostic.Counts[category] or 0) .. "]"
            row.TextColor3 = diagnostic.Selected[category] and Color3.fromRGB(235, 245, 255) or Color3.fromRGB(125, 135, 150)
        end
    end
end

local function updateStatus(message)
    if ui.Status then
        ui.Status.Text = message
    end
end

local function buildSelectionProfile()
    return {
        DisableParticles = diagnostic.Selected.Particles,
        DisableTrailsBeams = diagnostic.Selected.TrailsBeams,
        DisableLights = diagnostic.Selected.Lights,
        DisablePostEffects = diagnostic.Selected.PostEffects,
        DisableHighlights = diagnostic.Selected.Highlights,
        HideWorldTextures = diagnostic.Selected.Textures,
        HideClothing = diagnostic.Selected.Clothing,
        HideAccessories = diagnostic.Selected.Accessories,
        DisableShadows = diagnostic.Selected.Shadows,
        SimplifyBodyColors = false,
        DisableTerrainDecoration = diagnostic.Selected.Terrain,
    }
end

local function scanEnvironment()
    if diagnostic.Running then
        return
    end

    diagnostic.Token = diagnostic.Token + 1
    local token = diagnostic.Token
    diagnostic.Running = true
    diagnostic.Total = 0
    for _, category in ipairs(CATEGORY_ORDER) do
        diagnostic.Counts[category] = 0
        diagnostic.Samples[category] = {}
    end
    updateStatus("Escaneando Workspace y Lighting...")
    refreshRows()

    task.spawn(function()
        local all = {}
        local seen = {}
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if not seen[instance] then
                seen[instance] = true
                all[#all + 1] = instance
            end
        end
        for _, instance in ipairs(Lighting:GetDescendants()) do
            if not seen[instance] then
                seen[instance] = true
                all[#all + 1] = instance
            end
        end

        local batch = math.max(1, tonumber(CONFIG.BatchSize) or 80)
        for index, instance in ipairs(all) do
            if token ~= diagnostic.Token then
                return
            end
            local category = classify(instance)
            if category then
                diagnostic.Counts[category] = diagnostic.Counts[category] + 1
                diagnostic.Total = diagnostic.Total + 1
                if #diagnostic.Samples[category] < 3 then
                    diagnostic.Samples[category][#diagnostic.Samples[category] + 1] = instance:GetFullName()
                end
            end
            if index % batch == 0 then
                updateStatus("Escaneando... " .. formatNumber(index) .. " instancias revisadas")
                refreshRows()
                task.wait(CONFIG.YieldSeconds)
            end
        end

        diagnostic.Running = false
        updateStatus("Escaneo terminado: " .. formatNumber(diagnostic.Total) .. " elementos visuales detectados")
        refreshRows()
    end)
end

local function applySelectedCategories()
    if diagnostic.Running then
        updateStatus("Espera a que termine el escaneo")
        return
    end

    local profile = buildSelectionProfile()
    restoreAll()
    state.Token = state.Token + 1
    local token = state.Token
    state.Enabled = true
    state.ProfileName = "Diagnostic"
    state.Profile = profile
    state.Stats.Processed = 0
    state.Stats.Changed = 0
    state.Stats.Restored = 0

    processTerrain(profile)
    installWatchers(token)
    task.spawn(function()
        enqueueWorkspaceSnapshot()
        processQueue(token)
    end)
    updateStatus("Aplicando categorías seleccionadas por lotes...")
end

-- ════════════════════════════════════════════════════════════════════
--  GUI PRO v3 — rediseño con rail de íconos lateral + tamaño responsive
--  real (misma técnica que yin_FIXED: clamp contra ScreenGui.AbsoluteSize,
--  sin UIScale). Nada de esto toca la lógica de optimización de arriba.
-- ════════════════════════════════════════════════════════════════════

-- ── Paleta (tokens del tema "Dark" de yin_FIXED) ──────────────────
local BG_DEEP      = Color3.fromRGB(12, 12, 14)      -- ≈ Theme.Background
local BG_SURFACE   = Color3.fromRGB(40, 40, 45)      -- = Theme.Secondary (tarjetas)
local BG_SURFACE2  = Color3.fromRGB(58, 58, 64)      -- = Theme.AccentOff (hover / track off)
local STROKE_COLOR = Color3.fromRGB(90, 90, 96)      -- = Theme.Stroke
local YIN_COLOR    = Color3.fromRGB(240, 240, 240)
local YANG_COLOR   = Color3.fromRGB(135, 145, 255)   -- identidad única del script
local YANG_COLOR_B = Color3.fromRGB(80, 205, 255)
local ON_COLOR     = Color3.fromRGB(52, 199, 89)     -- = Theme.ToggleOn
local OFF_COLOR    = BG_SURFACE2
local TEXT_MAIN    = Color3.fromRGB(240, 240, 240)   -- = Theme.Text
local TEXT_SUB     = Color3.fromRGB(190, 192, 198)
local TEXT_DIM     = Color3.fromRGB(160, 160, 165)   -- = Theme.TextDim

-- ── Helpers visuales ───────────────────────────────────────────────
local function corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = inst
    return c
end

local function stroke(inst, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = inst
    return s
end

-- Gradiente "glassy" + sweep animado (misma técnica que HideGuis-7.lua: Tween sobre
-- UIGradient/UIStroke, sin loops, así que no genera lag).
local function applyGlassSweep(target, accentA, accentB)
    local glassy = Instance.new("UIGradient")
    glassy.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 64, 78)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 96, 116)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60, 64, 78)),
    })
    glassy.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.55),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(1,   0.55),
    })
    glassy.Rotation = 90
    glassy.Parent = target

    local ring = stroke(target, accentA, 1.6, 0.25)
    local sweep = Instance.new("UIGradient")
    sweep.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   accentB),
        ColorSequenceKeypoint.new(0.5, accentA),
        ColorSequenceKeypoint.new(1,   accentB),
    })
    sweep.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.5),
        NumberSequenceKeypoint.new(0.5, 0.05),
        NumberSequenceKeypoint.new(1,   0.5),
    })
    sweep.Offset = Vector2.new(-1.5, 0)
    sweep.Parent = ring

    TweenService:Create(
        sweep,
        TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
        { Offset = Vector2.new(1.5, 0) }
    ):Play()
    TweenService:Create(
        ring,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.05 }
    ):Play()

    return ring
end

local function makeLabel(parent, text, size, position, textSize, color, font, align)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = size
    lbl.Position = position
    lbl.Text = text
    lbl.TextColor3 = color or TEXT_MAIN
    lbl.Font = font or Enum.Font.Gotham
    lbl.TextSize = textSize or 12
    lbl.TextXAlignment = align or Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

local function makeTextButton(parent, text, size, position, color)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Size = size
    button.Position = position
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 240, 240)
    button.TextSize = 13
    button.AutoButtonColor = true
    button.Parent = parent
    corner(button, UDim.new(0, 10))
    return button
end

-- Chip/badge redondeado (estilo "361 flags" de la referencia Vaystrap)
local function makeChip(parent, text, position, size)
    local chip = Instance.new("Frame")
    chip.BackgroundColor3 = BG_SURFACE2
    chip.BorderSizePixel = 0
    chip.Size = size or UDim2.fromOffset(78, 20)
    chip.Position = position
    chip.Parent = parent
    corner(chip, UDim.new(1, 0))
    local lbl = makeLabel(chip, text, UDim2.new(1, -12, 1, 0), UDim2.fromOffset(6, 0), 10, TEXT_SUB, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    return chip, lbl
end

-- Switch estilo iOS con sombra de profundidad (inspirado en el CreateToggle de yin_FIXED)
local function makeSwitch(parent, position, initial, onChanged)
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 24)
    track.Position = position
    track.BackgroundColor3 = initial and ON_COLOR or OFF_COLOR
    track.BorderSizePixel = 0
    track.Parent = parent
    corner(track, UDim.new(1, 0))

    local knobShadow = Instance.new("Frame")
    knobShadow.Size = UDim2.fromOffset(20, 20)
    knobShadow.AnchorPoint = Vector2.new(0, 0.5)
    knobShadow.Position = UDim2.new(0, 3, 0.5, 1)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.7
    knobShadow.BorderSizePixel = 0
    knobShadow.ZIndex = 2
    knobShadow.Parent = track
    corner(knobShadow, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(20, 20)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 2, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(250, 250, 253)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    corner(knob, UDim.new(1, 0))

    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = ""
    btn.ZIndex = 4
    btn.Parent = track

    local ON_X, OFF_X = 22, 2

    local isOn = initial
    local function set(value, silent)
        isOn = value
        TweenService:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = value and ON_COLOR or OFF_COLOR }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0, value and ON_X or OFF_X, 0.5, 0)
        }):Play()
        TweenService:Create(knobShadow, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0, (value and ON_X or OFF_X) + 1, 0.5, 1)
        }):Play()
        if not silent and onChanged then
            onChanged(value)
        end
    end

    btn.MouseButton1Click:Connect(function()
        set(not isOn)
    end)

    return { Frame = track, Set = set, Get = function() return isOn end }
end

local uiLoopToken = 0

local function makePanel()
    local localPlayer = Players.LocalPlayer
    local playerGui = localPlayer and (localPlayer:FindFirstChildOfClass("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5))
    if not playerGui then
        return
    end

    local old = playerGui:FindFirstChild("YinYangPerformanceDiagnostic")
    if old then
        old:Destroy()
    end

    uiLoopToken = uiLoopToken + 1
    local myToken = uiLoopToken

    local screen = Instance.new("ScreenGui")
    screen.Name = "YinYangPerformanceDiagnostic"
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.DisplayOrder = 9999
    screen.Parent = playerGui
    ui.ScreenGui = screen

    -- ── Panel principal — tamaño responsive real ──────────────────
    -- Misma técnica que Window.UpdateWindowSize de yin_FIXED: preset fijo,
    -- recortado contra el tamaño real de pantalla (92%), sin UIScale.
    local PRESET_W, PRESET_H = 380, 580

    local panel = Instance.new("Frame")
    panel.Name = "OptimizerPanel"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(PRESET_W, PRESET_H)
    panel.BackgroundColor3 = BG_DEEP
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Visible = false
    panel.Parent = screen
    ui.Panel = panel
    corner(panel, UDim.new(0, 16))
    applyGlassSweep(panel, YANG_COLOR, YANG_COLOR_B)

    local function updateWindowSize()
        local avail = screen.AbsoluteSize
        local width, height = PRESET_W, PRESET_H
        if avail.X > 0 and avail.Y > 0 then
            width = math.min(PRESET_W, math.floor(avail.X * 0.92))
            height = math.min(PRESET_H, math.floor(avail.Y * 0.92))
        end
        panel.Size = UDim2.fromOffset(width, height)
    end
    updateWindowSize()
    screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateWindowSize)

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local title = makeLabel(header, "YIN YANG", UDim2.new(1, -100, 0, 20), UDim2.fromOffset(18, 8), 15, Color3.fromRGB(0, 0, 0), Enum.Font.GothamBlack)
    -- Animación "Yin Yang" de la librería: el título alterna negro↔blanco lentamente.
    -- La librería lo hace con RunService.RenderStepped (cálculo de seno por frame);
    -- acá uso un Tween infinito con reverses=true — mismo resultado visual, sin loop por frame.
    TweenService:Create(
        title,
        TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { TextColor3 = Color3.fromRGB(255, 255, 255) }
    ):Play()

    makeLabel(header, "PERFORMANCE OPTIMIZER", UDim2.new(1, -100, 0, 16), UDim2.fromOffset(18, 27), 10, TEXT_DIM, Enum.Font.GothamMedium)

    local close = makeTextButton(header, "×", UDim2.fromOffset(34, 30), UDim2.new(1, -44, 0, 11), BG_SURFACE)
    close.TextSize = 20
    close.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    -- ── Cuerpo: rail de íconos (izquierda) + contenido (derecha) ──
    local RAIL_W = 58
    local FOOTER_H = 96

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -16, 1, -52 - FOOTER_H)
    body.Position = UDim2.fromOffset(8, 52)
    body.BackgroundTransparency = 1
    body.Parent = panel

    local rail = Instance.new("Frame")
    rail.Size = UDim2.new(0, RAIL_W, 1, 0)
    rail.BackgroundColor3 = BG_DEEP
    rail.BackgroundTransparency = 0.1
    rail.BorderSizePixel = 0
    rail.Parent = body
    corner(rail, UDim.new(0, 12))
    stroke(rail, STROKE_COLOR, 1, 0.55)

    local railList = Instance.new("UIListLayout")
    railList.Padding = UDim.new(0, 8)
    railList.SortOrder = Enum.SortOrder.LayoutOrder
    railList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    railList.Parent = rail
    local railPad = Instance.new("UIPadding")
    railPad.PaddingTop = UDim.new(0, 10)
    railPad.Parent = rail

    local function makeRailIcon(glyph, order)
        local cell = Instance.new("Frame")
        cell.Size = UDim2.fromOffset(40, 40)
        cell.BackgroundTransparency = 1
        cell.LayoutOrder = order
        cell.Parent = rail

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = BG_SURFACE
        btn.BorderSizePixel = 0
        btn.Text = glyph
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = TEXT_DIM
        btn.AutoButtonColor = false
        btn.Parent = cell
        corner(btn, UDim.new(0, 11))

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.fromOffset(3, 20)
        indicator.AnchorPoint = Vector2.new(0, 0.5)
        indicator.Position = UDim2.new(0, -7, 0.5, 0)
        indicator.BackgroundColor3 = YANG_COLOR
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.Parent = cell
        corner(indicator, UDim.new(1, 0))

        return btn, indicator
    end

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -RAIL_W - 8, 1, 0)
    content.Position = UDim2.fromOffset(RAIL_W + 8, 0)
    content.BackgroundTransparency = 1
    content.Parent = body

    -- Fondo decorativo del tema Dark de yin_FIXED (mismo asset que usa la librería,
    -- vive detrás de las tarjetas — solo se asoma por los huecos entre ellas).
    -- Transparencia más alta que en la librería (0.1) porque acá hay texto denso
    -- (log de eventos) encima y necesita quedar legible.
    local backgroundArt = Instance.new("ImageLabel")
    backgroundArt.Name = "BackgroundArt"
    backgroundArt.AnchorPoint = Vector2.new(0.5, 0.5)
    backgroundArt.Position = UDim2.fromScale(0.5, 0.5)
    backgroundArt.Size = UDim2.new(1, 20, 1, 20)
    backgroundArt.BackgroundTransparency = 1
    backgroundArt.Image = "rbxassetid://138004303203419"
    backgroundArt.ImageTransparency = 0.82
    backgroundArt.ScaleType = Enum.ScaleType.Crop
    backgroundArt.ZIndex = 1
    backgroundArt.Parent = content
    corner(backgroundArt, UDim.new(0, 10))

    -- ── PESTAÑA LOG ────────────────────────────────────────────
    local logTab = Instance.new("Frame")
    logTab.Size = UDim2.new(1, 0, 1, 0)
    logTab.BackgroundTransparency = 1
    logTab.Visible = true
    logTab.Parent = content

    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, 0, 0, 34)
    statsBar.BackgroundColor3 = BG_SURFACE
    statsBar.BorderSizePixel = 0
    statsBar.Parent = logTab
    corner(statsBar, UDim.new(0, 10))
    local statsLabel = makeLabel(statsBar, "Procesados 0 · Cambiados 0 · Restaurados 0 · Pendientes 0",
        UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 10, TEXT_SUB, Enum.Font.GothamMedium, Enum.TextXAlignment.Center)
    ui.StatsLabel = statsLabel

    makeLabel(logTab, "RESUMEN POR CATEGORÍA", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(2, 42), 10, TEXT_DIM, Enum.Font.GothamBold)

    local summaryList = Instance.new("ScrollingFrame")
    summaryList.Position = UDim2.fromOffset(0, 60)
    summaryList.Size = UDim2.new(1, 0, 0, 130)
    summaryList.BackgroundColor3 = BG_SURFACE
    summaryList.BorderSizePixel = 0
    summaryList.ScrollBarThickness = 4
    summaryList.CanvasSize = UDim2.new()
    summaryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    summaryList.Parent = logTab
    corner(summaryList, UDim.new(0, 10))
    local summaryLayout = Instance.new("UIListLayout")
    summaryLayout.Padding = UDim.new(0, 4)
    summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    summaryLayout.Parent = summaryList
    local summaryPad = Instance.new("UIPadding")
    summaryPad.PaddingTop = UDim.new(0, 8)
    summaryPad.PaddingBottom = UDim.new(0, 8)
    summaryPad.PaddingLeft = UDim.new(0, 10)
    summaryPad.PaddingRight = UDim.new(0, 10)
    summaryPad.Parent = summaryList

    ui.SummaryRows = {}
    for index, category in ipairs(CATEGORY_ORDER) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.LayoutOrder = index
        row.Parent = summaryList
        makeLabel(row, CATEGORY_LABELS[category], UDim2.new(1, -100, 1, 0), UDim2.fromOffset(0, 0), 11, TEXT_SUB)
        local chip, chipLbl = makeChip(row, "0 · 0", UDim2.new(1, -92, 0.5, -10), UDim2.fromOffset(92, 20))
        ui.SummaryRows[category] = chipLbl
    end

    makeLabel(logTab, "EVENTOS", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(2, 198), 10, TEXT_DIM, Enum.Font.GothamBold)

    local eventLog = Instance.new("ScrollingFrame")
    eventLog.Position = UDim2.fromOffset(0, 216)
    eventLog.Size = UDim2.new(1, 0, 1, -216)
    eventLog.BackgroundColor3 = BG_SURFACE
    eventLog.BorderSizePixel = 0
    eventLog.ScrollBarThickness = 4
    eventLog.CanvasSize = UDim2.new()
    eventLog.AutomaticCanvasSize = Enum.AutomaticSize.Y
    eventLog.Parent = logTab
    corner(eventLog, UDim.new(0, 10))
    local eventLayout = Instance.new("UIListLayout")
    eventLayout.Padding = UDim.new(0, 1)
    eventLayout.SortOrder = Enum.SortOrder.LayoutOrder
    eventLayout.Parent = eventLog
    local eventPad = Instance.new("UIPadding")
    eventPad.PaddingTop = UDim.new(0, 6)
    eventPad.PaddingBottom = UDim.new(0, 6)
    eventPad.PaddingLeft = UDim.new(0, 10)
    eventPad.PaddingRight = UDim.new(0, 10)
    eventPad.Parent = eventLog
    ui.EventLog = eventLog

    local EVENT_LIMIT = 60
    local eventOrder = 0
    local function pushLog(message)
        if not message or message == "" then return end
        eventOrder = eventOrder + 1
        local line = makeLabel(eventLog, ("[%s] %s"):format(os.date("%H:%M:%S"), message),
            UDim2.new(1, 0, 0, 14), UDim2.fromOffset(0, 0), 10, TEXT_SUB, Enum.Font.Code)
        line.LayoutOrder = eventOrder

        local rows = eventLog:GetChildren()
        local count = 0
        for _, child in ipairs(rows) do
            if child:IsA("TextLabel") then count = count + 1 end
        end
        if count > EVENT_LIMIT then
            for _, child in ipairs(rows) do
                if child:IsA("TextLabel") then
                    child:Destroy()
                    break
                end
            end
        end

        task.defer(function()
            eventLog.CanvasPosition = Vector2.new(0, math.max(0, eventLog.AbsoluteCanvasSize.Y))
        end)
    end
    ui.PushLog = pushLog

    -- ── PESTAÑA AJUSTES (toggles) ─────────────────────────────
    local togglesTab = Instance.new("Frame")
    togglesTab.Size = UDim2.new(1, 0, 1, 0)
    togglesTab.BackgroundTransparency = 1
    togglesTab.Visible = false
    togglesTab.Parent = content

    makeLabel(togglesTab, "Elegí qué categorías busca y optimiza el mejorador.",
        UDim2.new(1, 0, 0, 16), UDim2.fromOffset(2, 0), 11, TEXT_SUB)

    local toggleList = Instance.new("ScrollingFrame")
    toggleList.Position = UDim2.fromOffset(0, 22)
    toggleList.Size = UDim2.new(1, 0, 1, -22)
    toggleList.BackgroundColor3 = BG_SURFACE
    toggleList.BorderSizePixel = 0
    toggleList.ScrollBarThickness = 4
    toggleList.CanvasSize = UDim2.new()
    toggleList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    toggleList.Parent = togglesTab
    corner(toggleList, UDim.new(0, 10))
    local toggleLayout = Instance.new("UIListLayout")
    toggleLayout.Padding = UDim.new(0, 4)
    toggleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toggleLayout.Parent = toggleList
    local togglePad = Instance.new("UIPadding")
    togglePad.PaddingTop = UDim.new(0, 8)
    togglePad.PaddingBottom = UDim.new(0, 8)
    togglePad.PaddingLeft = UDim.new(0, 10)
    togglePad.PaddingRight = UDim.new(0, 10)
    togglePad.Parent = toggleList

    ui.ToggleAccents = {}
    ui.ToggleSubtext = {}
    for index, category in ipairs(CATEGORY_ORDER) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 56)
        row.BackgroundColor3 = BG_SURFACE
        row.LayoutOrder = index
        row.Parent = toggleList
        corner(row, UDim.new(0, 10))
        stroke(row, STROKE_COLOR, 1, 0.6)

        local initialOn = diagnostic.Selected[category]

        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.fromOffset(3, 32)
        accentBar.AnchorPoint = Vector2.new(0, 0.5)
        accentBar.Position = UDim2.new(0, 8, 0.5, 0)
        accentBar.BackgroundColor3 = initialOn and ON_COLOR or OFF_COLOR
        accentBar.BorderSizePixel = 0
        accentBar.Parent = row
        corner(accentBar, UDim.new(1, 0))
        ui.ToggleAccents[category] = accentBar

        makeLabel(row, CATEGORY_LABELS[category], UDim2.new(1, -100, 0, 18), UDim2.fromOffset(20, 9), 12, TEXT_MAIN, Enum.Font.GothamMedium)
        local subtext = makeLabel(row, (initialOn and "Activado" or "Desactivado") .. " · 0 encontrados",
            UDim2.new(1, -100, 0, 16), UDim2.fromOffset(20, 30), 10, TEXT_DIM)
        ui.ToggleSubtext[category] = subtext

        makeSwitch(row, UDim2.new(1, -60, 0.5, -12), initialOn, function(value)
            diagnostic.Selected[category] = value
            TweenService:Create(accentBar, TweenInfo.new(0.15), { BackgroundColor3 = value and ON_COLOR or OFF_COLOR }):Play()
            local found = diagnostic.Counts[category] or 0
            subtext.Text = (value and "Activado" or "Desactivado") .. " · " .. formatNumber(found) .. " encontrados"
        end)
    end

    -- ── Navegación del rail ────────────────────────────────────
    local logIcon, logIndicator = makeRailIcon("LOG", 1)
    local settingsIcon, settingsIndicator = makeRailIcon("⚙", 2)

    local function selectTab(name)
        logTab.Visible = (name == "log")
        togglesTab.Visible = (name == "toggles")

        logIndicator.Visible = (name == "log")
        settingsIndicator.Visible = (name == "toggles")

        TweenService:Create(logIcon, TweenInfo.new(0.15), {
            BackgroundColor3 = (name == "log") and BG_SURFACE2 or BG_SURFACE,
            TextColor3 = (name == "log") and TEXT_MAIN or TEXT_DIM,
        }):Play()
        TweenService:Create(settingsIcon, TweenInfo.new(0.15), {
            BackgroundColor3 = (name == "toggles") and BG_SURFACE2 or BG_SURFACE,
            TextColor3 = (name == "toggles") and TEXT_MAIN or TEXT_DIM,
        }):Play()
    end
    logIcon.MouseButton1Click:Connect(function() selectTab("log") end)
    settingsIcon.MouseButton1Click:Connect(function() selectTab("toggles") end)
    selectTab("log")

    -- ── Botonera de acciones (estilo Vaystrap: ícono + texto) ──
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, -16, 0, FOOTER_H - 8)
    footer.Position = UDim2.new(0, 8, 1, -FOOTER_H + 4)
    footer.BackgroundTransparency = 1
    footer.Parent = panel

    local scan = makeTextButton(footer, "▶  INICIAR ESCANEO", UDim2.new(1, 0, 0, 38), UDim2.fromOffset(0, 0), Color3.fromRGB(232, 235, 242))
    scan.TextColor3 = Color3.fromRGB(18, 18, 20)
    local apply = makeTextButton(footer, "✓  APLICAR", UDim2.new(0.5, -4, 0, 34), UDim2.fromOffset(0, 46), Color3.fromRGB(38, 90, 60))
    local restore = makeTextButton(footer, "↺  RESTAURAR", UDim2.new(0.5, -4, 0, 34), UDim2.new(0.5, 4, 0, 46), BG_SURFACE2)
    ui.ScanButton = scan
    ui.ApplyButton = apply
    ui.RestoreButton = restore

    local status = Instance.new("TextLabel")
    status.Visible = false
    status.Text = "Pulsa INICIAR ESCANEO para comenzar"
    status.Parent = panel
    ui.Status = status
    ui.Status:GetPropertyChangedSignal("Text"):Connect(function()
        pushLog(ui.Status.Text)
    end)
    pushLog("Panel listo. Pulsa INICIAR ESCANEO para comenzar.")

    scan.MouseButton1Click:Connect(scanEnvironment)
    apply.MouseButton1Click:Connect(applySelectedCategories)
    restore.MouseButton1Click:Connect(function()
        restoreAll()
        updateStatus("Todo restaurado a los valores originales")
    end)

    -- ── Drag del panel (por el header) ─────────────────────────
    local dragging = false
    local dragStart
    local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- ── Ícono flotante circular (estilo HideGuis) para abrir/cerrar el panel ──
    local pill = Instance.new("Frame")
    pill.Name = "TogglePill"
    pill.Size = UDim2.fromOffset(56, 56)
    pill.Position = UDim2.new(0, 20, 0, 60)
    pill.BackgroundColor3 = BG_SURFACE
    pill.BackgroundTransparency = 0.15
    pill.BorderSizePixel = 0
    pill.ZIndex = 2
    pill.Parent = screen
    corner(pill, UDim.new(1, 0))
    applyGlassSweep(pill, YANG_COLOR, YANG_COLOR_B)

    local pillLabel = makeLabel(pill, "YY", UDim2.new(1, 0, 1, 0), UDim2.fromOffset(0, 0), 16, TEXT_MAIN, Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    pillLabel.ZIndex = 3

    local pillBtn = Instance.new("TextButton")
    pillBtn.Size = UDim2.new(1, 0, 1, 0)
    pillBtn.BackgroundTransparency = 1
    pillBtn.Text = ""
    pillBtn.ZIndex = 4
    pillBtn.Parent = pill

    local pDragging, pMoved = false, false
    local pOrigin, pPillOrigin = Vector2.zero, UDim2.new()
    local THRESHOLD = 6

    pillBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            pDragging = true
            pMoved = false
            pOrigin = inp.Position
            pPillOrigin = pill.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not pDragging then return end
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - pOrigin
            if not pMoved and (math.abs(d.X) > THRESHOLD or math.abs(d.Y) > THRESHOLD) then
                pMoved = true
            end
            if pMoved then
                pill.Position = UDim2.new(pPillOrigin.X.Scale, pPillOrigin.X.Offset + d.X, pPillOrigin.Y.Scale, pPillOrigin.Y.Offset + d.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if pDragging and not pMoved then
                panel.Visible = not panel.Visible
            end
            pDragging = false
            pMoved = false
        end
    end)

    -- ── Loop de refresco del resumen (LOG): 0 lag — solo texto, cada 0.35s ──
    task.spawn(function()
        while myToken == uiLoopToken and screen.Parent do
            local stats = getStats()
            statsLabel.Text = ("Procesados %s · Cambiados %s · Restaurados %s · Pendientes %s")
                :format(formatNumber(stats.Processed), formatNumber(stats.Changed), formatNumber(stats.Restored), formatNumber(stats.Pending))

            for _, category in ipairs(CATEGORY_ORDER) do
                local found = diagnostic.Counts[category] or 0
                local changed = state.CategoryChanged[category] or 0
                local summaryLbl = ui.SummaryRows[category]
                if summaryLbl then
                    summaryLbl.Text = formatNumber(found) .. " · " .. formatNumber(changed)
                end
                local subtextLbl = ui.ToggleSubtext[category]
                if subtextLbl then
                    local isOn = diagnostic.Selected[category]
                    subtextLbl.Text = (isOn and "Activado" or "Desactivado") .. " · " .. formatNumber(found) .. " encontrados"
                end
            end
            task.wait(0.35)
        end
    end)

    screen.Destroying:Connect(function()
        if myToken == uiLoopToken then
            uiLoopToken = uiLoopToken + 1
        end
    end)
end

local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.F6 then
        if ui.Panel then ui.Panel.Visible = not ui.Panel.Visible end
    elseif input.KeyCode == Enum.KeyCode.F7 then
        restoreAll()
        updateStatus("Todo restaurado a los valores originales")
    elseif input.KeyCode == Enum.KeyCode.F8 then
        if diagnostic.Running then
            updateStatus("Espera a que termine el escaneo")
        elseif state.Enabled then
            restoreAll()
            updateStatus("Optimización desactivada y valores restaurados")
        else
            applySelectedCategories()
        end
    end
end)

GEN[API_NAME] = {
    Config = CONFIG,
    Apply = function(profileName)
        return applyProfile(profileName or CONFIG.DefaultProfile)
    end,
    ApplySelected = applySelectedCategories,
    Scan = scanEnvironment,
    Restore = function()
        restoreAll()
        updateStatus("Todo restaurado a los valores originales")
    end,
    Toggle = toggle,
    Stats = function()
        local result = getStats()
        result.ScanRunning = diagnostic.Running
        result.ScanTotal = diagnostic.Total
        result.CategoryCounts = diagnostic.Counts
        result.CategoryChanged = state.CategoryChanged
        return result
    end,
    Shutdown = function()
        restoreAll()
        if inputConnection then
            pcall(function()
                inputConnection:Disconnect()
            end)
        end
        uiLoopToken = uiLoopToken + 1
        if ui.ScreenGui then
            ui.ScreenGui:Destroy()
            ui.ScreenGui = nil
        end
        GEN[API_NAME] = nil
    end,
}

makePanel()
print("YinYang Performance PRO v3: rail de íconos + tamaño responsive real — F6/F7/F8 disponibles")


return function()
    if GEN[API_NAME] and type(GEN[API_NAME].Shutdown) == "function" then
        pcall(GEN[API_NAME].Shutdown)
    end
end

end

local function registerStatsHUD()
-- StatsHUD — FPS / Ping / Timer, mismo sistema de efectos que HideGuis
print("[StatsHUD] Iniciando...")
-- Base: HideGuis-7.lua (gradiente glassy + UIStroke con sweep+pulse)
-- Adaptado: rectángulo ancho (no pill), negro, borde blanco, sweep rojo ancho y lento

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local StatsService  = game:GetService("Stats")
local lp            = Players.LocalPlayer
local pg            = lp:WaitForChild("PlayerGui")

-- Limpiar instancia previa
local prev = pg:FindFirstChild("_StatsHUD")
if prev then prev:Destroy() end

-- ── Paleta (según pedido: fondo negro, borde blanco, sweep rojo) ──
local BG          = Color3.fromRGB(0, 0, 0)      -- negro
local BORDER      = Color3.fromRGB(255, 255, 255) -- blanco (borde estático)
local SWEEP_BASE  = Color3.fromRGB(255, 40, 40)   -- rojo (base del efecto que gira)

-- ── ScreenGui ─────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = "_StatsHUD"
gui.ResetOnSpawn   = false
gui.IgnoreGuiInset = true
gui.DisplayOrder   = 9999

-- Usa gethui() si está disponible (evita que el ejecutor bloquee silenciosamente
-- el parenting a PlayerGui). Fallback a PlayerGui igual que la librería Zin.
local guiParent = pg
pcall(function()
    if typeof(gethui) == "function" then
        local hidden = gethui()
        if hidden then guiParent = hidden end
    end
end)
-- Synapse X / Wave: protect_gui evita que el juego destruya la GUI
pcall(function()
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        syn.protect_gui(gui)
    end
end)
gui.Parent = guiParent
print("[StatsHUD] GUI parented a:", tostring(guiParent))

-- ── Panel principal (rectángulo ancho, no pill) ────────────────
local panel = Instance.new("Frame")
panel.Size                   = UDim2.fromOffset(230, 58)
panel.Position               = UDim2.new(0, 20, 0, 60)
panel.BackgroundColor3       = BG
panel.BackgroundTransparency = 0.5   -- "medio transparente"
panel.BorderSizePixel        = 0
panel.ZIndex                 = 2
panel.Parent                 = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)  -- rectángulo redondeado, no cápsula
panelCorner.Parent       = panel

-- UIGradient glassy (mismo patrón que HideGuis, sin cambios de color)
local glassy = Instance.new("UIGradient")
glassy.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(60,  60,  65)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90,  90,  95)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  60,  65)),
})
glassy.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.55),
    NumberSequenceKeypoint.new(0.5, 0.25),
    NumberSequenceKeypoint.new(1,   0.55),
})
glassy.Rotation = 90
glassy.Parent   = panel

-- UIStroke: base blanca estática + gradiente rojo animado encima
local stroke = Instance.new("UIStroke")
stroke.Thickness    = 2.5
stroke.Color        = BORDER   -- "bordes blancos"
stroke.Transparency = 0.10
stroke.LineJoinMode = Enum.LineJoinMode.Round
stroke.Parent       = panel

-- ── Gradiente del sweep: ANCHO (banda amplia, no un pico fino) ──
local h, s, v      = Color3.toHSV(SWEEP_BASE)
local sweepLight   = Color3.fromHSV(h, math.max(0, s - 0.25), math.min(1, v + 0.15))
local sweepDark    = Color3.fromHSV(h, math.min(1, s + 0.1),  math.max(0, v - 0.35))

local strokeGrad = Instance.new("UIGradient")
-- 5 keypoints en vez de 3: crea una meseta ancha en vez de un pico fino
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    sweepDark),
    ColorSequenceKeypoint.new(0.35, sweepLight),
    ColorSequenceKeypoint.new(0.5,  sweepLight),
    ColorSequenceKeypoint.new(0.65, sweepLight),
    ColorSequenceKeypoint.new(1,    sweepDark),
})
strokeGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,    0.5),
    NumberSequenceKeypoint.new(0.35, 0.0),
    NumberSequenceKeypoint.new(0.5,  0.0),
    NumberSequenceKeypoint.new(0.65, 0.0),
    NumberSequenceKeypoint.new(1,    0.5),
})
strokeGrad.Offset = Vector2.new(-1.5, 0)
strokeGrad.Parent = stroke

-- Sweep MÁS LENTO: 1.4s (HideGuis) → 3.6s
TweenService:Create(
    strokeGrad,
    TweenInfo.new(3.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
    { Offset = Vector2.new(1.5, 0) }
):Play()

-- Pulse (igual patrón que HideGuis, levemente más lento para acompañar el sweep)
TweenService:Create(
    stroke,
    TweenInfo.new(2.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Transparency = 0.0 }
):Play()

-- ── Labels (2 líneas: FPS/Ping arriba, Timer abajo) ────────────
local lineTop = Instance.new("TextLabel")
lineTop.Size               = UDim2.new(1, -12, 0, 20)
lineTop.Position           = UDim2.new(0, 6, 0, 8)
lineTop.BackgroundTransparency = 1
lineTop.Text               = "FPS: -- | Ping: -- ms"
lineTop.TextColor3         = Color3.fromRGB(240, 240, 240)
lineTop.Font               = Enum.Font.GothamBlack
lineTop.TextSize           = 14
lineTop.TextXAlignment     = Enum.TextXAlignment.Center
lineTop.ZIndex             = 3
lineTop.Parent             = panel

local lineBottom = Instance.new("TextLabel")
lineBottom.Size               = UDim2.new(1, -12, 0, 18)
lineBottom.Position           = UDim2.new(0, 6, 0, 30)
lineBottom.BackgroundTransparency = 1
lineBottom.Text               = "Client Timer: 0h 0m 0s"
lineBottom.TextColor3         = Color3.fromRGB(220, 220, 220)
lineBottom.Font               = Enum.Font.GothamBold
lineBottom.TextSize           = 12
lineBottom.TextXAlignment     = Enum.TextXAlignment.Center
lineBottom.ZIndex             = 3
lineBottom.Parent             = panel

-- ── Botón invisible encima (solo para el drag, sin acción de tap) ──
local btn = Instance.new("TextButton")
btn.Size                 = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text                 = ""
btn.ZIndex               = 4
btn.Parent               = panel

-- ── Medición de FPS ──────────────────────────────────────────
-- Contador de frames por ventana de tiempo (evita el ruido de 1/dt por frame)
local frameCount   = 0
local fpsWindowT   = 0
local currentFPS   = 0
local FPS_SAMPLE_INTERVAL = 0.5

local renderConn = RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    fpsWindowT = fpsWindowT + dt
    if fpsWindowT >= FPS_SAMPLE_INTERVAL then
        currentFPS = math.floor((frameCount / fpsWindowT) + 0.5)
        frameCount = 0
        fpsWindowT = 0
    end
end)

-- ── Medición de Ping ─────────────────────────────────────────
-- API real de Roblox: Stats.Network.ServerStatsItem["Data Ping"]
-- Envuelto en pcall: algunos ejecutadores restringen el servicio Stats
local function getPing()
    local ok, ms = pcall(function()
        return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and ms then
        return math.floor(ms + 0.5)
    end
    return nil
end

-- ── Timer de ejecución ───────────────────────────────────────
local startTime = tick()

local function formatElapsed(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%dh %dm %ds", h, m, s)
end

-- ── Loop de actualización de texto (cada 0.5s) ────────────────
task.spawn(function()
    while panel.Parent do
        local ping = getPing()
        local pingText = ping and (ping .. " ms") or "N/A"

        lineTop.Text    = string.format("FPS: %d | Ping: %s", currentFPS, pingText)
        lineBottom.Text = "Client Timer: " .. formatElapsed(tick() - startTime)

        task.wait(0.5)
    end
end)

-- Limpiar la conexión de RenderStepped si el HUD se destruye
gui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        renderConn:Disconnect()
    end
end)

-- ── Drag con threshold (idéntico a HideGuis) ──────────────────
local dragging   = false
local moved      = false
local dragOrigin = Vector2.zero
local panelOrigin = UDim2.new()
local THRESHOLD  = 6

btn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
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

print("[StatsHUD] ✅ Listo — HUD activo")

-- ════════════════════════════════════════════════════════════════════════
-- REGISTRO DE FUNCIÓN DE PARADA — requerido por el sistema de scripts externos
-- La librería llama a _G["_YY_STOP_StatsHUD"]() al presionar el botón por segunda vez.
-- Destruye la GUI; el loop de texto y la conexión de FPS se autolimpian solos
-- (panel.Parent pasa a nil, y gui.AncestryChanged desconecta renderConn).
-- ════════════════════════════════════════════════════════════════════════
return function()
    pcall(function() gui:Destroy() end)
end

end

local ModuleFactories = {
    HideGuis = registerHideGuis,
    FOVAdjust = registerFOVAdjust,
    Waypoint = registerWaypoint,
    PerformanceOptimizer = registerPerformanceOptimizer,
    StatsHUD = registerStatsHUD,
}

local activeStops = {}
local function activateModule(moduleKey)
    local factory = ModuleFactories[moduleKey]
    if type(factory) ~= "function" then
        warn("[YinYang Classic] Módulo no registrado: " .. tostring(moduleKey))
        return false
    end

    local ok, stop = pcall(factory)
    if not ok then
        warn("[YinYang Classic] Error al iniciar " .. tostring(moduleKey) .. ": " .. tostring(stop))
        return false
    end
    if type(stop) ~= "function" then
        warn("[YinYang Classic] El módulo " .. tostring(moduleKey) .. " no devolvió una función de parada")
        return false
    end

    activeStops[moduleKey] = stop
    return true
end

if requestedModule and requestedModule ~= "" then
    activateModule(tostring(requestedModule))
else
    for moduleKey in pairs(ModuleFactories) do
        activateModule(moduleKey)
    end
end

local function stopModule(moduleKey)
    local stop = activeStops[moduleKey]
    if stop then
        pcall(stop)
        activeStops[moduleKey] = nil
    end
    _G["_YY_STOP_" .. tostring(moduleKey)] = nil
end

if requestedModule and requestedModule ~= "" then
    local moduleKey = tostring(requestedModule)
    _G["_YY_STOP_" .. moduleKey] = function()
        stopModule(moduleKey)
    end
else
    _G["_YY_STOP_ClassicOptions"] = function()
        for moduleKey in pairs(activeStops) do
            stopModule(moduleKey)
        end
        _G["_YY_STOP_ClassicOptions"] = nil
    end
end

