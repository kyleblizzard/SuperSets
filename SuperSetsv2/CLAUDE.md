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

**Liquid Glass + Facebook-Inspired Adaptive Themes:**
- **Adaptive Light/Dark Mode** — Professional light mode (Facebook-inspired clean white/gray) and premium dark mode (deep navy blue)
- **Liquid Glass Effects** — Frosted glass panels using `.ultraThinMaterial`, `.regularMaterial` with gradient borders
- **Circular Design Elements** — Tinder-inspired circular glass morphing tab bar, glowing circular muscle group icons
- **Gradient Borders** — Multi-color gradient strokes instead of solid borders for depth
- **Colored Shadows** — Shadows match accent colors for glow effects
- **Bright Muscle Group Colors** — Unique accent color per muscle group (coral for chest, sky blue for lats, etc.)
- **Adaptive Backgrounds:**
  - Light mode: Clean gradient from white (`#F0F2F5`) to light gray (`#D8DADF`)
  - Dark mode: Deep navy blue gradient (`#0A1929` → `#132F4C` → `#1A3A52`)
- **Adaptive Text Colors:**
  - Light mode: True black (`#1C1E21`) for primary text, dark gray (`#4E4F50`) for secondary
  - Dark mode: Off-white (`#E4E6EB`) for primary text, light gray (`#B0B3B8`) for secondary
- **Adaptive Accents:**
  - Light mode: Facebook blue (`#1565C0`)
  - Dark mode: Electric blue (`#2196F3`)
- Spring animations with `response: 0.35, dampingFraction: 0.7`
- **Custom Tinder-inspired liquid glass tab bar** with circular selection indicators
- Circle buttons with glass material for lift selectors
- Monospaced digits for timer and measurements
- **GlassEffectContainer** for unified rendering and morphing effects
- **Staggered animations** on search/filter (50ms delay between items)
- iOS 26+ liquid glass design language throughout

## App Architecture

```
SuperSetsApp.swift (entry point, sets up SwiftData modelContainer)
├── ContentView.swift (root view + native TabView with 4 tabs)
│   ├── WorkoutView (main tracker)
│   │   ├── Lift Circle Buttons (top: Add + 4 recent)
│   │   ├── Set Input (weight/reps + Log Set button)
│   │   ├── Current Sets display
│   │   ├── Rest Timer (start/stop, resets to 0 on stop)
│   │   ├── Comparison section (today vs previous) + End Workout button
│   │   └── 🏆 PR Badge overlay (appears briefly when a new PR is set)
│   ├── CalendarView (monthly grid + workout dots)
│   │   └── WorkoutDetailView (past workout details)
│   ├── ProgressView (fitness dashboard — v0.002)
│   │   ├── Workout Stats Summary (total workouts, weekly, avg duration, total sets)
│   │   ├── Body Weight Tracking (current weight, 30/90-day chart, log button)
│   │   ├── Personal Records (searchable, grouped by muscle, tap for detail + chart)
│   │   ├── Volume Trends (8-week bar chart of total weekly volume)
│   │   └── Calorie Estimates (TDEE, activity level, weekly workout calories)
│   └── ProfileView (personal info + RMR calculator + theme preference)
├── Models/
│   ├── MuscleGroup.swift (enum with adaptive hex colors)
│   ├── LiftDefinition.swift (@Model)
│   ├── Workout.swift (@Model)
│   ├── WorkoutSet.swift (@Model)
│   ├── UserProfile.swift (@Model with theme preference + activityLevel)
│   ├── WeightEntry.swift (@Model — body weight log entries, v0.002)
│   └── PreloadedLifts.swift (seed data catalog - 100+ exercises)
├── ViewModels/
│   ├── WorkoutManager.swift (@Observable with PR calc, stats, weight tracking, calorie estimates)
│   └── TimerManager.swift (@Observable)
├── Views/
│   ├── LiftLibraryView.swift (unified browse + create with circular glass design)
│   ├── WorkoutSummaryView.swift
│   ├── WorkoutDetailView.swift
│   └── Progress/ProgressDashboardView.swift (v0.002 progress dashboard)
└── Theme/
    └── AppTheme.swift (adaptive color system, glass modifiers, animations)
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
- `preferredTheme: AppThemeOption` — **Dark (default)** or Light mode preference
- `activityLevel: ActivityLevel` — for TDEE calculation (sedentary/light/moderate/active/very active)
- `startDate: Date?`
- `profilePhotoData: Data?` (@Attribute(.externalStorage))
- Computed: `restingMetabolicRate` (Mifflin-St Jeor equation)
- Computed: `totalDailyEnergyExpenditure` (RMR × activity multiplier)

### WeightEntry (@Model) — v0.002
- `date: Date` — when the weigh-in occurred
- `weight: Double` — body weight in user's preferred unit

## Core Feature Specifications

### Tinder-Inspired Liquid Glass Tab Bar
- **Compact floating capsule** at bottom with intense glass effects
- **Circular selection indicators** — 44pt glass circles that morph between tabs
- **Glowing icons** with gradient fills when selected
- **Dynamic sizing** — icons scale up (20pt → 18pt) on selection
- **Pulsing dot indicator** — small blue dot appears below selected tab
- **Tactile press animation** — scales to 92% on tap
- **GlassEffectContainer** wraps entire bar for unified rendering
- **Dual shadows** — colored accent shadow + deep black shadow for depth
- **Gradient borders** — multi-stop gradients (glassBorder → accent)
- **Adaptive colors** — changes based on light/dark mode

### LiftLibraryView (Unified Browse + Create)
- **Circular glass muscle group cards** with:
  - Large glowing circular icon (60pt) with gradient border
  - Outer glow ring with blur effect
  - Exercise count badge
  - "Create Custom Exercise" button (capsule shape)
  - Individual lift cards with blue-tinted glass
- **Searchable** across all exercises
- **Staggered animations** — 50ms delay between cards when searching
- **Color-coded** by muscle group with gradient accents
- **Circular indicators** throughout (dots, badges, icons)
- **100+ pre-loaded exercises** across 13 muscle groups

### Lift Circle Buttons (Removed "All Lifts")
- **5 circles total** (was 6), always in this order:
  1. **Add Lift** (fixed, far left) — opens LiftLibraryView with circular design
  2-5. **4 Recent Lifts** (scrollable) — most recently used, newest on left
- ~~All Lifts button removed~~ — now integrated into Add Lift flow
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
- **Theme preference: Dark (default) or Light mode**
- Start date
- **Resting Metabolic Rate** calculated via Mifflin-St Jeor:
  - Male: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
  - Female: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161

## Adaptive Color System

### Light Mode (Facebook-Inspired)
- Background: Clean white/light gray gradient (`#F0F2F5` → `#E8EAED` → `#D8DADF`)
- Primary Text: True black (`#1C1E21`)
- Subtle Text: Dark gray (`#4E4F50`)
- Accent: Facebook blue (`#1565C0`)
- Cards: Pure white (`#FFFFFF`)
- Borders: Medium gray (`#BFC1C5` @ 80% opacity)
- Navigation bars: Light background with dark text and black back buttons

