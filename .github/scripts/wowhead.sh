#!/usr/bin/env bash
# wowhead.sh — la veille Wowhead : les fissures et tornades que Wowhead montre et que la liste
# commune n'a pas, versées sur une branche feat/positions-wowhead-AAAA-MM-JJ prête à relire.
#
# DEPUIS LE 2026-10-16, À LA MAIN. Wowhead défie les robots (pare-feu AWS WAF) : ni le runner ni un
# script ne lisent plus ses pages, et on ne contourne pas le défi. Le user ouvre les deux pages dans
# son navigateur et les enregistre avec l'extension Chrome de l'outillage (tools\wowhead-page :
# Téléchargements\wowhead\forever_object_602735.html et …616992.html), ou à défaut Ctrl+S « Page
# Web, HTML uniquement ». La session lance, dans un worktree de LeyLines tiré d'origin/main (le
# script y crée la branche) :
#   FISSURE_HTML=<page 602735> TORNADE_HTML=<page 616992> LUA=<lua 5.1> LUAC=<luac 5.1> \
#     bash .github/scripts/wowhead.sh
# Le reste (tri, garde-fous, branche, PR) est le même que sans les deux variables, où le script
# télécharge lui-même : c'est ce que fait .github/workflows/wowhead.yml, lancé à la main seulement,
# pour voir si Wowhead a levé le défi.
# DRY_RUN=1 s'arrête avant la branche et remet l'arbre dans l'état où il l'a trouvé.
#
# Ne fusionne, ne tague, ne publie rien : un humain relit la branche, passe les portes et les tests
# de l'outillage, puis publie. Rien de neuf = rien d'écrit (une contribution vide monterait quand
# même le palier). Une page illisible = un ÉCHEC du job, jamais « rien de neuf » : sinon un blocage
# de Wowhead passerait pour un calme plat. Le tri et la sécurité sont dans tools/ll_wowhead.lua.
#
# AUTEUR : `from=` de la contribution, affiché en jeu parmi les remerciements (LL.THANKS). Vide :
# personne n'est remercié (comme la graine).
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-Wafhi3n/LeyLines}}"
LUA="${LUA:-lua5.1}"
LUAC="${LUAC:-luac5.1}"
DRY_RUN="${DRY_RUN:-0}"
AUTEUR="${AUTEUR-Wowhead}"
DATE=$(date -u +%Y-%m-%d)
ID="wowhead-$DATE"
PREFIX="feat/positions-wowhead-"
BRANCH="$PREFIX$DATE"
CONTRIB="data/contrib/$ID.ll"
BASE="https://www.wowhead.com/forever/object="
UA="Mozilla/5.0 (compatible; LeyLines-veille; +https://github.com/$REPO)"

