#!/bin/bash
# Génère le PDF d'une proposition commerciale depuis son proposition.html.
#
# Usage :
#   ./build.sh                                   # depuis un dossier de devis (contient proposition.html)
#   ./build.sh clients/biocarmes/2026-10-pilote-ia  # depuis la racine du socle
#
# Le PDF est écrit dans le dossier du devis, nommé d'après le fichier HTML :
#   proposition.html -> proposition.pdf  (renommez ensuite librement, ex. Proposition_<Client>_<annee>.pdf)

set -euo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
DIR="${1:-.}"

if [ -f "$DIR/proposition.html" ]; then
  HTML="$DIR/proposition.html"
else
  if [ -f "$DIR" ] && [ "$(basename "$DIR")" = "proposition.html" ]; then
    HTML="$DIR"
  else
    echo "Erreur : aucun proposition.html trouvé dans '$DIR'" >&2
    echo "Usage : ./build.sh [dossier-du-devis|chemin/vers/proposition.html]" >&2
    exit 1
  fi
fi

OUT="$(dirname "$HTML")/proposition.pdf"
ABS="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$OUT" "file://$ABS" 2>&1 | grep -E "bytes written|error" || true
echo "PDF généré : $OUT"