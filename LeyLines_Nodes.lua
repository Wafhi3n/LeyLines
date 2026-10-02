-- LeyLines_Nodes.lua — la base des positions connues, et l'anti-doublon.
--
-- Forme persistée : LeyLinesDB.nodes[uiMapID] = { {x, y, map, kind, name, src, hits, first, last, seen, found}, ... }
-- x/y sont des coordonnées de CARTE (0..1). Tout le reste de l'addon LIT cette base et n'écrit
-- jamais ailleurs : capture → base → affichage, jamais capture → affichage.
--
-- `kind`, l'ESPÈCE du point (depuis la v1.1.0) : chaque faction absorbe SON objet, et seulement
-- le sien (dit par le joueur le 2026-09-27) — l'Alliance une fissure au sol (Ley Line), la Horde
-- une tornade (Elemental Convergence). La base est au niveau du COMPTE, donc un joueur qui a des
-- personnages des deux côtés mélange les deux : sans espèce, un code Horde importé chez un gnome
-- posait des « Ley Line » dans les Tarides (vu en jeu le 2026-09-27).
local _, LL = ...
local L = LL.L

local Nodes = {}
LL.Nodes = Nodes

-- Précision de chaque source, du plus fiable au moins fiable :
--   vignette = position de l'OBJET donnée par le client (exacte) ;
--   spell / manual = position du JOUEUR, à portée de l'objet (le buff long se donne jusqu'à ~25 yd) ;
--   tooltip = position du joueur qui VISE l'objet à distance — ça peut être 30 yd à côté.
-- Un relevé plus précis DÉPLACE le point existant ; un relevé de même précision ou moins précis ne
-- fait que le confirmer (le premier reste, voir Nodes:Confirm).
-- `import` et `shipped` sont volontairement au plus bas : une position reçue d'un autre joueur ou
-- livrée avec l'addon ne doit JAMAIS déplacer un relevé que CE joueur a fait sur place. Elle
-- comble un trou, elle ne corrige pas une vérité locale.
local PRECISION = { vignette = 3, spell = 2, manual = 2, tooltip = 1, import = 1, shipped = 1, restored = 2 }

-- Les sources que le JEU a tranchées : la position de l'objet donnée par le client (vignette), ou un
-- lancer suivi du buff long (sort). Elles seules partent vers la liste commune (A2), et elles seules
-- datent `seen`, la dernière observation CONFIRMÉE, et `found`, la PREMIÈRE. `last` bouge aussi
-- quand une donnée livrée ou importée recoupe le point : il ne dit pas que quelqu'un est allé voir.
-- (docs/specs/contribution-positions.md, critères 3 et 4 ; `found` : signal-contribution.md, le
-- signal ne se rallume pas pour une position déjà partagée puis reconfirmée.)
local VERIFIED = { spell = true, vignette = true }
Nodes.VERIFIED = VERIFIED

local SOURCE_LABEL = {
    vignette = L["vignette du client"],
    spell    = L["sort"],
    manual   = L["relevé manuel"],
    tooltip  = L["infobulle"],
    import   = L["import"],
    shipped  = L["livré avec l'addon"],
    restored = L["restauré"],
}

-- ---------------------------------------------------------------------------
-- Espèce : L = fissure (Alliance), V = tornade (Horde). TOUT point en a une.
--
-- Un point d'avant la v1.1.0 n'en a pas : il la reçoit au chargement (Init), d'après son nom s'il
-- en dit quelque chose, sinon d'après LegacyKind (A4). Une espèce « inconnue, visible des deux » a
-- été essayée le 2026-09-27 et rejetée en jeu : c'est exactement ce qui posait des « Ley Line »
-- Horde dans les Tarides chez un personnage Alliance. Un code d'échange sans espèce ne s'importe
-- donc plus (Share:Import).
-- ---------------------------------------------------------------------------
local KINDS = { L = true, V = true }

