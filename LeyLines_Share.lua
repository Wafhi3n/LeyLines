-- LeyLines_Share.lua — échanger des positions entre joueurs, sans réseau.
--
-- Il n'y a pas de transport dans cet addon : le partage passe par un TEXTE que le joueur copie et
-- colle où il veut (ticket GitHub, Discord, message). C'est volontaire — une base de positions
-- n'a pas besoin de temps réel, et un bout de texte se relit, se corrige et s'archive.
--
-- Format `LL1` : `LL1;<uiMapID>=<x>,<y>[,<x>,<y>…][;<uiMapID>=…]`, coordonnées en dix-millièmes
-- (0..10000), donc ~0,5 yd de précision sur une zone de 5000 yd. Entiers seulement : pas de
-- virgule flottante à recoller entre deux locales (un client FR écrit « 0,35 »), pas de guillemets
-- à échapper dans un ticket, et ça se relit à l'œil.
local _, LL = ...
local L = LL.L

local Share = {}
LL.Share = Share

local SCALE = 10000

-- ---------------------------------------------------------------------------
-- Codec (pur, testable sans client)
-- ---------------------------------------------------------------------------
function Share:Encode()
    local parts = {}
    for map, list in pairs(LL.db.nodes) do
        if #list > 0 then
            local nums = {}
            for _, node in ipairs(list) do
                nums[#nums + 1] = string.format("%d,%d",
                    math.floor(node.x * SCALE + 0.5), math.floor(node.y * SCALE + 0.5))
            end
            parts[#parts + 1] = tostring(map) .. "=" .. table.concat(nums, ",")
        end
    end
    if #parts == 0 then return nil end
    table.sort(parts)   -- sortie stable : deux exports de la même base sont identiques
    return "LL1;" .. table.concat(parts, ";")
end

-- Rend une table { [uiMapID] = { x, y, … } } et le nombre de points, ou nil + une raison.
-- Tout ce qui est douteux est JETÉ point par point plutôt que de faire échouer l'import entier :
-- un code recopié à la main perd souvent un caractère, et sauver 19 points sur 20 vaut mieux que
-- refuser les 20.
function Share:Decode(text)
    if type(text) ~= "string" then return nil, "format" end
    local body = text:gsub("%s+", ""):match("^LL1;(.+)$")
    if not body then return nil, "format" end

    local out, total = {}, 0
    for map, nums in body:gmatch("(%d+)=([%d,]+)") do
        local id = tonumber(map)
        local coords = {}
        for n in nums:gmatch("%d+") do coords[#coords + 1] = tonumber(n) end
        if id and id > 0 and #coords >= 2 then
            local pts = {}
            for i = 1, #coords - 1, 2 do
                local x, y = coords[i] / SCALE, coords[i + 1] / SCALE
                if x <= 1 and y <= 1 then
                    pts[#pts + 1], pts[#pts + 2] = x, y
                    total = total + 1
                end
            end
            if #pts > 0 then out[id] = pts end
        end
    end
    if total == 0 then return nil, "empty" end
    return out, total
end

-- ---------------------------------------------------------------------------
-- Import
-- ---------------------------------------------------------------------------
function Share:Import(text)
    local data, total = self:Decode(text)
    if not data then
        LL:Print(L["Code invalide : ce n'est pas un export de Ley Lines."])
        return
    end
    local added = 0
    for map, pts in pairs(data) do
        for i = 1, #pts - 1, 2 do
            local _, isNew = LL.Nodes:Add(map, pts[i], pts[i + 1], { src = "import" })
            if isNew then added = added + 1 end
        end
    end
    LL:Refresh()
    LL:Printf(L["%s ligne(s) importée(s), %s déjà connue(s)."], added, total - added)
end

-- ---------------------------------------------------------------------------
-- Fenêtre de copier-coller
-- ---------------------------------------------------------------------------
local function MakeButton(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(96, 22)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.25, 0.2, 0.35, 0.9)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
    b:SetScript("OnEnter", function() bg:SetColorTexture(0.38, 0.3, 0.5, 0.95) end)
    b:SetScript("OnLeave", function() bg:SetColorTexture(0.25, 0.2, 0.35, 0.9) end)
    b:SetScript("OnClick", onClick)
    return b
end

function Share:Build()
    -- Nom GLOBAL obligatoire pour UISpecialFrames (Échap ferme). Sans danger ici : la fenêtre est
    -- fille d'UIParent, donc jamais protégée — voir la garde de LeyLines_Geo:CanTouch.
    local f = CreateFrame("Frame", "LeyLinesShareFrame", UIParent)
    self.frame = f
    f:SetSize(480, 116)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 12, -10)
    f.title:SetText(L["Partage des lignes telluriques"])

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("TOPLEFT", 12, -30)
    f.hint:SetPoint("RIGHT", -12, 0)
    f.hint:SetJustifyH("LEFT")

    self:BuildBox(f)
    tinsert(UISpecialFrames, "LeyLinesShareFrame")
    return f
end

function Share:BuildBox(f)
    local boxBg = f:CreateTexture(nil, "ARTWORK")
    boxBg:SetPoint("TOPLEFT", 12, -50)
    boxBg:SetPoint("RIGHT", -12, 0)
    boxBg:SetHeight(24)
    boxBg:SetColorTexture(0.1, 0.1, 0.12, 1)

    f.box = CreateFrame("EditBox", nil, f)
    f.box:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 6, -4)
    f.box:SetPoint("BOTTOMRIGHT", boxBg, "BOTTOMRIGHT", -6, 4)
    f.box:SetFontObject("ChatFontNormal")
    f.box:SetMaxLetters(0)
    f.box:SetAutoFocus(false)
    f.box:SetScript("OnEscapePressed", function(box) box:ClearFocus(); f:Hide() end)

    MakeButton(f, L["Importer"], function()
        Share:Import(f.box:GetText())
        f:Hide()
    end):SetPoint("BOTTOMRIGHT", -116, 12)

    MakeButton(f, L["Fermer"], function() f:Hide() end):SetPoint("BOTTOMRIGHT", -12, 12)
end

function Share:Open(text, hint)
    local f = self.frame or self:Build()
    f.hint:SetText(hint)
    f.box:SetText(text or "")
    f:Show()
    f.box:SetFocus()
    if text then f.box:HighlightText() end
end

function Share:ShowExport()
    local blob = self:Encode()
    if not blob then
        LL:Print(L["Aucune ligne tellurique à exporter."])
        return
    end
    self:Open(blob, L["Copie ce texte (Ctrl+C) et partage-le."])
end

function Share:ShowImport()
    self:Open("", L["Colle un code reçu, puis clique sur Importer."])
end
