#!/usr/bin/env python3
"""
check-accessibility.py — analyse a uiautomator XML dump for accessibility issues.

Usage:
    python3 scripts/check-accessibility.py <ui_dump.xml> [package_filter]

Exits 1 if any clickable or focusable node is missing a text / content-desc label.
Called by scripts/check-accessibility.sh; can also be run standalone on a saved dump.
"""
import sys
import xml.dom.minidom

path       = sys.argv[1]
pkg_filter = sys.argv[2] if len(sys.argv) > 2 else ""

dom   = xml.dom.minidom.parseString(open(path).read())
nodes = dom.getElementsByTagName("node")

packages = sorted(set(n.getAttribute("package") for n in nodes) - {""})
print(f"Packages in dump: {', '.join(packages)}")

if pkg_filter:
    nodes = [n for n in nodes if pkg_filter in n.getAttribute("package")]
    print(f"Filtering to: {pkg_filter}  ({len(nodes)} nodes)")
print()

issues = []
for n in nodes:
    cls       = n.getAttribute("class")
    text      = n.getAttribute("text")
    desc      = n.getAttribute("content-desc")
    clickable = n.getAttribute("clickable") == "true"
    focusable = n.getAttribute("focusable") == "true"
    bounds    = n.getAttribute("bounds")
    label     = text or desc

    tag = []
    if clickable: tag.append("clickable")
    if focusable: tag.append("focusable")

    if tag:
        status = "OK" if label else "MISSING LABEL"
        print(f"  [{'/'.join(tag)}] {cls}")
        print(f"    text={repr(text)}  content-desc={repr(desc)}  bounds={bounds}")
        print(f"    --> {status}")
        print()
        if not label:
            issues.append(f"{cls} at {bounds} ({'/'.join(tag)})")

print("=" * 60)
if issues:
    print(f"ACCESSIBILITY ISSUES ({len(issues)}):")
    for i in issues:
        print(f"  - Missing label: {i}")
    sys.exit(1)
else:
    print("No accessibility issues found.")
