#!/usr/bin/env bash
# Render "Revised Burning Steel.md" (the current ruleset) to a PDF the TTS
# mod can load as a Custom PDF object.
#
# The output (tts/assets/png/v1/rules.pdf) is COMMITTED and served from
# GitHub Pages with the other assets, so multiplayer guests can read the
# rulebook in-game. The rules markdown/docx themselves stay gitignored.
# Re-run this script and push after each ruleset drop.
#
# The markdown has the docx's images stripped, so diagrams are absent. To
# ship the exact original rendering instead, export a PDF from Word and
# drop it at the same path.
set -euo pipefail
cd "$(dirname "$0")/../.."

# Land in the CURRENT asset version dir. TTS caches by URL forever, so a
# ruleset drop that changes the PDF must ship in a bumped ASSET_VERSION dir
# (00_config.lua) alongside re-copied images — never overwrite a published
# version's pdf in place.
VER=$(sed -nE 's/^ASSET_VERSION = "([^"]+)".*/\1/p' tts/src/global/00_config.lua)
OUT="tts/assets/png/${VER:-v1}/rules.pdf"
mkdir -p "$(dirname "$OUT")"
TMP_HTML="$(mktemp --suffix=.html)"
trap 'rm -f "$TMP_HTML"' EXIT

pandoc "Revised Burning Steel.md" -s -t html --metadata title="Burning Steel — Rules (2026-08-05)" \
  -V lang=en -o "$TMP_HTML" --css=/dev/null 2>/dev/null || pandoc "Revised Burning Steel.md" -s -t html \
  --metadata title="Burning Steel — Rules (2026-08-05)" -o "$TMP_HTML"

# Inline a print stylesheet
python3 - "$TMP_HTML" <<'EOF'
import sys
p = sys.argv[1]
css = """<style>
body{font-family:Georgia,serif;max-width:52em;margin:0 auto;padding:2em;line-height:1.45;color:#111}
h1{font-family:system-ui,sans-serif;border-bottom:2px solid #b33;padding-bottom:4px;margin-top:1.6em}
h2,h3{font-family:system-ui,sans-serif}
table{border-collapse:collapse;margin:1em 0;width:100%}
td,th{border:1px solid #999;padding:4px 8px;font-size:0.92em;text-align:left}
blockquote{margin-left:1em;color:#333}
.underline{text-decoration:underline}
@media print{h1{page-break-before:always} h1:first-of-type{page-break-before:avoid}}
</style>"""
s = open(p).read().replace("</head>", css + "</head>", 1)
open(p, "w").write(s)
EOF

cp "$TMP_HTML" .rules_render.html
(python3 -m http.server 8932 --bind 127.0.0.1 >/dev/null 2>&1 &)
sleep 1
playwright-cli -s=rulespdf open "http://127.0.0.1:8932/.rules_render.html" >/dev/null
playwright-cli -s=rulespdf pdf --filename="$OUT" >/dev/null
playwright-cli -s=rulespdf close >/dev/null
pkill -f "http.server 8932" || true
rm -f .rules_render.html
echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"
