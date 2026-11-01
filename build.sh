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

# Chrome : chemin macOS en priorité, puis fallbacks Linux.
CHROME=""
for CANDIDAT in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/usr/local/bin/google-chrome" \
  "/usr/bin/google-chrome-stable" \
  "/usr/bin/google-chrome" \
  "/usr/bin/chromium" \
  "/usr/bin/chromium-browser"; do
  if [ -x "$CANDIDAT" ]; then
    CHROME="$CANDIDAT"
    break
  fi
done
if [ -z "$CHROME" ]; then
  echo "Erreur : Chrome introuvable (macOS ou Linux)" >&2
  exit 1
fi

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

# Chrome ne se termine pas toujours seul après l'impression (conteneurs sans dbus) :
# on borne le temps et on valide le PDF produit.
LOG="$(mktemp)"
TIMEOUT_CMD=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout 60"
fi
set +e
$TIMEOUT_CMD "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --disable-dev-shm-usage \
  --print-to-pdf="$OUT" "file://$ABS" >"$LOG" 2>&1
CHROME_RC=$?
set -e
grep -E "bytes written|error" "$LOG" || true
rm -f "$LOG"

if [ ! -s "$OUT" ]; then
  echo "Erreur : le PDF n'a pas été généré (code $CHROME_RC)" >&2
  exit 1
fi
echo "PDF généré : $OUT"