#!/usr/bin/env bash
# positions.sh — d'un ticket « positions » à une branche feat/positions-gh-NNNN prête à relire.
#
# Lancé par .github/workflows/positions.yml. En local, pour relire sans rien pousser :
#   ISSUE=16 DRY_RUN=1 LUA=<lua 5.1> LUAC=<luac 5.1> bash .github/scripts/positions.sh
# DRY_RUN s'arrête avant la branche et remet l'arbre dans l'état où il l'a trouvé.
#
# Ne fusionne, ne tague, ne commente, ne ferme rien : un humain relit la branche, passe les portes
# et les tests de l'outillage, puis publie. Le contenu du ticket (titre, corps) ne passe JAMAIS par
# le shell : le corps va dans un fichier que seul tools/ll_guard.lua lit, et tout ce qui est écrit
# ensuite (branche, commit, PR) est bâti avec le numéro du ticket, le pseudo validé et la sortie du
# garde-fou. Spec : docs/specs/contribution-positions.md, T5 et D6.
set -euo pipefail

: "${ISSUE:?ISSUE (numéro du ticket) manquant}"
[[ "$ISSUE" =~ ^[0-9]{1,6}$ ]] || { echo "ISSUE doit être un numéro" >&2; exit 1; }
REPO="${REPO:-${GITHUB_REPOSITORY:-Wafhi3n/LeyLines}}"
LUA="${LUA:-lua5.1}"
LUAC="${LUAC:-luac5.1}"
DRY_RUN="${DRY_RUN:-0}"
ID=$(printf 'gh-%04d' "$ISSUE")
BRANCH="feat/positions-$ID"
CONTRIB="data/contrib/$ID.ll"

cd "$(git rev-parse --show-toplevel)"
WORK=$(mktemp -d)
# En DRY_RUN, l'arbre revient à son état de départ quelle que soit la sortie, échec compris.
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

# --- 1. Le ticket : les métadonnées, puis le corps dans un fichier ---------------------------------
META=$(gh api "repos/$REPO/issues/$ISSUE" --jq \
    '[.user.login, .created_at, .state, ([.labels[].name] | index("positions") != null), has("pull_request")] | @tsv')
IFS=$'\t' read -r LOGIN CREATED STATE LABELED IS_PR <<< "$META"
[[ "$LOGIN" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,38}$ ]] || { say "Ticket #$ISSUE : pseudo inattendu, rien versé."; exit 1; }
[ "$IS_PR" = "false" ]  || { say "#$ISSUE est une PR, pas un ticket : ignoré."; exit 0; }
[ "$LABELED" = "true" ] || { say "Ticket #$ISSUE sans l'étiquette positions : ignoré."; exit 0; }
[ "$STATE" = "open" ]   || { say "Ticket #$ISSUE fermé : ignoré."; exit 0; }

# --- 2. Déjà fait ? (un ticket créé par le formulaire déclenche deux runs) --------------------------
git fetch -q origin main
if git cat-file -e "origin/main:$CONTRIB" 2>/dev/null; then
    say "Ticket #$ISSUE déjà versé sur main ($CONTRIB) : rien à faire."; exit 0
fi
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null; then
    say "Branche $BRANCH déjà prête : rien à faire."; exit 0
fi
gh api "repos/$REPO/issues/$ISSUE" --jq '.body // ""' > "$WORK/body.txt"

# --- 3. L'auteur : âge du compte, tickets des dernières 24 h ---------------------------------------
NOW=$(date -u +%s)
USER_CREATED=$(gh api "users/$LOGIN" --jq '.created_at')
AGE=$(( (NOW - $(date -u -d "$USER_CREATED" +%s)) / 86400 ))
SINCE=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
RECENT=$(gh api -X GET search/issues \
    -f q="repo:$REPO is:issue label:positions author:$LOGIN created:>=$SINCE" --jq '.total_count')

# --- 4. Le garde-fou : 0 = à verser, 3 = refusé ------------------------------------------------------
set +e
"$LUA" tools/ll_guard.lua check . "$ISSUE" "$WORK/body.txt" "$LOGIN" "$AGE" "$RECENT" \
    "$WORK/code.txt" "$WORK/report.md" data/contrib/*.ll
RC=$?
set -e
[ -f "$WORK/report.md" ] && cat "$WORK/report.md" >> "$SUMMARY"
case $RC in
    0) ;;
    3) echo "Ticket #$ISSUE REFUSÉ par le garde-fou :"; cat "$WORK/report.md"; exit 1 ;;
    *) echo "Erreur du garde-fou (code $RC)." >&2; exit 1 ;;
esac

# --- 5. Verser le code canonique (jamais le corps du ticket), régénérer, vérifier -------------------
DATE="${CREATED%%T*}"
BEFORE=$(git status --porcelain | LC_ALL=C sort)
INGESTED=1
"$LUA" tools/ll_ingest.lua add . "$ID" "$LOGIN" "$DATE" - "$WORK/code.txt"
"$LUA" tools/ll_ingest.lua build . data/contrib/*.ll
"$LUAC" -p LeyLines_Data.lua
"$LUA" -e 'local LL = {} assert(loadfile("LeyLines_Data.lua"))("LeyLines", LL)
assert(type(LL.DATA) == "table" and type(LL.DATA_VERSION) == "number", "liste generee illisible")
print("liste chargee, DATA_VERSION = " .. LL.DATA_VERSION)'
# Le versement ne doit toucher que ces deux fichiers (comparé à l'état de départ de l'arbre).
CHANGED=$(LC_ALL=C comm -13 <(echo "$BEFORE") <(git status --porcelain | LC_ALL=C sort) | sed 's/^...//' | tr '\n' ' ')
[ "$CHANGED" = "LeyLines_Data.lua $CONTRIB " ] || { echo "Fichiers inattendus : $CHANGED" >&2; exit 1; }

if [ "$DRY_RUN" = "1" ]; then
    git --no-pager diff --stat -- LeyLines_Data.lua
    cat "$WORK/report.md"
    say "DRY_RUN : rien poussé, arbre remis en l'état."
    exit 0
fi

# --- 6. La branche, et une PR si le dépôt le permet -------------------------------------------------
# Jamais « #N » dans le commit ni dans la PR : GitHub y verrait un renvoi et accrocherait le rapport
# (drapeaux compris) à la page du ticket, sous les yeux du joueur. Le relecteur sait lire « ticket N ».
git switch -q -c "$BRANCH"
git add LeyLines_Data.lua "$CONTRIB"
{ echo "feat(donnees): ticket $ISSUE de $LOGIN, verse par l'Action"; echo; cat "$WORK/report.md"; } > "$WORK/msg.txt"
git -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -F "$WORK/msg.txt"
git push -q origin "$BRANCH"
say "Branche $BRANCH poussée."

cp "$WORK/report.md" "$WORK/pr.md"
if gh pr create -R "$REPO" --base main --head "$BRANCH" --title "Positions : ticket $ISSUE" --body-file "$WORK/pr.md"; then
    say "PR ouverte."
else
    say "PR non ouverte (le dépôt n'autorise pas l'Action à en créer) : la branche suffit."
fi
