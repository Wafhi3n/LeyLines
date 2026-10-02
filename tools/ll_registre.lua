-- ll_registre.lua — qui a apporté quoi à la liste commune, et l'exclusion d'un auteur.
--
-- Chargé par tools/ll_ingest.lua (Ingest.Registre), donc aussi par ll_guard.lua et par l'Action ;
-- JAMAIS par le client WoW (.pkgmeta exclut tools/). Spec : docs/specs/contribution-positions.md,
-- D8.
--
-- LE REGISTRE n'est pas un fichier de plus : il se DÉDUIT des contributions data/contrib/*.ll, qui
-- portent chacune leur auteur (`from=`), et s'affiche à la demande (scripts\ll_ingest.ps1
-- -Registre). Un fichier généré et commité serait réécrit par chaque branche de ticket, et elles se
-- disputeraient toutes les mêmes lignes (le piège de LeyLines_Data.lua, payé le 2026-10-01).
--
-- L'EXCLUSION, elle, est commitée : data/exclus.txt, une ligne par auteur, `<pseudo> <palier>
-- <date>`. L'Action reconstruit la liste à chaque ticket : une exclusion qui ne vivrait que sur ce
-- poste serait défaite par la PR suivante. Exclure un auteur, c'est :
--   1. ignorer toutes ses contributions (le .ll reste : c'est la pièce du dossier) ;
--   2. garder un point qu'il a posé si un AUTRE auteur l'a relevé aussi : il revient, au palier de
--      cet autre ;
--   3. inscrire dans LL.GONE, au palier de l'exclusion, chaque point qui n'avait que lui pour
--      témoin : le client l'efface chez les joueurs qui l'avaient déjà reçu (Nodes:ApplyGone).
-- Le palier de l'exclusion est au-dessus de la liste du moment : sans lui, DATA_VERSION ne
-- bougerait pas, et un client à jour ne relirait jamais les retraits.
local Ingest = ...
local Registre = {}

local KIND_NAME = { L = "fissure", V = "tornade" }

-- ---------------------------------------------------------------------------
-- data/exclus.txt
-- ---------------------------------------------------------------------------

-- Une ligne illisible ARRÊTE tout : une exclusion perdue en silence rendrait ses points à tous.
function Registre.ParseExclus(text)
    local list, n = {}, 0
    for line in ((text or "") .. "\n"):gmatch("([^\n]*)\n") do
        n = n + 1
        line = line:gsub("\r$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:find("^#") then
            local login, palier, date = line:match("^(%S+)%s+(%d+)%s+(%S+)$")
            if not login or not Ingest.SafeName(login) then
                return nil, string.format("data/exclus.txt, ligne %d illisible : <pseudo> <palier> <date>", n)
            end
            list[#list + 1] = { login = login, key = login:lower(), palier = tonumber(palier), date = date }
        end
    end
    table.sort(list, function(a, b) return a.palier < b.palier end)
    return list
end

function Registre.LoadExclus(dir)
    local fh = io.open(dir .. "/data/exclus.txt", "rb")
    if not fh then return {} end
    local text = fh:read("*a")
    fh:close()
    return Registre.ParseExclus(text)
end

-- Un pseudo GitHub ne distingue pas la casse : `Noblesun13` et `noblesun13` sont le même compte.
function Registre.Index(exclus)
    local set = {}
    for _, e in ipairs(exclus or {}) do set[e.key] = e end
    return set
end

local EXCLUS_HEADER = [[
# Auteurs EXCLUS de la liste commune (docs/specs/contribution-positions.md, D8).
# Une ligne par auteur : <pseudo> <palier> <date>. Le palier est celui de l'exclusion : les points
# dont il était le seul témoin partent dans LL.GONE à ce palier, et le client les efface.
# Ajouter une ligne : scripts\ll_ingest.ps1 -Exclure <pseudo>, puis relire le diff.
]]

-- Ajoute une exclusion au palier suivant la liste du moment. Rend le palier, ou nil + la raison.
function Registre.Exclude(dir, login, date)
    if not Ingest.SafeName(login) then return nil, "pseudo illisible : " .. tostring(login) end
    local exclus, err = Registre.LoadExclus(dir)
    if not exclus then return nil, err end
    if Registre.Index(exclus)[login:lower()] then return nil, login .. " est deja exclu" end
    local path = dir .. "/data/exclus.txt"
    local fh = io.open(path, "rb")
    local text = fh and fh:read("*a") or EXCLUS_HEADER
    if fh then fh:close() end
    if text ~= "" and not text:find("\n$") then text = text .. "\n" end
    local palier = Ingest.NextVersion(dir)
    fh = assert(io.open(path, "wb"))
    fh:write(text, string.format("%s %d %s\n", login, palier, date))
    fh:close()
    return palier
end

-- ---------------------------------------------------------------------------
-- La liste livrée, exclusions comprises
-- ---------------------------------------------------------------------------
local function Keep(contribs, out)
    local kept = {}
    for _, c in ipairs(contribs) do
        if not (c.from and out[c.from:lower()]) then kept[#kept + 1] = c end
    end
    return kept
end

-- Les points d'avant qui n'ont plus de voisin après : ils partent dans `gone`, au palier donné.
local function Lost(before, after, palier, gone)
    for _, kind in ipairs({ "L", "V" }) do
        for map, list in pairs(before[kind]) do
            for _, p in ipairs(list) do
                if not Ingest.Near(after[kind][map] or {}, map, p.x, p.y) then
                    gone[kind][map] = gone[kind][map] or {}
                    table.insert(gone[kind][map], { x = p.x, y = p.y, v = palier, from = p.from })
                end
            end
        end
    end
end

-- Comme Ingest.Merge, exclusions appliquées DANS L'ORDRE de leurs paliers : chaque retrait porte
-- le palier de l'exclusion qui l'a causé. data.gone = les retraits ; le palier rendu ne redescend
-- jamais sous celui d'une contribution déjà comptée, exclue ou non.
function Registre.Compile(LL, contribs, exclus)
    local out, top = {}, 0
    for _, c in ipairs(contribs) do top = math.max(top, c.version or 0) end
    local data, _, brought, doubts, trail = Ingest.Merge(LL, Keep(contribs, out))
    local gone = { L = {}, V = {} }
    for _, e in ipairs(exclus or {}) do
        out[e.key] = e
        local after, _, b, d, t = Ingest.Merge(LL, Keep(contribs, out))
        Lost(data, after, e.palier, gone)
        data, brought, doubts, trail = after, b, d, t
        top = math.max(top, e.palier)
    end
    data.gone = gone
    return data, top, brought, doubts, trail
end

-- Ce que la construction dit de chaque exclusion : combien de retraits elle a causés.
function Registre.Summary(exclus, gone)
    for _, e in ipairs(exclus) do
        local n = 0
        for _, kind in ipairs({ "L", "V" }) do
            for _, list in pairs(gone[kind]) do
                for _, p in ipairs(list) do if p.v == e.palier then n = n + 1 end end
            end
        end
        print(string.format("  exclu : %s (palier %d, %s) -- %d retrait(s) a ce palier", e.login, e.palier, e.date, n))
    end
end

-- ---------------------------------------------------------------------------
-- Le registre : par auteur, ce qu'il a posé, qui d'autre l'a relevé, ce qu'il a confirmé
-- ---------------------------------------------------------------------------
local function Witnesses(p)
    local names, seen = {}, { [(p.from or ""):lower()] = true }
    for _, w in ipairs(p.by or {}) do
        local key = (w.from or "?"):lower()
        if not seen[key] then seen[key] = true; names[#names + 1] = (w.from or "?") .. " (" .. w.id .. ")" end
    end
    return names
end

local function Where(kind, map, p)
    return string.format("%-7s %4d  %5.2f,%5.2f", KIND_NAME[kind] or kind, map, p.x * 100, p.y * 100)
end

local function ContribLines(out, c, trail)
    local tr = trail[c.id] or {}
    local new, alone = 0, 0
    for _, t in ipairs(tr) do
        if t.new then
            new = new + 1
            if #Witnesses(t.point) == 0 then alone = alone + 1 end
        end
    end
    out[#out + 1] = string.format("   %-24s %s  palier %d : %d lu(s), %d pose(s) dont %d seul temoin, %d confirmation(s)",
        c.id, c.date or "?", c.version or 0, #tr, new, alone, #tr - new)
    for _, t in ipairs(tr) do
        if t.new then
            local w = Witnesses(t.point)
            out[#out + 1] = "      pose  " .. Where(t.kind, t.map, t.point) .. "  "
                .. (#w == 0 and "SEUL TEMOIN" or ("aussi releve par " .. table.concat(w, ", ")))
        else
            out[#out + 1] = string.format("      conf  %s  -> point de %s (%s)", Where(t.kind, t.map, t.p),
                t.point.from or "la graine", t.point.id or "?")
        end
    end
    return alone
end

local function Authors(contribs)
    local order, by = {}, {}
    for _, c in ipairs(contribs) do
        local key = (c.from ~= nil and c.from ~= "") and c.from:lower() or "(sans auteur)"
        if not by[key] then by[key] = { name = c.from or key, list = {} }; order[#order + 1] = key end
        table.insert(by[key].list, c)
    end
    return order, by
end

-- Le registre en texte. Il se lit sur la liste SANS exclusion : on y voit aussi ce qu'un auteur
-- exclu avait apporté. `only` (pseudo, casse indifférente) limite à un auteur.
function Registre.Text(LL, contribs, exclus, only)
    local _, _, _, _, trail = Ingest.Merge(LL, Keep(contribs, {}))
    local banned, order, by = Registre.Index(exclus), Authors(contribs)
    local out = { string.format("Registre de la liste commune : %d contribution(s), %d auteur(s).", #contribs, #order) }
    for _, key in ipairs(order) do
        if not only or key == only:lower() then
            local a, e = by[key], banned[key]
            out[#out + 1] = ""
            out[#out + 1] = string.format("== %s : %d contribution(s)%s", a.name, #a.list,
                e and string.format("  [EXCLU au palier %d, %s]", e.palier, e.date) or "")
            local alone = 0
            for _, c in ipairs(a.list) do alone = alone + ContribLines(out, c, trail) end
            out[#out + 1] = string.format(e and "   -> exclu : %d point(s) dont il etait le seul temoin ont quitte la liste"
                or "   -> s'il etait exclu, %d point(s) quitteraient la liste", alone)
        end
    end
    return table.concat(out, "\n") .. "\n"
end

return Registre
