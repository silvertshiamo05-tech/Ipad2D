# Licence-startup failure: diagnosis

Date 2026-10-16. Scope: *only* the licence-related startup failure, per request.
All evidence is from the 5.3.04 arm64 package already extracted in earlier work
(`_work/payload`), reproduced on a non-Apple JVM (the stand-in for the iPad JVM).

## 1. Precise cause

There are **two** licence gates on the startup path, in this order, and **both
require the macOS-only native RLM client**:

```
CECubismEditorApp.a(String[])
  ├─ gate 1: integrity check of the RLM files for the detected OS   → CUBI-0337 → System.exit
  └─ gate 2: CEAppCtrl.command_loginApplication()  (the real RLM activation/login)
```

* **This is not a normal, usable activation screen.** On any OS that is not
  macOS, the code classifies the platform as Windows and looks for the Windows
  RLM files (`\lib\rlm1603.jar`, `\dll64\rlm1603.dll`), which do not exist, so
  **gate 1 fails first** and shows a dead-end modal: *"Unfortunately, an error
  occurred during startup."* Dismissing it calls `System.exit` — the app does
  **not** wait for user interaction and does **not** crash; it exits cleanly.
* If a port forces `os.name=Mac` (or otherwise passes gate 1), startup reaches
  **gate 2**, which must load `librlm1603` to compute the device id and perform
  activation. That library **cannot load on a non-macOS runtime** (see §3), so
  activation can never complete. Same blocker, one gate later.

So the licence request the port is showing is real, but it sits **behind a
component that cannot initialise on iPadOS** — it is not a missing network,
missing account, or wrong licence key.

## 2. The relevant evidence

Dialog raised here (thread dump, `_work`/run2):

```
at javax.swing.JOptionPane.showMessageDialog(JOptionPane.java:677)
at com.live2d.util.UUOption.a(Unknown Source)
at com.live2d.cubism.CECubismEditorApp.a(Unknown Source)   <- licence gate
at com.live2d.cubism.H.invoke / com.live2d.util.aD.f       <- startup runnable
```

Native-load reproduction on a non-macOS JVM (what iPadOS' dyld also does to a
macOS Mach-O):

```
$ java LoadRlm .../librlm1603.jnilib
LOAD FAILED: java.lang.UnsatisfiedLinkError
  -> librlm1603.jnilib: invalid ELF header
```

No iOS build of the RLM client ships anywhere in the package:

```
rlm1603.jar        (pure Java wrapper)
librlm1603.jnilib  platform=macOS      <- only native build present
```

## 3. What legitimate activation actually requires (and why it breaks on iPad)

The licensing is **Reprise License Manager (RLM) ISV activation** — a
documented commercial product. From the RLM jar API (`RlmActHandle`,
`RlmActInfo`) and strings in the native library:

| Requirement | Evidence | iPadOS status |
|---|---|---|
| **Native RLM client** `librlm1603` to build the signed activation request and read the device id | `RlmActHandle.activate`, `_act_request()` | **Blocker.** Only a macOS arm64 Mach-O exists; iOS dyld refuses macOS-platform binaries. No iOS build in the package. |
| **HTTPS** to an activation server (not a browser/OAuth flow) | `https://`, `unencrypted activation requests not allowed`, `Bad HTTP transaction with activation server`, `hostid=%s&extra=%s&time=%lx&` | OK on iPadOS — plain HTTPS, no embedded browser or special TLS needed. |
| **Device identifier (hostid)** | native strings `ether`, `uuid`, `user`, `host`, `disksn`; `Can't get ethernet address`; links **CoreWLAN** | **Blocker.** macOS binds to `ether` (the MAC address, read via CoreWLAN). iOS has no CoreWLAN and returns a fixed dummy MAC, so even a recompiled client could not produce the `ether` hostid Live2D's server expects. |
| OS credential store / keychain | none referenced | Not used. |

So the failing dependency is specifically the **native RLM client library plus
its macOS device-id source**, not a desktop UI API, not networking, and not the
user's licence itself.

## 4. Can it be made iPadOS-compatible, and what was tested

* **Can I substitute or re-implement it?** No — not without compromising the
  licence mechanism. Making activation "succeed" by stubbing `librlm1603`,
  faking a hostid, or patching gate 1/gate 2 is exactly the forging / bypass
  the task forbids, and it would also be an invalid licence state.
* **What a legitimate fix requires (vendor dependency):** an **iOS arm64 build
  of the RLM client from Reprise/Live2D**, *and* Live2D configuring an
  iOS-viable hostid type (e.g. `uuid`/`user` instead of `ether`, since the MAC
  is unreadable on iOS). Both are things only the vendor can provide; the HTTPS
  activation transport already works on iPadOS, so nothing else on the licence
  path needs porting.

**Result of the targeted test:** the precise failing component is confirmed to
be `librlm1603` (macOS-only, unloadable off macOS, no iOS variant shipped).
Licence initialisation therefore **cannot pass on the port as it stands**, and
cannot be made to pass by any change on our side that stays within legitimate
licensing. The single actionable next step is a vendor request (drafted in
`docs/FINDINGS.md` §4, path 1) for an iOS RLM client / supported iOS activation
mode.

*Not pursued:* decoding the gate-1 expected hashes or altering gate 1/gate 2 —
that would be circumventing the check, which is out of scope by instruction.
