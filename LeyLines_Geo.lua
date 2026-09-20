-- LeyLines_Geo.lua — toute la géométrie de l'addon, et RIEN d'autre.
--
-- Une position de ligne tellurique est stockée en coordonnées de CARTE (x/y dans [0,1] sur un
-- uiMapID). Pour l'afficher il faut des YARDS : c'est ici que se fait la conversion, une fois,
-- pour que la minicarte, la carte du monde et le HUD partagent exactement le même calcul.
--
-- Repères (API MAINLINE) :
--   * carte  : x croît vers l'EST, y croît vers le SUD (0,0 = coin haut-gauche).
--   * monde  : x = axe NORD, y = axe OUEST (c'est le repère de C_Map.GetWorldPosFromMapPos).
--   * écran  : +x = droite, +y = haut.
local _, LL = ...

local Geo = {}
LL.Geo = Geo

-- Diamètres (yards) du cercle visible de la minicarte par niveau de zoom — filet de sécurité si
-- C_Minimap.GetViewRadius est absent. Valeurs historiques du client, inchangées depuis vanilla.
local ZOOM_DIAMETER = { 466.7, 400, 333.3, 266.7, 200, 133.3 }
local ZOOM_DIAMETER_INDOOR = { 150, 120, 90, 60, 40, 25 }

local sizeCache = {}

function Geo:PlayerMap()
    return C_Map.GetBestMapForUnit("player")
end

function Geo:MapName(map)
    local info = map and C_Map.GetMapInfo(map)
    return info and info.name or tostring(map)
end

-- Renvoie map, x, y — ou nil si le client refuse la position (certaines instances).
function Geo:PlayerPos()
    local map = self:PlayerMap()
    if not map then return nil end
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return nil end
    local x, y = pos:GetXY()
    if not x or not y then return nil end
    return map, x, y
end

-- Taille de la zone en yards. C_Map.GetMapWorldSize la donne directement ; s'il rend 0 (vécu sur
-- des cartes de donjon), on la RECALCULE depuis deux coins en coordonnées monde.
function Geo:MapSize(map)
    if not map then return nil end
    local cached = sizeCache[map]
    if cached then return cached[1], cached[2] end

    local w, h = C_Map.GetMapWorldSize(map)
    if not w or w <= 0 then w, h = self:SizeFromCorners(map) end
    if not w or w <= 0 then return nil end

    sizeCache[map] = { w, h }
    return w, h
end

function Geo:SizeFromCorners(map)
    if not CreateVector2D or not C_Map.GetWorldPosFromMapPos then return nil end
    local _, tl = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(0, 0))
    local _, br = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(1, 1))
    if not tl or not br then return nil end
    local nx1, wy1 = tl:GetXY()
    local nx2, wy2 = br:GetXY()
    if not nx1 or not nx2 then return nil end
    -- largeur = étendue EST-OUEST (axe y du monde), hauteur = étendue NORD-SUD (axe x du monde).
    return math.abs(wy1 - wy2), math.abs(nx1 - nx2)
end

-- Repose une position d'une carte SUR UNE AUTRE, en passant par les coordonnées monde.
-- Sans ça, ouvrir la carte du continent n'afficherait rien : les points sont enregistrés sur la
-- carte de ZONE, et le canevas affiché serait un autre uiMapID.
-- Le contrôle de bornes est indispensable : demander la position d'un point d'Azeroth sur la carte
-- d'un autre continent rend des coordonnées hors [0,1] plutôt qu'un refus franc.
function Geo:Translate(map, x, y, target)
    if map == target then return x, y end
    if not CreateVector2D or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos then
        return nil
    end
    local continent, world = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(x, y))
    if not continent or not world then return nil end
    local _, pos = C_Map.GetMapPosFromWorldPos(continent, world, target)
    if not pos then return nil end
    local tx, ty = pos:GetXY()
    if not tx or not ty or tx < 0 or tx > 1 or ty < 0 or ty > 1 then return nil end
    return tx, ty
