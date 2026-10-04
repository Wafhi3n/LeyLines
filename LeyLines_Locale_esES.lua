-- LeyLines_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS LeyLines_Locale.lua. Sur un client non espagnol : early-return.
--
-- Les phrases qui nomment l'objet le prennent en %s (Nodes:Word). Les deux noms sont FÉMININS
-- (la línea telúrica, la convergencia elemental) : articles et adjectifs s'accordent dans les deux.

local _, LL = ...
LL = LL or _G.LeyLines
if not LL or not LL.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "esES" and locale ~= "esMX" then return end

local es = {
    -- Nombres. Nom client ES de la tornade non relevé : traduction à confirmer en jeu.
    ["Ligne tellurique"]                = "Línea telúrica",
    ["Convergence élémentaire"]         = "Convergencia elemental",
    ["ligne tellurique"]                = "línea telúrica",
    ["convergence élémentaire"]         = "convergencia elemental",
    ["ligne(s) tellurique(s)"]          = "línea(s) telúrica(s)",
    ["convergence(s) élémentaire(s)"]   = "convergencia(s) elemental(es)",
    ["lignes telluriques"]              = "líneas telúricas",
    ["convergences élémentaires"]       = "convergencias elementales",
    ["Lignes telluriques / Convergences élémentaires"] = "Líneas telúricas / Convergencias elementales",

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
    ["v%s — %s %s ici, %s au total."]       = "v%s — %s %s aquí, %s en total.",
    ["La plus proche : %s à %s yd."]        = "La más cercana: %s a %s yd.",
    ["Minicarte %s — carte %s — suivi %s — capture auto %s."] =
        "Minimapa %s — mapa %s — seguimiento %s — captura automática %s.",
    ["%s %s dans %s :"]                     = "%s %s en %s:",
    ["Commandes : /ley (état), add, del, list, clean, clear, export, import, contribute, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, name <texte>, scale <n>, probe."] =
        "Comandos: /ley (estado), add, del, list, clean, clear, export, import, contribute, credits, signal, hud, pins, map, skyborne, track, learn, auto, tooltip, warn <min>, name <texto>, scale <n>, probe.",
    ["Marche à suivre : place-toi SUR la %s et fais /ley add (ou le raccourci clavier)."] =
        "Cómo se usa: colócate SOBRE la %s y escribe /ley add (o usa el atajo de teclado).",

    -- Captura
    ["Nouvelle %s enregistrée dans %s (%s ici)."] = "Nueva %s registrada en %s (%s aquí).",
    ["%s déjà connue — position confirmée (%s relevés)."] =
        "%s ya conocida — posición confirmada (%s lecturas).",
    ["%s effacée."]                         = "%s borrada.",
    ["%s %s effacée(s)."]                   = "%s %s borrada(s).",
    ["Effacer toutes les %s connues dans %s ?"] = "¿Borrar todas las %s conocidas en %s?",
    ["Aucune %s connue dans cette zone."]   = "No se conoce ninguna %s en esta zona.",
    ["Aucune %s à moins de 60 yd — place-toi dessus pour l'effacer."] =
        "Ninguna %s a menos de 60 yd — colócate encima para borrarla.",
    ["Position indisponible ici — le client ne donne pas de coordonnées."] =
        "Posición no disponible aquí — el cliente no da coordenadas.",
    ["Capture automatique : %s."] = "Captura automática: %s.",
    ["Capture par infobulle : %s (relevé approximatif, à ta position)."] =
        "Captura por información: %s (lectura aproximada, en tu posición).",
    ["%s relevé(s) d'infobulle effacé(s)."] = "%s lectura(s) de información borrada(s).",
    ["Noms reconnus : %s."]       = "Nombres reconocidos: %s.",
    ["Nom reconnu ajouté : %s."]  = "Nombre reconocido añadido: %s.",
    ["Lance maintenant ton sort de %s : le prochain sort réussi sera retenu."] =
        "Lanza ahora tu hechizo de %s: se recordará el próximo hechizo lanzado con éxito.",
    ["Apprentissage abandonné : aucun sort lancé."] =
        "Aprendizaje cancelado: no se lanzó ningún hechizo.",
    ["Sort retenu : %s (%s). Désormais, seul un lancer suivi d'un buff LONG marquera une %s."] =
        "Hechizo recordado: %s (%s). A partir de ahora, solo un lanzamiento con buff LARGO marca una %s.",
    ["Buff court : pas de %s ici, rien n'a été enregistré."] =
        "Buff corto: aquí no hay %s, no se registró nada.",

    -- Visualización
    ["Affichage sur la minicarte : %s."]      = "Mostrar en el minimapa: %s.",
    ["Affichage sur la carte du monde : %s."] = "Mostrar en el mapa del mundo: %s.",
    ["Suivi à l'écran : %s."]                 = "Seguimiento en pantalla: %s.",
    ["Points seulement sur un personnage Skyborne : %s."] = "Puntos solo en personajes Skyborne: %s.",
    ["Points masqués sur ce personnage (pas Skyborne) : /ley skyborne pour les afficher partout."] =
        "Puntos ocultos en este personaje (no es Skyborne): /ley skyborne para mostrarlos en todos.",
    ["Échelle de la minicarte : %s (rayon lu : %s yd)."] =
        "Escala del minimapa: %s (radio leído: %s yd).",
    ["%s yd"]                      = "%s yd",
    ["%s yd — source : %s"]        = "%s yd — fuente: %s",
    ["Source : %s — %s relevé(s)"] = "Fuente: %s — %s lectura(s)",
    ["Clic droit : effacer ce point."]         = "Clic derecho: borrar este punto.",
    ["Effacer %s (%s) ?"]                      = "¿Borrar %s (%s)?",
    ["Clic gauche : poser un point de route."] = "Clic izquierdo: colocar un punto de ruta.",
    ["Clic droit : masquer. Glisser : déplacer."] = "Clic derecho: ocultar. Arrastrar: mover.",
    ["%s %s connue(s) au total."] = "%s %s conocida(s) en total.",
    ["Clic gauche : partager tes captures pour la liste commune."] =
        "Clic izquierdo: comparte tus puntos para la lista común.",
    ["Clic droit : afficher ou masquer le suivi."] = "Clic derecho: mostrar u ocultar el seguimiento.",
    ["Point de route posé sur %s."]            = "Punto de ruta colocado en %s.",
    ["Cette zone n'accepte pas de point de route."] = "Esta zona no admite puntos de ruta.",

    ["%s : buff à %s min de la fin — la plus proche à %s yd."] =
        "%s: el buff termina en %s min — la más cercana a %s yd.",
    ["%s : buff à %s min de la fin — aucune connue dans cette zone."] =
        "%s: el buff termina en %s min — ninguna conocida en esta zona.",
    ["Rappel de buff : à %s min restantes (0 = désactivé)."] =
        "Recordatorio de buff: a %s min restantes (0 = desactivado).",

    -- Compartir
    ["Partage des positions"] = "Compartir posiciones",
    ["Aucune position à exporter."] = "Ninguna posición que exportar.",
    ["Copie ce texte (Ctrl+C) et partage-le."] = "Copia este texto (Ctrl+C) y compártelo.",
    ["Colle ce code dans un ticket : github.com/Wafhi3n/LeyLines"] =
        "Pega este código en un issue: github.com/Wafhi3n/LeyLines",
    ["Rien à partager : seules tes captures confirmées par le jeu (sort lancé sur place) vont dans la liste commune."] =
        "Nada que compartir: solo tus capturas confirmadas por el juego (hechizo lanzado en el sitio) van a la lista común.",
    ["Rien de neuf depuis ta dernière contribution. /ley contribute all renvoie tout ce que tu as confirmé."] =
        "Nada nuevo desde tu última contribución. /ley contribute all envía todo lo que has confirmado.",
    ["Ouvre ce lien dans ton navigateur (Ctrl+C) : le formulaire sera déjà rempli."] =
        "Abre este enlace en tu navegador (Ctrl+C): el formulario ya viene rellenado.",
    ["Trop long pour un seul lien : ouvre celui-ci, puis colle le code (bouton Code)."] =
        "Demasiado largo para un enlace: abre este y pega el código (botón Código).",
    ["Code"] = "Código",
    ["Lien"] = "Enlace",
    ["Position absente de la liste commune : /ley contribute pour la partager avec tous."] =
        "Esta posición no está en la lista común: /ley contribute para compartirla con todos.",
    ["Signal des positions à partager : %s."] = "Aviso de posiciones por compartir: %s.",
    ["%s position(s) à partager, absente(s) de la liste commune."] =
        "%s posición(es) por compartir, ausente(s) de la lista común.",
    ["Position absente de la liste commune : clique sur l'icône apparue en haut de la minicarte pour la partager avec tous."] =
        "Esta posición no está en la lista común: haz clic en el nuevo icono, arriba del minimapa, para compartirla con todos.",
    ["Clic : le lien du ticket, déjà rempli."] = "Clic: el enlace del issue, ya rellenado.",
    ["Colle un code reçu, puis clique sur Importer."] = "Pega un código recibido y haz clic en Importar.",
    ["Importer"] = "Importar",
    ["Fermer"]   = "Cerrar",
    ["Code invalide : ce n'est pas un export de Ley Lines."] = "Ese código no es una exportación de Ley Lines.",
    ["%s position(s) importée(s), %s déjà connue(s)."] = "%s posición(es) importada(s), %s ya conocida(s).",
    ["Ancien code, qui ne dit pas à quelle faction appartiennent ses points : demande un nouvel export."] =
        "Código antiguo que no dice a qué facción pertenecen sus puntos: pide una nueva exportación.",
    ["%s position(s) sans faction ignorée(s) : demande un nouvel export."] =
        "%s posición(es) sin facción omitida(s): pide una nueva exportación.",
    ["%s position(s) ajoutée(s) depuis les données livrées."] =
        "%s posición(es) añadida(s) desde los datos incluidos.",
    ["%s position(s) retirée(s) de la liste commune."] =
        "%s posición(es) retirada(s) de la lista común.",

    -- Colaboradores (docs/specs/remerciements.md)
    ["%s et %s autre(s)"] =
        "%s y %s más",
    ["Merci à %s pour ces positions. /ley credits : tous les contributeurs."] =
        "Gracias a %s por estas posiciones. /ley credits muestra a todos los que han compartido.",
    ["Aucun contributeur pour l'instant : /ley contribute pour être le premier."] =
        "Todavía no hay colaboradores. /ley contribute para ser el primero.",
    ["%s contributeur(s) ont partagé leurs positions :"] =
        "%s colaborador(es) han compartido sus posiciones:",
    ["Toi aussi : /ley contribute."] =
        "Tú también: /ley contribute.",
    ["Une fois versée, ta contribution t'inscrit parmi les contributeurs (/ley credits)."] =
        "Cuando se añada, tu nombre aparecerá entre los colaboradores (/ley credits).",

    ["restauré"] = "restaurada",
    ["%s position(s) restaurée(s) depuis la sauvegarde interne."] =
        "%s posición(es) restaurada(s) desde la copia interna.",
    ["import"]              = "importación",
    ["livré avec l'addon"] = "incluida con el addon",

    -- Atajos de teclado
    ["Enregistrer une %s ici"]      = "Registrar una %s aquí",
    ["Suivre la %s la plus proche"] = "Seguir la %s más cercana",
}

for k, v in pairs(es) do LL.L[k] = v end
