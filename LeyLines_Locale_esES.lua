-- LeyLines_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS LeyLines_Locale.lua. Sur un client non espagnol : early-return.

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "esES" and locale ~= "esMX" then return end

local es = {
    -- Nombres
    ["Ligne tellurique"]   = "Línea telúrica",
    ["Vergence élémentaire"] = "Elemental Vergence",   -- nom client ES non relevé
    ["Lignes telluriques"] = "Líneas telúricas",

    -- Fuentes
    ["vignette du client"] = "viñeta del cliente",
    ["sort"]               = "hechizo",
    ["relevé manuel"]      = "lectura manual",
    ["infobulle"]          = "información",
    ["inconnue"]           = "desconocida",
    ["activé"]             = "activado",
    ["désactivé"]          = "desactivado",

    -- Estado y comandos
    ["v%s chargée. /ley pour l'état, /ley help pour le reste."] =
        "v%s cargada. /ley para el estado, /ley help para lo demás.",
    ["v%s — %s ligne(s) ici, %s au total."] = "v%s — %s línea(s) aquí, %s en total.",
    ["La plus proche : %s à %s yd."]        = "La más cercana: %s a %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minimapa %s — mapa %s — seguimiento %s — captura automática %s.",
    ["%s ligne(s) tellurique(s) dans %s :"] = "%s línea(s) telúrica(s) en %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."] =
        "Comandos: /ley (estado), add, del, list, clean, clear, export, import, hud, pins, map, track, learn, auto, tooltip, warn <min>, name <texto>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la ligne tellurique et fais /ley add (ou le raccourci clavier)."] =
        "Cómo se usa: colócate SOBRE la línea telúrica y escribe /ley add (o usa el atajo de teclado).",

    -- Captura
    ["Nouvelle ligne tellurique enregistrée dans %s (%s ici)."] =
        "Nueva línea telúrica registrada en %s (%s aquí).",
    ["Ligne tellurique déjà connue — position confirmée (%s relevés)."] =
        "Línea telúrica ya conocida — posición confirmada (%s lecturas).",
    ["Ligne tellurique effacée : %s."] = "Línea telúrica borrada: %s.",
    ["%s ligne(s) tellurique(s) effacée(s)."] = "%s línea(s) telúrica(s) borrada(s).",
    ["Effacer toutes les lignes telluriques connues dans %s ?"] =
        "¿Borrar todas las líneas telúricas conocidas en %s?",
    ["Aucune ligne tellurique connue dans cette zone."] =
        "No se conoce ninguna línea telúrica en esta zona.",
    ["Aucune ligne tellurique à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "Ninguna línea telúrica a menos de 60 yd — colócate encima para borrarla.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Posición no disponible aquí — el cliente no da coordenadas.",
    ["Capture automatique : %s."] = "Captura automática: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Captura por información: %s (lectura aproximada, en tu posición).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s lectura(s) de información borrada(s).",
    ["Noms reconnus : %s."]       = "Nombres reconocidos: %s.",
    ["Nom reconnu ajouté : %s."]  = "Nombre reconocido añadido: %s.",
    ["Lance maintenant ton sort de ligne tellurique : le prochain sort réussi sera retenu."] =
        "Lanza ahora tu hechizo de línea telúrica: se recordará el próximo hechizo lanzado con éxito.",
    ["Apprentissage abandonné : aucun sort lancé."] =
        "Aprendizaje cancelado: no se lanzó ningún hechizo.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une faille."] =
        "Hechizo recordado: %s (%s). A partir de ahora, solo un lanzamiento con buff LARGO marca una línea telúrica.",
    ["Buff court : pas de faille ici, rien n'a été enregistré."] =
        "Buff corto: aquí no hay línea telúrica, no se registró nada.",

    -- Visualización
    ["Affichage sur la minicarte : %s."]      = "Mostrar en el minimapa: %s.",
    ["Affichage sur la carte du monde : %s."] = "Mostrar en el mapa del mundo: %s.",
    ["Suivi à l'écran : %s."]                 = "Seguimiento en pantalla: %s.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Escala del minimapa: %s (radio leído: %s yd).",
    ["%s yd"]                      = "%s yd",
    ["%s yd — source : %s"]        = "%s yd — fuente: %s",
    ["Source : %s — %s relevé(s)"] = "Fuente: %s — %s lectura(s)",
    ["Clic : poser un point de route."]        = "Clic: colocar un punto de ruta.",
    ["Clic gauche : poser un point de route."] = "Clic izquierdo: colocar un punto de ruta.",
    ["Clic droit : masquer. Glisser : déplacer."] = "Clic derecho: ocultar. Arrastrar: mover.",
    ["Point de route posé sur %s."]            = "Punto de ruta colocado en %s.",
    ["Cette zone n'accepte pas de point de route."] = "Esta zona no admite puntos de ruta.",

    ["Buff de faille : %s min restantes — la plus proche à %s yd."] =
        "Buff de línea telúrica: quedan %s min — la más cercana a %s yd.",
    ["Buff de faille : %s min restantes — aucune faille connue dans cette zone."] =
        "Buff de línea telúrica: quedan %s min — ninguna línea conocida en esta zona.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Recordatorio de buff: a %s min restantes (0 = desactivado).",

    -- Compartir
    ["Partage des lignes telluriques"] = "Compartir líneas telúricas",
    ["Aucune ligne tellurique à exporter."] = "Ninguna línea telúrica que exportar.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Copia este texto (Ctrl+C) y compártelo.",
    ["Colle un code reçu, puis clique sur Importer."] = "Pega un código recibido y haz clic en Importar.",
    ["Importer"] = "Importar",
    ["Fermer"]   = "Cerrar",
    ["Code invalide : ce n'est pas un export de Ley Lines."] = "Ese código no es una exportación de Ley Lines.",
    ["%s ligne(s) importée(s), %s déjà connue(s)."] = "%s línea(s) telúrica(s) importada(s), %s ya conocida(s).",
    ["%s ligne(s) tellurique(s) ajoutée(s) depuis les données livrées."] =
        "%s línea(s) telúrica(s) añadida(s) desde los datos incluidos.",
    ["restauré"] = "restaurada",
    ["%s ligne(s) tellurique(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s línea(s) telúrica(s) restaurada(s) desde la copia interna.",
    ["import"]              = "importación",
    ["livré avec l'addon"] = "incluida con el addon",

    -- Atajos de teclado
    ["Enregistrer une ligne tellurique ici"]      = "Registrar una línea telúrica aquí",
    ["Suivre la ligne tellurique la plus proche"] = "Seguir la línea telúrica más cercana",
}

for k, v in pairs(es) do LL.L[k] = v end