### Dark Mode (Instagram/Twitter-Inspired)
- Background: Deep navy blue gradient (`#0A1929` → `#132F4C` → `#1A3A52`)
- Primary Text: Off-white (`#E4E6EB`)
- Subtle Text: Light gray (`#B0B3B8`)
- Accent: Electric blue (`#2196F3`)
- Cards: Deep navy (`#0D1B2A`)
- Borders: Steel blue (`#1E4976` @ 80% opacity)
- Navigation bars: Dark background with light text

### Semantic Colors
- Success: Material Green (`#2E7D32` light / `#4CAF50` dark)
- Danger: Material Red (`#C62828` light / `#F44336` dark)
- Secondary Accent: Darker teal (`#0097A7` light / `#00BCD4` dark)

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
- [x] Pre-loaded lift catalog (100+ exercises)
- [x] Custom lift creation
- [x] **Adaptive light/dark mode with theme preference**
- [x] **Tinder-inspired liquid glass tab bar**
- [x] **Circular glass design elements throughout**
- [x] **Facebook-quality light mode (WCAG AAA compliant)**
- [x] **Instagram/Twitter-quality dark mode (deep blue)**
- [x] **Unified lift library with search and creation**
- [x] **UIKit appearance API for navigation bar control**
- [x] **Enhanced error logging for debugging**
- [x] Weight unit preference (default lbs)

## v0.002 — Progress Tab (Completed)
- [x] Personal Records (all-time bests per lift, 4 PR categories)
- [x] 🏆 PR badge in WorkoutView when a new PR is set
- [x] Lift Progression Charts (Swift Charts line graph per lift)
- [x] Body Weight Tracking (log, chart, 30/90 day view)
- [x] Volume Trends (8-week bar chart)
- [x] Workout Stats Summary (total workouts, weekly, avg duration, total sets)
- [x] Calorie Estimates (TDEE, activity level, weekly workout calories)
- [x] WeightEntry SwiftData model
- [x] ActivityLevel enum on UserProfile

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
10. **Save SwiftData context** after every mutation with error logging
11. **Use AppColors for all text** — never hardcode `.white` or Color literals
12. **Adaptive colors everywhere** — use `Color(light:dark:)` pattern
13. **GlassEffectContainer** for multiple glass elements
14. **UIKit appearance API** for navigation bar control when needed
15. **@Environment(\.colorScheme)** to detect and adapt to mode changes
