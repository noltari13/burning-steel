#!/usr/bin/env bash
# Render "Revised Burning Steel.md" (the current ruleset) to a PDF the TTS
# mod can load as a Custom PDF object.
#
# NOTE: the rules are local-only by design (see update_ruleset.sh) — the
# output goes to tts/assets/png/v1/rules.pdf, which is GITIGNORED. The mod
# reads it via file:/// on this machine. Publishing it (for multiplayer
# guests) is a deliberate step: un-ignore it, commit, push.
#
# The markdown has the docx's images stripped, so diagrams are absent. To
# ship the exact original rendering instead, export a PDF from Word and
# drop it at the same path.
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT="tts/assets/png/v1/rules.pdf"
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
