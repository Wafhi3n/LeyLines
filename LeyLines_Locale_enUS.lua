-- LeyLines_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS LeyLines_Locale.lua (qui crée LL.L). Sur un client non anglais : early-return.
--
-- Les phrases qui nomment l'objet le prennent en %s (Nodes:Word) : « ley line » pour l'Alliance,
-- « elemental convergence » pour la Horde. D'où aucun article devant ce %s en anglais — « a ley
-- line » deviendrait « a elemental convergence ».

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "enUS" and locale ~= "enGB" then return end

local en = {
    -- Noms. « Elemental Convergence » est le nom relevé sur le client (base du compte #4).
    ["Ligne tellurique"]                = "Ley Line",
    ["Convergence élémentaire"]         = "Elemental Convergence",
    ["ligne tellurique"]                = "ley line",
    ["convergence élémentaire"]         = "elemental convergence",
    ["ligne(s) tellurique(s)"]          = "ley line(s)",
    ["convergence(s) élémentaire(s)"]   = "elemental convergence(s)",
    ["lignes telluriques"]              = "ley lines",
    ["convergences élémentaires"]       = "elemental convergences",
    ["Lignes telluriques / Convergences élémentaires"] = "Ley Line / Elemental Convergence Tracker",

    -- Sources
    ["vignette du client"] = "client vignette",
    ["sort"]               = "spell",
    ["relevé manuel"]      = "manual reading",
    ["infobulle"]          = "tooltip",
    ["inconnue"]           = "unknown",
    ["activé"]             = "on",
    ["désactivé"]          = "off",

    -- État et commandes
    ["v%s chargée. /ley pour l'état, /ley help pour le reste."] =
        "v%s loaded. /ley for status, /ley help for the rest.",
    ["v%s — %s %s ici, %s au total."]       = "v%s — %s %s here, %s in total.",
    ["La plus proche : %s à %s yd."]        = "Nearest: %s at %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minimap %s — map %s — tracker %s — auto capture %s.",
    ["%s %s dans %s :"]                     = "%s %s in %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, contribute, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."] =
        "Commands: /ley (status), add, del, list, clean, clear, export, import, contribute, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <text>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la %s et fais /ley add (ou le raccourci clavier)."] =
        "How it works: stand ON the %s, then type /ley add (or use the keybind).",

    -- Capture
    ["Nouvelle %s enregistrée dans %s (%s ici)."] = "New %s recorded in %s (%s here).",
    ["%s déjà connue — position confirmée (%s relevés)."] =
        "%s already known — position confirmed (%s readings).",
    ["%s effacée."]                         = "%s erased.",
    ["%s %s effacée(s)."]                   = "%s %s erased.",
    ["Effacer toutes les %s connues dans %s ?"] = "Erase all known %s in %s?",
    ["Aucune %s connue dans cette zone."]   = "No %s known in this zone.",
    ["Aucune %s à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "No %s within 60 yd — stand on it to erase it.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Position unavailable here — the client gives no coordinates.",
    ["Capture automatique : %s."] = "Automatic capture: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Tooltip capture: %s (rough reading, taken at your position).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s tooltip reading(s) erased.",
    ["Noms reconnus : %s."]       = "Recognised names: %s.",
    ["Nom reconnu ajouté : %s."]  = "Recognised name added: %s.",
    ["Lance maintenant ton sort de %s : le prochain sort réussi sera retenu."] =
        "Cast your %s spell now: the next successful cast will be remembered.",
    ["Apprentissage abandonné : aucun sort lancé."] = "Learning cancelled: no spell was cast.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une %s."] =
        "Spell remembered: %s (%s). From now on, only a cast followed by a LONG buff records the %s.",
    ["Buff court : pas de %s ici, rien n'a été enregistré."] =
        "Short buff: no %s here, nothing was recorded.",

    -- Affichage
    ["Affichage sur la minicarte : %s."]      = "Minimap display: %s.",
    ["Affichage sur la carte du monde : %s."] = "World map display: %s.",
    ["Suivi à l'écran : %s."]                 = "On-screen tracker: %s.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Minimap scale: %s (radius read: %s yd).",
    ["%s yd"]                  = "%s yd",
    ["%s yd — source : %s"]    = "%s yd — source: %s",
    ["Source : %s — %s relevé(s)"] = "Source: %s — %s reading(s)",
    ["Clic : poser un point de route."]        = "Click: drop a map pin.",
    ["Clic gauche : poser un point de route."] = "Left-click: drop a map pin.",
    ["Clic droit : masquer. Glisser : déplacer."] = "Right-click: hide. Drag: move.",
    ["%s %s connue(s) au total."] = "%s %s known in total.",
    ["Clic gauche : partager tes captures pour la liste commune."] =
        "Left-click: share your spots for the shared list.",
    ["Clic droit : afficher ou masquer le suivi."] = "Right-click: show or hide the tracker.",
    ["Point de route posé sur %s."]            = "Map pin set on %s.",
    ["Cette zone n'accepte pas de point de route."] = "This zone does not accept a map pin.",

    ["%s : buff à %s min de la fin — la plus proche à %s yd."] =
        "%s: buff ends in %s min — nearest one %s yd away.",
    ["%s : buff à %s min de la fin — aucune connue dans cette zone."] =
        "%s: buff ends in %s min — none known in this zone.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Buff reminder: at %s min left (0 = off).",

    -- Partage
    ["Partage des positions"] = "Position sharing",
    ["Aucune position à exporter."] = "No position to export.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Copy this text (Ctrl+C) and share it.",
    ["Colle ce code dans un ticket : github.com/Wafhi3n/LeyLines"] =
        "Paste this code in an issue: github.com/Wafhi3n/LeyLines",
    ["Rien à partager : seules tes captures confirmées par le jeu (sort lancé sur place) vont dans la liste commune."] =
        "Nothing to share: only your captures confirmed by the game (spell cast on the spot) go into the shared list.",
    ["Colle un code reçu, puis clique sur Importer."] = "Paste a code you were given, then click Import.",
    ["Importer"] = "Import",
    ["Fermer"]   = "Close",
    ["Code invalide : ce n'est pas un export de Ley Lines."] = "That code isn't a Ley Lines export.",
    ["%s position(s) importée(s), %s déjà connue(s)."] = "%s position(s) imported, %s already known.",
    ["Ancien code, qui ne dit pas à quelle faction appartiennent ses points : demande un nouvel export."] =
        "Old code that doesn't say which faction its spots belong to: ask for a new export.",
    ["%s position(s) sans faction ignorée(s) : demande un nouvel export."] =
        "%s position(s) with no faction skipped: ask for a new export.",
    ["%s position(s) ajoutée(s) depuis les données livrées."] =
        "%s position(s) added from the shipped data.",
    ["restauré"] = "restored",
    ["%s position(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s position(s) restored from the internal backup.",
    ["import"]              = "import",
    ["livré avec l'addon"] = "shipped with the addon",

    -- Raccourcis clavier
    ["Enregistrer une %s ici"]      = "Record the %s here",
    ["Suivre la %s la plus proche"] = "Track the nearest %s",
}

for k, v in pairs(en) do LL.L[k] = v end
