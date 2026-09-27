-- LeyLines_Share.lua — échanger des positions entre joueurs, sans réseau.
--
-- Il n'y a pas de transport dans cet addon : le partage passe par un TEXTE que le joueur copie et
-- colle où il veut (ticket GitHub, Discord, message). C'est volontaire — une base de positions
-- n'a pas besoin de temps réel, et un bout de texte se relit, se corrige et s'archive.
--
-- Format `LL2` : `LL2;<segment>[;<segment>…]`, un segment par (espèce, carte) :
--
--   [-][L|V]<uiMapID>=<x>,<y>[,<x>,<y>…]
--
--   L = fissure (Ley Line, Alliance), V = tornade (Elemental Convergence, Horde), rien = inconnue.
--   `-` = RETRAIT (« ces points n'existent plus »), réservé à la contribution par ticket
--   (docs/specs/contribution-positions.md). Ce client-ci ne sait pas l'appliquer, il l'IGNORE —
--   surtout pas le lire comme un ajout. Même règle pour une espèce qu'il ne connaît pas.
--
-- Coordonnées en dix-millièmes (0..10000), donc ~0,5 yd de précision sur une zone de 5000 yd.
-- Entiers seulement : pas de virgule flottante à recoller entre deux locales (un client FR écrit
-- « 0,35 »), pas de guillemets à échapper dans un ticket, et ça se relit à l'œil.
--
-- `LL1` (v1.0.x, jamais publié mais présent dans des bases de développement) est le même texte
-- sans espèce. Le décodeur le lit encore — l'instantané interne d'une vieille base en dépend —
-- mais l'IMPORT refuse tout point sans espèce : il ne dit pas quelle faction peut l'absorber.
local _, LL = ...
local L = LL.L

local Share = {}
LL.Share = Share

local SCALE = 10000
local KNOWN = { [""] = true, L = true, V = true }

-- ---------------------------------------------------------------------------
-- Codec (pur, testable sans client)
-- ---------------------------------------------------------------------------
function Share:Encode()
    local groups = {}
    for map, list in pairs(LL.db.nodes) do
        for _, node in ipairs(list) do
            local key = (node.kind or "") .. tostring(map)
            local nums = groups[key] or {}
            groups[key] = nums
            nums[#nums + 1] = string.format("%d,%d",
                math.floor(node.x * SCALE + 0.5), math.floor(node.y * SCALE + 0.5))
        end
    end
    local parts = {}
    for key, nums in pairs(groups) do parts[#parts + 1] = key .. "=" .. table.concat(nums, ",") end
    if #parts == 0 then return nil end
    table.sort(parts)   -- sortie stable : deux exports de la même base sont identiques
    return "LL2;" .. table.concat(parts, ";")
end

-- Un segment, ou nil s'il est à ignorer (retrait, espèce inconnue de ce client, rien d'utilisable).
local function DecodeSegment(seg)
    local minus, kind, map, nums = seg:match("^(%-?)(%a?)(%d+)=([%d,]+)$")
    if not map or minus ~= "" or not KNOWN[kind] then return nil end
    local id = tonumber(map)
    if not id or id <= 0 then return nil end

    local coords = {}
    for n in nums:gmatch("%d+") do coords[#coords + 1] = tonumber(n) end
    local pts = {}
    for i = 1, #coords - 1, 2 do
        local x, y = coords[i] / SCALE, coords[i + 1] / SCALE
        if x <= 1 and y <= 1 then pts[#pts + 1], pts[#pts + 2] = x, y end
    end
    if #pts == 0 then return nil end
    return { map = id, kind = (kind ~= "" and kind or nil), pts = pts }
end

-- Rend une liste de segments { map, kind, pts = { x, y, … } } et le nombre de points, ou nil + une
-- raison. Tout ce qui est douteux est JETÉ point par point plutôt que de faire échouer l'import
-- entier : un code recopié à la main perd souvent un caractère, et sauver 19 points sur 20 vaut
-- mieux que refuser les 20.
function Share:Decode(text)
    if type(text) ~= "string" then return nil, "format" end
    local body = text:gsub("%s+", ""):match("^LL[12];(.+)$")
    if not body then return nil, "format" end

    local out, total = {}, 0
    for raw in body:gmatch("[^;]+") do
        local seg = DecodeSegment(raw)
        if seg then
            out[#out + 1] = seg
            total = total + #seg.pts / 2
        end
    end
    if total == 0 then return nil, "empty" end
    return out, total
end

-- ---------------------------------------------------------------------------
-- Import
-- ---------------------------------------------------------------------------
-- Un point SANS espèce n'entre pas : il ne dit pas quelle faction peut l'absorber, et le deviner
-- a déjà raté — vu en jeu le 2026-09-27, les tornades Horde d'un vieux code devenaient des
-- « Ley Line » dans les Tarides chez un personnage Alliance. Celui qui a donné le code réexporte.
function Share:Import(text)
    local segments, total = self:Decode(text)
    if not segments then
        LL:Print(L["Code invalide : ce n'est pas un export de Ley Lines."])
        return
    end
    local kept, skipped = {}, 0
    for _, seg in ipairs(segments) do
        if seg.kind then kept[#kept + 1] = seg else skipped = skipped + #seg.pts / 2 end
    end
    if #kept == 0 then
        LL:Print(L["Ancien code, qui ne dit pas à quelle faction appartiennent ses points : demande un nouvel export."])
        return
    end
    local added = LL.Nodes:AddSegments(kept, "import")
    LL:Refresh()
    LL:Printf(L["%s position(s) importée(s), %s déjà connue(s)."], added, total - skipped - added)
    if skipped > 0 then
        LL:Printf(L["%s position(s) sans faction ignorée(s) : demande un nouvel export."], skipped)
    end
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
    f.title:SetText(L["Partage des positions"])

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
        LL:Print(L["Aucune position à exporter."])
        return
    end
    self:Open(blob, L["Copie ce texte (Ctrl+C) et partage-le."])
end

function Share:ShowImport()
    self:Open("", L["Colle un code reçu, puis clique sur Importer."])
end
