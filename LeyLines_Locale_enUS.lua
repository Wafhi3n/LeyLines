-- LeyLines_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS LeyLines_Locale.lua (qui crée LL.L). Sur un client non anglais : early-return.

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "enUS" and locale ~= "enGB" then return end

local en = {
    -- Noms
    ["Ligne tellurique"]  = "Ley Line",
    ["Vergence élémentaire"] = "Elemental Vergence",
    ["Lignes telluriques"] = "Ley Lines",

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
    ["v%s — %s ligne(s) ici, %s au total."] = "v%s — %s line(s) here, %s in total.",
    ["La plus proche : %s à %s yd."]        = "Nearest: %s at %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minimap %s — map %s — tracker %s — auto capture %s.",
    ["%s ligne(s) tellurique(s) dans %s :"] = "%s ley line(s) in %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."] =
        "Commands: /ley (status), add, del, list, clean, clear, export, import, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <text>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la ligne tellurique et fais /ley add (ou le raccourci clavier)."] =
        "How it works: stand ON the ley line, then type /ley add (or use the keybind).",

    -- Capture
    ["Nouvelle ligne tellurique enregistrée dans %s (%s ici)."] =
        "New ley line recorded in %s (%s here).",
    ["Ligne tellurique déjà connue — position confirmée (%s relevés)."] =
        "Ley line already known — position confirmed (%s readings).",
    ["Ligne tellurique effacée : %s."] = "Ley line erased: %s.",
    ["%s ligne(s) tellurique(s) effacée(s)."] = "%s ley line(s) erased.",
    ["Effacer toutes les lignes telluriques connues dans %s ?"] =
        "Erase every known ley line in %s?",
    ["Aucune ligne tellurique connue dans cette zone."] = "No ley line known in this zone.",
    ["Aucune ligne tellurique à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "No ley line within 60 yd — stand on it to erase it.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Position unavailable here — the client gives no coordinates.",
    ["Capture automatique : %s."] = "Automatic capture: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Tooltip capture: %s (rough reading, taken at your position).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s tooltip reading(s) erased.",
    ["Noms reconnus : %s."]       = "Recognised names: %s.",
    ["Nom reconnu ajouté : %s."]  = "Recognised name added: %s.",
    ["Lance maintenant ton sort de ligne tellurique : le prochain sort réussi sera retenu."] =
        "Cast your ley line spell now: the next successful cast will be remembered.",
    ["Apprentissage abandonné : aucun sort lancé."] = "Learning cancelled: no spell was cast.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une faille."] =
        "Spell remembered: %s (%s). From now on, only a cast followed by a LONG buff marks a ley line.",
    ["Buff court : pas de faille ici, rien n'a été enregistré."] =
        "Short buff: no ley line here, nothing was recorded.",

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
    ["Point de route posé sur %s."]            = "Map pin set on %s.",
    ["Cette zone n'accepte pas de point de route."] = "This zone does not accept a map pin.",

    ["Buff de faille : %s min restantes — la plus proche à %s yd."] =
        "Ley line buff: %s min left — nearest one %s yd away.",
    ["Buff de faille : %s min restantes — aucune faille connue dans cette zone."] =
        "Ley line buff: %s min left — no known ley line in this zone.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Buff reminder: at %s min left (0 = off).",

    -- Partage
    ["Partage des lignes telluriques"] = "Ley line sharing",
    ["Aucune ligne tellurique à exporter."] = "No ley line to export.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Copy this text (Ctrl+C) and share it.",
    ["Colle un code reçu, puis clique sur Importer."] = "Paste a code you were given, then click Import.",
    ["Importer"] = "Import",
    ["Fermer"]   = "Close",
    ["Code invalide : ce n'est pas un export de Ley Lines."] = "That code isn't a Ley Lines export.",
    ["%s ligne(s) importée(s), %s déjà connue(s)."] = "%s ley line(s) imported, %s already known.",
    ["%s ligne(s) tellurique(s) ajoutée(s) depuis les données livrées."] =
        "%s ley line(s) added from the shipped data.",
    ["restauré"] = "restored",
    ["%s ligne(s) tellurique(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s ley line(s) restored from the internal backup.",
    ["import"]              = "import",
    ["livré avec l'addon"] = "shipped with the addon",

    -- Raccourcis clavier
    ["Enregistrer une ligne tellurique ici"]     = "Record a ley line here",
    ["Suivre la ligne tellurique la plus proche"] = "Track the nearest ley line",
}

for k, v in pairs(en) do LL.L[k] = v end
