-- LeyLines_OptionsPanel.lua — la page de l'addon dans Options → AddOns (docs/specs/panneau-options.md).
--
-- Une page « canevas » (O1) : notre cadre, nos contrôles faits des modèles du jeu (case, curseur,
-- bouton) et AUCUN menu déroulant : sur Forever, ouvrir un menu déroulant créé par un addon fait
-- planter le client (constat C17, revérifié le 2026-10-08). Chaque contrôle lit et écrit par
-- LL.Options, le même setter que les commandes `/ley`.
--
-- Mesuré le 2026-10-08 (build 70245) : une page canevas s'enregistre et s'ouvre par
-- `Settings.OpenToCategory` sans blocage visible. Pas de `frame.OnDefault` : le « tout par défaut »
-- des options du jeu ne doit pas remettre nos réglages en silence ; notre bouton le fait (O4), après
-- confirmation. Les contrôles se construisent au premier affichage, pas au chargement.
local _, LL = ...
local L = LL.L

local Panel = {}
LL.OptionsPanel = Panel

local COL_X = { 16, 340 }
local TOP_Y = -70
local ROW_CHECK, ROW_SLIDER, ROW_BUTTON, GAP = 28, 50, 28, 14

local SECTIONS = {
    { id = "display", title = L["Affichage"],      col = 1 },
    { id = "capture", title = L["Capture"],        col = 2 },
    { id = "warn",    title = L["Rappel de buff"], col = 2 },
    { id = "share",   title = L["Partage"],        col = 2 },
}

-- Les boutons d'une section, sous ses réglages. La fenêtre de partage est en strate DIALOG,
-- au-dessus des options (HIGH) ; les autres gestes répondent dans le chat.
local ACTIONS = {
    display = { { L["Replacer le bandeau"], function() LL.Options:ResetHUDPosition() end } },
    capture = { { L["Apprendre mon sort"], function() LL.CMD.learn("") end },
                { L["Effacer les relevés d'infobulle"], function() LL.CMD.clean("") end } },
    share   = { { L["Contribuer"], function() LL.Share:ShowContribute() end },
                { L["Exporter"], function() LL.Share:ShowExport() end },
                { L["Importer"], function() LL.Share:ShowImport() end },
                { L["Contributeurs"], function() LL.Thanks:Show() end } },
}

-- Muette pendant la fabrication (fait 6 de la skill) : une infobulle qui contient « Ley Line » est
-- exactement ce que la capture par infobulle cherche.
local function Tip(region, title, text)
    region:HookScript("OnEnter", function(self)
        LL.Capture:Mute()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
        LL.Capture:Unmute()
    end)
    region:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Round(v, step)
    return math.floor(v / step + 0.5) * step
end

function Panel:Check(parent, e, x, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(26, 26)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetText(e.label)
    cb:SetScript("OnClick", function(self)
        LL.Options:Set(e, self:GetChecked() and true or false)
    end)
    Tip(cb, e.label, e.tip)
    cb.Load = function(self) self:SetChecked(LL.Options:Get(e) and true or false) end
    return cb, ROW_CHECK
end

-- Le curseur est borné par `panelMax` (le rappel : 14 min, le buff en dure 15) ; une valeur posée
-- plus haut par la commande s'affiche au bout du curseur sans être réécrite (Panel.loading).
function Panel:Slider(parent, e, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x + 4, y)
    label:SetText(e.label)
    local max = e.panelMax or e.max
    local s = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    s:SetPoint("TOPLEFT", x, y - 16)
    s:SetWidth(250)
    local right = MinimalSliderWithSteppersMixin.Label.Right
    s:Init(math.min(LL.Options:Get(e), max), e.min, max, (max - e.min) / e.step,
        { [right] = function(v) return tostring(Round(v, e.step)) end })
    s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v)
        if Panel.loading then return end
        local r = Round(v, e.step)
        if r ~= LL.Options:Get(e) then LL.Options:Set(e, r) end
    end, s)
    Tip(s.Slider, e.label, e.tip)
    s.Load = function(self) self:SetValue(math.min(LL.Options:Get(e), max)) end
    return s, ROW_SLIDER
end

-- Deux boutons par rangée. Rend la hauteur occupée.
function Panel:Buttons(parent, list, x, y)
    for i, a in ipairs(list) do
        local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetSize(150, 22)
        b:SetPoint("TOPLEFT", x + ((i - 1) % 2) * 156, y - math.floor((i - 1) / 2) * ROW_BUTTON)
        b:SetText(a[1])
        b:SetScript("OnClick", a[2])
    end
    return math.ceil(#list / 2) * ROW_BUTTON
end

-- Une section : son titre, ses réglages dans l'ordre de la liste, puis ses boutons. Rend le y suivant.
function Panel:Section(parent, sec, y)
    local x = COL_X[sec.col]
    local head = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    head:SetPoint("TOPLEFT", x, y)
    head:SetText(sec.title)
    y = y - 24
    for _, e in ipairs(LL.Options.LIST) do
        if e.section == sec.id then
            local build = (e.kind == "bool") and self.Check or self.Slider
            local ctl, h = build(self, parent, e, x, y)
            self.controls[#self.controls + 1] = ctl
            y = y - h
        end
    end
    if ACTIONS[sec.id] then y = y - 4 - self:Buttons(parent, ACTIONS[sec.id], x, y) end
    return y - GAP
end

function Panel:Build(f)
    self.controls = {}
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["Lignes telluriques / Convergences élémentaires"])
    local sub = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L["Réglages communs à tous les personnages du compte."])
    local ys = { TOP_Y, TOP_Y }
    for _, sec in ipairs(SECTIONS) do ys[sec.col] = self:Section(f, sec, ys[sec.col]) end

    local reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reset:SetSize(260, 22)
    reset:SetPoint("BOTTOMLEFT", 16, 40)
    reset:SetText(L["Rétablir les réglages par défaut"])
    reset:SetScript("OnClick", function() StaticPopup_Show("LEYLINES_RESET_OPTIONS") end)
    local foot = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 16, 16)
    foot:SetText(L["Raccourcis clavier : Échap → Options → Raccourcis. Toutes les commandes : /ley help."])
end

function Panel:Refresh()
    if not self.controls then return end
    self.loading = true
    for _, c in ipairs(self.controls) do c:Load() end
    self.loading = false
end

-- Au PLAYER_LOGIN : `Settings` passe par le délégué sûr de Blizzard (SettingsInbound) et rend la
-- catégorie tout de suite. Sans l'API (autre client), la page n'existe pas et `/ley options` le dit.
function Panel:Register()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local f = CreateFrame("Frame")
    f:Hide()
    f:SetScript("OnShow", function(frame)
        if not Panel.controls then Panel:Build(frame) end
        Panel:Refresh()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(f, L["Lignes telluriques / Convergences élémentaires"])
    Settings.RegisterAddOnCategory(category)
    LL.Options.category = category
    LL.Options.onChange = function() if f:IsShown() then Panel:Refresh() end end
    self.frame = f
end

StaticPopupDialogs["LEYLINES_RESET_OPTIONS"] = {
    text         = L["Remettre les réglages de l'addon par défaut ? Tes positions ne sont pas touchées."],
    button1      = YES,
    button2      = NO,
    OnAccept     = function() LL.Options:ResetDefaults() end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() Panel:Register() end)
