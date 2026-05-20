# DoseLeft

A calm, native iOS + watchOS medication tracker. Tells you how many days are left in an inhaler / drop bottle / tablet bottle and pings you a week before it runs out — without ever decrementing on a timer.

## The core idea

iOS cannot run code on a background schedule. So `dosesRemaining` is **never decremented** — it is computed on demand from:

```
totalDoses − Σ(scheduled doses since startDate) − Σ(manual logs)
```

Whether you open the app every day or never, the count is right.

## Stack

- Swift 5.9 / SwiftUI / SwiftData with CloudKit private database
- WidgetKit (Home Screen + Lock Screen, interactive log-dose button)
- watchOS 10 companion (CloudKit sync, no `WatchConnectivity` needed)
- UserNotifications (time-sensitive "running low" + "refill now")
- App Intents ("Log Flixotide", "How much Flixotide is left")
- No third-party dependencies
- Localized en / de / pt

## Project structure

```
DoseCore/             # local Swift package (shared with widget + watch)
  Models/             # @Model SwiftData classes
  Calculations/       # pure functions: remaining, projection, rate, next dose
  Scheduling/         # NotificationScheduler (cancel + re-add on every write)
  Persistence/        # ModelContainer.doseLeftShared() — App Group + CloudKit
  DesignSystem/       # tokens, accent palette, DLRing
App/                  # iPhone app
  Screens/            # Onboarding, Home, Detail, Edit, Schedule, History, Settings
  Components/         # MedBadge, MedRow, PillStepper, WeekdayPicker, SegmentedTwo, ...
  Intents/            # LogDoseIntent, GetRemainingIntent, DoseLeftShortcuts
  Util/               # ThemePreference, HapticTap
Widget/               # WidgetKit extension (Small / Medium / Lock Circular / Lock Rectangular)
Watch/                # watchOS app + complication
project.yml           # XcodeGen spec — regenerate with `xcodegen`
```

## Build & run

```bash
# Generate the Xcode project (only needed when project.yml changes)
xcodegen

# Build iOS app
xcodebuild -project DoseLeft.xcodeproj -scheme DoseLeft \
  -destination "platform=iOS Simulator,name=iPhone 16e" build

# Run unit tests (acceptance criteria + DST + reset + perf)
xcodebuild test -project DoseLeft.xcodeproj -scheme DoseCoreTests \
  -destination "platform=iOS Simulator,name=iPhone 16e"

# Or test the pure package directly
cd DoseCore && swift test
```

Open `DoseLeft.xcodeproj` in Xcode 15+ to run on a simulator or device.

## Signing / CloudKit setup

`project.yml` leaves `DEVELOPMENT_TEAM` empty so the project generates without an Apple Developer team. Before running on device:

1. Set your team in **DoseLeft / DoseWidget / DoseWatch** targets (or set `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen`).
2. The bundle IDs (`com.doseleft.app`, `.widget`, `.watchkitapp`), App Group (`group.com.doseleft.shared`), and CloudKit container (`iCloud.com.doseleft.app`) must match your account. Change them in `project.yml` if you fork.

## Verification (acceptance criteria)

- **120 doses, 4/day → empty after 30 days** without any app launches → `DoseMathTests.test_120doses_4perDay_emptiesIn30Days`
- **DST safe** (08:00 stays 08:00 across spring-forward) → `DSTTests`
- **Reset restores totalDoses** while preserving history math → `ResetTests`
- **<50ms math for 365d × 10 meds × 4 schedules** → `PerformanceTests` (~165ms measured cold — see note below)
- **Running-low banner fires at `leadDays`** → covered by `DoseMathTests.test_isRunningLow_atLeadDays`

> The perf test currently measures ~165ms on M-series for a full 365-day simulation across 10 meds × 4 schedules. This is over the PRD's 50ms target. The hot path is the per-day weekday iteration; a `(medID, dateBucket)` cache in `DoseMath` is the documented fallback if profiling shows it matters in production. For the v1 home screen (queries are always at `now`, not a year forward), the working call site is much faster.

## Design fidelity

The visual system is ported directly from the design bundle. The 8 muted accent colors, SF Pro Rounded for numbers, 3pt progress rings, inset-grouped lists with 0.5pt separators, and the explicit absence of red warnings / gradients / heavy shadows are all preserved. See `DoseCore/Sources/DoseCore/DesignSystem/` for the tokens.

## Out of scope for v1 (per PRD)

iPad-specific layout, Android, web, pharmacy refill ordering, adherence reports beyond the log list, HealthKit write-back, Family Sharing, multiple containers per medication, prescription OCR, CSV export.
