# AisleOK

US-first iOS aisle checker. Scan a barcode, photograph a label, or type a produce name. Eat / small portion / skip / unknown.

Not a medical device. Not Monash. Wellness journal only.

## Generate and build

Requires Xcode 15+ (iOS 17 SDK) and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open AisleOK.xcodeproj
```

Scheme: **AisleOK**. Bundle id: `com.tonborrellembat.aisleok`.

Local StoreKit: `Products.storekit` is wired on the scheme (yearly.4999, monthly.999).

```bash
xcodebuild -scheme AisleOK -destination 'platform=iOS Simulator,name=iPhone 16' test
```

CI (`.github/workflows/ci.yml`) installs XcodeGen, generates the project, and runs `xcodebuild` test on GitHub-hosted `macos-latest`.

## Locked drop-ins

- `AisleOK_trigger_tags_v1.json` — 103 tags / 186 aliases. Bundled as-is. Do not edit.
- `privacy.html` / `terms.html` — https://tonborrellembat.github.io/aisleok/
- `assets/` — App Store frames and `icon-1024.png` (listing). The in-app App Icon is a copy under `AisleOK/Assets.xcassets`.

## Screens

Scan home, verdict (Eat / Small portion / Skip / Unknown), paywall sheet after the first useful scan, settings (six trigger toggles), produce search, label OCR.
