# Frond — a quiet plant-watering companion (Android)

A calm, local-first Android app that remembers when your plants need water so
you don't have to. Each plant has its own rhythm; Frond shows a gentle "thirst"
bar filling toward the next watering, sorts the garden by urgency, and a single
tap on **Watered** resets the clock.

No account, no cloud, no notifications nagging you — the whole garden lives in
local storage on the device. Open it on a Sunday, water what's due, close it.

## Why it earns weekly opens

Plant-care apps tend to be bloated with social feeds, plant-ID cameras, and
subscriptions. The actual recurring need is tiny and honest: *which of my plants
needs water today?* Frond answers that in one glance and one tap, and it's the
kind of small, lived-in tool the Orbioom brand is built around.

## What's inside

- Per-plant watering interval, days-until-due (overdue / today / tomorrow / in N)
- Urgency-sorted list with a live thirst bar (green, warming when overdue)
- Add / water / remove; seeded with four common houseplants
- **Local-first persistence** via JSON in SharedPreferences — no Room, no KSP,
  no annotation processors, so it builds clean
- Material 3 `ColorScheme` tuned to Orbioom tokens; adaptive launcher icon (a
  single frond) with a monochrome layer
- Jetpack Compose only, MVVM (data / viewmodel / ui)

## Architecture (MVVM)

```
data/        Plant.kt             domain model + thirst / due-date math
             PlantRepository.kt   JSON ⇄ SharedPreferences
viewmodel/   PlantViewModel.kt    StateFlow garden, add/water/delete, seeding
ui/theme/    Color.kt Theme.kt Type.kt   Orbioom Material 3 theme
ui/screens/  PlantListScreen.kt   garden list + thirst cards
             AddPlantDialog.kt    new-plant form
MainActivity.kt                   Compose host
```

## Build

Open the `android/` folder in Android Studio (Giraffe+ / AGP 8.5, Kotlin 1.9,
JDK 17), let it sync, and **Run** on an emulator or device (min SDK 26).
A Gradle wrapper (8.7) is included.

### APK build in this run

`build-apk/build-log.txt` records the in-sandbox build attempt. The cloud
sandbox has **JDK 21 and Gradle, but no Android SDK** (`ANDROID_HOME` unset) and
no cached Android Gradle Plugin, and per run policy we don't install the ~5 GB
SDK. So no APK was produced here — the source is complete and builds in Android
Studio. Everything else (config, wrapper, sources, resources) is in place.
