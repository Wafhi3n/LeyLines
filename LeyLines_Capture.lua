-- LeyLines_Capture.lua — comment une position entre dans la base. Quatre sources, par précision
-- décroissante, toutes réduites au même geste : Store(map, x, y, {src=...}).
--
--   1. VIGNETTE — si le client déclare la ligne tellurique comme vignette, il en donne la position
--      EXACTE et on n'a rien à demander au joueur. C'est la source idéale ; on ne sait pas encore
--      si Forever le fait (à trancher en jeu avec `/ley probe`), donc les trois autres existent.
--   2. SORT — le sort de régénération Skyborn ne part que sur une ligne : une incantation réussie
--      vaut relevé exact. Le sort n'est pas codé en dur, il s'APPREND (`/ley learn`).
--   3. MANUEL — `/ley add` ou le raccourci clavier, le joueur étant posé dessus.
--   4. INFOBULLE — le simple survol de l'objet. Le joueur peut être à 30 yd : position marquée
--      approximative, qu'un relevé plus précis corrigera plus tard (voir PRECISION dans _Nodes).
local _, LL = ...
local L = LL.L

local Capture = {}
LL.Capture = Capture

local LEARN_TIMEOUT = 30

-- LE VERDICT DU JEU, et c'est le fait central de cet addon (mesuré en jeu le 2026-09-20) : le sort
-- d'absorption part de partout, mais il ne donne un buff de 15 MINUTES que lancé sur une faille —
-- ailleurs, 15 SECONDES. On n'a donc rien à deviner sur la portée ni sur la position de l'objet :
-- on lit la durée du buff obtenu. Le seuil est posé au milieu, très loin des deux valeurs.
local LONG_BUFF_MIN = 60    -- s : au-dessus = faille confirmée
local AURA_DELAY    = 0.8   -- s : laisser le buff s'appliquer avant de le lire
local FRESH_MARGIN  = 2     -- s : un buff POSÉ À L'INSTANT a expirationTime ≈ maintenant + durée
local MAX_BUFFS     = 40
local AURA_RETRY    = 5     -- s de pause après un refus de lecture d'aura (voir Capture:ReadAura)

-- La souris est-elle sur le MONDE 3D, et pas sur un cadre d'interface ? C'est LA question qui
-- sépare « je survole l'objet » de « je survole un point de la minicarte ». GetMouseFoci rend la
-- pile de cadres sous le curseur ; sur le décor, c'est WorldFrame. Sans l'API on répond NON : mieux
-- vaut une capture par infobulle muette qu'une boucle qui sème de faux relevés.
local function MouseOnWorld()
    if GetMouseFoci then
        local foci = GetMouseFoci()
        return (foci and foci[1]) == WorldFrame
    end
    if GetMouseFocus then return GetMouseFocus() == WorldFrame end
    return false
end

local function SafeLower(text)
    if type(text) ~= "string" or text == "" then return nil end
    -- Piège Forever : une chaîne rendue par le client peut être une valeur SECRÈTE, qui explose
    -- à la comparaison bien loin de son origine. On garde l'appel risqué, pas le bloc.
    local ok, lowered = pcall(string.lower, text)
    return ok and lowered or nil
end

local function SpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(spellID) end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    end
    return GetSpellInfo and (GetSpellInfo(spellID)) or nil
end

-- ---------------------------------------------------------------------------
-- Démarrage
-- ---------------------------------------------------------------------------

-- Piège Forever : RegisterEvent sur un événement INCONNU lève une erreur au lieu de rendre nil.
-- On garde chaque enregistrement et on note l'absence, que `/ley probe` sait afficher.
function Capture:Register(event, unit)
    local f, ok = self.frame, nil
    if unit then ok = pcall(f.RegisterUnitEvent, f, event, unit)
    else ok = pcall(f.RegisterEvent, f, event) end
    if not ok then
        self.unavailable = self.unavailable or {}
        table.insert(self.unavailable, event)
    end
    return ok
end

function Capture:Init()
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, ...) Capture:OnEvent(event, ...) end)

    self:Register("VIGNETTES_UPDATED")
    self:Register("VIGNETTE_MINIMAP_UPDATED")
    self:Register("ZONE_CHANGED_NEW_AREA")
    self:Register("UNIT_SPELLCAST_SUCCEEDED", "player")
    self:HookTooltip()
    self:ScanVignettes()
end

function Capture:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        self:OnSpellCast(spellID)
    else
        self:ScanVignettes()
    end
end

-- « Auto » ne parle que des sources EXACTES (vignette, sort). L'infobulle a son propre
-- interrupteur parce qu'elle relève une position approchée : la mélanger ici la rallumerait par
-- surprise, et c'est exactement ce qui a semé de faux points le 2026-09-20.
function Capture:AutoEnabled()
    local c = LL.db.capture
    return (c.vignette or c.spell) and true or false
end

-- ---------------------------------------------------------------------------
-- Reconnaissance du nom
-- ---------------------------------------------------------------------------
function Capture:Matches(text)
    local lowered = SafeLower(text)
    if not lowered then return false end
    for _, needle in ipairs(LL.db.names) do
        if string.find(lowered, needle, 1, true) then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Sources
