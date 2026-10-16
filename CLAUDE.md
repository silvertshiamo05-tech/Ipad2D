# Project memory — Ipad2D

## User context (persistent)
- **Can sideload IPAs onto the iPad.** Unsigned `.ipa` artifacts from CI are
  directly usable — no need to re-explain install routes each time. (Still
  confirm the method/iOS version only if an install actually fails.)
- **Has a PC, but it is low-end** — fine for basic tasks only. Do NOT assume it
  can run heavy toolchains (Xcode, large builds, Android Studio, JVM builds).
  Keep heavy compilation in the cloud (GitHub Actions) or in this session.
- **No Mac.** Primary device is an Android phone; the PC is a light secondary.
- Supersedes the older "no PC, Android only" note: there IS a PC, just weak.

## What this project is
Getting a Live2D Cubism editing experience onto an iPad (10th gen, A14).
Original Cubism Editor can't be shipped legitimately (RLM licence native lib
has no iOS build — see `docs/LICENSE-DIAGNOSIS.md`). Direction: a clean-room
iPad app, with `.cmo3` compatibility proven via Umamo.

## State (as of 2026-10-16)
- `docs/FINDINGS.md`, `docs/LICENSE-DIAGNOSIS.md` — why the original editor is blocked.
- `experiments/02-umamo-cmo3-roundtrip/` — Umamo losslessly round-trips 6 real
  `.cmo3` models (free + pro). `render_models.mjs` renders models via the
  official Cubism web runtime + headless Chromium.
- `ios/` + `.github/workflows/ios.yml` — SwiftUI app built to an **unsigned IPA**
  on GitHub Actions (`macos-15`, XcodeGen, no signing). Milestone 1 = hybrid
  Live2D canvas (WKWebView + official Cubism runtime; model fetched at build).
  **Next (task #3): native Metal renderer via the official Cubism iOS SDK**, then
  editing tools.

## Working notes
- Dev branch: `ccr-66c4129d-47wknl` (also the repo default). Repo is **public**
  → free unlimited macOS runners.
- Gradle/Maven here: Maven Central is rate-limited through the proxy; prefer the
  Google Maven mirror (`experiments/02-.../run_roundtrip.sh` sets it up).
- Proprietary/redistributable assets are never committed (see `.gitignore`);
  CI fetches runtime libs + the free sample model at build time.
- Clean-room rule: Umamo forbids contributions from anyone exposed to decompiled
  Cubism binaries. This project DID decompile the editor for diagnosis, so keep
  any Umamo-bound contribution clean of that; our own iOS app is unaffected.
