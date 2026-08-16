--[[
    YinYang_ClassicOptions.lua
    ─────────────────────────────────────────────────────────────────────
    Catálogo de "opciones Classic": scripts externos con su propia GUI y
    lógica, que se cargan/cierran desde la pestaña "Classic" de la
    librería Yin Yang con un solo click (apretar = cargar, volver a
    apretar = cerrar).

    ESTE ARCHIVO SE SUBE COMO REPO (raw URL) — la librería lo descarga
    con game:HttpGet() al iniciar, igual que hace con YinYang_Icons.lua
    y YinYang_Themes.lua. Formato: debe devolver ("return") una tabla
    con "Order" y "Options" tal como se ve abajo.

    ═══════════════════════════════════════════════════════════════════
    CÓMO AGREGAR UN NUEVO SCRIPT (para humanos o IAs que editen esto):
    ═══════════════════════════════════════════════════════════════════

    1. Subí tu script (.lua) a algún repo público, obtené su raw URL.

    2. Tu script DEBE seguir esta regla, sin excepción:
       - Crear su ScreenGui con un Name ÚNICO y FIJO (ej: "_MiScript").
       - Al principio del script, autolimpiarse si ya existe una
         instancia previa con ese mismo Name (mismo patrón que usa
         HideGuis.lua):

           local prev = pg:FindFirstChild("_MiScript")
           if prev then prev:Destroy() end

       Por qué: la librería NO usa una función de cleanup devuelta por
       el script. En vez de eso, para "cerrar" la opción, la librería
       busca el ScreenGui por su Name (el campo GuiName de abajo) dentro
       de PlayerGui y lo destruye directamente. Si tu script no nombra
       su ScreenGui exactamente igual a GuiName, la librería no va a
       poder cerrarlo y quedará corriendo para siempre hasta que el
       jugador recargue.

    3. Agregá una entrada nueva a la tabla "Options" de abajo, copiando
       la plantilla comentada al final de este archivo. Agregá también
       el nombre interno a "Order" para que aparezca en la pestaña.

    4. Subí este archivo actualizado al repo. La librería lo vuelve a
       descargar la próxima vez que un jugador abra el juego (no hace
       falta actualizar la librería en sí, solo este catálogo).

    CAMPOS DE CADA OPCIÓN:
        LabelES   (string)  Nombre en español, se muestra en la tarjeta.
        LabelEN   (string)  Nombre en inglés.
        Icon      (string)  rbxassetid:// del ícono de la tarjeta.
        GuiName   (string)  Name EXACTO del ScreenGui que crea el script
                             (ver punto 2 arriba). Obligatorio.
        Url       (string)  Raw URL del script .lua a descargar y correr
                             con loadstring() la primera vez que el
                             jugador aprieta la tarjeta (carga perezosa,
                             no se descarga hasta que se necesita).
    ─────────────────────────────────────────────────────────────────────
--]]

return {
    Version = 1,

    Order = {
        "HideGuis",
    },

    Options = {

        HideGuis = {
            LabelES = "Ocultar GUIs",
            LabelEN = "Hide GUIs",
            Icon    = "rbxassetid://83456197177232",  -- ⚠️ placeholder, reemplazar por el ícono real
            GuiName = "_HideGuis",
            Url     = "https://raw.githubusercontent.com/REEMPLAZAR/CON/TU/REPO/HideGuis.lua",
        },

        --// 👇 Agregá acá los próximos scripts, copiando esta plantilla:
        --[[
        NombreInterno = {
            LabelES = "Nombre en Español",
            LabelEN = "Name in English",
            Icon    = "rbxassetid://TU_ICONO_AQUI",
            GuiName = "_NombreExactoDelScreenGuiQueCreaTuScript",
            Url     = "https://raw.githubusercontent.com/tu-usuario/tu-repo/refs/heads/main/TuScript.lua",
        },
        --]]

    },
}
