-- LeyLines_Thanks.lua — les contributeurs de la liste commune (docs/specs/remerciements.md).
--
-- La liste livrée vient de joueurs. `LL.THANKS` (LeyLines_Data.lua, GÉNÉRÉ) dit qui a apporté
-- chaque palier : on les remercie au moment où leurs positions arrivent, et `/ley credits` les
-- donne tous. Rien n'est stocké : tout se lit dans la liste livrée.
local _, LL = ...
local L = LL.L

local Thanks = {}
LL.Thanks = Thanks

local SHOWN   = 6    -- au-delà, la ligne de chat compte les autres (R4)
local PER_ROW = 10   -- pseudos par ligne de `/ley credits`

-- Un pseudo vient d'un ticket : l'outil ne laisse passer que ces caractères (R2), et on refiltre
-- ici, parce qu'un `|` dans une ligne de chat est un code d'échappement du client.
local function Safe(name)
    return type(name) == "string" and name:find("^[%w_%-]+$") ~= nil
end

-- Pseudos des paliers plus récents que `since`, dans l'ordre des paliers, sans doublon.
function Thanks:Names(since)
    local tiers = {}
    for tier in pairs(LL.THANKS or {}) do
        if type(tier) == "number" and tier > (since or 0) then tiers[#tiers + 1] = tier end
    end
    table.sort(tiers)
    local names, seen = {}, {}
    for _, tier in ipairs(tiers) do
        for _, name in ipairs(LL.THANKS[tier]) do
            if Safe(name) and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end
    return names
end

function Thanks:Text(names)
    if #names <= SHOWN then return table.concat(names, ", ") end
    return string.format(L["%s et %s autre(s)"], table.concat(names, ", ", 1, SHOWN), #names - SHOWN)
end

-- Après une fusion des données livrées qui a AJOUTÉ des positions : merci à ceux des paliers que
-- ce joueur vient de recevoir. `since` = son palier d'avant la fusion. Rend vrai si une ligne part.
function Thanks:Announce(since)
    local names = self:Names(since)
    if #names == 0 then return false end
    LL:Printf(L["Merci à %s pour ces positions. /ley credits : tous les contributeurs."], self:Text(names))
    return true
end

-- `/ley credits` : tout le monde, du premier au dernier.
function Thanks:Show()
    local names = self:Names(0)
    if #names == 0 then
        LL:Print(L["Aucun contributeur pour l'instant : /ley contribute pour être le premier."])
        return
    end
    LL:Printf(L["%s contributeur(s) ont partagé leurs positions :"], #names)
    for i = 1, #names, PER_ROW do
        LL:Print(table.concat(names, ", ", i, math.min(i + PER_ROW - 1, #names)))
    end
    LL:Print(L["Toi aussi : /ley contribute."])
end
