-- ll_wowhead.lua — la veille Wowhead : les points que la carte d'un objet montre sur Wowhead et
-- que la liste commune n'a pas encore.
--
-- Lancé par .github/scripts/wowhead.sh (GitHub Action quotidienne), par Elune pour une relecture
-- locale, et par tests/test_ll_wowhead.lua ; JAMAIS par le client WoW (.pkgmeta exclut tools/).
--
--   delta <dossier LeyLines> <page fissure> <page tornade> <sortie code> <sortie rapport> <fichier.ll>...
--         Sortie 0 = points neufs (leur code LL2 est dans <sortie code>), 4 = rien de neuf,
--         2 = page illisible (Wowhead a changé, ou on a reçu autre chose que la page), 1 = erreur.
--         Le rapport Markdown est écrit dans les cas 0 et 4.
--
-- D'OÙ VIENNENT CES POINTS. L'addon Wowhead Looter (installé par le Wowhead Client) retient la
-- position du JOUEUR quand il reçoit un buff de site tout frais (au moins 14 min 55 restantes) :
-- Energized 1259691 → objet « Ley Line » 602735, Elemental Blessing 1270893 → objet « Elemental
-- Convergence » 616992 (lu dans +Wowhead_Looter.lua le 2026-10-11). C'est le principe de notre
-- capture, arrondi au 0,1 % de carte : un point Wowhead vaut un relevé de joueur, pas mieux.
--
-- Wowhead N'OUBLIE RIEN : un point qu'on a refusé reviendrait à chaque passage. Il se note dans
-- data/wowhead_refus.txt, une ligne par point : `V1413 39.9 13.9  # raison`.
--
-- SÉCURITÉ. La page vient d'un tiers, et ce qui en sort finit en Lua exécuté par chaque client. On
-- n'en lit que des NOMBRES (identité de la page, numéro de carte, coordonnées), réencodés par le
-- codec du client ; aucun texte de la page n'est recopié, pas même le nom de la zone.
local Wowhead = {}

Wowhead.OBJECTS = { L = 602735, V = 616992 }
local MAX_PAGE   = 4 * 1024 * 1024
local MAX_POINTS = 400      -- par page ; 15 et 19 le 2026-10-11
local MAX_MAP    = 100000
local REFUS      = "/data/wowhead_refus.txt"
local KIND_NAME  = { L = "fissure", V = "tornade" }

function Wowhead.Setup(dir)
    _G.LL_INGEST_LIB, _G.LL_GUARD_LIB = true, true
    local Ingest = assert(loadfile(dir .. "/tools/ll_ingest.lua"))()
    local Guard = assert(loadfile(dir .. "/tools/ll_guard.lua"))()
    return Ingest, Guard, Ingest.Setup(dir)
end

-- ---------------------------------------------------------------------------
-- La page d'un objet
-- ---------------------------------------------------------------------------

