-- LeyLines_Minimap.lua — les points sur la minicarte. C'est LA raison d'être de l'addon.
--
-- Principe : la minicarte est un disque centré sur le joueur dont on connaît le rayon en YARDS
-- (LL.Geo:MinimapRadius). Un point à `east`/`north` yards du joueur se place donc à
-- (east, north) * (demi-largeur du cadre / rayon) pixels du centre — après passage éventuel dans
-- le repère tourné (option « rotation de la minicarte » du client), fait par LL.Geo:ToMinimap.
--
-- Un point hors du disque n'est pas jeté : il est RABATTU sur le bord, atténué, pour garder le cap
-- de la ligne tellurique la plus proche même quand elle est loin (option db.minimap.edge).
local _, LL = ...
local L = LL.L

local MM = {}
LL.Minimap = MM

local UPDATE_INTERVAL = 0.1
local PIN_TEXTURE     = "Interface\\Icons\\Spell_Arcane_Arcane01"
local PIN_MASK        = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

function MM:Init()
    self.pins = {}
    self.driver = CreateFrame("Frame")
    self.driver.elapsed = 0
    self.driver:SetScript("OnUpdate", function(driver, elapsed)
        driver.elapsed = driver.elapsed + elapsed
        if driver.elapsed < UPDATE_INTERVAL then return end
        driver.elapsed = 0
        MM:Update()
    end)
    LL:OnRefresh(function() MM:Update() end)
end

function MM:Acquire(index)
    local pin = self.pins[index]
    if pin then return pin end

    pin = CreateFrame("Frame", nil, Minimap)
    pin:SetFrameStrata(Minimap:GetFrameStrata())
    pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    pin.isLeyLinePin = true   -- lu par Capture:OnTooltip pour ne pas s'auto-capturer

    pin.icon = pin:CreateTexture(nil, "OVERLAY")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture(PIN_TEXTURE)
    if pin.icon.SetMask then pcall(pin.icon.SetMask, pin.icon, PIN_MASK) end
    pin.icon:SetVertexColor(0.75, 0.55, 1)

    pin:EnableMouse(true)
    -- La minicarte se pilote au clic et à la molette : nos points ne doivent intercepter que le
    -- survol. SetMouseClickEnabled n'existe que sur l'API mainline — d'où la garde.
    if pin.SetMouseClickEnabled then pin:SetMouseClickEnabled(false) end
    pin:SetScript("OnEnter", function(frame) MM:ShowTooltip(frame) end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.pins[index] = pin
    return pin
end

-- Mute/Unmute encadrent TOUTE infobulle que nous fabriquons : sa 1re ligne porte le nom de la
-- ligne tellurique, que le hook de capture relirait comme s'il s'agissait de l'objet du monde.
function MM:ShowTooltip(pin)
    if not pin.node then return end
    LL.Capture:Mute()
    GameTooltip:SetOwner(pin, "ANCHOR_LEFT")
    GameTooltip:AddLine(LL.Nodes:Label(pin.node), 0.75, 0.55, 1)
    GameTooltip:AddLine(string.format(L["%s yd — source : %s"],
        math.floor((pin.dist or 0) + 0.5), LL.Nodes:SourceLabel(pin.node)), 1, 1, 1)
    GameTooltip:Show()
    LL.Capture:Unmute()
end

function MM:HideFrom(index)
    local pins = self.pins
    for i = index, #pins do
        if pins[i]:IsShown() and LL.Geo:CanTouch(pins[i]) then pins[i]:Hide() end
    end
end

function MM:Place(pin, px, py, faded)
    if not LL.Geo:CanTouch(pin) then return end
    local size = LL.db.minimap.size or 16
    pin:SetSize(size, size)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", Minimap, "CENTER", px, py)
    pin.icon:SetAlpha(faded and 0.55 or 1)
    pin:Show()
end

function MM:Update()
    local map, px, py = LL.Geo:PlayerPos()
    local list = (LL.db.minimap.show and map and Minimap:IsVisible()) and LL.Nodes:All(map) or nil
    if not list or #list == 0 then return self:HideFrom(1) end

    local radius = LL.Geo:MinimapRadius()
    local half   = Minimap:GetWidth() / 2
    if not radius or radius <= 0 or half <= 0 then return self:HideFrom(1) end

    local perYard = half / radius
    local shown   = 0
    for _, node in ipairs(list) do
        local east, north = LL.Geo:Offset(map, px, py, node.x, node.y)
        if east then
            shown = self:PlaceNode(node, east, north, radius, perYard, shown)
        end
    end
    self:HideFrom(shown + 1)
end

-- Rend le nouveau nombre de points affichés (le même si celui-ci a été écarté).
function MM:PlaceNode(node, east, north, radius, perYard, shown)
    local dist = math.sqrt(east * east + north * north)
    local outside = dist > radius
    if outside and not LL.db.minimap.edge then return shown end

    local rx, ry = LL.Geo:ToMinimap(east, north)
    if outside then
        local k = radius / dist
        rx, ry = rx * k, ry * k
    end

    shown = shown + 1
    local pin = self:Acquire(shown)
    pin.node, pin.dist = node, dist
    self:Place(pin, rx * perYard, ry * perYard, outside)
    return shown
end
