-- LeyLines_Signal.lua — « des positions attendent d'être partagées » (docs/specs/signal-contribution.md).
--
-- `/ley contribute` ne sert que si le joueur y pense. Au moment où ça compte, quand le jeu vient de
-- confirmer une position que la liste livrée n'a pas, une ligne de chat le lui dit (et, P4, une
-- icône s'allume dans la barre de la minicarte).
--
-- RIEN N'EST STOCKÉ : le compte se déduit de la base (`node.found`, `node.src`), de la date de la
-- dernière contribution (`db.contrib.at`) et de la liste livrée (`LL.DATA`). Une contribution, un
-- /reload ou une mise à jour qui livre le point changent donc le compte sans code dédié. Seul
-- l'interrupteur `db.signal` est persisté.
local _, LL = ...
local L = LL.L

local Signal = {}
LL.Signal = Signal

local VERIFIED = LL.Nodes.VERIFIED

-- Le point est-il dans la liste livrée ? « Dedans » = un point livré de même espèce à moins de
-- mergeRange (S3) : confirmer une fissure livrée n'allume rien, sinon tous ceux qui suivent la
-- liste auraient le signal allumé en permanence. Taille de zone inconnue (Geo:Distance rend nil) :
-- on répond OUI, mieux vaut taire le signal une fois que l'allumer pour un point que la liste a.
function Signal:Shipped(node)
    local list = LL.DATA and LL.DATA[node.kind] and LL.DATA[node.kind][node.map]
    if not list then return false end
    for i = 1, #list - 2, 3 do
        local d = LL.Geo:Distance(node.map, node.x, node.y, list[i], list[i + 1])
        if not d or d <= LL.db.mergeRange then return true end
    end
    return false
end

-- Les positions à partager : TROUVÉES par le jeu (sort, vignette) après la dernière contribution,
-- et absentes de la liste livrée. `found` et pas `seen` : reconfirmer une position déjà partagée ne
-- doit rien rallumer. La source est revérifiée parce qu'un `/ley add` sur un point `spell` le
-- redescend en `manual` : il sort alors de la contribution, et un signal qui compterait encore un
-- point que la contribution n'envoie pas ne s'éteindrait jamais.
function Signal:Count()
    local since = LL.db.contrib and LL.db.contrib.at or 0
    local n = 0
    for _, list in pairs(LL.db.nodes) do
        for _, node in ipairs(list) do
            if VERIFIED[node.src] and (node.found or 0) > since and not self:Shipped(node) then
                n = n + 1
            end
        end
    end
    return n
end

-- Recalcul après toute modification de la base (LL:Refresh). La ligne de chat part à l'ALLUMAGE
-- seulement, de rien à quelque chose : plusieurs découvertes avant le clic n'en donnent qu'une, et
-- il n'y a pas de rappel. Le premier calcul (Init) sert de point de départ et ne dit rien.
function Signal:Update()
    local count, before = self:Count(), self.count
    self.count = count
    if before == 0 and count > 0 and LL.db.signal then
        LL:Print(L["Position absente de la liste commune : /ley contribute pour la partager avec tous."])
    end
end

-- Appelé APRÈS la fusion des données livrées (3 s après la connexion) : avant, la taille des zones
-- peut manquer, le compte serait faux, et sa correction passerait pour une découverte.
function Signal:Init()
    LL:OnRefresh(function() Signal:Update() end)
    self:Update()
end
