-- LeyLines_HUD.lua — le bandeau « la plus proche », et le point de route natif.
--
-- Une ligne tellurique ne sert que si on peut se poser DESSUS : l'affichage minicarte donne le
-- cap, ce bandeau donne la distance qui reste et une flèche relative au regard du joueur.
-- Le clic pose un point de route du CLIENT (C_Map.SetUserWaypoint + C_SuperTrack), donc la
-- navigation native — pas de flèche maison à entretenir, pas de dépendance à TomTom.
local _, LL = ...
local L = LL.L

local HUD = {}
LL.HUD = HUD

local UPDATE_INTERVAL = 0.1
local BUFF_CHECK      = 1    -- s : cadence de surveillance du buff de faille
local ICON_TEXTURE    = "Interface\\Icons\\Spell_Arcane_Arcane01"
local ARROW_TEXTURE   = "Interface\\Minimap\\MinimapArrow"
local CLOSE_RANGE     = 10   -- yards : en dessous, on est dessus

function HUD:Init()
    self:Build()
    self:Wire()
    LL:OnRefresh(function() HUD:Apply() end)
    self:Apply()
end

function HUD:Build()
    local f = CreateFrame("Button", "LeyLinesHUD", UIParent)
    self.frame = f
    f:SetSize(196, 36)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f.isLeyLinePin = true

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.45)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(24, 24)
    f.icon:SetPoint("LEFT", 6, 0)
    f.icon:SetTexture(ICON_TEXTURE)
    f.icon:SetVertexColor(0.75, 0.55, 1)

    f.arrow = f:CreateTexture(nil, "ARTWORK")
    f.arrow:SetSize(24, 24)
    f.arrow:SetPoint("RIGHT", -6, 0)
    f.arrow:SetTexture(ARROW_TEXTURE)

    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 6, -1)
    f.name:SetPoint("RIGHT", f.arrow, "LEFT", -4, 0)
    f.name:SetJustifyH("LEFT")

    f.dist = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.dist:SetPoint("BOTTOMLEFT", f.icon, "BOTTOMRIGHT", 6, 1)
    f.dist:SetJustifyH("LEFT")
end

function HUD:Wire()
    local f = self.frame
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        HUD:SavePosition()
    end)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            LL.db.hud.show = false
            HUD:Apply()
            LL:Printf(L["Suivi à l'écran : %s."], LL:OnOff(false))
        else
            HUD:Track(HUD.node)
        end
    end)
    f:SetScript("OnEnter", function(frame)
        LL.Capture:Mute()   -- voir LeyLines_Minimap.lua : nos infobulles ne se capturent pas
        GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Lignes telluriques"], 0.75, 0.55, 1)
        GameTooltip:AddLine(L["Clic gauche : poser un point de route."], 1, 1, 1)
        GameTooltip:AddLine(L["Clic droit : masquer. Glisser : déplacer."], 0.7, 0.7, 0.7)
        GameTooltip:Show()
        LL.Capture:Unmute()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Deux cadences dans un seul pilote : le bandeau suit le joueur (10/s), la surveillance du
    -- buff n'a besoin que d'une seconde. Le rappel tourne MÊME BANDEAU MASQUÉ — c'est un rappel,
    -- pas un affichage : le masquer ne doit pas le débrancher.
    self.driver = CreateFrame("Frame")
    self.driver.fast, self.driver.slow = 0, 0
    self.driver:SetScript("OnUpdate", function(driver, elapsed)
        driver.fast, driver.slow = driver.fast + elapsed, driver.slow + elapsed
        if driver.slow >= BUFF_CHECK then
            driver.slow = 0
            HUD:CheckBuff()
        end
        if driver.fast < UPDATE_INTERVAL then return end
        driver.fast = 0
        HUD:Update()
    end)
end

function HUD:SavePosition()
    local point, _, _, x, y = self.frame:GetPoint()
    LL.db.hud.point, LL.db.hud.x, LL.db.hud.y = point or "CENTER", x or 0, y or 0
end

function HUD:Apply()
    if not self.frame then return end
    local db = LL.db.hud
    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
    if db.show then self:Update() else self.frame:Hide() end
end

function HUD:Update()
    local f = self.frame
    if not f or not LL.db.hud.show then return end

    local node, dist = LL.Nodes:NearestToPlayer()
    if not node then
        self.node = nil
        if f:IsShown() then f:Hide() end
        return
    end

    self.node = node
    if not f:IsShown() then f:Show() end
    f.name:SetText(LL.Nodes:Label(node))
    f.dist:SetText(string.format(L["%s yd"], math.floor((dist or 0) + 0.5)))
    if (dist or 0) <= CLOSE_RANGE then
        f.dist:SetTextColor(0.4, 1, 0.4)
    else
        f.dist:SetTextColor(1, 0.82, 0)
    end
    self:PointArrow(node)
end

-- La flèche est relative au REGARD du joueur : elle indique où tourner, pas le nord.
function HUD:PointArrow(node)
    local map, px, py = LL.Geo:PlayerPos()
    if not map then return end
    local east, north = LL.Geo:Offset(map, px, py, node.x, node.y)
    if not east then return end
    self.frame.arrow:SetRotation(LL.Geo:ArrowRotation(east, north))
end

-- Le buff d'absorption dure 15 min : le rappel prévient AVANT qu'il tombe et pose le point de
-- route sur la faille connue la plus proche, pour repartir se recharger sans ouvrir la carte.
-- Il ne se déclenche qu'UNE fois par buff : `warned` se réarme dès que le buff est repris (temps
-- restant redevenu supérieur au seuil) ou disparaît.
function HUD:CheckBuff()
    local minutes = LL.db.warnMinutes or 0
    if minutes <= 0 then return end

    local aura, left = LL.Capture:LeyAura()
    if not aura or left > minutes * 60 then
        self.warned = false
        return
    end
    if self.warned then return end
    self.warned = true
    self:WarnExpiring(left)
end

function HUD:WarnExpiring(left)
    local mins = math.max(0, math.floor(left / 60 + 0.5))
    local node, dist = LL.Nodes:NearestToPlayer()
    if not node then
        LL:Printf(L["Buff de faille : %s min restantes — aucune faille connue dans cette zone."], mins)
        return
    end
    LL:Printf(L["Buff de faille : %s min restantes — la plus proche à %s yd."],
        mins, math.floor(dist + 0.5))
    self:Track(node)
end

function HUD:Track(node)
    if not node then
        LL:Print(L["Aucune ligne tellurique connue dans cette zone."])
        return
    end
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(node.map) then
        LL:Print(L["Cette zone n'accepte pas de point de route."])
        return
    end
    local point = UiMapPoint and UiMapPoint.CreateFromCoordinates(node.map, node.x, node.y)
    if not point or not C_Map.SetUserWaypoint then return end

    C_Map.SetUserWaypoint(point)
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    -- Le bandeau est cliquable : sans ce garde-fou, quelques clics de suite remplissent le chat de
    -- la même ligne. On n'annonce que le CHANGEMENT de cible.
    if self.tracked ~= node then
        self.tracked = node
        LL:Printf(L["Point de route posé sur %s."], LL.Nodes:Label(node))
    end
end