cd "$(git rev-parse --show-toplevel)"
WORK=$(mktemp -d)
cleanup() {
    if [ "$DRY_RUN" = "1" ] && [ "${INGESTED:-0}" = "1" ]; then
        git checkout -q -- LeyLines_Data.lua
        rm -f "$CONTRIB"
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT
SUMMARY="${GITHUB_STEP_SUMMARY:-$WORK/summary.md}"
say() { echo "$*"; echo "$*" >> "$SUMMARY"; }

command -v "$LUA" >/dev/null  || { echo "Lua 5.1 introuvable : $LUA" >&2; exit 1; }
command -v "$LUAC" >/dev/null || { echo "luac 5.1 introuvable : $LUAC" >&2; exit 1; }
if [ -n "$(git status --porcelain -- LeyLines_Data.lua data/contrib)" ]; then
    echo "LeyLines_Data.lua ou data/contrib modifiés : arbre à nettoyer d'abord." >&2; exit 1
fi

# --- 1. Les deux pages (602735 = fissure, 616992 = tornade) -------------------------------------------
# Lues AVANT de regarder si une PR attend : une page bloquée ou remaniée doit faire échouer le run
# chaque jour, même quand la veille n'a rien à proposer.
#
# Une page lue, ou un échec qui dit POURQUOI. Pas de `curl -f` : il laisse passer un 202, et c'est
# par un 202 vide portant `x-amzn-waf-action: challenge` que Wowhead défie les robots (mesuré le
# 2026-10-16 depuis le poste du user ; 403 avec un User-Agent de navigateur). Ce défi demande
# d'exécuter le JavaScript de la page : on ne le contourne pas, on le nomme, et le job échoue.
fetch() {  # fetch <nom> <id de l'objet>
    local name=$1 id=$2 code waf
    code=$(curl -sSL --retry 3 --retry-delay 10 --max-time 60 -A "$UA" -D "$WORK/$name.headers" \
        -o "$WORK/$name.html" -w '%{http_code}' "$BASE$id")
    waf=$({ grep -i '^x-amzn-waf-action:' "$WORK/$name.headers" || true; } | tail -1 | cut -d: -f2- | tr -d ' \r')
    if [ -n "$waf" ]; then
        say "Wowhead refuse la page $name (objet $id) : HTTP $code, x-amzn-waf-action: $waf. C'est le pare-feu anti-robot de Wowhead (AWS WAF), pas notre lecteur : la veille ne passera pas tant qu'il défie le runner."
        exit 1
    fi
    if [ "$code" != "200" ]; then
        say "Wowhead répond HTTP $code pour la page $name (objet $id), $(wc -c < "$WORK/$name.html") octets : page non lue."
        exit 1
    fi
}
# Deux pages enregistrées à la main : on les prend telles quelles (ll_wowhead.lua vérifie qu'il
# s'agit bien de la page de chaque objet). Les deux ou aucune.
if [ -n "${FISSURE_HTML:-}" ] || [ -n "${TORNADE_HTML:-}" ]; then
    for f in "${FISSURE_HTML:-}" "${TORNADE_HTML:-}"; do
        [ -n "$f" ] && [ -s "$f" ] || { echo "FISSURE_HTML et TORNADE_HTML : deux pages enregistrées, non vides ($f)." >&2; exit 1; }
    done
    cp "$FISSURE_HTML" "$WORK/fissure.html"
    cp "$TORNADE_HTML" "$WORK/tornade.html"
    MANUEL=1
else
    fetch fissure 602735
    sleep 2
    fetch tornade 616992
    MANUEL=0
fi

# --- 2. Le tri : 0 = points neufs, 4 = rien de neuf, 2 = page illisible --------------------------------
set +e
"$LUA" tools/ll_wowhead.lua delta . "$WORK/fissure.html" "$WORK/tornade.html" \
    "$WORK/code.txt" "$WORK/report.md" data/contrib/*.ll
RC=$?
set -e
[ -f "$WORK/report.md" ] && cat "$WORK/report.md" >> "$SUMMARY"
case $RC in
    0) ;;
    4) echo "Rien de neuf sur Wowhead."; exit 0 ;;
    2) if [ "$MANUEL" = "1" ]; then
           echo "Page enregistrée illisible : chaque fichier est-il la page de SON objet (602735 fissure, 616992 tornade), enregistrée en « Page Web, HTML uniquement » ?" >&2
       else
           echo "Page Wowhead illisible : la veille ne sait plus lire Wowhead, à corriger." >&2
       fi
       exit 1 ;;
    *) echo "Erreur de ll_wowhead.lua (code $RC)." >&2; exit 1 ;;
esac

# --- 3. Une veille déjà en attente de relecture ? -----------------------------------------------------
# Une PR ouverte de la veille bloque la suivante : ses points seraient proposés deux fois. Fermer la
# PR (après une fusion locale, ou pour la refuser) rouvre la veille.
if [ "$DRY_RUN" != "1" ]; then
    # En local, la branche part d'ici : il faut que ce soit origin/main à jour (sur le runner,
    # l'Action vient de l'extraire).
    git fetch -q origin main
    [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || {
        echo "HEAD n'est pas origin/main à jour : lancer depuis un worktree tiré d'origin/main." >&2; exit 1; }
    OPEN=$(gh pr list -R "$REPO" --state open --limit 100 --json headRefName \
        --jq "[.[] | select(.headRefName | startswith(\"$PREFIX\"))] | length")
    [ "$OPEN" = "0" ] || { say "Une PR de la veille Wowhead attend encore sa relecture : rien de proposé."; exit 0; }
    if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null; then
        say "Branche $BRANCH déjà poussée aujourd'hui : rien à faire."; exit 0
    fi
fi

# --- 4. Verser, régénérer, vérifier --------------------------------------------------------------------
BEFORE=$(git status --porcelain | LC_ALL=C sort)
INGESTED=1
"$LUA" tools/ll_ingest.lua add . "$ID" "$AUTEUR" "$DATE" - "$WORK/code.txt"
"$LUA" tools/ll_ingest.lua build . data/contrib/*.ll | tee "$WORK/build.txt"
"$LUAC" -p LeyLines_Data.lua
"$LUA" -e 'local LL = {} assert(loadfile("LeyLines_Data.lua"))("LeyLines", LL)
assert(type(LL.DATA) == "table" and type(LL.DATA_VERSION) == "number", "liste generee illisible")
print("liste chargee, DATA_VERSION = " .. LL.DATA_VERSION)'
# Le tri et la construction doivent dire la même chose : autant de points neufs des deux côtés.
WANT=$(grep -c '^| tornade\|^| fissure' "$WORK/report.md" || true)
GOT=$(sed -n "s/^ *$ID *palier [0-9]* : \([0-9]*\) point.*/\1/p" "$WORK/build.txt")
[ "$GOT" = "$WANT" ] || { echo "Le tri annonçait $WANT point(s) neuf(s), la construction en verse ${GOT:-?}." >&2; exit 1; }
CHANGED=$(LC_ALL=C comm -13 <(echo "$BEFORE") <(git status --porcelain | LC_ALL=C sort) | sed 's/^...//' | tr '\n' ' ')
[ "$CHANGED" = "LeyLines_Data.lua $CONTRIB " ] || { echo "Fichiers inattendus : $CHANGED" >&2; exit 1; }

if [ "$DRY_RUN" = "1" ]; then
    git --no-pager diff --stat -- LeyLines_Data.lua
    cat "$WORK/report.md"
    say "DRY_RUN : rien poussé, arbre remis en l'état."
    exit 0
fi

# --- 5. La branche, et une PR ----------------------------------------------------------------------------
git switch -q -c "$BRANCH"
git add LeyLines_Data.lua "$CONTRIB"
if [ "$MANUEL" = "1" ]; then
    { echo "feat(donnees): veille Wowhead du $DATE, pages enregistrees a la main"; echo; cat "$WORK/report.md"; } > "$WORK/msg.txt"
    git commit -q -F "$WORK/msg.txt"   # l'identité git du poste : c'est un humain qui a lu les pages
else
    { echo "feat(donnees): veille Wowhead du $DATE, versee par l'Action"; echo; cat "$WORK/report.md"; } > "$WORK/msg.txt"
    git -c user.name="github-actions[bot]" \
        -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -F "$WORK/msg.txt"
fi
git push -q origin "$BRANCH"
say "Branche $BRANCH poussée."
if gh pr create -R "$REPO" --base main --head "$BRANCH" --title "Positions : veille Wowhead du $DATE" --body-file "$WORK/report.md"; then
    say "PR ouverte."
else
    say "PR non ouverte : la branche suffit, mais la veille de demain ne la verra pas en attente."
fi
