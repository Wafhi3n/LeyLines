-- LeyLines_Locale_deDE.lua — overlay ALLEMAND. Clé FR → texte DE.
-- Chargé APRÈS LeyLines_Locale.lua. Sur un client non allemand : early-return.

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "deDE" then return end

local de = {
    -- Namen
    ["Ligne tellurique"]   = "Ley-Linie",
    ["Lignes telluriques"] = "Ley-Linien",

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
    ["v%s — %s ligne(s) ici, %s au total."] = "v%s — %s Linie(n) hier, %s insgesamt.",
    ["La plus proche : %s à %s yd."]        = "Nächste: %s in %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minikarte %s — Karte %s — Verfolgung %s — Auto-Erfassung %s.",
    ["%s ligne(s) tellurique(s) dans %s :"] = "%s Ley-Linie(n) in %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."] =
        "Befehle: /ley (Status), add, del, list, clean, clear, hud, pins, map, track, learn, auto, tooltip, warn <Min>, name <Text>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la ligne tellurique et fais /ley add (ou le raccourci clavier)."] =
        "So geht's: Stell dich AUF die Ley-Linie und tippe /ley add (oder nutze die Tastenbelegung).",

    -- Erfassung
    ["Nouvelle ligne tellurique enregistrée dans %s (%s ici)."] =
        "Neue Ley-Linie in %s aufgezeichnet (%s hier).",
    ["Ligne tellurique déjà connue — position confirmée (%s relevés)."] =
        "Ley-Linie bereits bekannt — Position bestätigt (%s Messungen).",
    ["Ligne tellurique effacée : %s."] = "Ley-Linie gelöscht: %s.",
    ["%s ligne(s) tellurique(s) effacée(s)."] = "%s Ley-Linie(n) gelöscht.",
    ["Effacer toutes les lignes telluriques connues dans %s ?"] =
        "Alle bekannten Ley-Linien in %s löschen?",
    ["Aucune ligne tellurique connue dans cette zone."] =
        "In dieser Zone ist keine Ley-Linie bekannt.",
    ["Aucune ligne tellurique à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "Keine Ley-Linie innerhalb von 60 yd — stell dich darauf, um sie zu löschen.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Position hier nicht verfügbar — der Client liefert keine Koordinaten.",
    ["Capture automatique : %s."] = "Automatische Erfassung: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Tooltip-Erfassung: %s (ungefähre Messung, an deiner Position).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s Tooltip-Messung(en) gelöscht.",
    ["Noms reconnus : %s."]       = "Erkannte Namen: %s.",
    ["Nom reconnu ajouté : %s."]  = "Erkannter Name hinzugefügt: %s.",
    ["Lance maintenant ton sort de ligne tellurique : le prochain sort réussi sera retenu."] =
        "Wirke jetzt deinen Ley-Linien-Zauber: Der nächste erfolgreiche Zauber wird gemerkt.",
    ["Apprentissage abandonné : aucun sort lancé."] =
        "Lernen abgebrochen: kein Zauber gewirkt.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une faille."] =
        "Zauber gemerkt: %s (%s). Ab jetzt markiert nur ein Zauber mit LANGEM Buff eine Ley-Linie.",
    ["Buff court : pas de faille ici, rien n'a été enregistré."] =
        "Kurzer Buff: hier ist keine Ley-Linie, nichts wurde aufgezeichnet.",

    -- Anzeige
    ["Affichage sur la minicarte : %s."]      = "Minikartenanzeige: %s.",
    ["Affichage sur la carte du monde : %s."] = "Weltkartenanzeige: %s.",
    ["Suivi à l'écran : %s."]                 = "Bildschirmverfolgung: %s.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Minikartenskalierung: %s (gelesener Radius: %s yd).",
    ["%s yd"]                      = "%s yd",
    ["%s yd — source : %s"]        = "%s yd — Quelle: %s",
    ["Source : %s — %s relevé(s)"] = "Quelle: %s — %s Messung(en)",
    ["Clic : poser un point de route."]        = "Klick: Wegpunkt setzen.",
    ["Clic gauche : poser un point de route."] = "Linksklick: Wegpunkt setzen.",
    ["Clic droit : masquer. Glisser : déplacer."] = "Rechtsklick: ausblenden. Ziehen: verschieben.",
    ["Point de route posé sur %s."]            = "Wegpunkt gesetzt auf %s.",
    ["Cette zone n'accepte pas de point de route."] = "Diese Zone erlaubt keinen Wegpunkt.",

    ["Buff de faille : %s min restantes — la plus proche à %s yd."] =
        "Ley-Linien-Buff: noch %s Min — nächste Linie %s yd entfernt.",
    ["Buff de faille : %s min restantes — aucune faille connue dans cette zone."] =
        "Ley-Linien-Buff: noch %s Min — keine bekannte Ley-Linie in dieser Zone.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Buff-Erinnerung: bei %s Min Restzeit (0 = aus).",

    -- Tastenbelegung
    ["Enregistrer une ligne tellurique ici"]      = "Hier eine Ley-Linie aufzeichnen",
    ["Suivre la ligne tellurique la plus proche"] = "Der nächsten Ley-Linie folgen",
}

for k, v in pairs(de) do LL.L[k] = v end
