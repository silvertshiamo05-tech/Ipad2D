# Installing the Ipad2D IPA on your iPad

The CI produces an **unsigned** `.ipa` (GitHub → Actions → latest "iOS build"
run → Artifacts → `Ipad2D-unsigned-ipa`). Unsigned means it must be signed
before iOS will run it. How you do that depends on your iPad's iOS version and
what hardware you have.

## The honest constraint (no PC)

Apple does not let you install an arbitrary `.ipa` by just tapping it. You need
one of the routes below. With **only an Android phone + the iPad** (no computer
at all), your options are limited:

| Route | Needs a computer? | Needs Apple ID? | Permanent? | Works on which iOS |
|---|---|---|---|---|
| **TrollStore** | **No** | No | Yes (permanent) | iOS 14.0–16.6.1, and 17.0 on some devices (via exploit) |
| SideStore | Once, for pairing setup | Yes (free) | 7-day re-sign (auto, over Wi-Fi after setup) | iOS 15–18 |
| AltStore | Yes (AltServer on PC/Mac, periodically) | Yes (free) | 7 days | iOS 15–18 |
| Apple Developer Program | Yes (a Mac/Xcode) | Paid ($99/yr) | 1 year | all |

**If your iPad is on a TrollStore-compatible iOS version, that's the only route
that needs no computer at all** — install TrollStore once, then open the `.ipa`
with it and the app is permanently signed, no Apple ID, no 7-day expiry.

iPad 10th gen shipped on iPadOS 16 and updates to 17/18. **Check Settings →
General → About → Software Version first** — that decides your route:
* **16.6.1 or below** → TrollStore (no computer needed). Best case.
* **17.0** → TrollStore may work on some units; otherwise SideStore.
* **17.1+** → no TrollStore; you'll need a computer once to set up SideStore,
  or a friend's PC/Mac.

## TrollStore (no computer) — if your iOS version supports it

1. Install TrollStore following the official guide for your exact iOS version
   (the TrollStore project documents which installer applies to which version).
2. Open TrollStore → **+** → pick `Ipad2D-unsigned.ipa`.
3. TrollStore signs and installs it permanently. Done.

## SideStore (needs a computer once for the pairing file)

1. On a computer (any OS) create the pairing file and install SideStore per its
   guide; after that initial step it runs on the iPad over Wi-Fi.
2. In SideStore → **+** → select `Ipad2D-unsigned.ipa` → it signs with your free
   Apple ID (re-signs every 7 days automatically while on the same network).

## Notes

* The IPA is built for iPhone + iPad, iOS 15+.
* It's a personal build for your own device — don't redistribute it with the
  bundled sample model.
* Nothing here bypasses Apple's security; you are signing the app as yourself.
