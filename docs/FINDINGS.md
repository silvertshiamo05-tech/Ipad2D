# Cubism Editor → iPadOS: inspection and first experiment

Date: 2026-10-16. Subject: official installer
`Live2D_Cubism_Setup_5.3.04_arm64.pkg`
(sha256 `2ee1c534aeb3d671be8278d2a34d41f4d82acfb3fe1ed9216bec76d36f2fd75b`),
downloaded from the URL scheme in live2d.com's own `download.js`. No installer
was supplied with the task, so the public one was used. Everything below was
measured on that file; the commands are in `scripts/` and `tools/`.

## 1. What the application actually is

| Item | Finding | How measured |
|---|---|---|
| Version | 5.3.04 (build 503040001, 2026-09-03) | `Distribution`, `Info.plist`, startup log |
| Package | flat pkg (xar) → gzip+cpio payload, installs to `/Applications/Live2D Cubism 5.3` | `tools/xar_extract.py` |
| Architecture | **Java application.** `CubismEditor` (180 KB arm64 Mach-O) is only a jpackage-style launcher | `Info.plist` `JVMMainClassName`, `res/CubismEditor.cfg` |
| Main class | `com.live2d.cubism.CECubismEditorApp` (Kotlin + Java) | cfg, stack traces |
| Bytecode | class file v61 = Java 17; 17,081 classes in `Live2D_Cubism.jar` (42 MB), obfuscated, jar signed (`GMO-CODE.RSA`) | `unzip -l`, `javap` |
| Bundled JRE | OpenJDK 17.0.3.1, includes JavaFX modules | `jre/Contents/Home/release` |
| UI toolkit | **Swing** + FlatLaf 3.2.2. JavaFX only in a few dialogs and an embedded browser | `jdeps` |
| Graphics | **JOGL 2.4.0 (stock upstream build, commit 7982cc5)**, desktop **OpenGL 3.2+ core**, GLSL `#version 150` (80 shaders) and `330` (6) | jar manifest, constant-pool strings |
| Java2D | Metal pipeline on macOS (`-Dsun.java2d.metal=true`) | cfg |
| Licensing | **Reprise License Manager (RLM)** `rlm1603.jar` + native `librlm1603.jnilib`; installer creates `/Library/Application Support/Reprise` | `res/`, preinstall script |
| Other deps | Kotlin 1.7, log4j 2.17.1, ONNX Runtime 1.13 (AI features, CoreML), JPen (tablet), ffmpeg (`tools/`), Java-WebSocket, audio SPIs | `res/`, cfg |

### Native libraries (all built for **macOS**, none for iOS)

| Library | Platform / min OS | Links | Role |
|---|---|---|---|
| `libLive2DCubismCoreJNI.dylib` | macOS 15.0 arm64 | AppKit, libc++ | JNI wrapper around Cubism Core (moc3 runtime), 14 JNI functions |
| `libLive2DCubismMotionSyncJNI.dylib` (+ `_CRI` engine) | macOS 13 | AppKit | lip-sync |
| `libLive2DCubismPFUtilsJNI.dylib` | macOS 12 | AppKit, ApplicationServices | 2 functions: macOS accessibility prefs |
| `librlm1603.jnilib` | macOS 12 arm64 | **CoreWLAN**, Foundation | license manager client (142 JNI exports) |
| `libonnxruntime*.dylib` | macOS 11 | CoreML | AI auto-mesh/segmentation |
| JOGL/gluegen/nativewindow | universal x86_64+arm64 | AppKit/OpenGL.framework | GL context on NSOpenGL |

`tools/inspect_macho.py` prints this table's data.

### Where the editor logic lives

`jdeps -verbose:package` over the jar + `tools/desktop_coupling.py`:

* 793 packages; only **57** are free of AWT/Swing/JOGL/JavaFX/RLM even
  transitively. The model/document layer (`com.live2d.cubism.doc`, 196
  packages) has 98 packages that use AWT/Swing directly.
* The moc3 **Cubism Core is only used by the viewer/animation side**. Modeling
  (ArtMesh, deformers, keyforms, parameters, parts) is pure Java inside the
  jar. So the official Cubism SDK covers the *runtime*, never the editor.
* GL is concentrated in `com.live2d.graphics3d.*` plus one AWT wrapper
  (`graphics3d.view.glWrapper` → `com.jogamp.opengl.awt`).

Conclusion: there is no separable "editor core" to lift out from under the
Swing UI; the realistic way to keep the real editor is to run its unmodified
bytecode on a JVM that has substitutes for its platform layers.

## 2. Experiment 01 — is the editor's Java code platform-portable?

Script: `experiments/01-jvm-portability/run_editor_linux.sh`.
Setup: unmodified jars from the macOS pkg, Linux x86_64, OpenJDK 17 / 21,
Xvfb + Mesa llvmpipe (GL 4.5 core), JOGL 2.4.0 **Linux** natives from
jogamp.org substituted for the macOS ones. No class or jar was modified.

Result:

