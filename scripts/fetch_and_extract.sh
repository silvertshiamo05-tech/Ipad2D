#!/usr/bin/env bash
# Download the official Cubism Editor macOS installer and extract it for
# inspection. Works on Linux and on Android/Termux (needs: curl, python3,
# gzip, cpio). Nothing proprietary is written inside this repository.
#
# Usage: scripts/fetch_and_extract.sh [version] [workdir]
#   version  default 5.3.04  (URL scheme taken from live2d.com download.js)
#   workdir  default ./_work (git-ignored)
set -euo pipefail
VER="${1:-5.3.04}"
WORK="${2:-$(pwd)/_work}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$WORK/dl/Live2D_Cubism_Setup_${VER}_arm64.pkg"

mkdir -p "$WORK/dl"
if [ ! -f "$PKG" ]; then
  # Downloading means you accept the Live2D Software License Agreement:
  # https://www.live2d.com/eula/live2D-editor-software-license-agreement_en.html
  curl -fSL -o "$PKG" \
    "https://cubism.live2d.com/editor/bin/Live2D_Cubism_Setup_${VER}_arm64.pkg"
fi
sha256sum "$PKG"

# 1. outer xar container (libarchive mangles names on this pkg)
python3 -I "$HERE/tools/xar_extract.py" "$PKG" "$WORK/xar" >/dev/null
# 2. inner gzip+cpio payload -> the files that land in /Applications/Live2D Cubism 5.3
mkdir -p "$WORK/payload"
( cd "$WORK/payload" &&
  gzip -dc "$WORK/xar/Live2D_Cubism.pkg/Payload" | cpio -idm --no-absolute-filenames )
echo "extracted to $WORK/payload"
ls "$WORK/payload"
