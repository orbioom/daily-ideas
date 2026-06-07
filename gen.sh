#!/usr/bin/env bash
# Orbioom daily-ideas — regenerate Xcode projects from XcodeGen project.yml.
#
# New runs ship a `project.yml` per iOS app (not a .xcodeproj) so the project
# is generated locally and is always Xcode-valid. This script does that.
#
# Usage:
#   ./gen.sh                         # every iOS app in every run
#   ./gen.sh runs/2026-06-07_1809-UTC   # just one run
#
set -uo pipefail
export PATH="/opt/homebrew/bin:$PATH"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found — installing via Homebrew…"
  brew install xcodegen || { echo "Could not install xcodegen. Run: brew install xcodegen"; exit 1; }
fi

target="${1:-runs}"
count=0; fail=0
while IFS= read -r yml; do
  dir=$(dirname "$yml")
  app=$(basename "$(ls -d "$dir"/*/ 2>/dev/null | grep -vi xcodeproj | head -1)")
  ( cd "$dir" && xcodegen generate --quiet ) 2>/dev/null
  if [ -d "$dir/$app.xcodeproj" ]; then
    echo "  ✅ $dir/$app.xcodeproj"
    count=$((count+1))
  else
    echo "  ❌ $dir ($app) — generate failed"
    fail=$((fail+1))
  fi
done < <(find "$target" -path '*/ios/project.yml' 2>/dev/null | sort)

echo ""
echo "Generated $count project(s)${fail:+, $fail failed}."
echo "Open one with:  open <run>/<app>/ios/<App>.xcodeproj"
