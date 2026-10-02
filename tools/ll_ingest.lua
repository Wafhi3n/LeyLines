-- ll_ingest.lua — de la contribution d'un joueur à la liste commune (LeyLines_Data.lua).
--
-- Exécuté par Elune (Lua 5.1) via scripts\ll_ingest.ps1, JAMAIS par le client WoW : .pkgmeta
-- exclut tools/ du paquet. Spec : docs/specs/contribution-positions.md.
--
--   add   <dossier LeyLines> <id> <auteur> <date> <L|V|-> <fichier>
--         lit UNE contribution — un code LL2 (ou LL1 si la faction est déclarée), ou un fichier de
--         SavedVariables LeyLines.lua — et l'écrit, normalisée en LL2, dans data/contrib/<id>.ll
--   build <dossier LeyLines> <fichier.ll>...
--         régénère LeyLines_Data.lua à partir de TOUTES les contributions données
--
-- Le code est décodé par LeyLines_Share.lua lui-même : une seule grammaire, celle du client.
--
-- SÉCURITÉ. Tout ce qui entre ici vient d'un inconnu, et ce qui en sort finit en Lua exécuté par
-- chaque client. Donc : (1) un code n'est jamais recopié, il est DÉCODÉ en nombres puis réécrit ;
-- (2) un fichier de SavedVariables EST du code — il est filtré (tables seulement : ni appel, ni
-- concaténation, ni mot-clé), puis évalué dans un environnement VIDE, sans méthodes de chaîne, sous
-- un plafond d'instructions.
local Ingest = {}

local VERIFIED  = { spell = true, vignette = true }   -- même règle que /ley contribute
local HORDE_BUFF = 1270893                              -- Elemental Blessing (voir Nodes:LegacyKind)
-- Même point = même règle que le client (mergeRange) : le buff long se donne jusqu'à REACH yd de
-- l'objet (mesuré le 2026-09-29), deux contributions de la même fissure peuvent donc être à 2 ×
-- REACH. Une fusion au-delà de REACH est probable, pas certaine : elle est SIGNALÉE à la relecture.
local SAME_YD   = 50
local REACH_YD  = 25
-- Taille des zones en yards (C_Map.GetMapWorldSize, relevée en jeu). Zone absente : on compare en
-- unités de carte, ~50 yd sur une zone de 5000 yd, et la fusion est signalée.
local MAP_YARDS = { [2521] = { 5562, 3708 } }   -- Zephras Isle
local TOL_UNKNOWN = 0.01
local MAX_BYTES = 2 * 1024 * 1024
local KINDS     = { L = true, V = true }

-- ---------------------------------------------------------------------------
-- Chargement des modules de l'addon, sans client
-- ---------------------------------------------------------------------------
function Ingest.Setup(dir)
    local LL = {
        L = setmetatable({}, { __index = function(_, k) return k end }),
        Print = function() end, Printf = function() end, Refresh = function() end,
        db = { nodes = {} },
    }
    assert(loadfile(dir .. "/LeyLines_Nodes.lua"))("LeyLines", LL)
    assert(loadfile(dir .. "/LeyLines_Share.lua"))("LeyLines", LL)
    return LL
end

local function ReadFile(path)
    local fh = io.open(path, "rb")
    if not fh then return nil end
    local s = fh:read("*a")
    fh:close()
    return s
end

local function WriteFile(path, text)
    local fh = assert(io.open(path, "wb"))
    fh:write(text)
    fh:close()
end

-- ---------------------------------------------------------------------------
-- Entrée 1 : un code d'échange
-- ---------------------------------------------------------------------------