```
Live2D Cubism Editor ver5.3.04  [ 503040001 / 2026/09/03]
---------- OpenGL Environment ----------
 Version    : 4.5 (Core Profile) Mesa 25.2.8
 Renderer   : llvmpipe (LLVM 20.1.2, 256 bits)
window: "Live2D Cubism Editor 5.3.04    [ Unregistered ]  - Undefined"  1440x800
```

The complete editor main window (menus, Modeling workspace, Part/Deformer/
Parameter/Inspector palettes, canvas toolbar) was built and painted, and
JOGL created its GL 3.x+ core context. **The application's Java code, Swing UI
and GL setup ran on a non-Apple JVM with only the native layer swapped.**

Then a modal error appeared: *"Unfortunately, an error occurred during
startup."* Thread dump + `javap` show why:

1. `CECubismEditorApp.a(String[])` computes a hash of the license-manager
   files for the detected OS and compares it with an expected value.
   Entries: `MAC_JAR res/rlm1603.jar`, `MAC_ARM_JNILIB res/librlm1603.jnilib`,
   `MAC_INTEL_JNILIB …`, `WIN_JAR \lib\rlm1603.jar`, `WIN_DLL \dll64\rlm1603.dll`.
2. Mismatch → error `CUBI-0337` → `System.exit`.
3. Only after that: `command_loginApplication` (RLM license login), then
   update check, then opening files.

Any OS that is not macOS is treated as Windows, so on Linux it looked for the
Windows RLM files, which don't exist. This happens before the license dialog
for both FREE and PRO use.

(Spoofing `os.name` as macOS was tried once as an honest test of the macOS
check path; it breaks earlier on the Aqua look-and-feel and wasn't pursued.)

## 3. What this means for iPadOS

Requirements for running the real editor on iPadOS, and their status:

| Layer | What's needed on iPadOS | Status |
|---|---|---|
| Java 17 VM | an iOS arm64 OpenJDK 17 build | **Exists**: the Amethyst / PojavLauncher-iOS project ships one (used to run Minecraft Java Edition on iPads). Without JIT it only interprets; JIT needs a debugger-attach tool (e.g. StikDebug) and depends on the iPadOS version. Needs checking on your iPad. |
| AWT/Swing | AWT peers that draw into an offscreen buffer shown in a UIView | **Feasible**: Caciocavallo is the established way (PojavLauncher uses it for Swing installers). Not yet tested with this editor. |
| OpenGL 3.2 core + GLSL 150/330 | iPadOS has only GLES 3.0 (deprecated) and Metal | **Feasible**: Mesa Zink over MoltenVK gives desktop GL 4.x on Metal; Amethyst ships it. JOGL needs a new native backend for that context (no AWT GLCanvas on iOS). |
| Cubism Core JNI, MotionSync, PFUtils | iOS builds | Core: rewrite the 14-function JNI wrapper against the official Native SDK's iOS Core library. PFUtils: trivial stub. MotionSync: needs Live2D's iOS engine. |
| **RLM license library + integrity check** | an iOS build of `librlm1603`, loadable and **byte-identical** to what the check expects | **Blocked.** The only build is a macOS Mach-O that needs CoreWLAN; iOS's dyld refuses macOS-platform binaries; and sideloading re-signs every bundled binary, which changes the hashed bytes. Getting past this would mean altering or bypassing the license/integrity check, which this project won't do. |

**Verdict.** Technically, the real editor's code is portable: experiment 01
shows it runs unmodified once its native layer is swapped out. A real
recompilation isn't possible because the source isn't available, and an
Intel/ARM translation layer isn't needed because the code is JVM bytecode.
What actually stops it is legal and contractual: a licensed iPad build
**needs Live2D to ship (or approve) an iOS-compatible license component.**
Without that, the original editor can't legitimately start on iPadOS.

For the same reason, the editor's proprietary classes can't be reused inside a
separate iPad app: calling the model/editing code without going through
`CECubismEditorApp`'s check and license login would bypass the license.

## 4. Legitimate paths forward

1. **Ask Live2D** (the only route to the *actual* editor on iPad): send the
   evidence in §2. What would unblock it is either an iOS RLM client / an
   alternative licensing mode they support, or official approval of a
   specific method. All the other layers have known solutions.
2. **Clean-room iPad editor** built on Live2D's *official, redistributable*
   pieces: the Cubism SDK for Native (iOS + Metal renderer) for rendering and
   deforming models, plus a newly written editor for meshes, deformers,
   parameters and keyforms. This is a different product: it would not be the
   original editor, compatibility with `.cmo3` would have to be
   reverse-engineered from the file format, and it would take months.
3. Remote desktop to a licensed Mac/PC: works today, but you ruled it out.

Native-SDK-based work (path 2, and the Core JNI shim in path 1) can be built
for iOS with GitHub Actions `macos-*` runners, triggered from a phone. The
result can be installed with AltStore/SideStore (free Apple ID, 7-day
re-sign) or a paid developer account. None of this has been done yet.
