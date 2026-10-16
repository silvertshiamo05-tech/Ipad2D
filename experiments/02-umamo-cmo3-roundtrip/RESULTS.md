# Experiment 02 — Umamo reads and round-trips a real Cubism `.cmo3`

Date 2026-10-16. Goal: verify the claim behind the recommended iPad path —
that [Umamo](https://github.com/umamoorg/umamo) (open-source, GPL-3.0,
clean-room Cubism Editor replacement, Kotlin Multiplatform) genuinely opens
real Cubism projects. If it does, "a Cubism-compatible editor on iPad that
opens my files, with no licence gate" is reachable without touching anyone's
DRM.

## Setup

* Umamo `main` (977 commits at clone), built with its Gradle wrapper
  (Gradle 9.6.1) on OpenJDK 21. Only the `:cli` module (`dump`/`convert`/
  `diff`) was built — no UI needed for this test.
* Test models: official **Hiyori** sample from Live2D's sample-data CDN
  (free, Live2D Free Material License) — both `hiyori_free_t08.cmo3`
  (10.1 MB) and `hiyori_pro_t11.cmo3` (28.9 MB). Not committed (proprietary).
* Build note: Maven Central is rate-limited (HTTP 429) through this
  environment's proxy, which poisons Gradle's negative-lookup cache. Fixed by
  preferring Google's Maven Central mirror via an init script
  (`run_roundtrip.sh` creates it). First build 5m33s; `BUILD SUCCESSFUL`.

## Results

| Test | Command | Result |
|---|---|---|
| Parse editor project | `dump hiyori_free_t08.cmo3` | **Full parse.** Extracted all 86 embedded images incl. the 2048² atlas, and the model tree: ArtMeshes, rotation/warp/bezier deformers, parameters, parameter groups, parts, physics, filters, keyform grids. `SerializeFormatVersion=2`, `CModelSource=13`. |
| **Round-trip fidelity** | `convert … .cmo3 → .cmo3`, then `diff` | **`identical`** (semantic). FREE and PRO models both. |
| Round-trip stability | gen1 → gen2 `.cmo3`, `diff` | **`identical`** — no drift across generations. |
| Runtime export | `convert … .cmo3 → .moc3` | Wrote 236,544 B vs Live2D editor's own 236,480 B. One semantic notice: `ArtMesh36: SketchPartIsNotRuntimeContent`. |
| Export vs Live2D's own `.moc3` | `diff umamo.moc3 official.moc3` | 142 diff lines — **all non-geometric** (see below). |

### What differs in the `.moc3` export (vs Live2D's own exporter)

```
127  ~ [NAME]           display names on drawables/parameters (IDs match; only the human name differs)
  8  - parameterGroups  ParamGroupFace/Eyes/Brows/Mouth/Body/Arms/Sway … (editor organization)
  1  - part             PartBackground (a sketch/background part, not runtime content)
  1  ~ [document]        PARAMETER_ORDER/LINKS/TREE/ROOT_CHILDREN (parameter-tree ordering)
```

**Zero** differences in mesh geometry, vertices, deformers, or keyforms. The
rig itself is identical; the deltas are display names and editor-side
organization/ordering metadata. (The 82 "geometry-related" diff lines the
summary counted were every one just the `[NAME]` attribute of an `ArtMeshNN`,
not its mesh data.)

## Verdict

Umamo **losslessly round-trips real Cubism `.cmo3` projects** (free and pro),
and exports a structurally-equivalent `.moc3`. The `.cmo3` compatibility claim
is confirmed on real files. This is the concrete evidence that the clean-room
route delivers the actual goal — opening your existing Live2D projects in an
editor that has no RLM licence gate — unlike the original editor, which stops
at licence init on iPad (see `docs/LICENSE-DIAGNOSIS.md`).

## Broadened coverage (2026-10-16, follow-up)

Round-tripped four more official free samples (from Live2D's sample-data CDN,
Free Material License), `.cmo3 → .cmo3` semantic `diff`:

| Model | `.cmo3` | Round-trip |
|---|---|---|
| Hiyori (free + pro) | 10.1 / 28.9 MB | **identical** |
| Mao (pro) | 70.5 MB | **identical** |
| Natori (pro) | 19.0 MB | **identical** |
| Rice (pro) | 10.6 MB | **identical** |
| Mark (free) | 1.2 MB | **identical** |

Six project files across free and pro tiers, all lossless — the compatibility
result is not specific to one model.

### Screenshots

`render_models.mjs` renders each model from its runtime files using the
**official** Cubism Web Core + pixi-live2d-display under headless Chromium
(Playwright), served locally. These confirm the downloaded samples are intact,
good-quality models (the screenshots shared in-chat). This renderer is the
official runtime, separate from Umamo — it is for producing previews, not part
of the editor path.

## Honest limits of this experiment

* Covered the Hiyori/Mao/Natori/Rice/Mark samples. Still worth widening to more
  Cubism versions; Umamo states `.cmo3`/`.moc3` support "up to Cubism 5.4".
* This validates the **codec/`:cli`**, not the **editor UI** and not **iPad**.
  Umamo's own status: iPadOS "Application and UI loads, but there is no puppet
  renderer and JDOM is incompatible." Those two gaps — a GLES puppet renderer
  and replacing JDOM on iOS — are the real remaining engineering for an iPad
  build, and they are ordinary portability work, not a licence wall.
* `.moc3` name/group/ordering deltas mean Umamo's runtime export is not
  byte-for-byte Live2D's; fine for editing/round-trip, worth noting if exact
  runtime parity with the official exporter matters.
