#!/usr/bin/env bash
# Experiment 01: run the ORIGINAL, unmodified Cubism Editor bytecode (taken
# from the official macOS arm64 installer) on a non-Apple JVM, with every
# macOS-only native library replaced by another platform's equivalent.
#
# What this proves (or disproves): whether the editor's Java code is
# platform-portable once its native layer is substituted. That is exactly the
# property an iPadOS port that keeps the original editor depends on.
#
# Inputs (env):
#   CUBISM_RES    extracted <install>/res directory (see scripts/extract_pkg.sh)
#   JOGL_NATIVES  directory with libgluegen_rt.so, libjogl_desktop.so, ...
#   JAVA_HOME     a JDK 17 (the editor bundles Java 17.0.3)
#   EXTRA_CP      optional extra classpath (e.g. OpenJFX jars)
#   EXTRA_OPTS    optional extra JVM options
set -euo pipefail

: "${CUBISM_RES:?set CUBISM_RES to the extracted res/ directory}"
: "${JOGL_NATIVES:?set JOGL_NATIVES}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"

# Classpath in the exact order of the official launcher config.
CP=$(grep '^app.classpath=' "$CUBISM_RES/CubismEditor.cfg" \
       | sed "s#^app.classpath=\$APPDIR#$CUBISM_RES#" | paste -sd:)
MAIN=$(grep '^app.mainclass=' "$CUBISM_RES/CubismEditor.cfg" | cut -d= -f2)

# JVM options from the official launcher, minus macOS-only ones
# (-Xdock, sun.java2d.metal).
exec "$JAVA_HOME/bin/java" \
  -Djava.library.path="$JOGL_NATIVES" \
  -Djogamp.gluegen.UseTempJarCache=false \
  -Djava.locale.providers=COMPAT,SPI \
  -XX:MaxRAMPercentage=50 \
  -Dsun.java2d.opengl=false \
  ${EXTRA_OPTS:-} \
  -cp "$CP${EXTRA_CP:+:$EXTRA_CP}" "$MAIN" "$@"