end

-- Décalage en yards du point 1 vers le point 2 : est (droite), nord (haut).
function Geo:Offset(map, x1, y1, x2, y2)
    local w, h = self:MapSize(map)
    if not w then return nil end
    return (x2 - x1) * w, (y1 - y2) * h
end

function Geo:Distance(map, x1, y1, x2, y2)
    local east, north = self:Offset(map, x1, y1, x2, y2)
    if not east then return nil end
    return math.sqrt(east * east + north * north)
end

-- ---------------------------------------------------------------------------
-- Minicarte
-- ---------------------------------------------------------------------------

local function GetBool(cvar)
    if C_CVar and C_CVar.GetCVarBool then return C_CVar.GetCVarBool(cvar) end
    return GetCVarBool and GetCVarBool(cvar) or false
end

function Geo:MinimapRotating()
    if C_Minimap and C_Minimap.IsRotateMinimapIgnored and C_Minimap.IsRotateMinimapIgnored() then
        return false
    end
    return GetBool("rotateMinimap") and true or false
end

-- Rayon VISIBLE de la minicarte, en yards.
-- Piège : rien ne garantit que GetViewRadius rende un rayon plutôt qu'un diamètre, et une erreur
-- de facteur 2 place les points au bon cap mais à la mauvaise distance — donc invisible à l'œil.
-- Au-delà de 250 yd (rayon maximal possible en extérieur) on tient la valeur pour un diamètre.
-- `db.minimap.scale` reste la correction manuelle de dernier recours (`/ley scale`).
function Geo:MinimapRadius()
    local r
    if C_Minimap and C_Minimap.GetViewRadius then r = C_Minimap.GetViewRadius() end
    if not r or r <= 0 then
        local zoom = (Minimap.GetZoom and Minimap:GetZoom() or 0) + 1
        local tbl  = (IsIndoors and IsIndoors()) and ZOOM_DIAMETER_INDOOR or ZOOM_DIAMETER
        r = (tbl[zoom] or 200) / 2
    elseif r > 250 then
        r = r / 2
    end
    return r * (LL.db and LL.db.minimap.scale or 1)
end

-- Passe un décalage est/nord dans le repère ÉCRAN de la minicarte.
-- Sans rotation, le haut de la minicarte est le nord : rien à faire. Avec rotation, le haut
-- devient la direction regardée. GetPlayerFacing croît dans le sens trigonométrique depuis le
-- nord, donc le cap du joueur vaut -facing en horaire, et faire tourner le décor revient à
-- ajouter +facing à l'angle horaire de chaque point.
function Geo:ToMinimap(east, north)
    if not self:MinimapRotating() then return east, north end
    local f = (GetPlayerFacing and GetPlayerFacing()) or 0
    local c, s = math.cos(f), math.sin(f)
    return east * c + north * s, north * c - east * s
end

-- Angle HORAIRE depuis le nord (radians).
function Geo:Bearing(east, north)
    return math.atan2(east, north)
end

-- Rotation à donner à une flèche dont le « tout droit » est le HAUT, pour qu'elle désigne le
-- point : angle horaire à l'écran = cap du point + orientation du joueur, et SetRotation compte
-- dans le sens trigonométrique — d'où le signe. Ici plutôt que dans le HUD pour être testable
-- sans client (un signe inversé donne une flèche crédible qui ment).
function Geo:ArrowRotation(east, north)
    local facing = (GetPlayerFacing and GetPlayerFacing()) or 0
    return -(self:Bearing(east, north) + facing)
end

-- Garde-fou Forever : un cadre enfant d'un cadre Blizzard peut être PROTÉGÉ, et le client refuse
-- alors SetPoint/Show/Hide en combat. On ne tente rien plutôt que de lever une erreur ; la
-- position reprend au premier rafraîchissement après le combat.
function Geo:CanTouch(frame)
    return not (InCombatLockdown() and frame:IsProtected())
end
