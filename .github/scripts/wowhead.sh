#!/usr/bin/env bash
# wowhead.sh — la veille Wowhead : les fissures et tornades que Wowhead montre et que la liste
# commune n'a pas, versées sur une branche feat/positions-wowhead-AAAA-MM-JJ prête à relire.
#
# Lancé chaque jour par .github/workflows/wowhead.yml. En local, pour relire sans rien pousser :
#   DRY_RUN=1 LUA=<lua 5.1> LUAC=<luac 5.1> bash .github/scripts/wowhead.sh
# DRY_RUN s'arrête avant la branche et remet l'arbre dans l'état où il l'a trouvé.
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

# --- 1. Une veille déjà en attente de relecture ? -----------------------------------------------------
# Une PR ouverte de la veille bloque la suivante : ses points seraient proposés deux fois. Fermer la
# PR (après une fusion locale, ou pour la refuser) rouvre la veille.
if [ "$DRY_RUN" != "1" ]; then
    OPEN=$(gh pr list -R "$REPO" --state open --limit 100 --json headRefName \
        --jq "[.[] | select(.headRefName | startswith(\"$PREFIX\"))] | length")
    [ "$OPEN" = "0" ] || { say "Une PR de la veille Wowhead attend encore sa relecture : rien de proposé."; exit 0; }
    if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null; then
        say "Branche $BRANCH déjà poussée aujourd'hui : rien à faire."; exit 0
    fi
fi

# --- 2. Les deux pages (602735 = fissure, 616992 = tornade) -------------------------------------------
curl -fsSL --retry 3 --retry-delay 10 --max-time 60 -A "$UA" "${BASE}602735" -o "$WORK/fissure.html"
sleep 2
curl -fsSL --retry 3 --retry-delay 10 --max-time 60 -A "$UA" "${BASE}616992" -o "$WORK/tornade.html"

# --- 3. Le tri : 0 = points neufs, 4 = rien de neuf, 2 = page illisible --------------------------------
set +e
"$LUA" tools/ll_wowhead.lua delta . "$WORK/fissure.html" "$WORK/tornade.html" \
    "$WORK/code.txt" "$WORK/report.md" data/contrib/*.ll
RC=$?
set -e
[ -f "$WORK/report.md" ] && cat "$WORK/report.md" >> "$SUMMARY"
case $RC in
    0) ;;
    4) echo "Rien de neuf sur Wowhead."; exit 0 ;;
    2) echo "Page Wowhead illisible : la veille ne sait plus lire Wowhead, à corriger." >&2; exit 1 ;;
    *) echo "Erreur de ll_wowhead.lua (code $RC)." >&2; exit 1 ;;
esac

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
{ echo "feat(donnees): veille Wowhead du $DATE, versee par l'Action"; echo; cat "$WORK/report.md"; } > "$WORK/msg.txt"
git -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -F "$WORK/msg.txt"
git push -q origin "$BRANCH"
say "Branche $BRANCH poussée."
if gh pr create -R "$REPO" --base main --head "$BRANCH" --title "Positions : veille Wowhead du $DATE" --body-file "$WORK/report.md"; then
    say "PR ouverte."
else
    say "PR non ouverte : la branche suffit, mais la veille de demain ne la verra pas en attente."
fi
