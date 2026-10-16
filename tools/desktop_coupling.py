#!/usr/bin/env python3
"""Measure how coupled each package of a jar is to desktop-only Java APIs.

Input: output of `jdeps -verbose:package -q <jar>` (see scripts/analyze_jar.sh).
For every package in the jar we report whether it references AWT/Swing,
JOGL, JavaFX or the RLM licensing classes directly, and whether it reaches
them transitively through other packages of the same jar.

"Desktop-only" here means: not available in any Java runtime that can be
shipped on iOS today without porting AWT/Java2D/Swing (see docs/FINDINGS.md).

Usage: desktop_coupling.py jdeps_pkg.txt [prefix-filter]
"""
import collections
import re
import sys

DESKTOP = {
    "awt/swing": re.compile(r"^(java\.awt|javax\.swing|sun\.awt|sun\.java2d|javax\.imageio|java\.applet|sun\.swing|com\.formdev\.flatlaf)"),
    "jogl": re.compile(r"^(com\.jogamp|jogamp)"),
    "javafx": re.compile(r"^javafx"),
    "rlm": re.compile(r"^com\.reprisesoftware"),
}

LINE = re.compile(r"^\s+(\S+)\s+->\s+(\S+)\s+(\S.*)?$")


def main():
    path = sys.argv[1]
    prefix = sys.argv[2] if len(sys.argv) > 2 else ""
    edges = collections.defaultdict(set)
    own = set()
    for line in open(path):
        m = LINE.match(line)
        if not m:
            continue
        src, dst, where = m.group(1), m.group(2), (m.group(3) or "")
        own.add(src)
        edges[src].add(dst)
    direct = {p: {k for k, rx in DESKTOP.items() if any(rx.match(d) for d in edges[p])}
              for p in own}

    # transitive closure restricted to packages inside the jar
    memo = {}

    def reach(p, stack=()):
        if p in memo:
            return memo[p]
        if p in stack:
            return set()
        acc = set(direct.get(p, ()))
        for d in edges[p]:
            if d in own:
                acc |= reach(d, stack + (p,))
        memo[p] = acc
        return acc

    # iterate twice so cycles converge
    for _ in range(2):
        memo.clear()
        for p in own:
            reach(p)

    pkgs = sorted(p for p in own if p.startswith(prefix))
    clean_direct = [p for p in pkgs if not direct[p]]
    clean_trans = [p for p in pkgs if not memo[p]]
    print("packages: %d  direct-desktop-free: %d  transitively-desktop-free: %d"
          % (len(pkgs), len(clean_direct), len(clean_trans)))
    for kind in DESKTOP:
        print("  directly uses %-10s %d" % (kind, sum(kind in direct[p] for p in pkgs)))
    print()
    print("%-60s %-28s %s" % ("package", "direct", "transitive"))
    for p in pkgs:
        print("%-60s %-28s %s" % (p, ",".join(sorted(direct[p])) or "-",
                                  ",".join(sorted(memo[p])) or "-"))


if __name__ == "__main__":
    main()
