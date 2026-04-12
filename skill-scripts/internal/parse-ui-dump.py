#!/usr/bin/env python3
"""
parse-ui-dump.py — print a readable summary of a uiautomator XML dump.

Usage:
    python3 scripts/parse-ui-dump.py <ui_dump.xml> [package_filter]

If package_filter is provided, only nodes whose package contains that string
are printed. Useful for verifying ui_state / adb shell uiautomator dump output.
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
else:
    print(f"Total nodes: {len(nodes)}")
print()

for n in nodes:
    cls       = n.getAttribute("class")
    text      = n.getAttribute("text")
    desc      = n.getAttribute("content-desc")
    clickable = n.getAttribute("clickable")
    focusable = n.getAttribute("focusable")
    bounds    = n.getAttribute("bounds")
    print(f"  {cls}")
    print(f"    text={repr(text)}  content-desc={repr(desc)}")
    print(f"    clickable={clickable}  focusable={focusable}  bounds={bounds}")