-- Les coordonnées d'une entrée de g_mapperData ; une coordonnée hors de la carte (le Looter note
-- 0,0 quand il n'a pas pu lire la position) est écartée et comptée, pas versée.
local function Coords(points, kind, map, coords)
    local skipped = 0
    for sx, sy in coords:gmatch("%[%s*([%d%.]+)%s*,%s*([%d%.]+)%s*%]") do
        local x, y = tonumber(sx), tonumber(sy)
        if x and y and x > 0 and x < 100 and y > 0 and y < 100 then
            points[#points + 1] = { kind = kind, map = map, x = x / 100, y = y / 100 }
        else
            skipped = skipped + 1
        end
    end
    return skipped
end

-- Rend { {kind, map, x, y}, ... } et le nombre de coordonnées écartées, ou nil + la raison. Une
-- page qu'on ne sait pas lire est une ERREUR, jamais « rien de neuf » : sinon une page bloquée
-- ou remaniée passerait pour un calme plat, pour toujours.
function Wowhead.Parse(html, kind)
    local object = Wowhead.OBJECTS[kind]
    if type(html) ~= "string" or #html > MAX_PAGE then return nil, "page vide ou trop grosse" end
    local id = tonumber(html:match("g_pageInfo%s*=%s*{%s*type:%s*2%s*,%s*typeId:%s*(%d+)") or "")
    if id ~= object then return nil, string.format("pas la page de l'objet %d", object) end
    local mapper = html:match("g_mapperData%s*=%s*(%b{})")
    if not mapper then return nil, "g_mapperData absent" end
    local points, skipped = {}, 0
    for entry in mapper:sub(2, -2):gmatch("%b{}") do
        local map = tonumber(entry:match('"uiMapId"%s*:%s*(%d+)') or "")
        local coords = entry:match('"coords"%s*:%s*(%b[])')
        if not map or not coords or map <= 0 or map >= MAX_MAP then
            return nil, "entrée de carte illisible"
        end
        skipped = skipped + Coords(points, kind, map, coords)
    end
    if #points == 0 then return nil, "aucune coordonnée" end
    if #points > MAX_POINTS then return nil, string.format("%d points (plus de %d)", #points, MAX_POINTS) end
    return points, skipped
end

-- data/wowhead_refus.txt : { [kind] = { [map] = { {x, y}, ... } } }.
function Wowhead.ParseRefus(text)
    local refus = { L = {}, V = {} }
    for line in (text or ""):gmatch("[^\r\n]+") do
        local kind, map, x, y = line:match("^%s*([LV])(%d+)%s+([%d%.]+)%s+([%d%.]+)")
        if kind then
            map = tonumber(map)
            refus[kind][map] = refus[kind][map] or {}
            table.insert(refus[kind][map], { x = tonumber(x) / 100, y = tonumber(y) / 100 })
        end
    end
    return refus
end

-- ---------------------------------------------------------------------------
-- Ce qui est neuf
-- ---------------------------------------------------------------------------

-- Le point connu le plus proche, même espèce, même carte (nil si la carte n'en a aucun).
local function Nearest(Guard, list, p)
    local gap, unit
    for _, k in ipairs(list) do
        local d, u = Guard.Gap(p.map, p, k)
        if not gap or d < gap then gap, unit = d, u end
    end
    return gap, unit
end

-- Ce que le relecteur doit savoir d'un point neuf. Un site de l'AUTRE faction au même endroit
-- n'est pas une erreur (la liste en a une de chaque à 0,08 % de carte, carte 1434), mais se regarde.
local function Neuf(t, data, list, p)
    local gap, unit = Nearest(t.Guard, list, p)
    local other = p.kind == "L" and "V" or "L"
    local function Near(lists) return t.Ingest.Near((lists or {})[p.map] or {}, p.map, p.x, p.y) ~= nil end
    return { p = p, gap = gap, unit = unit, mapNew = #list == 0,
        gone = Near(data.gone[p.kind]), twin = Near(data[other]) and KIND_NAME[other] or nil }
end

-- La même règle que la construction (Ingest.Near sur la liste livrée, exclusions appliquées) :
-- un point est neuf si `build` l'ajouterait. Chaque point neuf rejoint la liste, pour que deux
-- relevés Wowhead du même objet ne comptent qu'une fois.
-- t : { Ingest, Guard, LL, dir, contribs, exclus, refus }. Rend { rows, known, refused, total }.
function Wowhead.Delta(t, points)
    local data = t.Ingest.Registre(t.dir).Compile(t.LL, t.contribs, t.exclus)
    local res = { rows = {}, known = 0, refused = 0, total = #points }
    for _, p in ipairs(points) do
        local maps = data[p.kind]
        local list = maps[p.map] or {}
        if t.Ingest.Near(list, p.map, p.x, p.y) then
            res.known = res.known + 1
        elseif t.Ingest.Near(t.refus[p.kind][p.map] or {}, p.map, p.x, p.y) then
            res.refused = res.refused + 1
        else
            res.rows[#res.rows + 1] = Neuf(t, data, list, p)
            maps[p.map] = list
            table.insert(list, { x = p.x, y = p.y })
        end
    end
    return res
end

-- ---------------------------------------------------------------------------
-- Le rapport (Markdown : résumé du job, message de commit, corps de PR)
-- ---------------------------------------------------------------------------
local function Row(r)
    local p = r.p
    local gap = not r.gap and "rien de cette espèce ici"
        or (r.unit == "yd" and string.format("%.0f yd", r.gap) or string.format("%.4f de carte", r.gap))
    local notes = {}
    if r.gone then notes[#notes + 1] = "près d'un point RETIRÉ de la liste (LL.GONE)" end
    if r.mapNew then notes[#notes + 1] = "carte jamais vue pour cette espèce" end
    if r.twin then notes[#notes + 1] = "une " .. r.twin .. " au même endroit" end
    return string.format("| %s | %d | %.2f | %.2f | %s | %s |", KIND_NAME[p.kind], p.map,
        p.x * 100, p.y * 100, gap, table.concat(notes, ", "))
end

-- info : { nextVersion, skipped }.
function Wowhead.Report(res, info)
    local out = { string.format("## Veille Wowhead : %d point(s) neuf(s)", #res.rows), "" }
    out[#out + 1] = string.format("Sur Wowhead : %d point(s) ; déjà dans la liste (ou en double) : %d ; refusés"
        .. " (data/wowhead_refus.txt) : %d ; hors carte, écartés : %d.",
        res.total, res.known, res.refused, info.skipped or 0)
    out[#out + 1] = "Source : position du joueur au buff de site tout frais (Wowhead Looter), arrondie"
        .. " au 0,1 % de carte. Objets 602735 (fissure) et 616992 (tornade) sur wowhead.com/forever."
    if #res.rows > 0 then
        if info.nextVersion then
            out[#out + 1] = string.format("Palier prévu : %d. À la fusion, il doit rester PLUS GRAND"
                .. " que le DATA_VERSION de main.", info.nextVersion)
        end
        out[#out + 1] = ""
        out[#out + 1] = "| Espèce | Carte | x | y | Point connu le plus proche | Remarque |"
        out[#out + 1] = "|---|---|---|---|---|---|"
        for _, r in ipairs(res.rows) do out[#out + 1] = Row(r) end
        out[#out + 1] = ""
        out[#out + 1] = "Un point à rejeter : l'écrire dans data/wowhead_refus.txt (`V1413 39.9 13.9  # raison`),"
            .. " sinon il revient au passage suivant."
    end
    return table.concat(out, "\n") .. "\n"
end

-- ---------------------------------------------------------------------------
-- Ligne de commande
-- ---------------------------------------------------------------------------
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

local function Fail(code, msg)
    io.stderr:write(msg .. "\n")
    os.exit(code)
end

-- Les deux pages, lues en points ; une seule illisible arrête tout (sortie 2).
local function ReadPages(pathL, pathV)
    local points, skipped = {}, 0
    for kind, path in pairs({ L = pathL, V = pathV }) do
        local list, n = Wowhead.Parse(ReadFile(path), kind)
        if not list then Fail(2, string.format("PAGE ILLISIBLE (%s, %s) : %s", KIND_NAME[kind], path, n)) end
        for _, p in ipairs(list) do points[#points + 1] = p end
        skipped = skipped + n
    end
    return points, skipped
end

function Wowhead.Main(args)
    local cmd, dir, pageL, pageV, outCode, outReport = unpack(args, 1, 6)
    if cmd ~= "delta" or not outReport then
        Fail(1, "usage : ll_wowhead.lua delta <dossier> <page fissure> <page tornade> <code> <rapport> <.ll>...")
    end
    local Ingest, Guard, LL = Wowhead.Setup(dir)
    local points, skipped = ReadPages(pageL, pageV)
    local contribs = {}
    for i = 7, #args do
        local c = Ingest.ParseContrib(ReadFile(args[i]))
        c.id = args[i]:match("([^/\\]+)%.ll$") or args[i]
        if c.code and c.version then contribs[#contribs + 1] = c end
    end
    local exclus, err = Ingest.Registre(dir).LoadExclus(dir)
    if not exclus then Fail(1, "ERREUR : " .. tostring(err)) end
    local res = Wowhead.Delta({ Ingest = Ingest, Guard = Guard, LL = LL, dir = dir, contribs = contribs,
        exclus = exclus, refus = Wowhead.ParseRefus(ReadFile(dir .. REFUS)) }, points)
    WriteFile(outReport, Wowhead.Report(res, { nextVersion = Ingest.NextVersion(dir), skipped = skipped }))
    print(string.format("Wowhead : %d point(s), %d deja connu(s), %d refuse(s), %d neuf(s)",
        res.total, res.known, res.refused, #res.rows))
    if #res.rows == 0 then os.exit(4) end
    local fresh = {}
    for _, r in ipairs(res.rows) do fresh[#fresh + 1] = r.p end
    WriteFile(outCode, Ingest.Encode(LL, fresh) .. "\n")
    os.exit(0)
end

if not _G.LL_WOWHEAD_LIB then Wowhead.Main(arg or {}) end
return Wowhead
