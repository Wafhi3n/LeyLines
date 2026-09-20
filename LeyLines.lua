-- LeyLines.lua — socle : table d'addon, réglages par défaut, SavedVariables, commandes /ley.
--
-- Chargé APRÈS la locale, AVANT les modules. Les modules (Geo/Nodes/Capture/Minimap/WorldMap/HUD)
-- s'accrochent à LL et sont démarrés ici sur PLAYER_LOGIN, quand tous les fichiers du .toc sont là.
--
-- Cible : WoW: Forever (Camelot) — API MAINLINE. Toute la géométrie passe par C_Map / C_Minimap,
-- qui n'existent pas sous cette forme sur Classic Era : cet addon n'a pas de variante Era.
local ADDON, LL = ...
local L = LL.L

LL.VERSION = "1.0.0"
LL.ADDON   = ADDON
_G.LeyLines = LL

-- Réglages par défaut.
--   names   : motifs reconnus dans une infobulle / une vignette (minuscules, comparaison `plain`).
--             Ce sont des textes CLIENT, pas du chrome : ils ne passent pas par L, et l'utilisateur
--             en ajoute un avec `/ley name <texte>` si son client nomme l'objet autrement.
--   spells  : [spellID] = nom — appris par `/ley learn`. Le sort d'absorption part de PARTOUT ;
--             c'est la DURÉE du buff obtenu qui dit s'il a touché une faille (voir _Capture).
--   mergeRange : deux relevés à moins de N yards sont la MÊME ligne (anti-doublon).
LL.DEFAULTS = {
    schemaVer  = 2,
    -- capture.tooltip est à FAUX depuis le 2026-09-20 : le simple survol relève la position du
    -- JOUEUR, pas celle de l'objet — mesuré à 40 yd d'écart en jeu — et notre propre infobulle de
    -- point se faisait relire. Source utile mais approximative, donc sur demande (`/ley tooltip`).
    capture    = { vignette = true, tooltip = false, spell = true },
    minimap    = { show = true, size = 16, edge = true, scale = 1.0 },
    worldmap   = { show = true, size = 18 },
    hud        = { show = true, point = "CENTER", x = 280, y = -150 },
    mergeRange = 20,
    -- Minutes restantes du buff de faille à partir desquelles on prévient et on pose le point de
    -- route sur la plus proche. 0 = jamais. Le buff dure 15 min, d'où 5 par défaut.
    warnMinutes = 5,
    names      = { "ley line", "ligne tellurique" },
    -- Le sort d'absorption Skyborn et le buff qu'il pose portent le MÊME id, relevé en jeu le
    -- 2026-09-20 (`/ley probe` après un lancer réussi). Livrés en dur : la capture marche dès le
    -- premier lancer, sans rien apprendre. `/ley learn` reste la porte de sortie si la bêta change
    -- l'id ou si un autre sort se met à faire la même chose.
    spells     = { [1259691] = "Energized" },   -- [spellID] = nom du sort d'absorption
    auras      = { [1259691] = "Energized" },   -- [spellID] = nom du buff long obtenu sur une faille
    nodes      = {},
}

function LL:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff9b6ef3Ley Lines|r " .. tostring(msg))
end

function LL:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

function LL:OnOff(v)
    return v and L["activé"] or L["désactivé"]
end

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

-- Échelle de migrations : une base déjà enregistrée ne connaît pas les nouveaux défauts, et
-- CopyDefaults ne touche QUE les clés absentes. Chaque palier est idempotent et se franchit une
-- fois, dans l'ordre. Appelée après CopyDefaults, donc les tables existent toujours.
local function Migrate(db)
    if (db.schemaVer or 1) < 2 then
        db.capture.tooltip = false   -- v2 : capture par infobulle devenue opt-in
        db.schemaVer = 2
    end
end

