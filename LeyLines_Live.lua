-- LeyLines_Live.lua — le partage en direct des failles actives (docs/specs/partage-direct.md).
--
-- Quand le jeu confirme une absorption (buff de 15 min), une ligne lisible peut partir dans le canal
-- General de la zone, avec le lien de point de route du jeu et l'étiquette #LL :
--     Ley Line active at 54.3, 62.6 [Map Pin Location] #LL
-- Un joueur sans l'addon la lit et clique le lien ; chez un porteur, elle date le point connu le plus
-- proche (`node.live`, « vue active il y a 4 min ») et rien d'autre (D7).
--
-- Le joueur choisit (D4) : une fenêtre à chaque absorption (`popup`) ou jamais (`off`). Tant qu'il
-- n'a pas choisi (`announce` à nil), la première absorption pose la question et rien ne part.
-- Écrire dans un canal du jeu exige un geste du joueur : c'est le clic sur Oui qui poste. Le mode
-- automatique (la ligne part au clic suivant dans le monde) est le palier 3.
local _, LL = ...
local L = LL.L

local Live = {}
LL.Live = Live

local FRESH      = 15 * 60    -- s : faille annoncée depuis moins de 15 min = pas d'annonce (D5)
local PLAYER_GAP = 5 * 60     -- s : au plus une annonce par joueur toutes les 5 min (D5)
local MAX_AGE    = 24 * 3600  -- s : au-delà, l'âge ne s'affiche plus (D8)
local MAX_BYTES  = 255        -- une ligne de canal
-- D9 : la phrase est en anglais FIXE, quelle que soit la langue du client. La lecture n'en lit que
-- l'étiquette et le lien : on peut la reformuler sans casser les lecteurs.
local SPECIES = { L = "Ley Line", V = "Elemental Convergence" }

-- Mémoire de SESSION, hors de la base (contrat : un point ne reçoit que `live`). Après un /reload,
-- une faille annoncée il y a 5 min peut donc l'être une fois de plus. `heard` : dernière annonce
-- de ce point, lue ou envoyée ; `offered` : dernière fenêtre ouverte pour lui.
Live.heard   = setmetatable({}, { __mode = "k" })
Live.offered = setmetatable({}, { __mode = "k" })

-- Une valeur SECRÈTE (combat de boss) est aussi de type string : elle casserait :match et ==.
local function Secret(v)
    return (_G.issecretvalue and _G.issecretvalue(v)) == true
end

-- ---------------------------------------------------------------------------
-- Le canal General
-- ---------------------------------------------------------------------------
-- Son nom est localisé et porte la zone : « 1. General - Elwynn Forest », « Général - … »,
-- « Allgemein - … ». On retire le numéro devant et la zone derrière avant de comparer. Son
-- `zoneChannelID` le dirait sans texte, mais sa valeur n'est pas mesurée sur Forever (M6) :
-- `/ley probe` la relève.
local GENERAL = { general = true, ["général"] = true, allgemein = true }

function Live.IsGeneral(name)
    if type(name) ~= "string" or Secret(name) then return false end
    local base = name:gsub("^%d+%.%s*", ""):gsub("%s+%-%s+.*$", "")
    return GENERAL[base:lower()] == true
end

-- Le numéro du canal General, ou nil : hors d'une zone qui en a un, ou après un `/leave`.
function Live:GeneralIndex()
    if type(GetChannelName) ~= "function" then return nil end
    for i = 1, 20 do
        local id, name = GetChannelName(i)
        if id and id > 0 and Live.IsGeneral(name) then return i, name end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- La ligne
-- ---------------------------------------------------------------------------
-- Les coordonnées sont celles du POINT, pas du lancer : les lecteurs les cherchent dans leur liste
-- (souvent la liste livrée) à `mergeRange` près.
function Live.Line(node, link)
    if type(link) ~= "string" or link == "" then return nil end
    local line = string.format("%s active at %.1f, %.1f %s #LL", SPECIES[node.kind] or SPECIES.L,
        node.x * 100, node.y * 100, link)
    if #line > MAX_BYTES then return nil end
    return line
end

