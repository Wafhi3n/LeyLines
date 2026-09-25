-- LeyLines_Nodes.lua — la base des positions connues, et l'anti-doublon.
--
-- Forme persistée : LeyLinesDB.nodes[uiMapID] = { {x, y, map, name, src, hits, first, last}, ... }
-- x/y sont des coordonnées de CARTE (0..1). Tout le reste de l'addon LIT cette base et n'écrit
-- jamais ailleurs : capture → base → affichage, jamais capture → affichage.
local _, LL = ...
local L = LL.L

local Nodes = {}
LL.Nodes = Nodes

-- Précision de chaque source, du plus fiable au moins fiable :
--   vignette = position de l'OBJET donnée par le client (exacte) ;
--   spell / manual = position du JOUEUR, qui est posé dessus (à un pas près) ;
--   tooltip = position du joueur qui VISE l'objet à distance — ça peut être 30 yd à côté.
-- Un relevé plus précis DÉPLACE le point existant ; un moins précis ne fait que le confirmer.
-- `import` et `shipped` sont volontairement au plus bas : une position reçue d'un autre joueur ou
-- livrée avec l'addon ne doit JAMAIS déplacer un relevé que CE joueur a fait sur place. Elle
-- comble un trou, elle ne corrige pas une vérité locale.
local PRECISION = { vignette = 3, spell = 2, manual = 2, tooltip = 1, import = 1, shipped = 1, restored = 2 }

local SOURCE_LABEL = {
    vignette = L["vignette du client"],
    spell    = L["sort"],
    manual   = L["relevé manuel"],
    tooltip  = L["infobulle"],
    import   = L["import"],
    shipped  = L["livré avec l'addon"],
    restored = L["restauré"],
}

-- Nettoie un nom lu sur le client : le texte d'une infobulle peut porter du balisage (icône
-- |T...|t, atlas |A...|a, couleur |c...|r) qui s'affiche ensuite en glyphe parasite dans NOS
-- messages — vu en jeu le 2026-09-20 : « Map pin set on ▾ Ley Line ».
function Nodes:CleanName(text)
    if type(text) ~= "string" then return nil end
    local ok, clean = pcall(function()
        local s = text:gsub("|[Tt].-|[Tt]", ""):gsub("|A.-|a", "")
        s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end)
    if not ok or clean == "" then return nil end
    return clean
end

-- Remet la base d'aplomb au démarrage : `map` est dupliqué dans chaque point (il rend Remove et
-- DistanceToPlayer autonomes), une entrée sans coordonnées est jetée plutôt que promenée, et les
-- noms déjà stockés repassent par le nettoyage (la base survit aux versions, pas les bugs).
function Nodes:Init()
    LL.db.nodes = LL.db.nodes or {}
    for map, list in pairs(LL.db.nodes) do
        for i = #list, 1, -1 do
            local node = list[i]
            if type(node) ~= "table" or type(node.x) ~= "number" or type(node.y) ~= "number" then
                table.remove(list, i)
            else
                node.map  = map
                node.name = self:CleanName(node.name)
            end
        end
    end
end

-- Efface les points venus d'une source donnée (aujourd'hui « tooltip ») : de quoi rattraper une
-- session où une source approximative a semé des positions fausses, sans vider la zone entière.
function Nodes:RemoveBySource(src)
    local removed = 0
    for _, list in pairs(LL.db.nodes) do
        for i = #list, 1, -1 do
            if list[i].src == src then
                table.remove(list, i)
                removed = removed + 1
            end
        end
    end
    return removed
end

-- ---------------------------------------------------------------------------
-- Filet de sécurité
--
-- Le 2026-09-20, une base s'est retrouvée VIDE après une déconnexion : SavedVariables déclarées,
-- aucune erreur Lua attrapée, et pourtant les relevés du joueur avaient disparu. Cause jamais
-- établie — ce qui est précisément la raison d'être d'un filet : pour un addon dont le SEUL travail
-- est de retenir des positions, une perte silencieuse est la pire panne possible.
--
-- L'instantané est stocké en TEXTE (codec LL1), pas en table : une chaîne survit à un changement
-- de forme des données, se relit à l'oeil dans le fichier, et se recolle dans `/ley import` à la
-- main si tout le reste échoue.
-- ---------------------------------------------------------------------------

-- Règle : on ne remplace JAMAIS un instantané non vide par un instantané vide, sauf si le joueur
-- vient d'effacer lui-même (`force`). Sans ça, la première session qui démarre à vide écraserait
-- la seule copie qui restait.
function Nodes:Snapshot(force)
    if not LL.Share then return end
    local count = self:Count()
    local kept  = LL.db.backup and LL.db.backup.n or 0
    if count == 0 and kept > 0 and not force then return end
    LL.db.backup = { at = time(), n = count, blob = LL.Share:Encode() }
