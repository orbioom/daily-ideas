#!/usr/bin/env bash
# Lightweight static audit for a scaffolded Orbioom iOS app (no Xcode available).
# Usage: ./audit.sh <app_ios_dir>   e.g. runs/2026-06-14_0613-UTC/06-nonet/ios
set -uo pipefail
d="${1:?usage: audit.sh <app_ios_dir>}"
app=$(basename "$(ls -d "$d"/*/ 2>/dev/null | grep -vi xcodeproj | grep -vi 'Preview Content' | head -1)")
src="$d/$app"
echo "=== AUDIT $app ($src) ==="

echo "-- swift file count --"
find "$src" -name '*.swift' | wc -l

echo "-- anti-stub grep (want ZERO) --"
grep -rniE "TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|// stub|unimplemented" "$src" --include='*.swift' || echo "  clean"

echo "-- force ops on user paths (want only the in-memory container try!) --"
grep -rnE "try!|fatalError|as!|\.unsafelyUnwrapped" "$src" --include='*.swift' || echo "  none"
echo "-- force-unwrap '!' suspects (manual review; ignore '!=' and bool '!') --"
grep -rnE "[a-zA-Z0-9_\)\]]\![^=]" "$src" --include='*.swift' | grep -vE "!=|return !|if !|guard !|, !|\(!|\\s!\\w" | head -40 || echo "  none obvious"

echo "-- @Observable + @StateObject mix check (should be empty) --"
obs=$(grep -rl "@Observable" "$src" --include='*.swift' 2>/dev/null)
if [ -n "$obs" ]; then echo "  files using @Observable:"; echo "$obs"; grep -rn "@StateObject\|@EnvironmentObject" $obs 2>/dev/null | head; else echo "  no @Observable macro used"; fi

echo "-- @main count (want 1) --"
grep -rn "@main" "$src" --include='*.swift' | wc -l

echo "-- brace/paren balance per file --"
python3 - "$src" <<'PY'
import sys, os, re
root=sys.argv[1]; bad=0
for dp,_,fs in os.walk(root):
    for f in fs:
        if not f.endswith('.swift'): continue
        p=os.path.join(dp,f); s=open(p,encoding='utf-8',errors='replace').read()
        # crude: ignore braces/parens inside string & char literals & comments is hard; just count raw
        for ch_open,ch_close,nm in [('{','}','brace'),('(',')','paren'),('[',']','bracket')]:
            o=s.count(ch_open); c=s.count(ch_close)
            if o!=c:
                print(f"  IMBALANCE {nm} {o}/{c}: {os.path.relpath(p,root)}"); bad+=1
if not bad: print("  balanced (raw count)")
PY

echo "-- project.yml / Info.plist / icon present --"
[ -f "$d/project.yml" ] && echo "  project.yml ok" || echo "  MISSING project.yml"
[ -f "$src/Info.plist" ] && echo "  Info.plist ok" || echo "  MISSING Info.plist"
ic="$src/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
[ -f "$ic" ] && file "$ic" || echo "  MISSING icon"

echo "-- README present --"
[ -f "$(dirname "$d")/README.md" ] && echo "  README ok ($(wc -l < "$(dirname "$d")/README.md") lines)" || echo "  MISSING README"

echo "-- JSON validity (asset Contents.json) --"
python3 - "$src" <<'PY'
import sys,os,json
root=sys.argv[1]; bad=0
for dp,_,fs in os.walk(root):
    for f in fs:
        if f.endswith('.json'):
            p=os.path.join(dp,f)
            try: json.load(open(p))
            except Exception as e: print("  BAD JSON",os.path.relpath(p,root),e); bad+=1
if not bad: print("  all json ok")
PY
echo "=== done $app ==="
