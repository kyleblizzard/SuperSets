# Super Sets

A workout tracker for iOS 26 built with SwiftUI and SwiftData, focused on **progressive overload** — seeing what you lifted last time so you can beat it today.

## What It Does

Select a lift, log your sets, and instantly see a side-by-side comparison with the last time you performed that exercise. Green arrows mean you're progressing. Red arrows mean you regressed. That's the whole idea.

**Core features:**
- 90+ preloaded exercises across 13 muscle groups
- Side-by-side today vs. previous comparison with volume-based arrows
- Live workout duration timer and manual rest timer
- Custom exercise creation
- Workout history calendar with detail views
- Post-workout summary with share sheet
- Profile with body measurements and RMR calculation
- Light and dark mode with adaptive colors

## Tech Stack

- **SwiftUI** — declarative UI framework
- **SwiftData** — persistence layer (replaces Core Data)
- **iOS 26 Liquid Glass** — `.glassEffect()` API for buttons, cards, and navigation
- **MVVM architecture** — views talk to WorkoutManager, never directly to the database

## Project Structure

```
SuperSetsv2/
├── Models/          Data models (Workout, WorkoutSet, LiftDefinition, etc.)
├── ViewModels/      WorkoutManager, TimerManager
├── Views/
│   ├── Workout/     Main tracking screen, post-workout summary
│   ├── Calendar/    Monthly calendar, workout detail
│   ├── Lifts/       Exercise library (two-step picker)
│   └── Profile/     User profile, measurements, preferences
└── Theme/           Color system, glass effects, animations
```

## Requirements

- Xcode 26+
- iOS 26+
- No external dependencies

## License

MIT
