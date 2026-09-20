-- LeyLines_Probe.lua — `/ley probe` : ce que le client expose RÉELLEMENT autour de toi.
--
-- Raison d'être : l'addon est écrit sans avoir vu une ligne tellurique de près. Trois inconnues
-- ne se tranchent qu'en jeu — (1) le client en fait-il une VIGNETTE (auquel cas la capture est
-- automatique et exacte), (2) sous quel NOM exact l'infobulle l'annonce, (3) C_Minimap.GetViewRadius
-- rend-il bien un rayon. Cette commande répond aux trois en un passage, debout sur la ligne.
--
-- Les libellés de ce fichier restent en français À DESSEIN : c'est une sortie de diagnostic pour le
-- développeur, pas du chrome — elle ne passe donc pas par LL.L.
local _, LL = ...

local Probe = {}
LL.Probe = Probe

local function YesNo(v) return v and "oui" or "non" end

function Probe:Dump()
    LL:Print("---- diagnostic ----")
    self:DumpLoad()
    self:DumpPosition()
    self:DumpMinimap()
    self:DumpWorldMap()
    self:DumpVignettes()
    self:DumpAreaPOIs()
    self:DumpCapture()
end

-- Ce que le client a rendu au chargement, avant que l'addon n'y touche.
function Probe:DumpLoad()
    local st = LL.loadState
    if not st then LL:Print("chargement : instrument absent"); return end
    LL:Printf("au chargement : SavedVariables rendues %s, %s point(s), dataVersion %s, instantane %s",
        YesNo(st.restored), st.nodes, tostring(st.dataVersion), tostring(st.backup))
    if st.restored and st.nodes == 0 and (st.backup or 0) > 0 then
        LL:Print("  >>> base VIDE alors qu'un instantane existe : la perte vient de la SESSION")
    elseif not st.restored then
        LL:Print("  >>> le client n'a RIEN rendu : soit 1re utilisation, soit SavedVariables non restaurees")
    end
end

function Probe:DumpPosition()
    local map, x, y = LL.Geo:PlayerPos()
    if not map then
        LL:Print("position : INDISPONIBLE (C_Map.GetPlayerMapPosition rend nil ici)")
        return
    end
    local w, h = LL.Geo:MapSize(map)
    LL:Printf("carte : %s (uiMapID %s) — position %.2f / %.2f", LL.Geo:MapName(map), map, x * 100, y * 100)
    LL:Printf("taille de la zone : %s x %s yards%s", w and math.floor(w) or "?",
        h and math.floor(h) or "?", w and "" or "  <<< sans taille, aucun calcul de distance")
    LL:Printf("lignes connues : %s ici, %s au total", LL.Nodes:CountMap(map), LL.Nodes:Count())
end

function Probe:DumpMinimap()
    local raw = (C_Minimap and C_Minimap.GetViewRadius) and C_Minimap.GetViewRadius() or nil
    LL:Printf("minicarte : rayon brut %s -> rayon retenu %.1f yd (echelle %s)",
        raw and string.format("%.1f", raw) or "API absente",
        LL.Geo:MinimapRadius(), LL.db.minimap.scale)
    LL:Printf("  zoom %s, largeur %.0f px, rotation %s",
        Minimap.GetZoom and Minimap:GetZoom() or "?", Minimap:GetWidth(),
        YesNo(LL.Geo:MinimapRotating()))

    local pin = LL.Minimap.pins and LL.Minimap.pins[1]
    if pin then
        LL:Printf("  1er point : protege %s, visible %s", YesNo(pin:IsProtected()), YesNo(pin:IsShown()))
        LL:Printf("  texture chargee : icone %s, fleche %s",
            YesNo(pin.icon:GetTexture() ~= nil),
            YesNo(LL.HUD.frame and LL.HUD.frame.arrow:GetTexture() ~= nil))
    else
        LL:Print("  aucun point affiche pour l'instant")
    end
end

