-- LeyLines_Locale_deDE.lua — overlay ALLEMAND. Clé FR → texte DE.
-- Chargé APRÈS LeyLines_Locale.lua. Sur un client non allemand : early-return.
--
-- Les phrases qui nomment l'objet le prennent en %s (Nodes:Word). Les deux noms sont FÉMININS
-- (die Ley-Linie, die Elementarkonvergenz) : articles et adjectifs s'accordent dans les deux cas.

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "deDE" then return end

local de = {
    -- Namen. Nom client DE de la tornade non relevé : traduction à confirmer en jeu.
    ["Ligne tellurique"]                = "Ley-Linie",
    ["Convergence élémentaire"]         = "Elementarkonvergenz",
    ["ligne tellurique"]                = "Ley-Linie",
    ["convergence élémentaire"]         = "Elementarkonvergenz",
    ["ligne(s) tellurique(s)"]          = "Ley-Linie(n)",
    ["convergence(s) élémentaire(s)"]   = "Elementarkonvergenz(en)",
    ["lignes telluriques"]              = "Ley-Linien",
    ["convergences élémentaires"]       = "Elementarkonvergenzen",
    ["Lignes telluriques / Convergences élémentaires"] = "Ley-Linien / Elementarkonvergenzen",

    -- Quellen
    ["vignette du client"] = "Client-Vignette",
    ["sort"]               = "Zauber",
    ["relevé manuel"]      = "manuelle Messung",
    ["infobulle"]          = "Tooltip",
    ["inconnue"]           = "unbekannt",
    ["activé"]             = "an",
    ["désactivé"]          = "aus",

    -- Status und Befehle
    ["v%s chargée. /ley pour l'état, /ley help pour le reste."] =
        "v%s geladen. /ley für den Status, /ley help für den Rest.",
    ["v%s — %s %s ici, %s au total."]       = "v%s — %s %s hier, %s insgesamt.",
    ["La plus proche : %s à %s yd."]        = "Nächste: %s in %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minikarte %s — Karte %s — Verfolgung %s — Auto-Erfassung %s.",
    ["%s %s dans %s :"]                     = "%s %s in %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, contribute, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, waypoint, name <texte>, scale <n>, probe."] =
        "Befehle: /ley (Status), add, del, list, clean, clear, export, import, contribute, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <Min>, waypoint, name <Text>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la %s et fais /ley add (ou le raccourci clavier)."] =
        "So geht's: Stell dich AUF die %s und tippe /ley add (oder nutze die Tastenbelegung).",

    -- Erfassung
    ["Nouvelle %s enregistrée dans %s (%s ici)."] = "Neue %s in %s aufgezeichnet (%s hier).",
    ["%s déjà connue — position confirmée (%s relevés)."] =
        "%s bereits bekannt — Position bestätigt (%s Messungen).",
    ["%s effacée."]                         = "%s gelöscht.",
    ["%s %s effacée(s)."]                   = "%s %s gelöscht.",
    ["Effacer toutes les %s connues dans %s ?"] = "Alle bekannten %s in %s löschen?",
    ["Aucune %s connue dans cette zone."]   = "In dieser Zone ist keine %s bekannt.",
    ["Aucune %s à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "Keine %s innerhalb von 60 yd — stell dich darauf, um sie zu löschen.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Position hier nicht verfügbar — der Client liefert keine Koordinaten.",
    ["Capture automatique : %s."] = "Automatische Erfassung: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Tooltip-Erfassung: %s (ungefähre Messung, an deiner Position).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s Tooltip-Messung(en) gelöscht.",
    ["Noms reconnus : %s."]       = "Erkannte Namen: %s.",
    ["Nom reconnu ajouté : %s."]  = "Erkannter Name hinzugefügt: %s.",
    ["Lance maintenant ton sort de %s : le prochain sort réussi sera retenu."] =
        "Wirke jetzt deinen Zauber für die %s: Der nächste erfolgreiche Zauber wird gemerkt.",
    ["Apprentissage abandonné : aucun sort lancé."] =
        "Lernen abgebrochen: kein Zauber gewirkt.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une %s."] =
        "Zauber gemerkt: %s (%s). Ab jetzt markiert nur ein Zauber mit LANGEM Buff eine %s.",
    ["Buff court : pas de %s ici, rien n'a été enregistré."] =
        "Kurzer Buff: hier ist keine %s, nichts wurde aufgezeichnet.",

    -- Anzeige
    ["Affichage sur la minicarte : %s."]      = "Minikartenanzeige: %s.",
    ["Affichage sur la carte du monde : %s."] = "Weltkartenanzeige: %s.",
    ["Suivi à l'écran : %s."]                 = "Bildschirmverfolgung: %s.",
    ["Points seulement sur un personnage Skyborne : %s."] = "Punkte nur bei Skyborne-Charakteren: %s.",
    ["Points masqués sur ce personnage (pas Skyborne) : /ley skyborne pour les afficher partout."] =
        "Punkte bei diesem Charakter ausgeblendet (kein Skyborne): /ley skyborne zeigt sie überall.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Minikartenskalierung: %s (gelesener Radius: %s yd).",
    ["%s yd"]                      = "%s yd",
    ["%s yd — source : %s"]        = "%s yd — Quelle: %s",
    ["Source : %s — %s relevé(s)"] = "Quelle: %s — %s Messung(en)",
    ["Clic droit : effacer ce point."]         = "Rechtsklick: diesen Punkt löschen.",
    ["Effacer %s (%s) ?"]                      = "%s (%s) löschen?",
    ["Clic gauche : poser un point de route."] = "Linksklick: Wegpunkt setzen.",
    ["Clic droit : masquer. Glisser : déplacer."] = "Rechtsklick: ausblenden. Ziehen: verschieben.",
    ["%s %s connue(s) au total."] = "%s %s insgesamt bekannt.",
    ["Clic gauche : partager tes captures pour la liste commune."] =
        "Linksklick: deine Punkte für die gemeinsame Liste teilen.",
    ["Clic droit : afficher ou masquer le suivi."] = "Rechtsklick: Verfolgung ein- oder ausblenden.",
    ["Point de route posé sur %s."]            = "Wegpunkt gesetzt auf %s.",
    ["Cette zone n'accepte pas de point de route."] = "Diese Zone erlaubt keinen Wegpunkt.",

    ["%s : buff à %s min de la fin — la plus proche à %s yd."] =
        "%s: Buff endet in %s Min — die nächste ist %s yd entfernt.",
    ["%s : buff à %s min de la fin — aucune connue dans cette zone."] =
        "%s: Buff endet in %s Min — keine bekannt in dieser Zone.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Buff-Erinnerung: bei %s Min Restzeit (0 = aus).",
    ["Point de route posé par le rappel de buff : %s."] = "Wegpunkt durch die Buff-Erinnerung: %s.",

    -- Optionsfenster (docs/specs/panneau-options.md)
    ["Affichage"]      = "Anzeige",
    ["Capture"]        = "Erfassung",
    ["Rappel de buff"] = "Buff-Erinnerung",
    ["Partage"]        = "Teilen",
    ["Réglages communs à tous les personnages du compte."] = "Diese Einstellungen gelten für alle Charaktere des Accounts.",
    ["Points sur la minicarte"]               = "Punkte auf der Minikarte",
    ["Les points connus sur la minicarte."]   = "Die bekannten Punkte auf der Minikarte.",
    ["Garder au bord les points hors de portée"] = "Punkte außer Reichweite am Rand halten",
    ["Un point trop loin pour la minicarte reste à son bord, atténué, pour garder le cap."] =
        "Ein Punkt außerhalb der Minikarte bleibt abgeschwächt am Rand, damit du die Richtung kennst.",
    ["Taille des points de la minicarte"]     = "Punktgröße auf der Minikarte",
    ["En pixels."]                            = "In Pixeln.",
    ["Points sur la carte du monde"]          = "Punkte auf der Weltkarte",
    ["Les points connus sur la grande carte."] = "Die bekannten Punkte auf der Weltkarte.",
    ["Taille des points de la carte du monde"] = "Punktgröße auf der Weltkarte",
    ["Bandeau de la plus proche"]             = "Leiste zum nächsten Punkt",
    ["La distance et une flèche vers le point le plus proche. Un clic dessus pose un point de route."] =
        "Entfernung und ein Pfeil zum nächsten Punkt. Ein Klick darauf setzt einen Wegpunkt.",
    ["Seulement sur mes personnages Skyborne"] = "Nur bei meinen Skyborne-Charakteren",
    ["Les personnages d'une autre race ne voient plus les points."] =
        "Charaktere anderer Völker zeigen die Punkte nicht mehr.",
    ["Échelle de la minicarte (avancé)"]      = "Minikartenskalierung (erweitert)",
    ["À changer seulement si les points de la minicarte tombent à côté de leur place."] =
        "Nur ändern, wenn die Punkte auf der Minikarte neben ihrer Stelle liegen.",
    ["Capture automatique"]                   = "Automatische Erfassung",
    ["Retient un point quand le jeu confirme ton absorption (buff de 15 min)."] =
        "Merkt sich einen Punkt, wenn das Spiel deine Absorption bestätigt (15-Minuten-Buff).",
    ["Capture par infobulle (approximative)"] = "Tooltip-Erfassung (ungefähr)",
    ["Retient ta position quand tu survoles l'objet : jusqu'à 40 yd d'écart."] =
        "Merkt sich deine Position beim Überfahren des Objekts: bis zu 40 yd daneben.",
    ["Prévenir à N min de la fin du buff"]    = "N Min vor Buff-Ende erinnern",
    ["0 = jamais. Le buff dure 15 min."]      = "0 = nie. Der Buff hält 15 Minuten.",
    ["Poser aussi un point de route"]         = "Auch einen Wegpunkt setzen",
    ["Le rappel pose le point de route du jeu sur le point le plus proche, à la place du tien."] =
        "Die Erinnerung setzt den Wegpunkt des Spiels auf den nächsten Punkt, anstelle deines eigenen.",
    ["Signal des positions à partager"]       = "Hinweis auf zu teilende Positionen",
    ["Une icône près de la minicarte quand tu trouves un point que la liste commune n'a pas."] =
        "Ein Symbol an der Minikarte, wenn du einen Punkt findest, der in der gemeinsamen Liste fehlt.",
    ["Replacer le bandeau"]                   = "Leiste zurücksetzen",
    ["Apprendre mon sort"]                    = "Meinen Zauber lernen",
    ["Effacer les relevés d'infobulle"]       = "Tooltip-Messungen löschen",
    ["Contribuer"]                            = "Beitragen",
    ["Exporter"]                              = "Exportieren",
    ["Contributeurs"]                         = "Mitwirkende",
    ["Rétablir les réglages par défaut"]      = "Standardeinstellungen wiederherstellen",
    ["Remettre les réglages de l'addon par défaut ? Tes positions ne sont pas touchées."] =
        "Standardeinstellungen des Addons wiederherstellen? Deine Punkte bleiben erhalten.",
    ["Réglages remis par défaut."]            = "Standardeinstellungen wiederhergestellt.",
    ["Raccourcis clavier : Échap → Options → Raccourcis. Toutes les commandes : /ley help."] =
        "Tastenbelegung: Esc → Optionen → Tastenbelegung. Alle Befehle: /ley help.",
    ["Options : /ley options, ou Échap → Options → AddOns."] =
        "Optionen: /ley options, oder Esc → Optionen → AddOns.",
    ["Le panneau d'options n'est pas disponible sur ce client."] =
        "Das Optionsfenster ist auf diesem Client nicht verfügbar.",

    -- Teilen
    ["Partage des positions"] = "Positionen teilen",
    ["Aucune position à exporter."] = "Keine Position zum Exportieren.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Kopiere diesen Text (Strg+C) und teile ihn.",
    ["Colle ce code dans un ticket : github.com/Wafhi3n/LeyLines"] =
        "Füge diesen Code in ein Issue ein: github.com/Wafhi3n/LeyLines",
    ["Rien à partager : seules tes captures confirmées par le jeu (sort lancé sur place) vont dans la liste commune."] =
        "Nichts zu teilen: Nur deine vom Spiel bestätigten Erfassungen (Zauber vor Ort gewirkt) kommen in die gemeinsame Liste.",
    ["Rien de neuf depuis ta dernière contribution. /ley contribute all renvoie tout ce que tu as confirmé."] =
        "Nichts Neues seit deinem letzten Beitrag. /ley contribute all sendet alles, was du bestätigt hast.",
    ["Ouvre ce lien dans ton navigateur (Ctrl+C) : le formulaire sera déjà rempli."] =
        "Öffne diesen Link im Browser (Strg+C): Das Formular ist schon ausgefüllt.",
    ["Trop long pour un seul lien : ouvre celui-ci, puis colle le code (bouton Code)."] =
        "Zu lang für einen Link: Öffne diesen und füge dann den Code ein (Knopf Code).",
    ["Code"] = "Code",
    ["Lien"] = "Link",
    ["Position absente de la liste commune : /ley contribute pour la partager avec tous."] =
        "Diese Position fehlt in der gemeinsamen Liste: /ley contribute, um sie mit allen zu teilen.",
    ["Signal des positions à partager : %s."] = "Hinweis auf zu teilende Positionen: %s.",
    ["%s position(s) à partager, absente(s) de la liste commune."] =
        "%s Position(en) zu teilen, fehlen in der gemeinsamen Liste.",
    ["Position absente de la liste commune : clique sur l'icône apparue en haut de la minicarte pour la partager avec tous."] =
        "Diese Position fehlt in der gemeinsamen Liste: Klicke auf das neue Symbol oben an der Minikarte, um sie mit allen zu teilen.",
    ["Clic : le lien du ticket, déjà rempli."] = "Klick: der Link zum Issue, schon ausgefüllt.",
    ["Colle un code reçu, puis clique sur Importer."] = "Füge einen erhaltenen Code ein und klicke auf Importieren.",
    ["Importer"] = "Importieren",
    ["Fermer"]   = "Schließen",
    ["Code invalide : ce n'est pas un export de Ley Lines."] = "Dieser Code ist kein Ley-Lines-Export.",
    ["%s position(s) importée(s), %s déjà connue(s)."] = "%s Position(en) importiert, %s bereits bekannt.",
    ["Ancien code, qui ne dit pas à quelle faction appartiennent ses points : demande un nouvel export."] =
        "Alter Code ohne Fraktionsangabe zu seinen Punkten: bitte um einen neuen Export.",
    ["%s position(s) sans faction ignorée(s) : demande un nouvel export."] =
        "%s Position(en) ohne Fraktion übersprungen: bitte um einen neuen Export.",
    ["%s position(s) ajoutée(s) depuis les données livrées."] =
        "%s Position(en) aus den mitgelieferten Daten hinzugefügt.",
    ["%s position(s) retirée(s) de la liste commune."] =
        "%s Position(en) aus der gemeinsamen Liste entfernt.",

    -- Mitwirkende (docs/specs/remerciements.md)
    ["%s et %s autre(s)"] =
        "%s und %s weitere",
    ["Merci à %s pour ces positions. /ley credits : tous les contributeurs."] =
        "Danke an %s für diese Positionen. /ley credits zeigt alle, die geteilt haben.",
    ["Aucun contributeur pour l'instant : /ley contribute pour être le premier."] =
        "Noch keine Mitwirkenden. /ley contribute, um der Erste zu sein.",
    ["%s contributeur(s) ont partagé leurs positions :"] =
        "%s Mitwirkende haben ihre Positionen geteilt:",
    ["Toi aussi : /ley contribute."] =
        "Du auch: /ley contribute.",
    ["Une fois versée, ta contribution t'inscrit parmi les contributeurs (/ley credits)."] =
        "Sobald sie aufgenommen ist, steht dein Name bei den Mitwirkenden (/ley credits).",

    ["restauré"] = "wiederhergestellt",
    ["%s position(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s Position(en) aus der internen Sicherung wiederhergestellt.",
    ["import"]              = "Import",
    ["livré avec l'addon"] = "mit dem Addon geliefert",

    -- Tastenbelegung
    ["Enregistrer une %s ici"]      = "Hier eine %s aufzeichnen",
    ["Suivre la %s la plus proche"] = "Der nächsten %s folgen",
}

for k, v in pairs(de) do LL.L[k] = v end