-- Les deux noms sont FÉMININS dans les quatre langues livrées (ligne / convergence, Linie /
-- Konvergenz, línea / convergencia) : une seule phrase par message suffit, l'accord tient. Une
-- langue où ce n'est plus vrai demandera deux phrases.
local WORDS = {
    L = { title = L["Ligne tellurique"], one = L["ligne tellurique"],
          many = L["ligne(s) tellurique(s)"], all = L["lignes telluriques"] },
    V = { title = L["Convergence élémentaire"], one = L["convergence élémentaire"],
          many = L["convergence(s) élémentaire(s)"], all = L["convergences élémentaires"] },
}

function Nodes:PlayerKind()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    return faction == "Horde" and "V" or "L"
end

-- L'espèce qu'un nom lu sur le client trahit, ou nil. « vergence » attrape Elemental Convergence
-- et ses traductions du même tronc ; « ley » et « tellurique », la fissure.
function Nodes:KindOfName(name)
    if type(name) ~= "string" then return nil end
    local ok, lowered = pcall(string.lower, name)
    if not ok then return nil end
    if string.find(lowered, "vergence", 1, true) then return "V" end
    if string.find(lowered, "ley", 1, true) or string.find(lowered, "tellurique", 1, true) then
        return "L"
    end
    return nil
end

-- Le nom de l'objet pour les MESSAGES : title (début de phrase), one, many (« ligne(s) »), all.
function Nodes:Word(form, kind)
    return (WORDS[kind] or WORDS[self:PlayerKind()])[form]
end

-- Ce point s'affiche-t-il pour l'espèce `kind` ?
function Nodes:Shows(node, kind)
    return node.kind == kind
end

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
-- Un point confirmé d'avant `seen` (v1.2.1 et avant) en reçoit un : la première contribution après
-- la mise à jour le renvoie, comme elle l'aurait fait avant — l'ingestion dédoublonne. Un point
-- confirmé d'avant `found` reçoit son `seen` : la meilleure date connue de sa découverte.
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
                if node.seen == nil and VERIFIED[node.src] then
                    node.seen = node.last or node.first or 1
                end
                if node.found == nil then node.found = node.seen end
            end
        end
    end
    self:KeepLegacyCopy()
    local legacy = self:LegacyKind()
    for _, list in pairs(LL.db.nodes) do
        for _, node in ipairs(list) do
            node.kind = KINDS[node.kind] and node.kind or self:KindOfName(node.name) or legacy
        end
    end
end

