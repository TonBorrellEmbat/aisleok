# AisleOK system — iOS 26, one page

**Price lock:** AisleOK Yearly **$49.99**, AisleOK Monthly **$9.99**. Not a $40–60 range.


Ship this. Bite icon is the only logo. No scanner-bracket motif. No Fig lime. No traffic lights.

## Two layers

**UI layer** = system. NavigationStack, toolbar, tab/bottom bar, `.sheet`, buttons. Liquid Glass comes free if we use stock controls and compile with the current SDK. Do not set a custom nav/toolbar/sheet background. Do not tint the bar paprika.

**Content layer** = brand. Canvas, verdict word, primary action fill, the Bite icon in the store. That’s it.

Apple: glass is the topmost navigation layer. Content stays primary. Remove custom bar/sheet backgrounds or the glass dies.

## Color (content only)

| Token | Light | Dark | Use |
|---|---|---|---|
| Canvas | `Color(.systemBackground)` — cream wash `#F6EFE3` only as a grouped background if we need it | `systemBackground` | Screens, lists |
| Label | `.primary` / `.secondary` / `.tertiary` | system | All text unless a verdict |
| Paprika `#C94A2A` | same | same | **Small portion** word + `.borderedProminent` tint only |
| Clay `#C45A3A` | same | same | **Skip** word only |
| Cocoa `#2B1A12` | cream-tinted in dark | **Eat** word only (not traffic-light green) |
| Sand `#C4B49A` | same | **Unknown** word only |
| Sage | do not use | — | Too close to Fig/go-green |

No brand color on nav, toolbar, sheet chrome, or reticle.

## Type

SF Pro. Dynamic Type. Semantic styles only:

- Verdict word → `.largeTitle.weight(.bold)`
- Product name → `.title3`
- Dose / unknown body → `.body` + `.secondary`
- “This looks wrong” → `.footnote` + `.secondary`
- Recap chip on paywall → `.subheadline.weight(.semibold)`
- Settings → default `List` typography

No custom font. No fixed px. Support Dynamic Type + larger accessibility sizes (verdict can wrap two lines).

## Symbols

SF Symbols only. `barcode.viewfinder` is fine on a button label. Do not draw four L-brackets or a center dot anywhere in the UI. Bite icon is the app icon, not an in-app glyph.

## Components (SwiftUI)

**Scan (home)**  
`NavigationStack` + camera as content, not a dark HUD. Cream/system canvas. Live preview sits in a large rounded rectangle (`RoundedRectangle(cornerRadius: 28)`) inset from the safe area — airy, like Fig’s one-job screens, not iOS Camera’s black theater. Thin system reticle: 2pt `Color.secondary` rounded rect, no corners-only brackets.  
Toolbar (glass, trailing): `gearshape` → inset-grouped Settings (onion, garlic, wheat, lactose, polyols, inulin).  
Bottom toolbar (glass): `camera` “Photo of label” and `magnifyingglass` “Search produce” as two `ToolbarItem`s, not twin Android pills.  
First open: one `.secondary` line under the well — “Point at a barcode.” Then it just works. History is never home.

**Verdict**  
Same stack, system back. One huge word: Eat / Small portion / Skip / Unknown. Color from the table above. Product name under it. Trigger as a quiet text line, not a candy chip (“Lactose”). Small portion only: one dose line.  
Primary: `Button("Scan another") { }.buttonStyle(.borderedProminent).tint(Color.paprika)` — except Unknown, where primary is “Photo of label”.  
Quiet control, Eat/Small/Skip only: `Button("This looks wrong")` `.buttonStyle(.borderless)` `.font(.footnote)` `.foregroundStyle(.secondary)` under the dose/trigger. One tap: drop the OFF ingredient list, keep the product name, same screen becomes Unknown. No confirm. Hidden on Unknown.  
Tap the trigger → `.sheet` with the 3-line why (what it is, why it bothers IBS, what “small” means). System sheet, no custom chrome.

**Paywall**  
`.sheet` after the first useful verdict. They already see the result. Recap chip is content: “Skip · onion powder”. Headline: “That’s one down. The aisle has thousands more.” Yearly is the prominent product (`$49.99/year`, 7-day trial). Monthly is a plain button. If they dismiss, they keep that first result. Do not blur it.  
`presentationDetents([.medium, .large])`. No `.containerBackground` / no painted sheet. Liquid Glass inset sheet does the work.

**Settings**  
`List` + `.listStyle(.insetGrouped)`. Toggles for the six triggers. Standard `Form` footer if we need a line of wellness copy. No medical claims.

**Why sheet**  
Three `Text`s. Done. System dismiss.

## Dark Mode

Forced cream is light-only. Dark uses `systemBackground` / `primary`. Paprika, clay, cocoa, sand stay. Glass nav adapts. Camera well can go darker; the page around it stays system, not charcoal chrome.

## Motion / first scan

First useful scan teaches: land on Verdict, then the paywall sheet. No coach-mark tour. No 15-step Fig onboarding. One toggle screen on first launch, then camera.

## Accessibility

Dynamic Type. VoiceOver: “Small portion. Chobani Plain Greek Yogurt. Lactose. A few spoons. Not the cup.” Contrast: paprika on cream, cream on paprika for the prominent button. Reduce Transparency: system glass falls back — we don’t invent a brand bar.

## Kill list

Dark charcoal scan home. Android twin pills. Custom scanner brackets as brand. Medical guts. Fig lime. EMS red/green traffic lights. Custom nav backgrounds. Fake 2019 card kits.

## Store shots

Five 1290×2796. Headlines locked. UI in this system. Bite icon in the frame if we show a springboard; not as a watermark.

1. Scan it. Eat, nibble, or skip.
2. Lactose. A few spoons is usually fine.
3. Onion powder. This jar is a no.
4. No fake green light.
5. No barcode, still works.