-- ---------------------------------------------------------------------------
function Capture:ScanVignettes()
    if not LL.db.capture.vignette or not C_VignetteInfo then return end
    local map = LL.Geo:PlayerMap()
    if not map then return end
    local guids = C_VignetteInfo.GetVignettes and C_VignetteInfo.GetVignettes()
    if not guids then return end

    for _, guid in ipairs(guids) do
        local info = C_VignetteInfo.GetVignetteInfo(guid)
        if info and self:Matches(info.name) then
            local pos = C_VignetteInfo.GetVignettePosition(guid, map)
            if pos then
                local x, y = pos:GetXY()
                self:Store(map, x, y, { src = "vignette", name = LL.Nodes:CleanName(info.name) })
            end
        end
    end
end

function Capture:HookTooltip()
    if not GameTooltip or not GameTooltip.HookScript then return end
    local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnShow", function() Capture:OnTooltip() end)
    self.tooltipHooked = ok and true or false
end

-- Pendant qu'on remplit NOTRE propre infobulle (point de minicarte, point de carte, bandeau),
-- la capture se tait : sa première ligne porte le nom de la ligne tellurique, donc le hook OnShow
-- la relirait et enregistrerait une ligne à la position du JOUEUR. Vu en jeu le 2026-09-20, à 40 yd
-- de l'objet réel. Verrou synchrone, il ne dépend d'aucune API.
function Capture:Mute()   self.silent = true  end
function Capture:Unmute() self.silent = false end

function Capture:OwnerName()
    local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
    if not owner then return "nil" end
    if owner.isLeyLinePin then return "<point LeyLines>" end
    return (owner.GetName and owner:GetName()) or "<sans nom>"
end

function Capture:OnTooltip()
    if self.silent then return end
    local now = GetTime()
    if now - (self.lastTooltip or 0) < 0.3 then return end
    self.lastTooltip = now

    local line = _G["GameTooltipTextLeft1"]
    local text = line and line:GetText()
    -- Mémorisés même capture éteinte : `/ley probe` s'en sert pour révéler le nom exact de l'objet
    -- et pour prouver quelle garde a laissé passer quoi.
    self.lastText  = (type(text) == "string") and text or nil
    self.lastOwner = self:OwnerName()
    self.lastWorld = MouseOnWorld()

    if not LL.db.capture.tooltip then return end
    -- Trois verrous indépendants, parce qu'un seul a déjà cédé.
    if not self.lastWorld then return end
    local owner = GameTooltip.GetOwner and GameTooltip:GetOwner()
    if owner and owner.isLeyLinePin then return end
    if not self:Matches(text) then return end

    local map, x, y = LL.Geo:PlayerPos()
    if map then self:Store(map, x, y, { src = "tooltip", name = LL.Nodes:CleanName(text) }) end
end

function Capture:OnSpellCast(spellID)
    if self.learning then return self:Learn(spellID) end
    if not LL.db.capture.spell or not spellID then return end
    if not LL.db.spells[spellID] and not self:LearnByName(spellID) then return end

    -- La position est prise À L'INSTANT DU LANCER, pas après le délai : le joueur bouge.
    local map, x, y = LL.Geo:PlayerPos()
    if not map then return end
    C_Timer.After(AURA_DELAY, function() Capture:ResolveCast(map, x, y) end)
end

-- Un sort dont l'id n'est pas connu mais dont le NOM figure dans `spellNames` (Skysight, côté
-- Horde) : on inscrit son id, et les lancers suivants passent par la voie rapide. Le nom sert de
-- clé d'entrée, jamais de verdict — c'est toujours la durée du buff qui tranche.
function Capture:LearnByName(spellID)
    local lowered = SafeLower(SpellName(spellID))
    if not lowered then return false end
    for _, wanted in ipairs(LL.db.spellNames or {}) do
        if lowered == wanted then
            LL.db.spells[spellID] = SpellName(spellID)
            return true
        end
    end
    return false
end

-- Un buff est « posé à l'instant » quand son temps restant est encore (presque) sa durée totale.
-- Sans ce test, un buff de faille encore actif ferait passer pour réussi un lancer raté.
local function IsFreshLong(aura, now)
    local dur, exp = aura.duration, aura.expirationTime
    if type(dur) ~= "number" or type(exp) ~= "number" then return false end
    return dur >= LONG_BUFF_MIN and (exp - now) > (dur - FRESH_MARGIN)
end

-- Piège Forever payé en jeu le 2026-09-20, EN COMBAT : lire une aura depuis du code d'addon ne
-- rend pas nil quand elle est secrète, ça LÈVE une erreur — « Auras cannot be accessed when secret
-- while tainted by 'LeyLines' ». Protéger la comparaison des champs ne servait à rien : c'est
-- l'APPEL qu'il faut garder. Et comme le rappel bat une fois par seconde, un refus doit mettre la
-- lecture en pause au lieu d'être retenté sans fin.
function Capture:AurasBlocked()
    return (self.auraBlockedUntil or 0) > GetTime()
end

