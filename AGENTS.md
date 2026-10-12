# AGENTS.md

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
