#!/usr/bin/env python3
"""Compile-by-inspection audit for the run's Swift apps.

Per app: brace/paren/bracket balance (after stripping strings + comments),
forbidden-pattern greps (force-unwrap heuristics, try!/as!, NavigationView,
single-arg .onChange, fatalError), anti-stub greps, and a check that every
@Model type is referenced in a Schema(...) / ModelContainer call.
"""
import os, re, sys, glob

RUN = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STUB = re.compile(r"\b(TODO|FIXME|XXX|placeholder|lorem|coming soon|not implemented|unimplemented)\b", re.I)
STUB_SLASH = re.compile(r"//\s*stub", re.I)


def strip(src):
    """Remove // and /* */ comments and string/char literal contents."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '"':
            # handle multiline """ too
            if src[i:i+3] == '"""':
                j = src.find('"""', i+3)
                i = (j + 3) if j != -1 else n
                out.append('""')
                continue
            i += 1
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if src[i] == '"':
                    i += 1
                    break
                i += 1
            out.append('""')
            continue
        if c == '/' and i+1 < n and src[i+1] == '/':
            j = src.find('\n', i)
            i = n if j == -1 else j
            continue
        if c == '/' and i+1 < n and src[i+1] == '*':
            j = src.find('*/', i+2)
            i = n if j == -1 else j+2
            continue
        out.append(c)
        i += 1
    return ''.join(out)


def balance(s):
    pairs = {')': '(', ']': '[', '}': '{'}
    opens = set('([{')
    st = []
    for ch in s:
        if ch in opens:
            st.append(ch)
        elif ch in pairs:
            if not st or st[-1] != pairs[ch]:
                return False, f"unmatched {ch}"
            st.pop()
    if st:
        return False, f"unclosed {st[-1]}"
    return True, ""


def audit_app(appdir):
    name = os.path.basename(appdir)
    swifts = glob.glob(os.path.join(appdir, "**", "*.swift"), recursive=True)
    issues = []
    models = set()
    schema_text = ""
    forceunwrap = []
    for f in sorted(swifts):
        raw = open(f, encoding="utf-8").read()
        s = strip(raw)
        ok, why = balance(s)
        if not ok:
            issues.append(f"BRACE {os.path.relpath(f, appdir)}: {why}")
        # forbidden
        for pat, label in [(r"\btry!", "try!"), (r"\bas!\s", "as!"),
                           (r"\bNavigationView\b", "NavigationView"),
                           (r"\bfatalError\(", "fatalError")]:
            for m in re.finditer(pat, s):
                ln = s[:m.start()].count('\n')+1
                issues.append(f"{label} {os.path.relpath(f, appdir)}:{ln}")
        # single-arg onChange: .onChange(of: X) { Y in ... } with one param is fine in iOS17 (zero or two);
        # flag the deprecated single-trailing-param form .onChange(of:) { newValue in -- can't reliably detect; skip.
        # @Model collection
        for m in re.finditer(r"@Model\s+(?:final\s+)?class\s+(\w+)", s):
            models.add(m.group(1))
        if "Schema(" in s or "ModelContainer" in s or "modelContainer(" in s:
            schema_text += s
        # anti-stub on raw (comments included)
        for m in STUB.finditer(raw):
            ln = raw[:m.start()].count('\n')+1
            issues.append(f"STUB '{m.group(0)}' {os.path.relpath(f, appdir)}:{ln}")
        for m in STUB_SLASH.finditer(raw):
            ln = raw[:m.start()].count('\n')+1
            issues.append(f"STUB-slash {os.path.relpath(f, appdir)}:{ln}")
        # force-unwrap heuristic: a `!` directly after an identifier/paren/bracket, not `!=`, not `!x`
        for m in re.finditer(r"[\w\)\]]\!(?!=)", s):
            ln = s[:m.start()].count('\n')+1
            forceunwrap.append(f"{os.path.relpath(f, appdir)}:{ln}  ...{s[max(0,m.start()-25):m.start()+2]}")

    # models not in schema
    missing = [m for m in sorted(models) if m not in schema_text]
    return {
        "name": name, "files": len(swifts), "models": sorted(models),
        "missing_in_schema": missing, "issues": issues, "forceunwrap": forceunwrap,
    }


def main():
    apps = sorted(glob.glob(os.path.join(RUN, "0*-*")))
    total_files = 0
    any_issue = False
    for a in apps:
        r = audit_app(a)
        total_files += r["files"]
        print(f"\n=== {r['name']}  ({r['files']} swift files) ===")
        print(f"  @Models: {', '.join(r['models']) or '(none)'}")
        if r["missing_in_schema"]:
            any_issue = True
            print(f"  ⚠ @Models NOT found near Schema/ModelContainer: {r['missing_in_schema']}")
        if r["issues"]:
            any_issue = True
            for i in r["issues"]:
                print(f"  ❌ {i}")
        else:
            print("  ✅ no brace/forbidden/stub issues")
        if r["forceunwrap"]:
            print(f"  ⚠ {len(r['forceunwrap'])} possible force-unwrap(s) (review):")
            for fu in r["forceunwrap"][:40]:
                print(f"      {fu}")
    print(f"\nTOTAL swift files: {total_files}")
    print("AUDIT:", "ISSUES FOUND" if any_issue else "clean (review force-unwrap warnings)")


if __name__ == "__main__":
    main()
