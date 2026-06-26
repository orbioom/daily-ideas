# Keg — Homebrewing Recipe Calculator & Batch Log

Private, offline homebrewing companion for iOS. Build recipes, log batches, track fermentation, and calculate brew day numbers — all on your device.

## Features

- **Recipe builder** — name, beer style, batch size, OG/FG targets, IBU, SRM, efficiency
- **Auto-calculated stats** — ABV (OG−FG)×131.25, BU:GU ratio, color description from SRM
- **Grain bill** — list grains with amounts (g/kg display)
- **Hop schedule** — hops with alpha acid %, addition time in minutes
- **Yeast & adjuncts** — complete ingredient tracking
- **Batch logging** — actual OG, FG, volume, fermentation temperature, status workflow
- **Fermentation log** — timestamped gravity + temperature readings with line chart
- **Attenuation calculation** — actual vs expected
- **Status badges** — Planned → Fermenting → Conditioning → Kegged/Bottled → Complete
- **Active batch badge** — tab badge showing fermenting/conditioning batch count
- **5 seeded recipes** — Cascade IPA, Oatmeal Stout, Hefeweizen, Amber Ale, Kölsch
- **4 brewing calculators** — ABV, Priming Sugar (Terrill-corrected CO₂), Strike Water Temp (Palmer's formula), Refractometer FG Correction
- **Search & style filter** — find recipes by name/tag/style
- **Favorites** — heart-mark best recipes
- **Full accessibility** — VoiceOver, Dynamic Type, WCAG AA, Reduce Motion

## Screens

1. **Recipes** — searchable list with style filter, ABV/IBU chips, SRM color swatch
2. **Recipe Detail** — stats grid, grain bill, hop schedule, yeast/adjuncts, batch history
3. **Batch Detail** — actual stats, fermentation gravity chart (Swift Charts), log CRUD
4. **Batches** — all batches across recipes with status filter
5. **Calculators** — ABV / Priming Sugar / Strike Water Temp / Refractometer correction
6. **Settings** — brewery name, metric/imperial/Celsius, haptics, stats

## Run Steps

1. `cd ios && xcodegen generate`
2. Open `Keg.xcodeproj` in Xcode 15+
3. Select a simulator or device
4. Product → Run

> Free signing: In Xcode → Signing & Capabilities, set your personal team.

## Monetization

One-time Pro unlock ($4.99): recipe scaling (scale ingredients to any batch size), water chemistry calculator (RO additions), full recipe export (BeerXML/JSON), custom ingredient libraries, recipe notes with photos.

## Why it can boom

Brewer's Friend and BrewFather are subscription-based web apps with clunky mobile experiences ($10–20/month). The homebrewing market has 1.2M active US homebrewers. A clean, native iOS-first app with one-time pricing and core calculations built in has a clear market position.
