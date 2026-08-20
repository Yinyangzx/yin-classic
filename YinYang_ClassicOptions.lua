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

local ModuleFactories = {
    HideGuis = registerHideGuis,
    FOVAdjust = registerFOVAdjust,
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
