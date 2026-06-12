#!/bin/bash
# permcheck (preview) — snapshot & diff the developer identities of your installed apps.
#
# The Bartender problem: a trusted app can be sold, re-signed by a new developer,
# and keep every permission you granted it — and macOS never tells you.
# This script is the core idea in ~100 lines: snapshot every app's code-signing
# identity today, run it again later, and see exactly which apps changed hands.
#
# Usage:
#   ./permcheck.sh            # snapshot (first run) or diff against last snapshot
#   ./permcheck.sh --list     # just print every app's signing identity
#
# No network. No dependencies. Snapshots live in ~/.permcheck/
# Full app (menu-bar, automatic alerts, sensitive-permission flagging):
#   https://permcheck.com

set -euo pipefail

SNAP_DIR="$HOME/.permcheck"
SNAP="$SNAP_DIR/snapshot.tsv"
NEW="$SNAP_DIR/snapshot.new.tsv"
mkdir -p "$SNAP_DIR"

bold=$(tput bold 2>/dev/null || true); red=$(tput setaf 1 2>/dev/null || true)
grn=$(tput setaf 2 2>/dev/null || true); ylw=$(tput setaf 3 2>/dev/null || true)
rst=$(tput sgr0 2>/dev/null || true)

scan() {
  # TSV: app-path <tab> TeamIdentifier <tab> Authority(leaf)
  local app authority team
  for app in /Applications/*.app "$HOME"/Applications/*.app; do
    [ -d "$app" ] || continue
    # codesign exits non-zero for unsigned apps; capture what we can
    local out
    out=$(codesign -dv --verbose=2 "$app" 2>&1 || true)
    team=$(printf '%s\n' "$out" | awk -F= '/^TeamIdentifier=/{print $2; exit}')
    authority=$(printf '%s\n' "$out" | awk -F= '/^Authority=/{print $2; exit}')
    printf '%s\t%s\t%s\n' "$app" "${team:-UNSIGNED}" "${authority:-none}"
  done | sort
}

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' "${bold}App → Team ID → Signing authority${rst}"
  scan | awk -F'\t' '{printf "%-52s %-12s %s\n", substr($1, 15), $2, $3}'
  exit 0
fi

if [ ! -f "$SNAP" ]; then
  scan > "$SNAP"
  count=$(wc -l < "$SNAP" | tr -d ' ')
  echo "${grn}✓ Baseline saved:${rst} $count apps' signing identities recorded in $SNAP"
  echo "  Run ${bold}./permcheck.sh${rst} again any time to see which apps changed owners."
  exit 0
fi

scan > "$NEW"

changes=0
# Apps whose Team ID changed since the snapshot — the Bartender scenario.
while IFS=$'\t' read -r app old_team old_auth; do
  new_line=$(grep -F "$app"$'\t' "$NEW" || true)
  [ -n "$new_line" ] || continue   # app removed; not an ownership change
  new_team=$(printf '%s' "$new_line" | cut -f2)
  new_auth=$(printf '%s' "$new_line" | cut -f3)
  if [ "$new_team" != "$old_team" ]; then
    changes=$((changes+1))
    name=$(basename "$app" .app)
    echo "${red}${bold}⚠ $name changed signing identity${rst}"
    echo "    was: $old_team ($old_auth)"
    echo "    now: $new_team ($new_auth)"
  fi
done < "$SNAP"

new_apps=$(comm -13 <(cut -f1 "$SNAP") <(cut -f1 "$NEW") | wc -l | tr -d ' ')
gone_apps=$(comm -23 <(cut -f1 "$SNAP") <(cut -f1 "$NEW") | wc -l | tr -d ' ')

if [ "$changes" -eq 0 ]; then
  echo "${grn}✓ No ownership changes${rst} — every app is signed by the same team as your baseline."
else
  echo
  echo "${ylw}Review these before the apps next auto-update. An identity change can be"
  echo "legitimate (new cert, company restructure) — or an unannounced sale.${rst}"
fi
[ "$new_apps" != "0" ] && echo "  ($new_apps new app(s) since baseline, $gone_apps removed — run with --list to inspect)"

mv "$NEW" "$SNAP"
echo
echo "Baseline updated. permcheck (the app) does this continuously from your menu bar"
echo "and flags apps holding screen-recording/accessibility/full-disk permissions:"
echo "  ${bold}https://permcheck.com${rst}"