-- Carte, x, y (0..1) d'une ligne #LL, ou nil. Seul le lien porte la position : `|Hworldmap:<carte>:
-- <x>:<y>|h`, x et y en dix-millièmes (format du jeu, vu le 2026-10-08). Une ligne forgée (sans
-- l'étiquette, sans lien, hors bornes, trop longue) ne rend rien.
function Live.Parse(msg)
    if type(msg) ~= "string" or Secret(msg) or #msg > MAX_BYTES then return nil end
    if not msg:find("#LL%s*$") then return nil end
    local map, x, y = msg:match("|Hworldmap:(%d+):(%d+):(%d+)")
    map, x, y = tonumber(map), tonumber(x), tonumber(y)
    if not (map and x and y) or map <= 0 or x > 10000 or y > 10000 then return nil end
    return map, x / 10000, y / 10000
end

-- Le lien s'EMPRUNTE au jeu : un lien écrit à la main arrive en texte brut (M4). Dans le même geste,
-- le point de route du joueur est mis de côté, le nôtre posé le temps de lire le lien, puis le sien
-- rendu, ou effacé s'il n'en avait pas (vu en jeu le 2026-10-08 : il revient à sa place).
function Live:BorrowLink(map, x, y)
    local M = C_Map
    if not (M and M.SetUserWaypoint and M.GetUserWaypointHyperlink and UiMapPoint) then return nil end
    if M.CanSetUserWaypointOnMap and not M.CanSetUserWaypointOnMap(map) then return nil end
    local saved = M.GetUserWaypoint and M.GetUserWaypoint()
    local ok, link = pcall(function()
        M.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
        return M.GetUserWaypointHyperlink()
    end)
    if saved then
        pcall(M.SetUserWaypoint, saved)
    elseif M.ClearUserWaypoint then
        pcall(M.ClearUserWaypoint)
    end
    return ok and type(link) == "string" and link ~= "" and link or nil
end

-- ---------------------------------------------------------------------------
-- Annoncer
-- ---------------------------------------------------------------------------
function Live:Recent(node, now)
    local at = self.heard[node]
    return at ~= nil and now - at < FRESH
end

-- La fenêtre à ouvrir après une absorption, ou nil (D4, D5). Rien n'est ouvert pour une faille déjà
-- annoncée, ni deux fois pour la même en 15 min, ni à moins de 5 min de notre dernière annonce.
function Live:Offer(node, now)
    local mode = LL.db.announce
    if mode == "off" or self:Recent(node, now) then return nil end
    if self.lastSent and now - self.lastSent < PLAYER_GAP then return nil end
    if self.offered[node] and now - self.offered[node] < FRESH then return nil end
    if not self:GeneralIndex() then return nil end
    if mode == nil then
        if self.asked then return nil end   -- la question : une fois par session au plus
        return "LEYLINES_ANNOUNCE_ASK"
    end
    return "LEYLINES_ANNOUNCE"
end

-- Appelée par la capture après un lancer confirmé : le point est vu actif MAINTENANT, qu'on
-- l'annonce ou non (« un point qu'on a absorbé soi-même porte le même âge »).
function Live:OnAbsorb(node)
    if not node then return end
    local now = time()
    node.live = now
    local which = self:Offer(node, now)
    if not which then return end
    self.offered[node] = now
    if which == "LEYLINES_ANNOUNCE_ASK" then self.asked = true end
    StaticPopup_Show(which, LL.Nodes:Word("one", node.kind), nil, node)
end

local function ChatLocked()
    local C = C_ChatInfo
    return (C and C.InChatMessagingLockdown and C.InChatMessagingLockdown()) == true
end

local function Send(line, index)
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or _G.SendChatMessage
    return send ~= nil and pcall(send, line, "CHANNEL", nil, index)
end

-- Le clic sur Oui : le geste qui permet d'écrire. Tout se revérifie ici, la fenêtre a pu rester
-- ouverte (un autre joueur l'a peut-être annoncée entre-temps, ou on a changé de zone).
function Live:Announce(node)
    local now = time()
    if self:Recent(node, now) then return LL:Print(L["Déjà annoncée par un autre joueur : rien n'est parti."]) end
    local index = self:GeneralIndex()
    if not index or ChatLocked() then return LL:Print(L["Pas de canal Général ici : rien n'est parti."]) end
    local line = Live.Line(node, self:BorrowLink(node.map, node.x, node.y))
    if not line then return LL:Print(L["Cette zone n'accepte pas de point de route : rien n'est parti."]) end
    if Send(line, index) then
        self.lastSent, self.heard[node] = now, now
    end
end

-- ---------------------------------------------------------------------------
-- Lire
-- ---------------------------------------------------------------------------
-- Une annonce lue compte pour D5 même lecture coupée : ne pas répéter ce qu'un autre vient de dire
-- n'est pas un affichage. Seul l'âge du point dépend de la lecture (D10).
function Live:Heard(map, x, y, now)
    local node = LL.Nodes:Find(map, x, y, LL.db.mergeRange, LL.Nodes:PlayerKind())
    if not node then return nil end   -- D7 : une position inconnue ne crée rien
    self.heard[node] = now
    if LL.db.readAnnounces ~= false then node.live = now end
    -- Quelqu'un l'a dite avant nous : notre fenêtre pour ce point n'a plus d'objet.
    if StaticPopup_Hide then StaticPopup_Hide("LEYLINES_ANNOUNCE", node) end
    return node
end

function Live:OnChannel(msg, channelName, guid, zoneID)
    if not LL.db or Secret(msg) or Secret(guid) or not Live.IsGeneral(channelName) then return end
    self.generalZoneID = zoneID   -- M6, relevé par `/ley probe`
    local map, x, y = Live.Parse(msg)
    if not map then return end
    -- Notre propre ligne revient en écho : déjà datée à l'envoi. Par le GUID, jamais par le nom.
    if guid and UnitGUID and guid == UnitGUID("player") then return end
    self:Heard(map, x, y, time())
end

-- « Vue active il y a 4 min » (D8) : minutes sous 1 h, heures jusqu'à 24 h, rien au-delà.
function Live.AgeText(node, now)
    local at = node and node.live
    if type(at) ~= "number" then return nil end
    local age = math.max(0, (now or time()) - at)
    if age >= MAX_AGE then return nil end
    if age < 3600 then return string.format(L["Vue active il y a %s min"], math.floor(age / 60)) end
    return string.format(L["Vue active il y a %s h"], math.floor(age / 3600))
end

-- ---------------------------------------------------------------------------
-- Les fenêtres et l'écoute
-- ---------------------------------------------------------------------------
local function SetMode(value)
    LL.Options:Set(LL.Options.BY_KEY.announce, value)
end

StaticPopupDialogs["LEYLINES_ANNOUNCE"] = {
    text         = L["Annoncer cette %s dans le canal Général ?"],
    button1      = YES,
    button2      = NO,
    OnAccept     = function(_, node) Live:Announce(node) end,
    timeout      = 120,
    whileDead    = true,
    hideOnEscape = true,
}

-- La question (D4). Échap ne tranche rien : elle reviendra à la session suivante. Le délai et le
-- remplacement par une autre fenêtre appellent aussi OnCancel, d'où le test de `reason`.
StaticPopupDialogs["LEYLINES_ANNOUNCE_ASK"] = {
    text             = L["Annoncer cette %s dans le canal Général ? Une ligne avec un lien de point de route, que tous les joueurs de la zone peuvent lire. Oui : l'annoncer, et te le proposer après chaque absorption. Jamais : ne plus le proposer. Ça se change dans /ley options."],
    button1          = YES,
    button2          = L["Jamais"],
    OnAccept         = function(_, node)
        SetMode("popup")
        Live:Announce(node)
    end,
    OnCancel         = function(_, _, reason)
        if reason ~= "clicked" then return end
        SetMode("off")
        LL:Print(L["Annonce dans Général : jamais. /ley options pour changer."])
    end,
    noCancelOnEscape = true,
    timeout          = 0,
    whileDead        = true,
    hideOnEscape     = true,
}

local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_CHANNEL")
listener:SetScript("OnEvent", function(_, _, msg, _, _, channelName, _, _, zoneID, _, _, _, _, guid)
    Live:OnChannel(msg, channelName, guid, zoneID)
end)
