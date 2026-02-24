# CLAUDE.md — Super Sets: The Workout Tracker

## Your Role

You are a senior iOS engineer with emphasis in UI and modern Swift practices. You are building this app WITH a junior developer. Your goals:

1. **Build production-grade code** — App Store ready, no shortcuts.
2. **Teach as you go** — Document everything at a beginner level. Add `// LEARNING NOTE:` comments explaining Swift concepts, even things that seem obvious. Someone should be able to learn Swift by reading this codebase.
3. **Use the latest patterns** — iOS 26+, SwiftUI, SwiftData, @Observable (not ObservableObject), @Bindable, @Query. No UIKit unless absolutely necessary.
4. **Build → Preview → Verify** — After every change, build the project and check SwiftUI Previews to verify things look right. If there are build errors, fix them before moving on.

## Platform & Target

- **iOS 26+** (SwiftUI only)
- **Swift** (latest stable)
- **SwiftData** for persistence (not Core Data, not UserDefaults for complex data)
- **No external dependencies** — use only Apple frameworks

## Design Language

**Liquid Glass + Health/Fitness Vibe:**
- Frosted glass panels using `.ultraThinMaterial` with subtle white gradient overlays
- Soft shadows for depth and layering
- Bright, happy accent colors per muscle group (coral for chest, sky blue for lats, etc.)
- Deep navy/purple gradient background behind glass panels
- Spring animations with `response: 0.35, dampingFraction: 0.7`
- Custom liquid glass tab bar at the bottom (not default TabView)
- Circle buttons with glass material for lift selectors
- Monospaced digits for the timer display
- The iOS 26 liquid glass design language wherever applicable

## App Architecture

```
SuperSetsApp.swift (entry point, sets up SwiftData modelContainer)
├── ContentView.swift (root view + custom GlassTabBar)
│   ├── WorkoutView (main tracker)
│   │   ├── Lift Circle Buttons (top: Add + 4 recent + All)
│   │   ├── Set Input (weight/reps + Log Set button)
│   │   ├── Current Sets display
│   │   ├── Rest Timer (start/stop, resets to 0 on stop)
│   │   └── Comparison section (today vs previous) + End Workout button
│   ├── CalendarView (monthly grid + workout dots)
│   │   └── WorkoutDetailView (past workout details)
│   └── ProfileView (personal info + RMR calculator)
├── Models/
│   ├── MuscleGroup.swift (enum)
│   ├── LiftDefinition.swift (@Model)
│   ├── Workout.swift (@Model)
│   ├── WorkoutSet.swift (@Model)
│   ├── UserProfile.swift (@Model)
│   └── PreloadedLifts.swift (seed data catalog)
├── ViewModels/
│   ├── WorkoutManager.swift (@Observable)
│   └── TimerManager.swift (@Observable)
├── Views/ (organized by feature)
└── Components/
    └── LiquidGlassStyle.swift (reusable glass modifiers)
```

## Data Models

### MuscleGroup (enum)
Chest, Lats, Lower Back, Traps, Neck, Shoulders, Abs, Quads, Leg Biceps, Glutes, Calves, Biceps, Triceps. Each has a display name, SF Symbol, and accent color.

### LiftDefinition (@Model)
- `name: String` — e.g. "Bench Press"
- `muscleGroup: MuscleGroup`
- `isCustom: Bool` — user-created vs pre-loaded
- `dateCreated: Date`
- `lastUsedDate: Date?` — for sorting recent lifts
- Relationship: has many `WorkoutSet`

### Workout (@Model)
- `date: Date` — when started
- `endDate: Date?` — when finished
- `notes: String?` — added at end of workout
- `isActive: Bool` — only ONE active at a time
- Relationship: has many `WorkoutSet`
- Computed: `duration`, `uniqueLifts`, `setsGroupedByLift()`

### WorkoutSet (@Model)
- `weight: Double` — in user's preferred unit
- `reps: Int`
- `setNumber: Int` — auto-incremented per lift per workout
- `timestamp: Date`
- Relationships: belongs to `Workout`, belongs to `LiftDefinition`

### UserProfile (@Model)
- `name`, `age`, `biologicalSex`, `heightInches`, `bodyWeight`, `waistInches`
- `preferredUnit: WeightUnit` — defaults to **lbs**, user can change in profile
- `startDate: Date?`
- `profilePhotoData: Data?` (@Attribute(.externalStorage))
- Computed: `restingMetabolicRate` (Mifflin-St Jeor equation)

