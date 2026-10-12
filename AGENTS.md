# AGENTS.md

> Naming: the app is published under two names — **"Rocket Launcher"** and
> **"Rocket Launcher X"** — that refer to the **same application**. Treat them as
> one product everywhere (legal pages, App Store metadata, docs).

## ⚠️ HIGHEST PRIORITY — Legal / Privacy / Monetization

**Whenever a change touches privacy, data collection, advertising, monetization,
purchases, or anything legal, you MUST update BOTH `docs/privacy.html` and
`docs/terms.html` in the SAME change, before committing.** Examples that trigger this:

- Adding/removing an analytics event, SDK, or third party (e.g. ads, Crashlytics).
- Changing what data is collected, stored, shared, or its retention.
- Adding/removing an ad format (banner, rewarded, interstitial) or consent/ATT flow.
- Changing products, prices, entitlements, subscriptions, or rewarded unlocks.
- Any new permission, API usage, or privacy-manifest change.

Rules:
- The privacy policy must stay an accurate, complete inventory of what the app
  collects and shares. Keep `docs/privacy.html` §2 ("Information We Collect") in
  sync at all times.
- Keep the in-app privacy labels, `PrivacyInfo.xcprivacy`, and `Info.plist`
  (`NSUserTrackingUsageDescription`, `GADApplicationIdentifier`, `SKAdNetworkItems`)
  consistent with the pages.
- If you are unsure whether a change is legal/privacy/monetization related, treat
  it as if it is, and update the pages.
- "We cannot get sued." Never ship a data/privacy/ads/purchase change without the
  matching policy/terms update. This rule outranks all other conventions.

## Build & Install to the user's iPhone 13

`xcodebuild ... build` only compiles + signs; it does **not** install. Always run
all three steps so the change actually lands on the device.

1. Build (signed, for the device), using a local derived data path:

```
xcodebuild -project "Rocket Launcher.xcodeproj" \
  -scheme "Rocket Launcher" \
  -configuration Debug \
  -destination 'platform=iOS,id=00008110-001851691E44401E' \
  -allowProvisioningUpdates \
  -derivedDataPath build \
  build
```

2. Install to the device:

```
xcrun devicectl device install app \
  --device 00008110-001851691E44401E \
  "build/Build/Products/Debug-iphoneos/Rocket Launcher.app"
```

3. Launch:

```
xcrun devicectl device process launch \
  --device 00008110-001851691E44401E \
  com.Robledas.rocketlauncher
```

- Device: iPhone 13 (iPhone14,5), UDID `00008110-001851691E44401E`.
- Bundle id: `com.Robledas.rocketlauncher`.
- `build/` is git-ignored, so the derived data path is safe.
- If the device isn't listed by `xcrun devicectl list devices`, re-check the UDID
  with `xcodebuild -showdestinations`.

## Conventions

- Commit every change with a concise, descriptive message after a successful build.
- `BUILD SUCCEEDED` is required before committing.
