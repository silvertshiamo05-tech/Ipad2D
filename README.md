# Ipad2D — Live2D Cubism Editor on iPadOS (investigation)

Goal: get the real Live2D Cubism Editor running on an iPad 10th gen, without
a Mac and without circumventing licensing.

**Current status:** see [`docs/FINDINGS.md`](docs/FINDINGS.md). Short version:
the editor (5.3.04) is a Java 17 Swing + JOGL application. Its unmodified
bytecode runs on a non-Apple JVM with substituted natives, and the full main
window renders. Startup then stops at a hash check of the macOS/Windows-only
RLM license library. That component has no iOS equivalent, and getting past
the check would mean circumventing licensing, so a real iPad port of the
original editor needs Live2D's involvement.

## Layout

| Path | What |
|---|---|
| `scripts/fetch_and_extract.sh` | download the official macOS pkg and unpack it (Linux/Termux) |
| `tools/xar_extract.py` | dependency-free `.pkg` (xar) extractor |
| `tools/inspect_macho.py` | Mach-O platform / min-OS / linked frameworks / JNI exports (needs `pip install lief`) |
| `tools/desktop_coupling.py` | per-package AWT/Swing/JOGL/JavaFX/RLM coupling from `jdeps` output |
| `experiments/01-jvm-portability/` | run the original editor bytecode on Linux with JOGL Linux natives |
| `experiments/02-umamo-cmo3-roundtrip/` | build Umamo's CLI and prove it round-trips a real `.cmo3` (experiment 02) |
| `ios/` | iPad app (SwiftUI shell + hybrid Live2D canvas) built to an unsigned IPA by GitHub Actions |
| `.github/workflows/ios.yml` | macOS CI: builds + packages the unsigned `.ipa` artifact |
| `docs/INSTALL.md` | how to sign/install the IPA on your iPad (TrollStore / SideStore) |

Proprietary Live2D files are never committed (`.gitignore`); everything is
extracted into `_work/`.

## Reproduce (Linux; Termux works for steps 1–3)

```sh
scripts/fetch_and_extract.sh 5.3.04 _work
pip install lief && python3 tools/inspect_macho.py _work/payload/res/*.dylib _work/payload/res/*.jnilib
cd _work/payload/res && jdeps -verbose:package -q \
   -cp "$(ls *.jar | grep -v Live2D_Cubism.jar | paste -sd:)" Live2D_Cubism.jar > ../../jdeps.txt
cd - && python3 tools/desktop_coupling.py _work/jdeps.txt com.live2d.cubism.doc | head
# experiment 01 (needs Xvfb, Mesa, OpenJDK 17, JOGL 2.4.0 linux-amd64 natives from
# https://jogamp.org/deployment/v2.4.0/jar/ unpacked into _work/jogl)
Xvfb :99 -screen 0 1920x1200x24 +extension GLX &
DISPLAY=:99 APPDATA=$PWD/_work/appdata CUBISM_RES=$PWD/_work/payload/res \
  JOGL_NATIVES=$PWD/_work/jogl JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
  experiments/01-jvm-portability/run_editor_linux.sh
```
