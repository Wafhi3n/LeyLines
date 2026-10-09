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
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, contribute, bug, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, waypoint, name <texte>, scale <n>, probe."] =
        "Commands: /ley (status), add, del, list, clean, clear, export, import, contribute, bug, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, waypoint, name <text>, scale <n>, probe.",
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
    ["Points seulement sur un personnage Skyborne : %s."] = "Spots on Skyborne characters only: %s.",
    ["Points masqués sur ce personnage (pas Skyborne) : /ley skyborne pour les afficher partout."] =
        "Spots hidden on this character (not Skyborne): /ley skyborne to show them everywhere.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Minimap scale: %s (radius read: %s yd).",
    ["%s yd"]                  = "%s yd",
    ["%s yd — source : %s"]    = "%s yd — source: %s",
    ["Source : %s — %s relevé(s)"] = "Source: %s — %s reading(s)",
    ["Clic droit : effacer ce point."]         = "Right-click: erase this spot.",
    ["Effacer %s (%s) ?"]                      = "Erase %s (%s)?",
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
    ["Point de route posé par le rappel de buff : %s."] = "Map pin from the buff reminder: %s.",

    -- Options panel (docs/specs/panneau-options.md)
    ["Affichage"]      = "Display",
    ["Capture"]        = "Capture",
    ["Rappel de buff"] = "Buff reminder",
    ["Partage"]        = "Sharing",
    ["Réglages communs à tous les personnages du compte."] = "These settings apply to every character on your account.",
    ["Points sur la minicarte"]               = "Spots on the minimap",
    ["Les points connus sur la minicarte."]   = "The spots you know, on the minimap.",
    ["Garder au bord les points hors de portée"] = "Keep out-of-range spots on the edge",
    ["Un point trop loin pour la minicarte reste à son bord, atténué, pour garder le cap."] =
        "A spot too far for the minimap stays on its edge, dimmed, so you still know which way to go.",
    ["Taille des points de la minicarte"]     = "Spot size on the minimap",
    ["En pixels."]                            = "In pixels.",
    ["Points sur la carte du monde"]          = "Spots on the world map",
    ["Les points connus sur la grande carte."] = "The spots you know, on the world map.",
    ["Taille des points de la carte du monde"] = "Spot size on the world map",
    ["Bandeau de la plus proche"]             = "Nearest-spot tracker",
    ["La distance et une flèche vers le point le plus proche. Un clic dessus pose un point de route."] =
        "Distance and an arrow to the nearest spot. Click it to drop a map pin.",
    ["Seulement sur mes personnages Skyborne"] = "Only on my Skyborne characters",
    ["Les personnages d'une autre race ne voient plus les points."] =
        "Characters of other races no longer show the spots.",
    ["Échelle de la minicarte (avancé)"]      = "Minimap scale (advanced)",
    ["À changer seulement si les points de la minicarte tombent à côté de leur place."] =
        "Only change this if minimap spots land away from where they belong.",
    ["Capture automatique"]                   = "Automatic capture",
    ["Retient un point quand le jeu confirme ton absorption (buff de 15 min)."] =
        "Saves a spot when the game confirms you absorbed it (15 minute buff).",
    ["Capture par infobulle (approximative)"] = "Tooltip capture (rough)",
    ["Retient ta position quand tu survoles l'objet : jusqu'à 40 yd d'écart."] =
        "Saves your own position when you hover the object: up to 40 yd off.",
    ["Prévenir à N min de la fin du buff"]    = "Warn N min before the buff ends",
    ["0 = jamais. Le buff dure 15 min."]      = "0 = never. The buff lasts 15 minutes.",
    ["Poser aussi un point de route"]         = "Also drop a map pin",
    ["Le rappel pose le point de route du jeu sur le point le plus proche, à la place du tien."] =
        "The reminder drops the game's map pin on the nearest spot, replacing yours.",
    ["Signal des positions à partager"]       = "Reminder for spots to share",
    ["Une icône près de la minicarte quand tu trouves un point que la liste commune n'a pas."] =
        "An icon near the minimap when you find a spot the shared list doesn't have.",
    ["Replacer le bandeau"]                   = "Reset tracker position",
    ["Apprendre mon sort"]                    = "Learn my spell",
    ["Effacer les relevés d'infobulle"]       = "Erase tooltip readings",
    ["Contribuer"]                            = "Contribute",
    ["Exporter"]                              = "Export",
    ["Contributeurs"]                         = "Contributors",
    ["Rétablir les réglages par défaut"]      = "Restore default settings",
    ["Remettre les réglages de l'addon par défaut ? Tes positions ne sont pas touchées."] =
        "Restore the addon's default settings? Your spots are kept.",
    ["Réglages remis par défaut."]            = "Default settings restored.",
    ["Raccourcis clavier : Échap > Options > Raccourcis. Toutes les commandes : /ley help."] =
        "Key bindings: Esc > Options > Keybindings. All commands: /ley help.",
    ["Options : /ley options, ou Échap > Options > AddOns."] =
        "Options: /ley options, or Esc > Options > AddOns.",
    ["Le panneau d'options n'est pas disponible sur ce client."] =
        "The options panel isn't available on this client.",
    ["Les options s'ouvrent hors combat."]   = "The options open out of combat.",

    -- Partage
    ["Partage des positions"] = "Position sharing",
    ["Aucune position à exporter."] = "No position to export.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Copy this text (Ctrl+C) and share it.",
    ["Colle ce code dans un ticket : github.com/Wafhi3n/LeyLines"] =
        "Paste this code in an issue: github.com/Wafhi3n/LeyLines",
    ["Rien à partager : seules tes captures confirmées par le jeu (sort lancé sur place) vont dans la liste commune."] =
        "Nothing to share: only your captures confirmed by the game (spell cast on the spot) go into the shared list.",
    ["Rien de neuf depuis ta dernière contribution. /ley contribute all renvoie tout ce que tu as confirmé."] =
        "Nothing new since your last contribution. /ley contribute all sends everything you've confirmed.",
    ["Ouvre ce lien dans ton navigateur (Ctrl+C) : le formulaire sera déjà rempli."] =
        "Open this link in your browser (Ctrl+C): the form comes pre-filled.",
    ["Trop long pour un seul lien : ouvre celui-ci, puis colle le code (bouton Code)."] =
        "Too long for one link: open this one, then paste the code (Code button).",
    ["Code"] = "Code",
    ["Lien"] = "Link",
    ["Position absente de la liste commune : /ley contribute pour la partager avec tous."] =
        "This spot isn't in the shared list yet: /ley contribute to share it with everyone.",
    ["Signal des positions à partager : %s."] = "Reminder for spots to share: %s.",
    ["%s position(s) à partager, absente(s) de la liste commune."] =
        "%s spot(s) to share, missing from the shared list.",
    ["Position absente de la liste commune : clique sur l'icône apparue en haut de la minicarte pour la partager avec tous."] =
        "This spot isn't in the shared list yet: click the new icon at the top of the minimap to share it with everyone.",
    ["Clic : le lien du ticket, déjà rempli."] = "Click: the issue link, already filled in.",
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
    ["%s position(s) retirée(s) de la liste commune."] =
        "%s position(s) removed from the shared list.",

    -- Contributors (docs/specs/remerciements.md)
    ["%s et %s autre(s)"] =
        "%s and %s more",
    ["Merci à %s pour ces positions. /ley credits : tous les contributeurs."] =
        "Thanks to %s for these spots. /ley credits lists everyone who shared.",
    ["Aucun contributeur pour l'instant : /ley contribute pour être le premier."] =
        "No contributors yet. /ley contribute to be the first.",
    ["%s contributeur(s) ont partagé leurs positions :"] =
        "%s contributor(s) shared their spots:",
    ["Toi aussi : /ley contribute."] =
        "You too: /ley contribute.",
    ["Une fois versée, ta contribution t'inscrit parmi les contributeurs (/ley credits)."] =
        "Once it's in, your name joins the contributors (/ley credits).",

    ["restauré"] = "restored",
    ["%s position(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s position(s) restored from the internal backup.",
    ["import"]              = "import",
    ["livré avec l'addon"] = "shipped with the addon",

    -- Raccourcis clavier
    ["Enregistrer une %s ici"]      = "Record the %s here",
    ["Suivre la %s la plus proche"] = "Track the nearest %s",

    -- Signaler un bug ou une idée (LeyLines_Report.lua, 2026-10-07)
    ["Signaler un bug ou proposer une idée"] = "Report a bug or suggest an idea",
    ["Bug"] = "Bug",
    ["Idée"] = "Idea",
    ["Sans compte GitHub"] = "No GitHub account",
    ["Lien copié : colle-le (Ctrl+V) dans ton navigateur."] = "Link copied: paste it (Ctrl+V) into your browser.",
    ["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."] = "Copy this link (Ctrl+C) and open it in your browser: the form comes up with the version already filled in.",
    ["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."] = "No GitHub account? Copy this link (Ctrl+C) and leave a comment on the CurseForge page.",
    ["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."] = "A bug, or an idea for the addon? Pick below: the addon gives you the link to the form, already filled in.",
    ["Maj+clic : signaler un bug ou proposer une idée."] = "Shift-click: report a bug or suggest an idea.",
}

for k, v in pairs(en) do LL.L[k] = v end