end

function Nodes:RestoreIfEmpty()
    local backup = LL.db.backup
    if self:Count() > 0 or not backup or not backup.blob or (backup.n or 0) == 0 then return 0 end

    local data = LL.Share and LL.Share:Decode(backup.blob)
    if not data then return 0 end
    local restored = 0
    for map, pts in pairs(data) do
        for i = 1, #pts - 1, 2 do
            local _, isNew = self:Add(map, pts[i], pts[i + 1], { src = "restored" })
            if isNew then restored = restored + 1 end
        end
    end
    return restored
end

-- Fusionne les positions livrées avec l'addon (LeyLines_Data.lua), UNE fois par palier de
-- DATA_VERSION. Sans ce palier, un point que le joueur a effacé exprès reviendrait à chaque
-- chargement : la base lui appartient dès la première fusion.
function Nodes:ApplyShipped()
    local version = LL.DATA_VERSION or 0
    if (LL.db.dataVersion or 0) >= version then return 0 end

    local added = 0
    for map, list in pairs(LL.DATA or {}) do
        for i = 1, #list - 1, 2 do
            local _, isNew = self:Add(map, list[i], list[i + 1], { src = "shipped" })
            if isNew then added = added + 1 end
        end
    end
    LL.db.dataVersion = version
    return added
end

function Nodes:All(map)
    return map and LL.db.nodes[map] or nil
end

function Nodes:CountMap(map)
    local list = self:All(map)
    return list and #list or 0
end

function Nodes:Count()
    local total = 0
    for _, list in pairs(LL.db.nodes) do total = total + #list end
    return total
end

-- Point le plus proche de x/y sur cette carte. `range` filtre le résultat ; sans `range`, rend le
-- plus proche quelle que soit la distance. Renvoie node, index, distance.
function Nodes:Find(map, x, y, range)
    local list = self:All(map)
    if not list then return nil end
    local best, bestIdx, bestDist
    for i, node in ipairs(list) do
        local d = LL.Geo:Distance(map, x, y, node.x, node.y)
        if d and (not bestDist or d < bestDist) then best, bestIdx, bestDist = node, i, d end
    end
    if best and (not range or bestDist <= range) then return best, bestIdx, bestDist end
    return nil, nil, bestDist
end

function Nodes:Add(map, x, y, info)
    if not map or type(x) ~= "number" or type(y) ~= "number" then return nil, false end
    info = info or {}

    local existing = self:Find(map, x, y, LL.db.mergeRange)
    if existing then
        self:Confirm(existing, x, y, info)
        return existing, false
    end

    local list = LL.db.nodes[map]
    if not list then list = {}; LL.db.nodes[map] = list end
    local node = {
        map = map, x = x, y = y,
        name  = info.name,
        src   = info.src or "manual",
        hits  = 1,
        first = time(), last = time(),
    }
    table.insert(list, node)
    return node, true
end

function Nodes:Confirm(node, x, y, info)
    node.hits = (node.hits or 1) + 1
    node.last = time()
    if info.name and not node.name then node.name = info.name end

    local incoming = PRECISION[info.src or "manual"] or 1
    local current  = PRECISION[node.src or "manual"] or 1
    if incoming >= current then
        node.x, node.y, node.src = x, y, info.src or node.src
    end
end

function Nodes:Remove(node)
    local list = self:All(node and node.map)
    if not list then return false end
    for i, n in ipairs(list) do
        if n == node then table.remove(list, i); return true end
    end
    return false
end

function Nodes:ClearMap(map)
    local n = self:CountMap(map)
    LL.db.nodes[map] = nil
    return n
end

function Nodes:NearestToPlayer()
    local map, x, y = LL.Geo:PlayerPos()
    if not map then return nil end
    local node, _, dist = self:Find(map, x, y)
    if not node then return nil end
    return node, dist or 0
end

function Nodes:DistanceToPlayer(node)
    if not node then return nil end
    local map, x, y = LL.Geo:PlayerPos()
    if not map or node.map ~= map then return nil end
    return LL.Geo:Distance(map, x, y, node.x, node.y)
end

-- Libellé par défaut selon la faction du joueur : la Horde absorbe une vergence élémentaire,
-- l'Alliance une ligne tellurique. Un nom lu sur le client (node.name) passe toujours devant.
function Nodes:Label(node)
    if node and node.name then return node.name end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Horde" then return L["Vergence élémentaire"] end
    return L["Ligne tellurique"]
end

function Nodes:SourceLabel(node)
    return SOURCE_LABEL[node and node.src or ""] or L["inconnue"]
end