-- Le point central : si les lignes telluriques sont des vignettes, on lit leur position EXACTE.
-- On liste donc TOUTES les vignettes autour, pas seulement celles qui matchent, pour apprendre le
-- nom reel du jour ou le motif ne correspond pas.
function Probe:DumpVignettes()
    if not C_VignetteInfo or not C_VignetteInfo.GetVignettes then
        LL:Print("vignettes : C_VignetteInfo absent sur ce client")
        return
    end
    local guids = C_VignetteInfo.GetVignettes() or {}
    LL:Printf("vignettes autour : %s", #guids)
    for _, guid in ipairs(guids) do
        local info = C_VignetteInfo.GetVignetteInfo(guid)
        if info then
            LL:Printf("  \"%s\"  atlas=%s  reconnue=%s", tostring(info.name),
                tostring(info.atlasName), YesNo(LL.Capture:Matches(info.name)))
        end
    end
end

-- Un point de carte peut etre PRESENT, survolable, et invisible : il suffit qu'il soit dessine a
-- 5 px ou sous une couche de la carte. Ces nombres-la tranchent, la ou l'oeil ne peut pas.
function Probe:DumpWorldMap()
    if not WorldMapFrame or not WorldMapFrame.GetCanvas then
        LL:Print("carte du monde : cadre absent")
        return
    end
    local canvas = WorldMapFrame:GetCanvas()
    LL:Printf("carte du monde : ouverte %s, canevas %.0f x %.0f", YesNo(WorldMapFrame:IsShown()),
        canvas:GetWidth(), canvas:GetHeight())
    LL:Printf("  echelle du canevas : reelle %.3f, annoncee par GetCanvasScale %.3f",
        canvas:GetScale(),
        (WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale()) or -1)

    local pin = LL.WorldMap.pins and LL.WorldMap.pins[1]
    if not pin then
        LL:Print("  aucun point de carte cree (ouvre la carte d'abord)")
        return
    end
    LL:Printf("  point 1 : visible %s, %.0f px a l'ecran, echelle %.3f, niveau %s (canevas %s)",
        YesNo(pin:IsShown()), pin:GetWidth() * pin:GetEffectiveScale(), pin:GetScale(),
        pin:GetFrameLevel(), canvas:GetFrameLevel())
end

-- Les vignettes ayant rendu 0 en jeu (2026-09-20), voici l'AUTRE mecanisme d'icone qu'un addon
-- peut lire : les Area POI. Ils portent une position exacte — si une faille y figure, la capture
-- redevient automatique sans rien lancer. Sinon, le sort reste la seule source fiable.
function Probe:DumpAreaPOIs()
    local map = LL.Geo:PlayerMap()
    if not map or not C_AreaPoiInfo or not C_AreaPoiInfo.GetAreaPOIForMap then
        LL:Print("area POI : API absente sur ce client")
        return
    end
    local ids = C_AreaPoiInfo.GetAreaPOIForMap(map) or {}
    LL:Printf("area POI sur cette carte : %s", #ids)
    for _, id in ipairs(ids) do
        local info = C_AreaPoiInfo.GetAreaPOIInfo(map, id)
        if info then
            local x, y = info.position and info.position:GetXY()
            LL:Printf("  \"%s\"  atlas=%s  %s", tostring(info.name), tostring(info.atlasName),
                x and string.format("%.1f / %.1f", x * 100, y * 100) or "?")
        end
    end
end

function Probe:DumpCapture()
    local c = LL.db.capture
    LL:Printf("capture : vignette %s, infobulle %s (accrochee %s), sort %s",
        YesNo(c.vignette), YesNo(c.tooltip), YesNo(LL.Capture.tooltipHooked), YesNo(c.spell))
    LL:Printf("noms reconnus : %s", table.concat(LL.db.names, " | "))
    -- %q montre les octets tels quels (balisage |T...|t, glyphes) : c'est ce qui a revele le
    -- « ▾ Ley Line » du 2026-09-20. tostring() seul aurait menti par omission.
    local last = LL.Capture.lastText
    LL:Printf("derniere infobulle vue : %s", last and string.format("%q", last) or "aucune")
    LL:Printf("  proprietaire : %s — souris sur le monde 3D : %s",
        tostring(LL.Capture.lastOwner), YesNo(LL.Capture.lastWorld))
    LL:Printf("  API de focus souris : GetMouseFoci %s, GetMouseFocus %s",
        YesNo(GetMouseFoci ~= nil), YesNo(GetMouseFocus ~= nil))

    local spells = {}
    for id, name in pairs(LL.db.spells) do table.insert(spells, tostring(name) .. " (" .. id .. ")") end
    LL:Printf("sorts retenus : %s", #spells > 0 and table.concat(spells, ", ") or "aucun (/ley learn)")

    local auras = {}
    for id, name in pairs(LL.db.auras) do table.insert(auras, tostring(name) .. " (" .. id .. ")") end
    LL:Printf("buffs de faille reconnus : %s", #auras > 0 and table.concat(auras, ", ") or "aucun")
    local fresh = LL.Capture:FreshLongBuff()
    LL:Printf("buff long pose a l'instant : %s", fresh and tostring(fresh.name) or "aucun")
    -- Une lecture d'aura REFUSEE (auras secretes + execution teintee) met la surveillance en pause :
    -- sans cette ligne, un rappel muet ressemblerait a un bug plutot qu'a une attente.
    LL:Printf("lecture des auras : %s", LL.Capture:AurasBlocked() and "EN PAUSE (refus du client)" or "ouverte")

    local missing = LL.Capture.unavailable
    if missing and #missing > 0 then
        LL:Printf("EVENEMENTS ABSENTS sur ce client : %s", table.concat(missing, ", "))
    end
end
