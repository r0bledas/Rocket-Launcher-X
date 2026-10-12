# AGENTS.md

## Build & Run

Always build/run the app to the user's connected **iPhone 13** (not the simulator):

```
xcodebuild -project "Rocket Launcher.xcodeproj" \
  -scheme "Rocket Launcher" \
  -configuration Debug \
  -destination 'platform=iOS,id=00008110-001851691E44401E' \
  -allowProvisioningUpdates \
  build
```

- Device: iPhone 13 (iPhone14,5), UDID `00008110-001851691E44401E`.
- Use `-allowProvisioningUpdates` so automatic signing can generate profiles.
- If the device isn't listed by `xcrun devicectl list devices`, re-check the UDID with
  `xcodebuild -showdestinations`.

## Conventions

- Commit every change with a concise, descriptive message after a successful build.
- `BUILD SUCCEEDED` is required before committing.
