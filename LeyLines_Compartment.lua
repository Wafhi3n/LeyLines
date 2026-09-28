-- LeyLines_Compartment.lua — l'entrée de l'addon dans le compartiment d'addons de la minicarte.
--
-- Le compartiment est le bouton NATIF de la minicarte qui déroule les addons inscrits (Retail ;
-- présent sur Forever, vérifié en jeu le 2026-09-27 : `AddonCompartmentFrame` existe). On s'y
-- inscrit par le .toc (`## AddonCompartmentFunc…`), avec l'icône de `## IconTexture` : pas de
-- bouton maison sur la minicarte, pas de bibliothèque à embarquer.
--
-- Pourquoi : `/ley contribute` ne sert que si on le trouve. Clic gauche = la fenêtre de
-- contribution, clic droit = le bandeau. Pas de menu déroulant : c'est ce genre de menu qui a déjà
-- semé de la taint sur Forever (voir la chasse au taint des barres d'action).
--
-- Le client appelle ces fonctions par leur NOM GLOBAL, lu dans le .toc : ne pas les renommer sans
-- renommer les lignes `## AddonCompartmentFunc*`. Signature : (nomDeLAddon, boutonOuCadre).
local _, LL = ...
local L = LL.L

function LeyLines_OnCompartmentClick(_, button)
    if not LL.db then return end
    if button == "RightButton" then
        LL:ToggleHUD()
    else
        LL.Share:ShowContribute()
    end
end

-- Muette pendant la fabrication : la 1re ligne porte le nom de l'addon, qui contient « Ley Line » —
-- exactement ce que la capture par infobulle cherche. Voir le commentaire jumeau de _Minimap.
function LeyLines_OnCompartmentEnter(_, frame)
    if not LL.db or not frame then return end
    local kind = LL.Nodes:PlayerKind()
    LL.Capture:Mute()
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["Lignes telluriques / Convergences élémentaires"], 0.75, 0.55, 1)
    GameTooltip:AddLine(string.format(L["%s %s connue(s) au total."], LL.Nodes:Count(kind),
        LL.Nodes:Word("many", kind)), 1, 1, 1)
    -- Donné même signal coupé (signal-contribution.md) : c'est ici qu'on le retrouve.
    local pending = LL.Signal:Count()
    if pending > 0 then
        GameTooltip:AddLine(string.format(L["%s position(s) à partager, absente(s) de la liste commune."],
            pending), 1, 0.82, 0)
    end
    GameTooltip:AddLine(L["Clic gauche : partager tes captures pour la liste commune."], 0.4, 0.8, 0.4)
    GameTooltip:AddLine(L["Clic droit : afficher ou masquer le suivi."], 0.7, 0.7, 0.7)
    GameTooltip:Show()
    LL.Capture:Unmute()
end

function LeyLines_OnCompartmentLeave()
    GameTooltip:Hide()
end
