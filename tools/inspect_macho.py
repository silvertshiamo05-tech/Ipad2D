#!/usr/bin/env python3
"""Report platform, min OS, linked libraries, and JNI exports of Mach-O files.

Answers, per binary: which Apple platform it was built for (macOS vs iOS),
which system frameworks it needs, and which JNI entry points it exposes.

Usage: inspect_macho.py <file> [<file> ...]
"""
import sys
import lief

PLATFORMS = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 6: "MacCatalyst",
             7: "iOS-sim"}


def describe(binary):
    out = []
    cpu = str(binary.header.cpu_type).split(".")[-1]
    plat, minos = "?", "?"
    for cmd in binary.commands:
        t = str(cmd.command).split(".")[-1]
        if t == "BUILD_VERSION":
            plat = PLATFORMS.get(int(cmd.platform), str(cmd.platform))
            minos = ".".join(map(str, cmd.minos))
        elif t == "VERSION_MIN_MACOSX":
            plat, minos = "macOS", ".".join(map(str, cmd.version))
        elif t == "VERSION_MIN_IPHONEOS":
            plat, minos = "iOS", ".".join(map(str, cmd.version))
    out.append("  arch=%s platform=%s minos=%s" % (cpu, plat, minos))
    for lib in binary.libraries:
        out.append("  needs  " + lib.name)
    jni = sorted(s.name for s in binary.exported_symbols
                 if s.name.startswith("_Java_") or s.name.startswith("_JNI_"))
    out.append("  exports: %d JNI, %d total" % (len(jni), len(binary.exported_symbols)))
    for s in jni[:400]:
        out.append("    " + s)
    return out


def main():
    for path in sys.argv[1:]:
        print("== " + path)
        fat = lief.MachO.parse(path)
        if fat is None:
            print("  not Mach-O")
            continue
        for b in fat:
            print("\n".join(describe(b)))


if __name__ == "__main__":
    main()
