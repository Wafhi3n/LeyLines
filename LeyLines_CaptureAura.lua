-- LeyLines_CaptureAura.lua — la lecture du buff de faille : le verdict d'un lancer
-- (Capture:FreshLongBuff), le temps restant pour le rappel (Capture:LeyAura), la lecture gardée
-- quand le jeu la refuse, et la liste des buffs connus. Détachée de LeyLines_Capture.lua (limite
-- de 500 lignes) ; chargée après lui, elle ajoute ses méthodes à la même table.
local _, LL = ...
local Capture = LL.Capture

-- LE VERDICT DU JEU, et c'est le fait central de cet addon (mesuré en jeu le 2026-09-20) : le sort
-- d'absorption part de partout, mais il ne donne un buff de 15 MINUTES que lancé sur une faille —
-- ailleurs, 15 SECONDES. On n'a donc rien à deviner sur la portée ni sur la position de l'objet :
-- on lit la durée du buff obtenu. Le seuil est posé au milieu, très loin des deux valeurs.
local LONG_BUFF_MIN = 60    -- s : au-dessus = faille confirmée
local FRESH_MARGIN  = 2     -- s : un buff POSÉ À L'INSTANT a expirationTime ≈ maintenant + durée
local MAX_BUFFS     = 40
local AURA_RETRY    = 5     -- s de pause après un refus de lecture d'aura (voir Capture:ReadAura)

-- Un buff est « posé à l'instant » quand son temps restant est encore (presque) sa durée totale.
-- Sans ce test, un buff de faille encore actif ferait passer pour réussi un lancer raté. `now` est
-- l'instant du verdict tel qu'il aurait dû tomber : relu après un combat (LeyLines_CaptureCombat),
-- le buff doit avoir été posé au moment du lancer, ni avant, ni après (LATE_MARGIN).
local LATE_MARGIN = 5   -- s
local function IsFreshLong(aura, now)
    local dur, exp = aura.duration, aura.expirationTime
    if type(dur) ~= "number" or type(exp) ~= "number" then return false end
    return dur >= LONG_BUFF_MIN and (exp - now) > (dur - FRESH_MARGIN) and (exp - now) <= dur + LATE_MARGIN
end

-- Un buff INCONNU n'est pris pour celui de la faille que s'il en a la durée (15 min, d'où la
-- fenêtre). Signalé par un joueur le 2026-10-02 : la Night Watchman's Torch, jouet de Duskwood,
-- pose une aura de zone de 5 min reposée en continu, donc toujours « toute fraîche ». Chaque
-- lancer RATÉ torche allumée marquait une faille, et le buff de la torche s'inscrivait comme buff
-- de faille. Les ids livrés (LL.DEFAULTS.auras) n'ont pas besoin de ce filet.
local LEY_BUFF_MIN, LEY_BUFF_MAX = 600, 1200   -- s
local function IsFreshLeyLike(aura, now)
    local dur = aura.duration
    return IsFreshLong(aura, now) and dur >= LEY_BUFF_MIN and dur <= LEY_BUFF_MAX
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
    -- secret: ok (en combat, rend nil sans erreur, vu le 2026-10-11 ; pour LeyAura et FreshLongBuff, nil = « on ne sait pas » et les champs se lisent sous pcall)
    return self:ReadAura(get, id)
end

function Capture:AuraByIndex(i)
    local get = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if not get then return nil, false end
    return self:ReadAura(get, "player", i, "HELPFUL")
end

-- Cherche le buff long fraîchement appliqué. Les buffs DÉJÀ identifiés passent en premier : une
-- lecture ciblée au lieu de balayer 40 emplacements, donc moins d'occasions de heurter le mur.
-- Rend aussi `blocked` : la lecture refusée (en combat) ou un champ secret qu'on ne peut comparer
-- ne disent PAS « pas de buff », ils disent « on ne sait pas encore ».
function Capture:FreshLongBuff(now)
    now = now or GetTime()
    for id in pairs(LL.db.auras) do
        local aura, blocked = self:AuraBySpellID(id)
        if blocked then return nil, true end
        if aura then
            local ok, fresh = pcall(IsFreshLong, aura, now)
            if not ok then return nil, true end
            if fresh then return aura end
        end
    end

    -- Aucun buff connu : on cherche un buff inconnu qui a la durée de celui de la faille, au cas où
    -- la bêta changerait l'id. Un autre buff long tout frais (la torche) ne suffit pas.
    for i = 1, MAX_BUFFS do
        local aura, blocked = self:AuraByIndex(i)
        if blocked then return nil, true end
        if not aura then break end
        local ok, fresh = pcall(IsFreshLeyLike, aura, now)
        if ok and fresh then return aura end
    end
    return nil, false
end

-- Le buff de faille est LIVRÉ en dur (LL.DEFAULTS.auras) : la liste n'en garde pas d'autre.
-- Jusqu'à la v1.3.4, un lancer y inscrivait le buff qui l'avait confirmé, quel qu'il soit : la
-- torche s'y retrouvait, et le rappel d'expiration la surveillait (« plus que 5 min » sur un buff
-- de torche). Appelée à chaque chargement : idempotente, sans palier de migration. Rend le nombre
-- d'ids retirés.
function Capture:KeepShippedAuras(db)
    local shipped = LL.DEFAULTS and LL.DEFAULTS.auras or {}
    local removed = 0
    for id in pairs(type(db.auras) == "table" and db.auras or {}) do
        if not shipped[id] then
            db.auras[id] = nil   -- effacer un champ pendant pairs() est permis en Lua
            removed = removed + 1
        end
    end
    return removed
end

-- Temps restant du buff de faille et son heure de fin, ou nil si cette aura n'est pas la nôtre.
-- Isolée dans sa propre fonction pour être appelée SOUS pcall : sur Forever une donnée d'aura peut
-- être secrète, et le soustraire ferait exploser l'appelant loin de l'origine.
local function LeyRemaining(aura)
    if not aura.spellId or not LL.db.auras[aura.spellId] then return nil end
    local exp = aura.expirationTime
    if type(exp) ~= "number" or exp <= 0 then return nil end
    return exp - GetTime(), exp
end

-- Le buff de faille actuellement actif sur le joueur : rend l'aura, son temps restant et son heure
-- de fin (ce qui DÉSIGNE ce buff : le reprendre la change), pour que l'appelant n'ait jamais à
-- toucher aux champs bruts. Sert au rappel d'expiration (LeyLines_HUD).
-- nil ne veut PAS dire « plus de buff ». En combat le buff devient secret, et GetPlayerAuraBySpellID
-- porte RequiresNonSecretAura (doc du client, build 70338) : il rend nil SANS erreur, « protected
-- APIs will return no values ». Vu au banc le 2026-10-11 : nil en combat, aucun refus relevé.
function Capture:LeyAura()
    -- Une seule lecture, ciblée sur l'id connu : c'est le chemin qui bat chaque seconde.
    for id in pairs(LL.db.auras) do
        local aura = self:AuraBySpellID(id)
        if aura then
            local ok, left, ends = pcall(LeyRemaining, aura)
            if ok and left then return aura, left, ends end
        end
    end
    return nil
end
