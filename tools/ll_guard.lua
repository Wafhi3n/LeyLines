-- ll_guard.lua — garde-fou d'un ticket « positions », avant que l'Action ne le verse.
--
-- Lancé par .github/scripts/positions.sh (GitHub Action), par Elune pour une relecture locale, et
-- par tests/test_ll_guard.lua ; JAMAIS par le client WoW (.pkgmeta exclut tools/). Spec :
-- docs/specs/contribution-positions.md, T5 et D6.
--
--   check <dossier LeyLines> <ticket> <corps> <auteur> <âge du compte, jours> <tickets en 24 h>
--         <sortie code> <sortie rapport> <fichier.ll>...
--         Sortie 0 = à verser (le code canonique est dans <sortie code>), 3 = refusé, 1 = erreur.
--         Le rapport Markdown est écrit dans les deux premiers cas.
--
-- Un seul niveau REFUSE : ce qu'une machine tranche sans se tromper. Tout le reste est un DRAPEAU
-- pour le relecteur, parce que les signaux faibles visent aussi de vrais joueurs : un compte
-- GitHub ouvert pour l'occasion est la norme, et sionnabhan a envoyé cinq tickets légitimes en
-- trois heures (#11 à #15, 2026-09-30).
--
-- SÉCURITÉ. Le corps du ticket vient d'un inconnu, et l'Action tourne avec un jeton qui écrit dans
-- le dépôt. Il ne prend JAMAIS le chemin SavedVariables de ll_ingest.lua (qui évalue du Lua) : on
-- n'en garde que le jeton `LL2;…`, décodé en nombres puis réécrit par le codec du client. C'est ce
-- code canonique, et lui seul, que l'Action donne ensuite à `ll_ingest.lua add`.
local Guard = {}

local MAX_BODY    = 20000   -- octets ; un ticket du formulaire en fait quelques centaines
local MAX_POINTS  = 40      -- refus au-delà
local MANY_POINTS = 10      -- drapeau au-delà
local MAX_MAP     = 100000  -- un uiMapID tient en quelques chiffres (2521 pour Zephras Isle)
local BURST, FLOOD = 5, 20  -- tickets « positions » du même auteur en 24 h : drapeau, puis refus
local NEW_ACCOUNT = 30      -- jours : drapeau en dessous

-- Verdicts, mêmes seuils que la veille : la portée du sort est d'environ 25 yd, donc deux lancers
-- valides sur le même objet peuvent être à 50 yd l'un de l'autre. Sans taille de carte connue,
-- ~0,01 de carte ≈ 50 yd.
local REACH_YD, SAME_YD   = 25, 50
local REACH_MAP, SAME_MAP = 0.005, 0.01
local MAP_YARDS = { [2521] = { 5562, 3708 } }   -- Zephras Isle, seule taille relevée

local KIND_NAME = { L = "fissure", V = "tornade" }

-- ---------------------------------------------------------------------------
-- Chargement : le décodeur est celui du client, via ll_ingest.lua
-- ---------------------------------------------------------------------------
function Guard.Setup(dir)
    _G.LL_INGEST_LIB = true
    local Ingest = assert(loadfile(dir .. "/tools/ll_ingest.lua"))()
    return Ingest, Ingest.Setup(dir)
end

-- ---------------------------------------------------------------------------
-- Ce qu'on lit du ticket
-- ---------------------------------------------------------------------------

-- Le seul morceau du ticket qui sert : le jeton LL2. Rend le jeton, ou nil + la raison du refus.
function Guard.Token(body)
    if type(body) ~= "string" then return nil, "ticket illisible" end
    if #body > MAX_BODY then return nil, string.format("ticket de plus de %d octets", MAX_BODY) end
    local token = body:match("LL2;[%w;=,%-]+")
    if token then return token end
    if body:find("LeyLinesDB", 1, true) then
        return nil, "fichier de sauvegarde au lieu d'un code : à verser à la main (ll_ingest.ps1 -SavedVariables)"
    end
    if body:find("LL1;", 1, true) then
        return nil, "code LL1, sans espèce : à verser à la main avec -Faction"
    end
    return nil, "aucun code LL2 dans le ticket (fichier joint ? à verser à la main)"
end

-- Un pseudo GitHub : lettres, chiffres, tirets, 39 caractères au plus. Il finit dans un fichier
-- de contribution, dans un commit, et un jour dans /ley credits.
function Guard.SafeLogin(s)
    return type(s) == "string" and #s <= 39 and s:find("^%w[%w%-]*$") ~= nil
end

-- ---------------------------------------------------------------------------
-- Ce que main sait déjà
-- ---------------------------------------------------------------------------

-- contribs : { {id=, from=, code=}, ... } (data/contrib/*.ll lus par Ingest.ParseContrib).
-- exclus : data/exclus.txt lu par tools/ll_registre.lua (facultatif).
function Guard.Known(Ingest, LL, contribs, exclus)
    local known = { points = {}, maps = {}, authors = {}, codes = {}, excluded = {} }
    for _, e in ipairs(exclus or {}) do known.excluded[e.key] = e end
    for _, c in ipairs(contribs) do
        if c.from then known.authors[c.from] = true end
        if c.code then
            known.codes[c.code] = c.id or "?"
            for _, p in ipairs(Ingest.FromCode(LL, c.code) or {}) do
                known.points[#known.points + 1] = p
                known.maps[p.map] = true
            end
        end
    end
    return known
end

-- Écart entre deux points d'une même carte : en yards si sa taille est connue, sinon en unités de
-- carte. Rend l'écart, son unité, et le verdict.
function Guard.Gap(map, a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    local size = MAP_YARDS[map]
    if size then
        local d = math.sqrt((dx * size[1]) ^ 2 + (dy * size[2]) ^ 2)
        return d, "yd", (d <= REACH_YD and "confirmation") or (d <= SAME_YD and "à relire") or "neuf"
    end
    local d = math.sqrt(dx * dx + dy * dy)
    return d, "carte", (d <= REACH_MAP and "confirmation") or (d <= SAME_MAP and "à relire") or "neuf"
end

-- Le point connu le plus proche, de même espèce et sur la même carte.
local function Nearest(known, p)
    local gap, unit, verdict
    for _, k in ipairs(known.points) do
        if k.kind == p.kind and k.map == p.map then
            local d, u, v = Guard.Gap(p.map, p, k)
            if not gap or d < gap then gap, unit, verdict = d, u, v end
        end
    end
    return gap, unit, verdict or "neuf"
end

-- ---------------------------------------------------------------------------
-- Le verdict
-- ---------------------------------------------------------------------------
local function Add(list, fmt, ...) list[#list + 1] = string.format(fmt, ...) end

-- Les drapeaux : rien de tout ça ne refuse, tout ça se relit.
local function Flag(res, known, input, points, rep)
    local f, kinds, near, edge = res.flags, {}, false, 0
    local newMaps, seen = {}, {}   -- un uiMapID sert de clé : liste et ensemble séparés
    for _, p in ipairs(points) do
        local gap, unit, verdict = Nearest(known, p)
        res.rows[#res.rows + 1] = { p = p, gap = gap, unit = unit, verdict = verdict }
        kinds[p.kind] = true
        if verdict ~= "neuf" then near = true end
        if not known.maps[p.map] and not seen[p.map] then seen[p.map] = true; newMaps[#newMaps + 1] = p.map end
        if p.x <= 0 or p.y <= 0 or p.x >= 1 or p.y >= 1 then edge = edge + 1 end
    end
    if (input.ageDays or NEW_ACCOUNT) < NEW_ACCOUNT then Add(f, "compte GitHub ouvert il y a %d jour(s)", input.ageDays) end
    if (input.recent or 0) > BURST then Add(f, "%d tickets « positions » de cet auteur en 24 h", input.recent) end
    if not known.authors[input.login] then Add(f, "premier ticket de cet auteur") end
    if kinds.L and kinds.V then Add(f, "fissures ET tornades dans le même code (deux personnages ?)") end
    if #points > MANY_POINTS then Add(f, "%d points dans un seul ticket", #points) end
    if #points >= 3 and not near then Add(f, "aucun point ne recoupe un point déjà connu") end
    table.sort(newMaps)
    for _, map in ipairs(newMaps) do Add(f, "carte jamais vue dans la liste : %d", map) end
    if edge > 0 then Add(f, "%d point(s) sur le bord de la carte", edge) end
    local skipped = (rep and rep.read or #points) - #points
    if skipped > 0 then Add(f, "%d point(s) sans espèce, ignoré(s)", skipped) end
end

-- input : { login, body, ageDays, recent }. Rend { refused = raison | nil, token, rows, flags }.
function Guard.Check(Ingest, LL, known, input)
    local res = { flags = {}, rows = {} }
    local function Refuse(fmt, ...) res.refused = string.format(fmt, ...); return res end
    if not Guard.SafeLogin(input.login) then return Refuse("pseudo GitHub inattendu") end
    -- Un auteur exclu (D8) : sa contribution serait ignorée à la construction, autant ne pas ouvrir
    -- une PR qui ne fait rien. Les pseudos GitHub ne distinguent pas la casse.
    if (known.excluded or {})[input.login:lower()] then return Refuse("auteur exclu de la liste commune") end
    if (input.recent or 0) > FLOOD then
        return Refuse("%d tickets « positions » de cet auteur en 24 h (plus de %d)", input.recent, FLOOD)
    end
    local token, why = Guard.Token(input.body)
    if not token then return Refuse("%s", why) end
    local points, rep = Ingest.FromCode(LL, token, nil)
    if not points or #points == 0 then return Refuse("aucun point lisible dans le code") end
    if #points > MAX_POINTS then return Refuse("%d points (plus de %d)", #points, MAX_POINTS) end
    for _, p in ipairs(points) do
        if p.map >= MAX_MAP then return Refuse("numéro de carte impossible : %d", p.map) end
    end
    res.token = Ingest.Encode(LL, points)
    if known.codes[res.token] then return Refuse("code déjà versé (%s)", known.codes[res.token]) end
    Flag(res, known, input, points, rep)
    return res
end

-- ---------------------------------------------------------------------------
-- Le rapport (Markdown : résumé du job, message de commit, corps de PR)
-- ---------------------------------------------------------------------------
local function Row(r)
    local p = r.p
    local gap = not r.gap and "rien de connu ici"
        or (r.unit == "yd" and string.format("%.0f yd", r.gap) or string.format("%.4f de carte", r.gap))
    return string.format("| %s | %d | %.2f | %.2f | %s | %s |",
        KIND_NAME[p.kind] or p.kind, p.map, p.x * 100, p.y * 100, gap, r.verdict)
end

function Guard.Report(res, input)
    local out = { string.format("## Ticket %d : garde-fou", input.issue or 0), "" }
    out[#out + 1] = res.refused and ("**REFUSÉ** : " .. res.refused .. ". Rien n'est versé.") or "**À relire puis verser.**"
    out[#out + 1] = ""
    if Guard.SafeLogin(input.login) then
        Add(out, "Auteur : `%s` (ce pseudo sera affiché en jeu parmi les contributeurs).", input.login)
    end
    if input.nextVersion and not res.refused then
        Add(out, "Palier prévu : %d. À la fusion, il doit rester PLUS GRAND que le DATA_VERSION de main.", input.nextVersion)
    end
    if #res.rows > 0 then
        out[#out + 1] = ""
        out[#out + 1] = "| Espèce | Carte | x | y | Point connu le plus proche | Verdict |"
        out[#out + 1] = "|---|---|---|---|---|---|"
        for _, r in ipairs(res.rows) do out[#out + 1] = Row(r) end
    end
    if #res.flags > 0 then
        out[#out + 1] = ""
        out[#out + 1] = "Drapeaux :"
        for _, f in ipairs(res.flags) do out[#out + 1] = "- " .. f end
    end
    if not res.refused then
        out[#out + 1] = ""
        out[#out + 1] = "Vérifié ici : le code seul (jamais le reste du ticket), `luac -p` et le chargement de la"
            .. " liste générée. PAS ici : les portes et les tests de l'outillage, à passer avant la fusion."
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

function Guard.Main(args)
    local cmd, dir, issue, bodyPath, login, age, recent, outCode, outReport = unpack(args, 1, 9)
    if cmd ~= "check" or not outReport then
        io.stderr:write("usage : ll_guard.lua check <dossier> <ticket> <corps> <auteur> <age> <recent> <code> <rapport> <.ll>...\n")
        os.exit(1)
    end
    local Ingest, LL = Guard.Setup(dir)
    local contribs = {}
    for i = 10, #args do
        local c = Ingest.ParseContrib(ReadFile(args[i]))
        c.id = args[i]:match("([^/\\]+)%.ll$") or args[i]
        contribs[#contribs + 1] = c
    end
    local exclus, err = Ingest.Registre(dir).LoadExclus(dir)
    if not exclus then io.stderr:write("ERREUR : " .. err .. "\n"); os.exit(1) end
    local input = { issue = tonumber(issue), body = ReadFile(bodyPath), login = login,
        ageDays = tonumber(age), recent = tonumber(recent), nextVersion = Ingest.NextVersion(dir) }
    local res = Guard.Check(Ingest, LL, Guard.Known(Ingest, LL, contribs, exclus), input)
    WriteFile(outReport, Guard.Report(res, input))
    if res.refused then
        print("REFUSE : " .. res.refused)
        os.exit(3)
    end
    WriteFile(outCode, res.token .. "\n")
    print(string.format("A verser : %d point(s), %d drapeau(x)", #res.rows, #res.flags))
    os.exit(0)
end

if not _G.LL_GUARD_LIB then Guard.Main(arg or {}) end
return Guard
