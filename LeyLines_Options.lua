-- LeyLines_Options.lua — la liste des réglages (docs/specs/panneau-options.md, O2).
--
-- Une entrée par réglage que le joueur peut vouloir changer. Les commandes `/ley` de réglage et le
-- panneau d'options (LeyLines_OptionsPanel.lua) lisent la même liste et passent par le MÊME setter :
-- ce qu'on règle d'un côté se voit de l'autre. Le setter ne parle pas ; seule la commande écrit dans
-- le chat (un curseur du panneau n'y laisse pas une ligne par cran).
--
-- Champs : key (chemin dans LeyLinesDB, « minimap.show »), kind (bool | num), section, label, tip,
-- cmd (noms de la commande, alias compris), msg (la ligne de chat de la commande), min / max / step
-- (num ; panelMax borne le curseur sans borner la commande), after (effet d'un changement, panneau
-- comme commande), tell (ce que la commande dit après sa ligne), say (remplace msg), get / set / def
-- (un réglage qui n'est pas une simple clé : `auto` en tient deux).
local _, LL = ...
local L = LL.L

local Options = {}
LL.Options = Options

local function Refresh() LL:Refresh() end
local function Hidden() LL:WarnHidden() end   -- les quatre bascules d'affichage le rappellent
local function Pending()   -- coupé, le signal se tait, mais le nombre reste calculé : redonné ici
    local n = LL.Signal:Count()
    if n > 0 then LL:Printf(L["%s position(s) à partager, absente(s) de la liste commune."], n) end
end

Options.LIST = {
    { key = "minimap.show", kind = "bool", section = "display", cmd = { "pins", "minimap" },
      label = L["Points sur la minicarte"], tip = L["Les points connus sur la minicarte."],
      msg = L["Affichage sur la minicarte : %s."], after = Refresh, tell = Hidden },
    { key = "minimap.edge", kind = "bool", section = "display",
      label = L["Garder au bord les points hors de portée"],
      tip = L["Un point trop loin pour la minicarte reste à son bord, atténué, pour garder le cap."],
      after = Refresh },
    { key = "minimap.size", kind = "num", section = "display", min = 10, max = 32, step = 1,
      label = L["Taille des points de la minicarte"], tip = L["En pixels."], after = Refresh },
    { key = "worldmap.show", kind = "bool", section = "display", cmd = { "map", "carte" },
      label = L["Points sur la carte du monde"], tip = L["Les points connus sur la grande carte."],
      msg = L["Affichage sur la carte du monde : %s."], after = Refresh, tell = Hidden },
    { key = "worldmap.size", kind = "num", section = "display", min = 10, max = 32, step = 1,
      label = L["Taille des points de la carte du monde"], tip = L["En pixels."], after = Refresh },
    { key = "hud.show", kind = "bool", section = "display", cmd = { "hud" },
      label = L["Bandeau de la plus proche"],
      tip = L["La distance et une flèche vers le point le plus proche. Un clic dessus pose un point de route."],
      msg = L["Suivi à l'écran : %s."], after = function() LL.HUD:Apply() end, tell = Hidden },
    -- Demandé sur CurseForge le 2026-10-04 : la base est au compte, donc un personnage d'une autre
    -- race voyait des points qu'il ne peut pas absorber.
    { key = "skyborneOnly", kind = "bool", section = "display", cmd = { "skyborne", "skyborn" },
      label = L["Seulement sur mes personnages Skyborne"],
      tip = L["Les personnages d'une autre race ne voient plus les points."],
      msg = L["Points seulement sur un personnage Skyborne : %s."], after = Refresh, tell = Hidden },
    { key = "minimap.scale", kind = "num", section = "display", min = 0.25, max = 4, step = 0.05,
      cmd = { "scale" }, label = L["Échelle de la minicarte (avancé)"],
      tip = L["À changer seulement si les points de la minicarte tombent à côté de leur place."],
      say = function(v)
          LL:Printf(L["Échelle de la minicarte : %s (rayon lu : %s yd)."], v,
              math.floor(LL.Geo:MinimapRadius() + 0.5))
      end },

    { key = "capture.auto", kind = "bool", section = "capture", cmd = { "auto" },
      label = L["Capture automatique"],
      tip = L["Retient un point quand le jeu confirme ton absorption (buff de 15 min)."],
      msg = L["Capture automatique : %s."],
      get = function() return LL.Capture:AutoEnabled() end,
      set = function(v) LL.db.capture.vignette, LL.db.capture.spell = v, v end,
      def = function() return LL.DEFAULTS.capture.spell end },
    -- Son propre interrupteur : elle relève la position du JOUEUR qui VISE, donc des points
    -- approximatifs. On ne la rallume pas par mégarde avec `auto`.
    { key = "capture.tooltip", kind = "bool", section = "capture", cmd = { "tooltip", "infobulle" },
      label = L["Capture par infobulle (approximative)"],
      tip = L["Retient ta position quand tu survoles l'objet : jusqu'à 40 yd d'écart."],
      msg = L["Capture par infobulle : %s (relevé approximatif, à ta position)."] },

    -- Un nouveau seuil doit pouvoir se déclencher tout de suite : `warned` se réarme.
    { key = "warnMinutes", kind = "num", section = "warn", min = 0, max = 60, panelMax = 14, step = 1,
      cmd = { "warn", "rappel" }, label = L["Prévenir à N min de la fin du buff"],
      tip = L["0 = jamais. Le buff dure 15 min."],
      msg = L["Rappel de buff : à %s min restantes (0 = désactivé)."],
      after = function() LL.HUD.warned = false end },
    { key = "autoWaypoint", kind = "bool", section = "warn", cmd = { "waypoint", "route" },
      label = L["Poser aussi un point de route"],
      tip = L["Le rappel pose le point de route du jeu sur le point le plus proche, à la place du tien."],
      msg = L["Point de route posé par le rappel de buff : %s."] },

    { key = "signal", kind = "bool", section = "share", cmd = { "signal" },
      label = L["Signal des positions à partager"],
      tip = L["Une icône près de la minicarte quand tu trouves un point que la liste commune n'a pas."],
      msg = L["Signal des positions à partager : %s."], after = Refresh, tell = Pending },
}

-- « minimap.show » → LeyLinesDB.minimap, "show".
local function Slot(root, path)
    local head, rest = path:match("^([^.]+)%.(.+)$")
    if head then return root[head], rest end
    return root, path
end

function Options:Get(e)
    if e.get then return e.get() end
    local t, k = Slot(LL.db, e.key)
    return t[k]
end

function Options:Default(e)
    if e.def then return e.def() end
    local t, k = Slot(LL.DEFAULTS, e.key)
    return t[k]
end

function Options:Set(e, value)
    if e.set then
        e.set(value)
    else
        local t, k = Slot(LL.db, e.key)
        t[k] = value
    end
    if e.after then e.after() end
    if self.onChange then self.onChange() end
end

local function Switch(current, rest)   -- `on` / `off`, sinon bascule
    local arg = string.lower(rest or "")
    if arg == "on" then return true elseif arg == "off" then return false end
    return not current
end

-- La commande : change (si l'argument le permet), puis le dit. Un nombre hors bornes ne change
-- rien, et la ligne redonne la valeur en place.
function Options:Command(e, rest)
    if e.kind == "bool" then
        self:Set(e, Switch(self:Get(e), rest))
    else
        local n = tonumber(rest)
        if n and n >= e.min and n <= e.max then self:Set(e, n) end
    end
    local v = self:Get(e)
    if e.say then e.say(v) else LL:Printf(e.msg, e.kind == "bool" and LL:OnOff(v) or v) end
    if e.tell then e.tell() end
end

Options.BY_KEY = {}
for _, e in ipairs(Options.LIST) do
    Options.BY_KEY[e.key] = e
    for _, name in ipairs(e.cmd or {}) do
        LL.CMD[name] = function(rest) Options:Command(e, rest) end
    end
end

-- Partagé par `/ley hud` et le clic droit du compartiment d'addons (LeyLines_Compartment.lua).
function LL:ToggleHUD()
    Options:Command(Options.BY_KEY["hud.show"], "")
end

function Options:ResetHUDPosition()
    local d, db = LL.DEFAULTS.hud, LL.db.hud
    db.point, db.x, db.y = d.point, d.x, d.y
    LL.HUD:Apply()
end

-- O4 : les réglages de la liste et la place du bandeau. Jamais les positions, les contributions,
-- le palier de la liste livrée ni la sauvegarde interne : ils ne sont pas dans la liste.
function Options:ResetDefaults()
    for _, e in ipairs(self.LIST) do
        local d = self:Default(e)
        if d ~= nil then self:Set(e, d) end
    end
    self:ResetHUDPosition()
    LL:Print(L["Réglages remis par défaut."])
end

-- O5 : `/ley options` ouvre la page (enregistrée par LeyLines_OptionsPanel.lua au PLAYER_LOGIN).
function Options:Open()
    if self.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.category:GetID())
    else
        LL:Print(L["Le panneau d'options n'est pas disponible sur ce client."])
    end
end
LL.CMD.options = function() Options:Open() end
LL.CMD.config  = LL.CMD.options

-- `/ley` et `/ley help` rappellent que la page existe, sur une ligne À PART : la ligne d'aide liste
-- les commandes et change à chaque commande ajoutée, d'une branche à l'autre.
local function WithHint(fn)
    return function(rest)
        fn(rest)
        LL:Print(L["Options : /ley options, ou Échap → Options → AddOns."])
    end
end
LL.CMD.status = WithHint(LL.CMD.status)
LL.CMD.help   = WithHint(LL.CMD.help)
