#!/usr/bin/env bash
# Experiment 02: does Umamo (the open-source, clean-room Cubism Editor
# replacement that is the realistic iPad path) genuinely read and round-trip a
# real Cubism .cmo3 editor project? If yes, the iPad goal — "an editor that
# opens my existing Live2D projects, with no licence gate" — is reachable
# through a route that touches no one's DRM.
#
# This builds Umamo's lightweight :cli (dump / convert / diff) and runs it
# against a .cmo3. Works on Linux; the same commands work on Android/Termux
# with a JDK 21 (building Compose/LWJGL desktop UI does not, but the CLI does).
#
# Usage: run_roundtrip.sh <model.cmo3> [workdir]
#   Get a free, licensed test model from Live2D's official sample page
#   (Free Material License), e.g. the Hiyori sample's hiyori_free_t08.cmo3.
set -euo pipefail
CMO3="${1:?pass a path to a .cmo3 file}"
WORK="${2:-$(pwd)/_work}"; mkdir -p "$WORK"; WORK="$(cd "$WORK" && pwd)"
CMO3="$(cd "$(dirname "$CMO3")" && pwd)/$(basename "$CMO3")"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"

# Umamo checkout (shallow).
UM="$WORK/umamo"
[ -d "$UM/.git" ] || git clone --depth 1 https://github.com/umamoorg/umamo.git "$UM"

# This environment reaches Maven Central through a proxy that Central
# rate-limits (429), which poisons Gradle's lookup cache. Prefer Google's
# un-throttled Maven Central mirror, applied to the root build and every
# includeBuild. Harmless elsewhere; drop --init-script if you have clean access.
INIT="$WORK/mirror.init.gradle"
cat > "$INIT" <<'EOF'
def gmirror = "https://maven-central.storage-download.googleapis.com/maven2"
beforeSettings { settings ->
    settings.pluginManagement { repositories { maven { url gmirror }; gradlePluginPortal(); google(); mavenCentral() } }
    settings.dependencyResolutionManagement { repositories { maven { url gmirror }; google(); mavenCentral() } }
}
EOF

cli() { ( cd "$UM" && ./gradlew -q --console=plain --init-script "$INIT" --no-configuration-cache :cli:run --args="$*" ) ; }

base="$(basename "${CMO3%.*}")"
RT="$WORK/${base}.roundtrip.cmo3"
MOC="$WORK/${base}.umamo.moc3"

echo "## dump (does Umamo parse the editor project?)"
cli "dump $CMO3" | grep -E '^# (versions|imports)' | head -2

echo "## round-trip: .cmo3 -> .cmo3, then semantic diff vs original"
cli "convert $CMO3 $RT" >/dev/null
echo -n "   original vs round-trip: "; cli "diff $CMO3 $RT"

echo "## export runtime: .cmo3 -> .moc3"
cli "convert $CMO3 $MOC" >/dev/null && ls -l "$MOC" | awk '{print "   wrote "$5" bytes"}'

echo "Done. Outputs in $WORK"