-- Raccourcis appelés par Bindings.xml (le client ne sait appeler qu'une globale).
function LL:Record()      LL.Capture:Record("manual") end
function LL:TrackNearest()
    local node = LL.Nodes:NearestToPlayer()
    if node then LL.HUD:Track(node) else LL:Print(L["Aucune ligne tellurique connue dans cette zone."]) end
end

-- ---------------------------------------------------------------------------
-- Commandes
-- ---------------------------------------------------------------------------
local CMD = {}

CMD.status = function()
    local map  = LL.Geo:PlayerMap()
    local here = map and LL.Nodes:CountMap(map) or 0
    LL:Printf(L["v%s — %s ligne(s) ici, %s au total."], LL.VERSION, here, LL.Nodes:Count())
    local node, dist = LL.Nodes:NearestToPlayer()
    if node then
        LL:Printf(L["La plus proche : %s à %s yd."], LL.Nodes:Label(node), math.floor(dist + 0.5))
    end
    LL:Printf(L["Minicarte %s — carte %s — suivi %s — capture auto %s."],
        LL:OnOff(LL.db.minimap.show), LL:OnOff(LL.db.worldmap.show),
        LL:OnOff(LL.db.hud.show), LL:OnOff(LL.Capture:AutoEnabled()))
end

CMD.add = function(rest)
    LL.Capture:Record("manual", (rest ~= "" and rest) or nil)
end
CMD.here = CMD.add
CMD.ici  = CMD.add

CMD.del = function()
    local node, dist = LL.Nodes:NearestToPlayer()
    if not node or dist > 60 then
        LL:Print(L["Aucune ligne tellurique à moins de 60 yd — place-toi dessus pour l'effacer."])
        return
    end
    LL.Nodes:Remove(node)
    LL:Printf(L["Ligne tellurique effacée : %s."], LL.Nodes:Label(node))
    LL:Refresh()
end
CMD.suppr = CMD.del

CMD.list = function()
    local map = LL.Geo:PlayerMap()
    local list = map and LL.Nodes:All(map)
    if not list or #list == 0 then
        LL:Print(L["Aucune ligne tellurique connue dans cette zone."])
        return
    end
    LL:Printf(L["%s ligne(s) tellurique(s) dans %s :"], #list, LL.Geo:MapName(map))
    for _, node in ipairs(list) do
        local dist = LL.Nodes:DistanceToPlayer(node)
        LL:Printf("  |cff9b6ef3%s|r  %.1f / %.1f  —  %s yd  (%s)", LL.Nodes:Label(node),
            node.x * 100, node.y * 100, dist and math.floor(dist + 0.5) or "?", LL.Nodes:SourceLabel(node))
    end
end
CMD.liste = CMD.list

CMD.clear = function()
    local map = LL.Geo:PlayerMap()
    if not map or LL.Nodes:CountMap(map) == 0 then
        LL:Print(L["Aucune ligne tellurique connue dans cette zone."])
        return
    end
    StaticPopup_Show("LEYLINES_CLEAR_ZONE", LL.Geo:MapName(map), nil, map)
end
CMD.vider = CMD.clear

CMD.hud = function()
    LL.db.hud.show = not LL.db.hud.show
    LL.HUD:Apply()
    LL:Printf(L["Suivi à l'écran : %s."], LL:OnOff(LL.db.hud.show))
end

CMD.pins = function()
    LL.db.minimap.show = not LL.db.minimap.show
    LL:Refresh()
    LL:Printf(L["Affichage sur la minicarte : %s."], LL:OnOff(LL.db.minimap.show))
end
CMD.minimap = CMD.pins

CMD.map = function()
    LL.db.worldmap.show = not LL.db.worldmap.show
    LL:Refresh()
    LL:Printf(L["Affichage sur la carte du monde : %s."], LL:OnOff(LL.db.worldmap.show))
end
CMD.carte = CMD.map

CMD.track = function() LL:TrackNearest() end
CMD.suivre = CMD.track

CMD.learn = function() LL.Capture:ArmLearn() end
CMD.apprendre = CMD.learn

CMD.auto = function()
    local on = not LL.Capture:AutoEnabled()
    LL.db.capture.vignette, LL.db.capture.spell = on, on
    LL:Printf(L["Capture automatique : %s."], LL:OnOff(on))
end

-- La capture par infobulle a son propre interrupteur : elle relève la position du JOUEUR qui
-- VISE, donc elle pose des points approximatifs. On ne la rallume pas par mégarde avec `auto`.
CMD.tooltip = function()
    LL.db.capture.tooltip = not LL.db.capture.tooltip
    LL:Printf(L["Capture par infobulle : %s (relevé approximatif, à ta position)."],
        LL:OnOff(LL.db.capture.tooltip))
end
CMD.infobulle = CMD.tooltip

CMD.clean = function()
    local n = LL.Nodes:RemoveBySource("tooltip")
    LL:Printf(L["%s relevé(s) d'infobulle effacé(s)."], n)
    LL:Refresh()
end
CMD.nettoyer = CMD.clean

CMD.name = function(rest)
    if rest == "" then
        LL:Printf(L["Noms reconnus : %s."], table.concat(LL.db.names, ", "))
        return
    end
    local text = string.lower(rest)
    for _, n in ipairs(LL.db.names) do
        if n == text then return end
    end
    table.insert(LL.db.names, text)
    LL:Printf(L["Nom reconnu ajouté : %s."], text)
end
CMD.nom = CMD.name

CMD.scale = function(rest)
    local n = tonumber(rest)
    if n and n >= 0.25 and n <= 4 then LL.db.minimap.scale = n end
    LL:Printf(L["Échelle de la minicarte : %s (rayon lu : %s yd)."],
        LL.db.minimap.scale, math.floor(LL.Geo:MinimapRadius() + 0.5))
end

CMD.warn = function(rest)
    local n = tonumber(rest)
    if n and n >= 0 and n <= 60 then
        LL.db.warnMinutes = n
        LL.HUD.warned = false   -- un nouveau seuil doit pouvoir se déclencher tout de suite
    end
    LL:Printf(L["Rappel de buff : à %s min restantes (0 = désactivé)."], LL.db.warnMinutes)
end
CMD.rappel = CMD.warn

CMD.export = function() LL.Share:ShowExport() end
CMD.import = function(rest)
    -- Un code court tient dans la ligne de chat ; au-dela, la fenetre est le seul chemin.
    if rest ~= "" then LL.Share:Import(rest) else LL.Share:ShowImport() end
end
CMD.partage = CMD.export

CMD.probe = function() LL.Probe:Dump() end
CMD.diag  = CMD.probe

CMD.help = function()
    LL:Print(L["Commandes : /ley (état), add, del, list, clean, clear, export, import, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."])
    LL:Print(L["Marche à suivre : place-toi SUR la ligne tellurique et fais /ley add (ou le raccourci clavier)."])
end
CMD.aide = CMD.help

function LL:Slash(msg)
    local cmd, rest = string.match(strtrim(msg or ""), "^(%S*)%s*(.-)$")
    local fn = CMD[string.lower(cmd or "")] or (cmd == "" and CMD.status) or CMD.help
    fn(rest or "")
end

SLASH_LEYLINES1 = "/ley"
SLASH_LEYLINES2 = "/leyline"
SLASH_LEYLINES3 = "/lignes"
SlashCmdList["LEYLINES"] = function(msg) LL:Slash(msg) end

-- Une seule porte de rafraîchissement : les modules d'affichage s'y abonnent au démarrage, donc
-- tout ce qui MODIFIE la base (capture, suppression, réglage) n'a qu'un appel à faire.
LL.listeners = {}
function LL:OnRefresh(fn) table.insert(self.listeners, fn) end
function LL:Refresh()
    for _, fn in ipairs(self.listeners) do fn() end
end

StaticPopupDialogs["LEYLINES_CLEAR_ZONE"] = {
    text         = L["Effacer toutes les lignes telluriques connues dans %s ?"],
    button1      = YES,
    button2      = NO,
    OnAccept     = function(_, map)
        local n = LL.Nodes:ClearMap(map)
        LL:Printf(L["%s ligne(s) tellurique(s) effacée(s)."], n)
        LL:Refresh()
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- ---------------------------------------------------------------------------
-- Démarrage
-- ---------------------------------------------------------------------------
_G.BINDING_HEADER_LEYLINES      = L["Lignes telluriques"]
_G.BINDING_NAME_LEYLINES_RECORD = L["Enregistrer une ligne tellurique ici"]
_G.BINDING_NAME_LEYLINES_TRACK  = L["Suivre la ligne tellurique la plus proche"]

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        LeyLinesDB = LeyLinesDB or {}
        CopyDefaults(LeyLinesDB, LL.DEFAULTS)
        Migrate(LeyLinesDB)
        LL.db = LeyLinesDB
    elseif event == "PLAYER_LOGIN" then
        LL.Nodes:Init()
        local shipped = LL.Nodes:ApplyShipped()
        LL.Capture:Init()
        LL.Minimap:Init()
        LL.WorldMap:Init()
        LL.HUD:Init()
        LL:Refresh()
        LL:Printf(L["v%s chargée. /ley pour l'état, /ley help pour le reste."], LL.VERSION)
        if shipped > 0 then
            LL:Printf(L["%s ligne(s) tellurique(s) ajoutée(s) depuis les données livrées."], shipped)
        end
    end
end)
