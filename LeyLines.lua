-- LeyLines.lua — socle : table d'addon, réglages par défaut, SavedVariables, commandes /ley.
--
-- Chargé APRÈS la locale, AVANT les modules. Les modules (Geo/Nodes/Capture/Minimap/WorldMap/HUD)
-- s'accrochent à LL et sont démarrés ici sur PLAYER_LOGIN, quand tous les fichiers du .toc sont là.
--
-- Cible : WoW: Forever (Camelot) — API MAINLINE. Toute la géométrie passe par C_Map / C_Minimap,
-- qui n'existent pas sous cette forme sur Classic Era : cet addon n'a pas de variante Era.
local ADDON, LL = ...
local L = LL.L

LL.VERSION = "1.6.3"
LL.ADDON   = ADDON
_G.LeyLines = LL

-- Réglages par défaut.
--   names   : motifs reconnus dans une infobulle / une vignette (minuscules, comparaison `plain`).
--             Ce sont des textes CLIENT, pas du chrome : ils ne passent pas par L, et l'utilisateur
--             en ajoute un avec `/ley name <texte>` si son client nomme l'objet autrement.
--   spells  : [spellID] = nom — appris par `/ley learn`. Le sort d'absorption part de PARTOUT ;
--             c'est la DURÉE du buff obtenu qui dit s'il a touché une faille (voir _Capture).
--   spellNames : noms de sort reconnus quand l'id n'est pas encore connu (minuscules, textes
--             CLIENT). Le premier lancer reconnu par son nom inscrit son id dans `spells`.
--   mergeRange : deux relevés à moins de N yards sont la MÊME ligne (anti-doublon).
--
-- DEUX FACTIONS, DEUX OBJETS (dit par le joueur le 2026-09-25) : l'Alliance absorbe une « Ley
-- Line » avec Skyborn, la Horde une « Elemental Vergence » avec « Skysight ». Même geste, même
-- verdict attendu (la durée du buff) — d'où une seule base et une seule capture pour les deux.
LL.DEFAULTS = {
    schemaVer  = 4,
    -- capture.tooltip est à FAUX depuis le 2026-09-20 : le simple survol relève la position du
    -- JOUEUR, pas celle de l'objet — mesuré à 40 yd d'écart en jeu — et notre propre infobulle de
    -- point se faisait relire. Source utile mais approximative, donc sur demande (`/ley tooltip`).
    capture    = { vignette = true, tooltip = false, spell = true },
    minimap    = { show = true, size = 16, edge = true, scale = 1.0 },
    worldmap   = { show = true, size = 18 },
    hud        = { show = true, point = "CENTER", x = 280, y = -150 },
    -- Le buff long se donne jusqu'à ~25 yd de l'objet (mesuré en jeu le 2026-09-29) : deux lancers
    -- réussis sur la MÊME fissure peuvent donc être à 50 yd l'un de l'autre, depuis deux bords
    -- opposés. À 20 yd, un lancer du bord créait un doublon, que le signal puis la liste commune
    -- propageaient à tout le monde. Contrepartie acceptée : deux vraies fissures à moins de 100 yd
    -- (une seule paire connue, à 73,5 yd) peuvent fusionner si on les absorbe par leurs bords.
    mergeRange = 50,
    -- Minutes restantes du buff de faille à partir desquelles on prévient et on pose le point de
    -- route sur la plus proche. 0 = jamais. Le buff dure 15 min, d'où 5 par défaut.
    warnMinutes = 5,
    -- « vergence » attrape « Elemental Vergence » et, sans le connaître, un nom français du même
    -- tronc. Si le client nomme l'objet autrement : `/ley name <texte>`.
    names      = { "ley line", "ligne tellurique", "vergence" },
    -- Le sort d'absorption Skyborn et le buff qu'il pose portent le MÊME id, relevé en jeu le
    -- 2026-09-20 (`/ley probe` après un lancer réussi). Livrés en dur : la capture marche dès le
    -- premier lancer, sans rien apprendre. `/ley learn` reste la porte de sortie si la bêta change
    -- l'id ou si un autre sort se met à faire la même chose.
    --
    -- Côté Horde (relevé en jeu le 2026-09-25) : 1270893, buff « Elemental Blessing », 15 min lui
    -- aussi. Posé aux deux tables comme pour l'Alliance ; si l'id du SORT diffère de celui du
    -- buff, `spellNames` rattrape le lancer par son nom et la durée du buff tranche quand même.
    spells     = { [1259691] = "Energized", [1270893] = "Skysight" },          -- sort d'absorption
    auras      = { [1259691] = "Energized", [1270893] = "Elemental Blessing" }, -- buff long obtenu
    -- Filet si l'id du sort n'est pas le bon : reconnaissance par NOM (anglais). Client dans une
    -- autre langue : `/ley learn` fait le même travail.
    spellNames = { "skysight" },
    nodes      = {},
    -- contrib.at : date (time()) de la dernière contribution générée par `/ley contribute`. La
    -- suivante ne porte que les points confirmés APRÈS (node.seen, voir _Nodes).
    contrib    = {},
    -- Le signal des positions à partager (LeyLines_Signal.lua) : `/ley signal off` le coupe.
    signal     = true,
    -- `/ley skyborne` : points affichés sur un personnage Skyborne seulement (voir LL:PinsHidden).
    -- Jeton de race lu en jeu le 2026-10-04 : « Skyborne » pour les deux races (ids 95 et 96).
    skyborneOnly = false,
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
    if db.schemaVer < 3 then
        -- v3 : vergences élémentaires (Horde). `names` est une LISTE : CopyDefaults ne comble que
        -- les index absents, donc un nom ajouté par le joueur en position 3 masquerait le nôtre.
        local has = false
        for _, n in ipairs(db.names) do if n == "vergence" then has = true end end
        if not has then table.insert(db.names, "vergence") end
        db.schemaVer = 3
    end
    if db.schemaVer < 4 then
        -- v4 : anti-doublon de 20 à 50 yd (voir DEFAULTS). Aucune commande ne le règle : 20 est
        -- l'ancien défaut, toute autre valeur a été posée à la main et reste.
        if db.mergeRange == 20 then db.mergeRange = LL.DEFAULTS.mergeRange end
        db.schemaVer = 4
    end
end

-- Raccourcis appelés par Bindings.xml (le client ne sait appeler qu'une globale).
function LL:Record()      LL.Capture:Record("manual") end
function LL:TrackNearest()
    local node = LL.Nodes:NearestToPlayer()
    if node then LL.HUD:Track(node) else LL:NoneHere() end
end

function LL:NoneHere()
    LL:Printf(L["Aucune %s connue dans cette zone."], LL.Nodes:Word("one"))
end

-- Les points (minicarte, carte, bandeau) masqués sur ce personnage : option `/ley skyborne` et pas
-- Skyborne. Le rappel de buff n'y regarde pas : sans le sort, il n'y a pas de buff à rappeler.
function LL:PinsHidden()
    return (LL.db.skyborneOnly and not LL.Capture:IsAbsorber()) and true or false
end

-- Sans cette ligne, « Suivi : activé » suivi de rien à l'écran ressemblerait à un bug.
function LL:WarnHidden()
    if LL:PinsHidden() then
        LL:Print(L["Points masqués sur ce personnage (pas Skyborne) : /ley skyborne pour les afficher partout."])
    end
end

-- ---------------------------------------------------------------------------
-- Commandes
-- ---------------------------------------------------------------------------
local CMD = {}

-- Les comptes sont ceux de l'espèce du JOUEUR : ce qu'il voit sur sa carte, pas ce que la base
-- du compte range pour ses personnages de l'autre faction.
CMD.status = function()
    local kind = LL.Nodes:PlayerKind()
    local map  = LL.Geo:PlayerMap()
    local here = map and LL.Nodes:CountMap(map, kind) or 0
    LL:Printf(L["v%s — %s %s ici, %s au total."], LL.VERSION, here, LL.Nodes:Word("many"),
        LL.Nodes:Count(kind))
    local node, dist = LL.Nodes:NearestToPlayer()
    if node then
        LL:Printf(L["La plus proche : %s à %s yd."], LL.Nodes:Label(node), math.floor(dist + 0.5))
    end
    LL:Printf(L["Minicarte %s — carte %s — suivi %s — capture auto %s."],
        LL:OnOff(LL.db.minimap.show), LL:OnOff(LL.db.worldmap.show),
        LL:OnOff(LL.db.hud.show), LL:OnOff(LL.Capture:AutoEnabled()))
    LL:WarnHidden()
end

CMD.add = function(rest)
    LL.Capture:Record("manual", (rest ~= "" and rest) or nil)
end
CMD.here = CMD.add
CMD.ici  = CMD.add

CMD.del = function()
    local node, dist = LL.Nodes:NearestToPlayer()
    if not node or dist > 60 then
        LL:Printf(L["Aucune %s à moins de 60 yd — place-toi dessus pour l'effacer."], LL.Nodes:Word("one"))
        return
    end
    LL:DeleteNode(node)
end

-- Le geste commun de `/ley del` et du clic droit sur la grande carte (après confirmation).
function LL:DeleteNode(node)
    if not LL.Nodes:Remove(node) then return end   -- déjà parti (popup restée ouverte)
    LL.Nodes:Snapshot(true)   -- effacement VOULU : il doit tenir au prochain chargement
    LL:Printf(L["%s effacée."], LL.Nodes:Label(node))
    LL:Refresh()
end
CMD.suppr = CMD.del

CMD.list = function()
    local kind = LL.Nodes:PlayerKind()
    local map  = LL.Geo:PlayerMap()
    local n    = map and LL.Nodes:CountMap(map, kind) or 0
    if n == 0 then return LL:NoneHere() end
    LL:Printf(L["%s %s dans %s :"], n, LL.Nodes:Word("many"), LL.Geo:MapName(map))
    for _, node in ipairs(LL.Nodes:All(map)) do
        if LL.Nodes:Shows(node, kind) then
            local dist = LL.Nodes:DistanceToPlayer(node)
            LL:Printf("  |cff9b6ef3%s|r  %.1f / %.1f  —  %s yd  (%s)", LL.Nodes:Label(node),
                node.x * 100, node.y * 100, dist and math.floor(dist + 0.5) or "?", LL.Nodes:SourceLabel(node))
        end
    end
end
CMD.liste = CMD.list

CMD.clear = function()
    local map = LL.Geo:PlayerMap()
    if not map or LL.Nodes:CountMap(map, LL.Nodes:PlayerKind()) == 0 then return LL:NoneHere() end
    StaticPopup_Show("LEYLINES_CLEAR_ZONE", LL.Nodes:Word("all"), LL.Geo:MapName(map), map)
end
CMD.vider = CMD.clear

-- Partagé par `/ley hud` et le clic droit du compartiment d'addons (LeyLines_Compartment.lua).
function LL:ToggleHUD()
    LL.db.hud.show = not LL.db.hud.show
    LL.HUD:Apply()
    LL:Printf(L["Suivi à l'écran : %s."], LL:OnOff(LL.db.hud.show))
    LL:WarnHidden()
end

CMD.hud = function() LL:ToggleHUD() end

CMD.pins = function()
    LL.db.minimap.show = not LL.db.minimap.show
    LL:Refresh()
    LL:Printf(L["Affichage sur la minicarte : %s."], LL:OnOff(LL.db.minimap.show))
    LL:WarnHidden()
end
CMD.minimap = CMD.pins

CMD.map = function()
    LL.db.worldmap.show = not LL.db.worldmap.show
    LL:Refresh()
    LL:Printf(L["Affichage sur la carte du monde : %s."], LL:OnOff(LL.db.worldmap.show))
    LL:WarnHidden()
end
CMD.carte = CMD.map

-- Demandé sur CurseForge le 2026-10-04 (« only show ley lines when playing a skyborn ») : la base
-- est au compte, donc un personnage d'une autre race voyait des points qu'il ne peut pas absorber.
CMD.skyborne = function()
    LL.db.skyborneOnly = not LL.db.skyborneOnly
    LL:Refresh()
    LL:Printf(L["Points seulement sur un personnage Skyborne : %s."], LL:OnOff(LL.db.skyborneOnly))
    LL:WarnHidden()
end
CMD.skyborn = CMD.skyborne

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
    LL.Nodes:Snapshot(true)
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
-- `/ley contribute all` (ou `tout`) renvoie tout ce que le joueur a confirmé, pas seulement le neuf.
CMD.contribute = function(rest)
    local arg = string.lower(rest)
    LL.Share:ShowContribute(arg == "all" or arg == "tout")
end
CMD.contribuer = CMD.contribute

-- Les contributeurs de la liste livrée (docs/specs/remerciements.md).
CMD.credits = function() LL.Thanks:Show() end
CMD.merci = CMD.credits

-- `/ley signal on|off` ; sans argument, bascule, comme hud / pins / map. Coupé, le signal se tait
-- mais le nombre reste calculé : il est redonné ici.
CMD.signal = function(rest)
    local arg = string.lower(rest)
    if arg == "on" then LL.db.signal = true
    elseif arg == "off" then LL.db.signal = false
    else LL.db.signal = not LL.db.signal end
    LL:Refresh()
    LL:Printf(L["Signal des positions à partager : %s."], LL:OnOff(LL.db.signal))
    local pending = LL.Signal:Count()
    if pending > 0 then
        LL:Printf(L["%s position(s) à partager, absente(s) de la liste commune."], pending)
    end
end

CMD.probe = function() LL.Probe:Dump() end
CMD.diag  = CMD.probe

-- Signaler un bug ou une idée : le lien d'un ticket GitHub (LeyLines_Report.lua).
CMD.bug  = function() LL.Report:Open("bug") end
CMD.idea = function() LL.Report:Open("idea") end
CMD.idee = CMD.idea
CMD["idée"] = CMD.idea

CMD.help = function()
    LL:Print(L["Commandes : /ley (état), add, del, list, clean, clear, export, import, contribute, bug, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."])
    LL:Printf(L["Marche à suivre : place-toi SUR la %s et fais /ley add (ou le raccourci clavier)."],
        LL.Nodes:Word("one"))
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
    text         = L["Effacer toutes les %s connues dans %s ?"],
    button1      = YES,
    button2      = NO,
    OnAccept     = function(_, map)
        local n = LL.Nodes:ClearMap(map, LL.Nodes:PlayerKind())
        LL.Nodes:Snapshot(true)
        LL:Printf(L["%s %s effacée(s)."], n, LL.Nodes:Word("many"))
        LL:Refresh()
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- Clic droit sur un point de la grande carte : demandé par un joueur le 2026-10-02 (effacer un faux
-- point sans aller dessus, ce qu'exige `/ley del`), avec confirmation à la demande du user.
StaticPopupDialogs["LEYLINES_DELETE_NODE"] = {
    text         = L["Effacer %s (%s) ?"],
    button1      = YES,
    button2      = NO,
    OnAccept     = function(_, node) LL:DeleteNode(node) end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

function LL:ConfirmDelete(node)
    if not node then return end
    StaticPopup_Show("LEYLINES_DELETE_NODE", LL.Nodes:Label(node),
        string.format("%.1f / %.1f", node.x * 100, node.y * 100), node)
end

-- ---------------------------------------------------------------------------
-- Démarrage
-- ---------------------------------------------------------------------------
_G.BINDING_HEADER_LEYLINES = L["Lignes telluriques / Convergences élémentaires"]

-- Les libellés de raccourcis nomment l'objet de la faction : ils attendent donc PLAYER_LOGIN, où
-- la faction est connue. La fenêtre des raccourcis ne s'ouvre pas avant.
local function NameBindings()
    local word = LL.Nodes:Word("one")
    _G.BINDING_NAME_LEYLINES_RECORD = string.format(L["Enregistrer une %s ici"], word)
    _G.BINDING_NAME_LEYLINES_TRACK  = string.format(L["Suivre la %s la plus proche"], word)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        -- INSTRUMENT : on note ce que le CLIENT vient de nous rendre, AVANT d'y toucher. C'est la
        -- seule facon de distinguer deux pannes qui se ressemblent a l'ecran -- « la base a ete
        -- videe pendant la session » et « le client n'a jamais restaure les SavedVariables ».
        -- Lu par `/ley probe`. Une base neuve donne les memes zeros : c'est le RETOUR du zero
        -- alors qu'on a deja joue qui accuse le client.
        local given = LeyLinesDB
        local state = { restored = (given ~= nil), nodes = 0,
                        dataVersion = given and given.dataVersion or nil,
                        backup = given and given.backup and given.backup.n or nil }
        -- Lu AVANT CopyDefaults, qui y ajoute le buff Horde par défaut : la v1.0.0 n'inscrivait
        -- 1270893 (Elemental Blessing) dans `auras` qu'après une VRAIE capture côté Horde. C'est
        -- ce qui permet de classer sans deviner les points sans nom d'une vieille base (Nodes:Init).
        state.legacyHorde = (given and type(given.auras) == "table" and given.auras[1270893] ~= nil) or false
        if given and type(given.nodes) == "table" then
            for _, list in pairs(given.nodes) do state.nodes = state.nodes + #list end
        end
        LL.loadState = state

        LeyLinesDB = LeyLinesDB or {}
        CopyDefaults(LeyLinesDB, LL.DEFAULTS)
        Migrate(LeyLinesDB)
        -- Hors de l'échelle : le buff d'une torche appris par erreur se retire à chaque chargement.
        LL.Capture:KeepShippedAuras(LeyLinesDB)
        LL.db = LeyLinesDB
    elseif event == "PLAYER_LOGOUT" then
        LL.Nodes:Snapshot()
    elseif event == "PLAYER_LOGIN" then
        LL.Nodes:Init()
        NameBindings()
        local restored = LL.Nodes:RestoreIfEmpty()
        LL.Capture:Init()
        LL.Minimap:Init()
        LL.WorldMap:Init()
        LL.HUD:Init()
        LL:Refresh()
        LL:Printf(L["v%s chargée. /ley pour l'état, /ley help pour le reste."], LL.VERSION)
        if restored > 0 then
            LL:Printf(L["%s position(s) restaurée(s) depuis la sauvegarde interne."], restored)
        end
        -- Les données livrées attendent 3 s : l'anti-doublon a besoin de la TAILLE de la zone
        -- (C_Map.GetMapWorldSize), que le client ne donne pas toujours dès PLAYER_LOGIN. Fusionner
        -- trop tôt ferait passer chaque point livré pour un point nouveau, à côté du vôtre.
        C_Timer.After(3, function()
            local since = LL.db.dataVersion or 0   -- lu AVANT la fusion, qui l'avance
            local shipped, gone = LL.Nodes:ApplyShipped()
            if gone > 0 then
                LL:Printf(L["%s position(s) retirée(s) de la liste commune."], gone)
            end
            if shipped > 0 then
                LL:Printf(L["%s position(s) ajoutée(s) depuis les données livrées."], shipped)
                LL.Thanks:Announce(since)
            end
            if shipped > 0 or gone > 0 then LL:Refresh() end
            LL.Nodes:Snapshot(gone > 0)   -- un retrait livré est VOULU : le filet ne doit pas le rendre
            LL.Signal:Init()
        end)
    end
end)