function Capture:ReadAura(fn, ...)
    if self:AurasBlocked() then return nil, true end
    local ok, aura = pcall(fn, ...)
    if not ok then
        self.auraBlockedUntil = GetTime() + AURA_RETRY
        return nil, true
    end
    return aura, false
end

function Capture:AuraBySpellID(id)
    local get = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if not get then return nil, false end
    return self:ReadAura(get, id)
end

function Capture:AuraByIndex(i)
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if not get then return nil, false end
    return self:ReadAura(get, "player", i, "HELPFUL")
end

-- Cherche le buff long fraîchement appliqué. Les buffs DÉJÀ identifiés passent en premier : une
-- lecture ciblée au lieu de balayer 40 emplacements, donc moins d'occasions de heurter le mur.
function Capture:FreshLongBuff()
    local now = GetTime()
    for id in pairs(LL.db.auras) do
        local aura, blocked = self:AuraBySpellID(id)
        if blocked then return nil end
        if aura then
            local ok, fresh = pcall(IsFreshLong, aura, now)
            if ok and fresh then return aura end
        end
    end

    -- Aucun buff connu : on cherche un buff long inconnu, au cas où la bêta changerait l'id.
    for i = 1, MAX_BUFFS do
        local aura, blocked = self:AuraByIndex(i)
        if blocked or not aura then break end
        local ok, fresh = pcall(IsFreshLong, aura, now)
        if ok and fresh then return aura end
    end
    return nil
end

-- Temps restant du buff de faille, ou nil si cette aura n'est pas la nôtre. Isolée dans sa propre
-- fonction pour être appelée SOUS pcall : sur Forever une donnée d'aura peut être secrète, et le
-- soustraire ferait exploser l'appelant loin de l'origine.
local function LeyRemaining(aura)
    if not aura.spellId or not LL.db.auras[aura.spellId] then return nil end
    local exp = aura.expirationTime
    if type(exp) ~= "number" or exp <= 0 then return nil end
    return exp - GetTime()
end

-- Le buff de faille actuellement actif sur le joueur : rend l'aura ET son temps restant, pour que
-- l'appelant n'ait jamais à toucher aux champs bruts. Sert au rappel d'expiration (LeyLines_HUD).
function Capture:LeyAura()
    -- Une seule lecture, ciblée sur l'id connu : c'est le chemin qui bat chaque seconde.
    for id in pairs(LL.db.auras) do
        local aura, blocked = self:AuraBySpellID(id)
        if blocked then return nil end
        if aura then
            local ok, left = pcall(LeyRemaining, aura)
            if ok and left then return aura, left end
        end
    end
    return nil
end

function Capture:ResolveCast(map, x, y)
    local aura = self:FreshLongBuff()
    if not aura then
        LL:Print(L["Buff court : pas de faille ici, rien n'a été enregistré."])
        return
    end
    if aura.spellId then LL.db.auras[aura.spellId] = aura.name or true end
    -- Si la faille a été survolée juste avant, on hérite de son VRAI nom ; sinon le libellé par
    -- défaut fera l'affaire. On ne prend le texte que s'il correspond aux noms reconnus.
    local seen = self:Matches(self.lastText) and LL.Nodes:CleanName(self.lastText) or nil
    self:Store(map, x, y, { src = "spell", name = seen })
end

function Capture:ArmLearn()
    self.learning = true
    LL:Print(L["Lance maintenant ton sort de ligne tellurique : le prochain sort réussi sera retenu."])
    C_Timer.After(LEARN_TIMEOUT, function()
        if Capture.learning then
            Capture.learning = nil
            LL:Print(L["Apprentissage abandonné : aucun sort lancé."])
        end
    end)
end

function Capture:Learn(spellID)
    self.learning = nil
    if not spellID then return end
    local name = SpellName(spellID) or tostring(spellID)
    LL.db.spells[spellID] = name
    LL:Printf(L["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une faille."],
        name, spellID)
    -- Ce lancer-ci compte comme les suivants : le sort vient d'être retenu, la garde ne bloque plus.
    self:OnSpellCast(spellID)
end

-- ---------------------------------------------------------------------------
-- Entrée unique dans la base
-- ---------------------------------------------------------------------------
function Capture:Store(map, x, y, info)
    local before = LL.Nodes:CountMap(map)
    local node, isNew = LL.Nodes:Add(map, x, y, info)
    if not node then return nil, false end

    if isNew then
        LL:Printf(L["Nouvelle ligne tellurique enregistrée dans %s (%s ici)."],
            LL.Geo:MapName(map), before + 1)
        LL:Refresh()
    elseif info.src == "manual" or info.src == "spell" then
        LL:Printf(L["Ligne tellurique déjà connue — position confirmée (%s relevés)."], node.hits)
        LL:Refresh()
    end
    return node, isNew
end

-- Relevé volontaire (commande ou raccourci) : le joueur est posé DESSUS.
function Capture:Record(src, name)
    local map, x, y = LL.Geo:PlayerPos()
    if not map then
        LL:Print(L["Position indisponible ici — le client ne donne pas de coordonnées."])
        return
    end
    self:Store(map, x, y, { src = src or "manual", name = LL.Nodes:CleanName(name) })
end
