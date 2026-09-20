-- LeyLines_WorldMap.lua — les mêmes points, sur la grande carte.
--
-- Les points sont des cadres enfants du CANEVAS de la carte (WorldMapFrame:GetCanvas()), donc ils
-- suivent le déplacement et le zoom sans qu'on ait à les recalculer. Deux détails repris tels
-- quels de MapCanvasMixin:ApplyPinPosition (Blizzard_MapCanvas.lua) :
--   * l'ancrage se fait au coin HAUT-GAUCHE du canevas, y étant compté vers le bas ;
--   * les décalages d'un SetPoint sont exprimés dans l'échelle DU POINT — d'où la division par
--     pin:GetScale(). Oublier cette division décale tous les points dès qu'on zoome.
--
-- Deux temps, à ne pas confondre : PLOT (quels points, à quelles coordonnées de la carte affichée)
-- ne change qu'au changement de carte ou de base, et demande des appels API ; PLACE (où les poser
-- à l'écran) suit le zoom et tourne en continu. Tout mélanger ferait des centaines d'appels de
-- conversion par seconde pour un résultat identique.
local _, LL = ...
local L = LL.L

local WM = {}
LL.WorldMap = WM

local UPDATE_INTERVAL = 0.25
local PIN_TEXTURE     = "Interface\\Icons\\Spell_Arcane_Arcane01"
local PIN_MASK        = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

function WM:Init()
    if not WorldMapFrame or not WorldMapFrame.GetCanvas then return end
    self.pins = {}
    self.plot = {}

    LL:OnRefresh(function() WM:Plot() end)
    WorldMapFrame:HookScript("OnShow", function() WM:Plot() end)
    if WorldMapFrame.OnMapChanged then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function() WM:Plot() end)
    end

    -- Le zoom n'émet pas d'événement exploitable : tant que la carte est ouverte on replace à
    -- intervalle lent. Quelques SetPoint par seconde sur une carte ouverte, et aucune dépendance
    -- aux entrailles du ScrollContainer.
    self.driver = CreateFrame("Frame")
    self.driver.elapsed = 0
    self.driver:SetScript("OnUpdate", function(driver, elapsed)
        driver.elapsed = driver.elapsed + elapsed
        if driver.elapsed < UPDATE_INTERVAL then return end
        driver.elapsed = 0
        if WorldMapFrame:IsShown() then WM:Place() end
    end)
end

function WM:Acquire(index)
    local pin = self.pins[index]
    if pin then return pin end
    local canvas = WorldMapFrame:GetCanvas()

    pin = CreateFrame("Button", nil, canvas)
    -- Blizzard pose SES points de carte à des niveaux ABSOLUS à partir de 2000
    -- (MAP_CANVAS_PIN_FRAME_LEVEL_DEFAULT, MapCanvas_PinFrameLevelsManager.lua) : un « niveau du
    -- canevas + 100 » passait sous tout ce que la carte empile. On se range au-dessus de leur bande.
    pin:SetFrameLevel(2600)
    pin.isLeyLinePin = true

    pin.icon = pin:CreateTexture(nil, "OVERLAY")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture(PIN_TEXTURE)
    if pin.icon.SetMask then pcall(pin.icon.SetMask, pin.icon, PIN_MASK) end
    pin.icon:SetVertexColor(0.75, 0.55, 1)

    pin:RegisterForClicks("LeftButtonUp")
    pin:SetScript("OnEnter", function(frame) WM:ShowTooltip(frame) end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(frame) LL.HUD:Track(frame.node) end)

    self.pins[index] = pin
    return pin
end

-- Muette pendant la fabrication : voir le commentaire jumeau dans LeyLines_Minimap.lua.
function WM:ShowTooltip(pin)
    if not pin.node then return end
    LL.Capture:Mute()
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:AddLine(LL.Nodes:Label(pin.node), 0.75, 0.55, 1)
    GameTooltip:AddLine(string.format("%.1f / %.1f", pin.node.x * 100, pin.node.y * 100), 1, 1, 1)
    GameTooltip:AddLine(string.format(L["Source : %s — %s relevé(s)"],
        LL.Nodes:SourceLabel(pin.node), pin.node.hits or 1), 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["Clic : poser un point de route."], 0.4, 0.8, 0.4)
    GameTooltip:Show()
    LL.Capture:Unmute()
end

function WM:HideFrom(index)
    local pins = self.pins
    if not pins then return end
    for i = index, #pins do
        if pins[i]:IsShown() and LL.Geo:CanTouch(pins[i]) then pins[i]:Hide() end
    end
end

-- Quoi afficher : TOUS les points connus, ramenés sur la carte actuellement ouverte. Un point
-- d'une autre zone n'est gardé que si la conversion le place bien dans ce cadre (voir Geo:Translate).
function WM:Plot()
    if not self.plot then return end
    wipe(self.plot)

    local map = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    if not LL.db.worldmap.show or not map or not WorldMapFrame:IsShown() then
        return self:HideFrom(1)
    end

    for nodeMap, list in pairs(LL.db.nodes) do
        for _, node in ipairs(list) do
            local x, y = LL.Geo:Translate(nodeMap, node.x, node.y, map)
            if x then table.insert(self.plot, { node = node, x = x, y = y }) end
        end
    end
    self:Place()
end

function WM:Place()
    local plot = self.plot
    if not plot then return end
    if #plot == 0 then return self:HideFrom(1) end

    local canvas = WorldMapFrame:GetCanvas()
    local size   = LL.db.worldmap.size or 18

    -- Échelle inverse du canevas : le point garde la même taille à l'écran quel que soit le zoom.
    -- On la lit SUR LE CANEVAS, jamais via WorldMapFrame:GetCanvasScale(). Cette dernière rend
    -- 1 par défaut tant que le conteneur n'a pas d'échelle en cours — et il remet currentScale ET
    -- targetScale à nil à chaque changement de carte (MapCanvas_ScrollContainerMixin). Avec 1 au
    -- lieu de la vraie valeur (~0,3), le point se dessinait à 5 px : présent, survolable, et
    -- invisible. `Child:SetScale(currentScale)` fait du canevas la source de vérité. Vécu 2026-09-20.
    local raw   = canvas:GetScale()
    if not raw or raw <= 0 then raw = 1 end
    local scale = 1 / raw

    for i, entry in ipairs(plot) do
        local pin = self:Acquire(i)
        if LL.Geo:CanTouch(pin) then
            pin.node = entry.node
            pin:SetScale(scale)
            pin:SetSize(size, size)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT",
                (canvas:GetWidth() * entry.x) / scale, -(canvas:GetHeight() * entry.y) / scale)
            pin:Show()
        end
    end
    self:HideFrom(#plot + 1)
end