-- Rend { {kind, map, x, y}, ... } et un rapport. `declared` (L/V ou nil) sert aux points SANS
-- espèce ; sans lui, ils sont écartés et comptés.
function Ingest.FromCode(LL, text, declared)
    local report = { read = 0, noKind = 0, otherKind = 0 }
    local token = type(text) == "string" and text:match("LL[12];[%w;=,%-]+")
    local segments, total = LL.Share:Decode(token)
    if not segments then return nil, "aucun code LL1/LL2 lisible" end
    report.read = total

    local points = {}
    for _, seg in ipairs(segments) do
        local kind = seg.kind or declared
        for i = 1, #seg.pts - 1, 2 do
            if not kind then
                report.noKind = report.noKind + 1
            else
                if declared and kind ~= declared then report.otherKind = report.otherKind + 1 end
                points[#points + 1] = { kind = kind, map = seg.map, x = seg.pts[i], y = seg.pts[i + 1] }
            end
        end
    end
    return points, report
end

-- ---------------------------------------------------------------------------
-- Entrée 2 : un fichier de SavedVariables (le joueur resté en v1.0.0, sans export)
-- ---------------------------------------------------------------------------

-- Retire les chaînes "..." (échappements compris) : ce qui reste doit être de la pure structure.
local function StripStrings(text)
    local out, i, n = {}, 1, #text
    while i <= n do
        local c = text:sub(i, i)
        if c == '"' then
            i = i + 1
            while i <= n and text:sub(i, i) ~= '"' do
                i = i + ((text:sub(i, i) == "\\") and 2 or 1)
            end
            out[#out + 1] = '""'
        else
            out[#out + 1] = c
        end
        i = i + 1
    end
    return table.concat(out)
end

local ALLOWED_WORDS = { LeyLinesDB = true, ["true"] = true, ["false"] = true, ["nil"] = true, e = true, E = true }

-- Ce que le sérialiseur de WoW écrit, et rien d'autre : affectations, tables, nombres, chaînes,
-- booléens, commentaires `-- [n]`. Pas de parenthèse, pas de `:`, pas de `..`, pas de mot-clé :
-- aucun appel ni aucune boucle ne peut s'écrire avec ce qui reste.
local function LooksLikeSavedVariables(text)
    if #text > MAX_BYTES then return false, "fichier trop gros" end
    local bare = StripStrings(text)
    if bare:find('[^%w%s%[%]{}=,%.%-_"]') then return false, "caractère interdit hors chaîne" end
    if bare:find("%.%.") then return false, "concaténation interdite" end
    for word in bare:gmatch("[%a_][%w_]*") do
        if not ALLOWED_WORDS[word] then return false, "mot interdit : " .. word end
    end
    return true
end

function Ingest.LoadSavedVariables(text)
    if type(text) ~= "string" then return nil, "fichier illisible" end
    local ok, why = LooksLikeSavedVariables(text)
    if not ok then return nil, why end
    local fn, err = loadstring(text, "=SavedVariables")
    if not fn then return nil, err end

    local env = {}
    setfenv(fn, env)
    local strmt = getmetatable("")
    local index = strmt.__index
    strmt.__index = nil   -- ("x"):rep(1e9) ne doit même pas exister
    debug.sethook(function() error("évaluation trop longue : refusé", 2) end, "", 1000000)
    local okRun, res = pcall(fn)
    debug.sethook()
    strmt.__index = index
    if not okRun then return nil, tostring(res) end
    if type(env.LeyLinesDB) ~= "table" then return nil, "pas de LeyLinesDB dans ce fichier" end
    return env.LeyLinesDB
end

-- Espèce d'un point de SavedVariables, même logique que Nodes:Init côté client, sauf qu'on ne
-- connaît pas le personnage : une vieille base qui a capturé côté Horde exige une faction déclarée.
local function KindOfSavedNode(LL, db, node, declared)
    if KINDS[node.kind] then return node.kind end
    local byName = LL.Nodes:KindOfName(node.name)
    if byName then return byName end
    if declared then return declared end
    local hordeSeen = type(db.auras) == "table" and db.auras[HORDE_BUFF] ~= nil
    return (not hordeSeen) and "L" or nil
end

function Ingest.FromSavedVariables(LL, text, declared)
    local db, err = Ingest.LoadSavedVariables(text)
    if not db then return nil, err end
    local report = { read = 0, noKind = 0, otherKind = 0, unverified = 0 }
    local points = {}
    for map, list in pairs(type(db.nodes) == "table" and db.nodes or {}) do
        for _, node in ipairs(type(list) == "table" and list or {}) do
            local x, y = type(node) == "table" and node.x, type(node) == "table" and node.y
            if type(map) == "number" and type(x) == "number" and type(y) == "number"
                and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                report.read = report.read + 1
                local kind = KindOfSavedNode(LL, db, node, declared)
                if not VERIFIED[node.src] then
                    report.unverified = report.unverified + 1
                elseif not kind then
                    report.noKind = report.noKind + 1
                else
                    if declared and kind ~= declared then report.otherKind = report.otherKind + 1 end
                    points[#points + 1] = { kind = kind, map = map, x = x, y = y }
                end
            end
        end
    end
    return points, report
end

-- ---------------------------------------------------------------------------
-- Contributions : data/contrib/<id>.ll, une par fichier, texte `clé=valeur`
-- ---------------------------------------------------------------------------

-- Réécrit les points en LL2 avec le codec du client : ce qui est rangé est ce qu'un joueur
-- pourrait réimporter tel quel.
function Ingest.Encode(LL, points)
    local nodes = {}
    for _, p in ipairs(points) do
        nodes[p.map] = nodes[p.map] or {}
        table.insert(nodes[p.map], { kind = p.kind, x = p.x, y = p.y })
    end
    LL.db.nodes = nodes
    return LL.Share:Encode()
end

function Ingest.ParseContrib(text)
    local c = {}
    for key, value in (text or ""):gmatch("([%w_]+)=([^\r\n]*)") do c[key] = value end
    c.version = tonumber(c.version)
    return c
end

-- Palier des contributions nouvelles : un de plus que la liste livrée actuelle.
function Ingest.NextVersion(dir)
    local stub = {}
    local fn = loadfile(dir .. "/LeyLines_Data.lua")
    if fn then pcall(fn, "LeyLines", stub) end
    return (stub.DATA_VERSION or 0) + 1
end

-- Les champs libres (auteur, id) finissent dans un fichier ligne à ligne : pas de retour à la ligne.
local function OneLine(s) return (tostring(s or ""):gsub("[\r\n]", " ")) end

function Ingest.RenderContrib(meta, code)
    return table.concat({
        "from=" .. OneLine(meta.from),
        "date=" .. OneLine(meta.date),
        "source=" .. OneLine(meta.source),
        "version=" .. tostring(meta.version),
        "code=" .. code,
        "",
    }, "\n")
end

-- ---------------------------------------------------------------------------
-- La liste livrée : fusion de toutes les contributions, dans l'ordre (palier, id)
-- ---------------------------------------------------------------------------

-- Le point connu le plus proche qui est le MÊME objet, et l'écart en yards (nil : zone inconnue).
function Ingest.Near(list, map, x, y)
    local size = MAP_YARDS[map]
    local best, bestD
    for i = 1, #list do
        local p = list[i]
        if size then
            local d = math.sqrt(((p.x - x) * size[1]) ^ 2 + ((p.y - y) * size[2]) ^ 2)
            if d <= SAME_YD and (not bestD or d < bestD) then best, bestD = p, d end
        elseif not best and math.abs(p.x - x) < TOL_UNKNOWN and math.abs(p.y - y) < TOL_UNKNOWN then
            best = p
        end
    end
    return best, bestD
end

-- contribs : { {id=, version=, code=}, ... }. Rend la liste { L = { [map] = {pts} }, V = ... },
-- le palier maximal, le nombre de points NOUVEAUX apportés par chaque contribution, et les fusions
-- à relire (au-delà de la portée du sort, ou sur une zone de taille inconnue).
function Ingest.Merge(LL, contribs)
    table.sort(contribs, function(a, b)
        if a.version ~= b.version then return a.version < b.version end
        return a.id < b.id
    end)
    local data, version, brought, doubts = { L = {}, V = {} }, 0, {}, {}
    for _, c in ipairs(contribs) do
        version = math.max(version, c.version or 0)
        Ingest.Thank(data, c)
        brought[c.id] = 0
        for _, p in ipairs(Ingest.FromCode(LL, c.code) or {}) do
            local maps = data[p.kind]
            maps[p.map] = maps[p.map] or {}
            local same, d = Ingest.Near(maps[p.map], p.map, p.x, p.y)
            if not same then
                table.insert(maps[p.map], { x = p.x, y = p.y, v = c.version })
                brought[c.id] = brought[c.id] + 1
            elseif not d or d > REACH_YD then
                doubts[#doubts + 1] = { id = c.id, map = p.map, x = p.x, y = p.y, into = same, yd = d }
            end
        end
    end
    return data, version, brought, doubts
end

local HEADER = [[
-- LeyLines_Data.lua — positions LIVRÉES avec l'addon, communes à tous les joueurs.
--
-- ATTENTION : FICHIER GÉNÉRÉ par tools/ll_ingest.lua (scripts\ll_ingest.ps1 -Build) à partir des
-- contributions data/contrib/*.ll. NE PAS L'ÉDITER À LA MAIN : la génération suivante écraserait
-- la modification. Pour retirer un point, corriger ou supprimer sa contribution, puis régénérer.
--
-- Format : [espèce][uiMapID] = { x, y, palier, ... } — coordonnées de carte (0..1) ; palier =
-- DATA_VERSION qui a introduit le point : Nodes:ApplyShipped ne fusionne que ceux qu'un joueur n'a
-- pas encore reçus, pour qu'un point qu'il a effacé ne revienne pas. Espèce : L = fissure
-- (Alliance), V = tornade (Horde). Un point par ligne, pour que la relecture d'une PR se fasse
-- ligne à ligne.
--
-- LL.THANKS : [palier] = pseudos de ceux dont la contribution est arrivée à ce palier, remerciés en
-- jeu (LeyLines_Thanks.lua). Un pseudo n'y entre que fait de lettres, chiffres, tiret et souligné.
local _, LL = ...
]]

local function SortedMaps(maps)
    local ids = {}
    for map in pairs(maps) do ids[#ids + 1] = map end
    table.sort(ids)
    return ids
end

-- Un pseudo vient d'un ticket et finit dans du Lua chargé par chaque client : lettres, chiffres,
-- tiret, souligné, 39 caractères au plus (GitHub, plus le souligné des pseudos CurseForge). Tout
-- autre pseudo est refusé tel quel, jamais « nettoyé » (docs/specs/remerciements.md, R2).
function Ingest.SafeName(s)
    if type(s) == "string" and #s <= 39 and s:find("^[%w_%-]+$") then return s end
    return nil
end

-- Range l'auteur d'une contribution parmi ceux de son palier (une fois par palier). Une
-- contribution sans auteur (la graine) ne remercie personne ; ses positions ne changent pas.
function Ingest.Thank(data, c)
    if c.from == nil or c.from == "" then return end
    local name = Ingest.SafeName(c.from)
    if not name then
        print("  ATTENTION : pseudo refuse dans " .. tostring(c.id) .. " : absent des remerciements")
        return
    end
    local tier = c.version or 0
    data.thanks = data.thanks or {}
    data.thanks[tier] = data.thanks[tier] or {}
    for _, known in ipairs(data.thanks[tier]) do
        if known == name then return end
    end
    table.insert(data.thanks[tier], name)
end

-- Des nombres formatés, et des pseudos passés par SafeName : rien d'autre de ce que contenait une
-- contribution n'y est recopié.
function Ingest.Render(data, version)
    local out = { HEADER, string.format("LL.DATA_VERSION = %d\n\nLL.THANKS = {", version) }
    for _, tier in ipairs(SortedMaps(data.thanks or {})) do
        out[#out + 1] = string.format('    [%d] = { "%s" },', tier, table.concat(data.thanks[tier], '", "'))
    end
    out[#out + 1] = "}\n\nLL.DATA = {"
    for _, kind in ipairs({ "L", "V" }) do
        out[#out + 1] = string.format("    %s = {", kind)
        for _, map in ipairs(SortedMaps(data[kind])) do
            out[#out + 1] = string.format("        [%d] = {", map)
            for _, p in ipairs(data[kind][map]) do
                out[#out + 1] = string.format("            %.4f, %.4f, %d,", p.x, p.y, p.v)
            end
            out[#out + 1] = "        },"
        end
        out[#out + 1] = "    },"
    end
    out[#out + 1] = "}\n"
    return table.concat(out, "\n")
end

-- ---------------------------------------------------------------------------
-- Ligne de commande
-- ---------------------------------------------------------------------------
local function Report(id, rep, kept)
    print(string.format("  %s : %d point(s) lu(s), %d garde(s)", id, rep.read, kept))
    if (rep.unverified or 0) > 0 then
        print(string.format("    %d non confirme(s) par le jeu (manuel, infobulle, livre, import) : ecarte(s)", rep.unverified))
    end
    if rep.noKind > 0 then
        print(string.format("    %d SANS faction : ecarte(s) -- relancer avec -Faction Alliance|Horde", rep.noKind))
    end
    if rep.otherKind > 0 then
        print(string.format("    ATTENTION : %d point(s) de l'AUTRE faction que celle declaree -- a verifier", rep.otherKind))
    end
end

function Ingest.Add(dir, id, from, date, declared, path)
    local LL = Ingest.Setup(dir)
    local text = ReadFile(path)
    if not text then return false, "fichier introuvable : " .. tostring(path) end
    local kind = KINDS[declared] and declared or nil
    local points, rep
    if text:find("LeyLinesDB", 1, true) then
        points, rep = Ingest.FromSavedVariables(LL, text, kind)
    else
        points, rep = Ingest.FromCode(LL, text, kind)
    end
    if not points then return false, rep end
    Report(id, rep, #points)
    if #points == 0 then return false, "rien a verser" end

    local meta = { from = from, date = date, source = id, version = Ingest.NextVersion(dir) }
    WriteFile(dir .. "/data/contrib/" .. id .. ".ll", Ingest.RenderContrib(meta, Ingest.Encode(LL, points)))
    print(string.format("  -> data/contrib/%s.ll (palier %d)", id, meta.version))
    return true
end

function Ingest.Build(dir, files)
    local LL = Ingest.Setup(dir)
    local contribs = {}
    for _, path in ipairs(files) do
        local c = Ingest.ParseContrib(ReadFile(path))
        c.id = path:match("([^/\\]+)%.ll$") or path
        if c.code and c.version then contribs[#contribs + 1] = c else print("  ignore (illisible) : " .. path) end
    end
    local data, version, brought, doubts = Ingest.Merge(LL, contribs)
    for _, c in ipairs(contribs) do
        print(string.format("  %-28s palier %d : %d point(s) nouveau(x)", c.id, c.version, brought[c.id]))
    end
    for _, f in ipairs(doubts) do
        print(string.format("  A RELIRE : %s %.2f,%.2f (carte %d) fusionne avec %.2f,%.2f a %s -- meme objet ?",
            f.id, f.x * 100, f.y * 100, f.map, f.into.x * 100, f.into.y * 100,
            f.yd and string.format("%d yd", f.yd + 0.5) or "un ecart de taille inconnue"))
    end
    WriteFile(dir .. "/LeyLines_Data.lua", Ingest.Render(data, version))
    print(string.format("  -> LeyLines_Data.lua regenere, DATA_VERSION = %d", version))
    return true
end

function Ingest.Main(args)
    local cmd, dir = args[1], args[2]
    local ok, err
    if cmd == "add" then
        ok, err = Ingest.Add(dir, args[3], args[4], args[5], args[6], args[7])
    elseif cmd == "build" then
        ok, err = Ingest.Build(dir, { select(3, unpack(args)) })
    else
        ok, err = false, "usage : ll_ingest.lua add|build <dossier LeyLines> ..."
    end
    if not ok then io.stderr:write("ERREUR : " .. tostring(err) .. "\n"); os.exit(1) end
end

if not _G.LL_INGEST_LIB then Ingest.Main(arg or {}) end
return Ingest