-- Espèce d'un point d'avant la v1.1.0 dont le nom ne dit rien (A4). La v1.0.0 capturait AUSSI côté
-- Horde, via `/ley learn`, et inscrivait alors le buff Horde dans `auras` (LeyLines.lua le relève
-- avant que les défauts ne l'y ajoutent). Base qui n'en porte aucun : tout y a été capturé côté
-- Alliance, fissure. Sinon, la faction du personnage qui la charge en premier — juste pour un compte
-- d'une seule faction, c'est-à-dire presque toujours, et KeepLegacyCopy couvre le reste.
function Nodes:LegacyKind()
    if LL.loadState and LL.loadState.legacyHorde then return self:PlayerKind() end
    return "L"
end

-- Avant de donner une espèce aux points d'une vieille base, on en garde UNE copie texte telle
-- quelle, jamais réécrite : si le classement se trompe, rien n'est perdu. Le joueur ne voit rien,
-- c'est une assurance que l'on relit dans son fichier de SavedVariables.
function Nodes:KeepLegacyCopy()
    if LL.db.legacy or not LL.Share then return end
    for _, list in pairs(LL.db.nodes) do
        for _, node in ipairs(list) do
            if not KINDS[node.kind] then
                LL.db.legacy = { at = time(), blob = LL.Share:Encode() }
                return
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

    local segments = LL.Share and LL.Share:Decode(backup.blob)
    if not segments then return 0 end
    -- Un instantané LL1 date d'avant l'espèce : même règle qu'au chargement (A4), fissure.
    return self:AddSegments(segments, "restored", "L")
end

-- Verse dans la base des segments décodés par Share:Decode ({ map, kind, pts }). `defaultKind`
-- sert aux segments sans espèce. Rend le nombre de points NOUVEAUX ; les autres ont confirmé un
-- point existant.
function Nodes:AddSegments(segments, src, defaultKind)
    local added = 0
    for _, seg in ipairs(segments) do
        local kind = seg.kind or defaultKind
        for i = 1, #seg.pts - 1, 2 do
            local _, isNew = self:Add(seg.map, seg.pts[i], seg.pts[i + 1], { src = src, kind = kind })
            if isNew then added = added + 1 end
        end
    end
    return added
end

-- Fusionne les positions livrées avec l'addon (LeyLines_Data.lua) : seulement celles qu'un palier
-- de DATA_VERSION a introduites DEPUIS la dernière fusion de ce joueur. Chaque point livré porte
-- son palier (triplets x, y, palier) : sans ça, chaque nouvelle livraison recopiait la liste
-- ENTIÈRE, et un point que le joueur avait effacé exprès revenait à chaque mise à jour des données.
-- La base lui appartient dès la première fusion.
-- Rend le nombre de points ajoutés, puis le nombre de points retirés (Nodes:ApplyGone).
function Nodes:ApplyShipped()
    local version = LL.DATA_VERSION or 0
    local since   = LL.db.dataVersion or 0
    if since >= version then return 0, 0 end

    local removed = self:ApplyGone(since)
    local added = 0
    for kind, maps in pairs(LL.DATA or {}) do
        for map, list in pairs(maps) do
            for i = 1, #list - 2, 3 do
                if (list[i + 2] or 0) > since then
                    local _, isNew = self:Add(map, list[i], list[i + 1], { src = "shipped", kind = kind })
                    if isNew then added = added + 1 end
                end
            end
        end
    end
    LL.db.dataVersion = version
    return added, removed
end

-- Retraits livrés (LL.GONE, mêmes triplets x, y, palier) : les points dont le seul témoin était un
-- auteur exclu de la liste commune (docs/specs/contribution-positions.md, D8). Pour chacun, le
-- point livré LUI-MÊME s'en va, s'il vient de la liste ou d'un import ; un relevé du joueur reste,
-- même un point livré qu'il a confirmé en lançant le sort (il est passé en `spell`) : A3. Passe
-- AVANT les ajouts, pour qu'un point re-livré par la même mise à jour revienne.
-- GONE_MATCH et pas `mergeRange` : un point `shipped`/`import` est posé aux coordonnées exactes de
-- la liste (quatre décimales, < 1 yd) et ne bouge plus tant qu'il garde cette source. Le rayon de
-- fusion, lui, attraperait un VRAI point voisin dans lequel le faux s'était fondu à la livraison :
-- l'outil, sur une zone de taille inconnue, compare à ±0,01 de carte, moins de 50 yd sur une zone
-- étroite, et peut donc retirer un point que ce client avait fusionné avec un autre.
local GIVEN = { shipped = true, import = true }
local GONE_MATCH = 5   -- yards

function Nodes:ApplyGone(since)
    local removed = 0
    for kind, maps in pairs(LL.GONE or {}) do
        for map, list in pairs(maps) do
            for i = 1, #list - 2, 3 do
                if (list[i + 2] or 0) > since then
                    local node = self:Find(map, list[i], list[i + 1], GONE_MATCH, kind)
                    if node and GIVEN[node.src] and self:Remove(node) then removed = removed + 1 end
                end
            end
        end
    end
    return removed
end

function Nodes:All(map)
    return map and LL.db.nodes[map] or nil
end

-- Sans `kind`, compte TOUT (le filet de sécurité en a besoin) ; avec, ce que cette espèce voit.
function Nodes:CountMap(map, kind)
    local list = self:All(map)
    if not list then return 0 end
    if not kind then return #list end
    local n = 0
    for _, node in ipairs(list) do
        if self:Shows(node, kind) then n = n + 1 end
    end
    return n
end

function Nodes:Count(kind)
    local total = 0
    for map in pairs(LL.db.nodes) do total = total + self:CountMap(map, kind) end
    return total
end

-- Point le plus proche de x/y sur cette carte. `range` filtre le résultat ; sans `range`, rend le
-- plus proche quelle que soit la distance. `kind` écarte l'AUTRE espèce : une fissure et une tornade
-- à 5 yd l'une de l'autre sont deux objets. Renvoie node, index, distance.
function Nodes:Find(map, x, y, range, kind)
    local list = self:All(map)
    if not list then return nil end
    local best, bestIdx, bestDist
    for i, node in ipairs(list) do
        local d = (not kind or self:Shows(node, kind)) and LL.Geo:Distance(map, x, y, node.x, node.y)
        if d and (not bestDist or d < bestDist) then best, bestIdx, bestDist = node, i, d end
    end
    if best and (not range or bestDist <= range) then return best, bestIdx, bestDist end
    return nil, nil, bestDist
end

function Nodes:Add(map, x, y, info)
    if not map or type(x) ~= "number" or type(y) ~= "number" then return nil, false end
    info = info or {}

    local existing = self:Find(map, x, y, LL.db.mergeRange, info.kind)
    if existing then
        self:Confirm(existing, x, y, info)
        return existing, false
    end

    local list = LL.db.nodes[map]
    if not list then list = {}; LL.db.nodes[map] = list end
    local node = {
        map = map, x = x, y = y,
        -- Les appelants donnent toujours l'espèce ; à défaut, celle du joueur plutôt qu'aucune.
        kind  = KINDS[info.kind] and info.kind or self:PlayerKind(),
        name  = info.name,
        src   = info.src or "manual",
        hits  = 1,
        first = time(), last = time(),
        seen  = VERIFIED[info.src] and time() or nil,
        found = VERIFIED[info.src] and time() or nil,
    }
    table.insert(list, node)
    return node, true
end

function Nodes:Confirm(node, x, y, info)
    node.hits = (node.hits or 1) + 1
    node.last = time()
    if VERIFIED[info.src] then
        node.seen  = time()
        node.found = node.found or node.seen
    end
    if info.name and not node.name then node.name = info.name end
    if not node.kind and KINDS[info.kind] then node.kind = info.kind end

    -- Le point ne bouge que pour mieux : une source plus précise, ou le jeu qui tranche un point
    -- qu'il n'avait pas tranché (un lancer sur un relevé manuel). À précision égale, le PREMIER
    -- reste : un lancer du bord de la portée tirait sinon à 25 yd un point posé pile sur la
    -- fissure, et un `/ley add` sur un point de sort le redescendait en `manual`.
    local incoming = PRECISION[info.src or "manual"] or 1
    local current  = PRECISION[node.src or "manual"] or 1
    if incoming > current or (VERIFIED[info.src] and not VERIFIED[node.src]) then
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

-- Avec `kind`, n'efface que ce que cette espèce VOIT : un joueur Horde qui vide les Tarides ne
-- touche pas aux fissures qu'un personnage Alliance du même compte y aurait relevées.
function Nodes:ClearMap(map, kind)
    local list = self:All(map)
    if not list then return 0 end
    local n = 0
    for i = #list, 1, -1 do
        if not kind or self:Shows(list[i], kind) then
            table.remove(list, i)
            n = n + 1
        end
    end
    if #list == 0 then LL.db.nodes[map] = nil end
    return n
end

-- Le plus proche parmi ce que le JOUEUR voit : l'objet de sa faction.
function Nodes:NearestToPlayer()
    local map, x, y = LL.Geo:PlayerPos()
    if not map then return nil end
    local node, _, dist = self:Find(map, x, y, nil, self:PlayerKind())
    if not node then return nil end
    return node, dist or 0
end

function Nodes:DistanceToPlayer(node)
    if not node then return nil end
    local map, x, y = LL.Geo:PlayerPos()
    if not map or node.map ~= map then return nil end
    return LL.Geo:Distance(map, x, y, node.x, node.y)
end

-- Libellé d'un point : le nom lu sur le client s'il existe, sinon celui de son ESPÈCE — et, pour
-- une espèce inconnue, celui de l'objet de la faction du joueur.
function Nodes:Label(node)
    if node and node.name then return node.name end
    return self:Word("title", node and node.kind)
end

function Nodes:SourceLabel(node)
    return SOURCE_LABEL[node and node.src or ""] or L["inconnue"]
end