## Core Feature Specifications

### Lift Circle Buttons (Top of Workout View)
- **6 circles total**, always in this order:
  1. **Add Lift** (fixed, far left) — opens muscle group picker → lift picker/creator
  2-5. **4 Recent Lifts** (scrollable) — most recently used, newest on left
  6. **All Lifts** (fixed, far right) — searchable catalog organized by muscle group
- Tapping a lift circle selects it for input and loads comparison data
- When a new lift is added, it goes to position 2 (right of Add) and pushes others right

### Add Lift Flow
1. User taps Add → sees muscle group grid (2 columns)
2. Taps a muscle group → sees pre-loaded lifts for that group + search + "Create Custom" option
3. Taps a lift (or creates custom) → lift is selected, sheet dismisses
- **Pre-loaded lifts:** ~90 common exercises across all 13 muscle groups
- **Custom lifts:** User types a name, picks the muscle group

### Set Tracking
- **Auto-numbered sets.** User enters weight + reps, taps "Log Set." The app determines set number automatically (first set = 1, second = 2, etc.) per lift per workout.
- User never manually types a set number.
- Weight field persists between sets (bodybuilders often do same weight).
- Reps field clears after each log.
- User can delete a set (with renumbering of remaining sets).

### Rest Timer
- Simple start/stop timer
- **Resets to 0 when stopped** (not paused — fully resets)
- Display format: `MM:SS` with monospaced font
- Green "Start" button, red "Stop" button

### Comparison View
- Located below the timer
- **End Workout button lives in the upper-right corner of the comparison section** — small, unobtrusive, uses red text with subtle red background
- Two columns: **Today** (left) vs **Previous** (right)
- Previous data = the **last time this specific lift was ever performed**, regardless of workout type
- Shows set number, weight × reps for each column
- Shows the date of the previous workout

### End Workout
- Tapping End Workout shows a confirmation sheet with optional notes field
- On confirmation: workout gets endDate, isActive = false
- Shows **Workout Summary** with:
  - Date, duration, total sets, total exercises
  - Each lift: today's sets vs previous sets (comparison)
  - **Share button** (ShareLink) for email/text with plain text summary

### Calendar
- Monthly grid showing dots on days with workouts
- Left/right arrows to navigate months
- Tap a date with a workout → shows WorkoutDetailView
- Recent workouts list below the calendar grid

### Profile
- Name, photo (PhotosPicker), age, biological sex
- Height (in inches, displayed as feet'inches"), body weight, waist measurement
- Weight unit preference: **lbs (default)** or kg
- Start date
- **Resting Metabolic Rate** calculated via Mifflin-St Jeor:
  - Male: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
  - Female: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161

## Overall Flow

Open app → land directly on the Workout tab → Start Workout button (or resume active workout) → Tap Add/recent lift → Enter weight + reps → Log Set → Start/stop timer between sets → Comparison updates live → End Workout → Summary with share option → Returns to Calendar showing that workout.

## v1 Must-Haves
- [x] Full workout tracking (lifts, sets, weight, reps)
- [x] Auto-numbered sets
- [x] Comparison with previous lift data
- [x] Rest timer (start/stop/reset)
- [x] End workout with notes + summary
- [x] Share/email workout summary
- [x] Calendar with workout history
- [x] Profile with measurements + RMR
- [x] Pre-loaded lift catalog (90+ exercises)
- [x] Custom lift creation
- [x] Liquid glass UI throughout
- [x] Weight unit preference (default lbs)

## v2 (Later)
- Workout naming (vs default date)
- Progress charts and graphs
- Workout templates/routines
- Apple Watch companion
- HealthKit integration
- Cloud sync via iCloud
- Active workout widget

## Code Style Rules

1. **Every file starts with a comment header** explaining what the file does and why
2. **LEARNING NOTE comments** for every non-obvious Swift concept
3. **MARK: - Section Name** dividers for navigation
4. **/// Doc comments** on all public functions and types
5. **guard let for early exits**, if let for conditional execution
6. **Descriptive variable names** — no single letters except loop counters
7. **Keep views small** — extract sub-views into their own structs
8. **Private by default** — only expose what child views need
9. **No force unwraps** (`!`) — always safely unwrap optionals
10. **Save SwiftData context** after every mutation
