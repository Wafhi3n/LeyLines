-- LeyLines_Indicator.lua — l'icône « positions à partager » dans la barre de la minicarte (Forever).
--
-- La barre en haut de la minicarte (`MinimapCluster.IndicatorFrame`) aligne des icônes qui
-- n'apparaissent que quand quelque chose attend le joueur : la lettre du courrier, les commandes
-- d'artisanat de Blizzard, celles de Crafting Order. LeyLines y pose la sienne tant que des
-- positions attendent d'être partagées (LeyLines_Signal.lua ; spec docs/specs/signal-contribution.md,
-- S4). Au clic, la fenêtre de contribution ; l'ouvrir éteint l'icône.
--
-- ⚠️ `MinimapCluster` est un cadre du MODE ÉDITION. Méthode RECOPIÉE de Crafting Order
-- (CraftingOrderClassic_MinimapIndicator.lua), mesurée dans TaintLab le 2026-09-27 et revue en jeu
-- le 2026-09-28 : enfant de la barre, `layoutIndex`, `Layout()` à chaque bascule. Aucune dépendance
-- à COC. Ne pas changer de méthode sans remesurer au labo.
local _, LL = ...
local L = LL.L

local Indicator = {}
LL.Indicator = Indicator

-- Rang dans la barre : 1 et 2 sont à Blizzard, 3 à 5 à Crafting Order (sa spec
-- icone-minicarte.md tient le registre). 10 laisse de la place à COC sans collision.
local ORDER     = 10
local ICON_SIZE = 22   -- comme COC : la lettre de Blizzard fait 20 x 15, un logo se lit mal à 16
local ICON      = "Interface\\AddOns\\LeyLines\\Textures\\icon"

local function Bar()
    local mc = _G.MinimapCluster
    return mc and mc.IndicatorFrame
end

-- Muette pendant la fabrication : la 1re ligne contient « Ley Line », ce que la capture par
-- infobulle cherche (même garde que _Compartment et _Minimap).
function Indicator:ShowTooltip(frame)
    LL.Capture:Mute()
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
    GameTooltip:AddLine(L["Lignes telluriques / Convergences élémentaires"], 0.75, 0.55, 1)
    GameTooltip:AddLine(string.format(L["%s position(s) à partager, absente(s) de la liste commune."],
        LL.Signal:Count()), 1, 1, 1)
    GameTooltip:AddLine(L["Clic : le lien du ticket, déjà rempli."], 0.4, 0.8, 0.4)
    GameTooltip:Show()
    LL.Capture:Unmute()
end

function Indicator:Build(bar)
    local f = CreateFrame("Frame", nil, bar)
    f:SetSize(ICON_SIZE, ICON_SIZE)
    f.layoutIndex = ORDER
    f:EnableMouse(true)
    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(ICON)
    tex:SetAllPoints()
    f:SetScript("OnEnter", function(frame) Indicator:ShowTooltip(frame) end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f:SetScript("OnMouseUp", function() LL.Share:ShowContribute() end)
    f:Hide()
    return f
end

-- Allume ou éteint ; rend vrai si la barre existe. Le cadre n'est créé qu'au premier allumage. Sans
-- la barre (Blizzard la retire ou la change), rien : la ligne de chat reste le seul signal.
function Indicator:Set(shown)
    local bar = Bar()
    if not bar then return false end
    if not self.frame then
        if not shown then return true end
        self.frame = self:Build(bar)
    end
    self.frame:SetShown(shown and true or false)
    if bar.Layout then bar:Layout() end
    return true
end
