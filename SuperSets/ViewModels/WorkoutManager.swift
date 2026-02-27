// WorkoutManager.swift
// Super Sets — The Workout Tracker
//
// The brain of the app. Coordinates workout lifecycle, set logging,
// comparison data, lift selection, database seeding, and user profile.
//
// LEARNING NOTE:
// This follows MVVM (Model-View-ViewModel). Views never talk directly
// to the database — they go through WorkoutManager. This keeps views
// simple and makes the app easier to test and maintain.
//
// @Observable (iOS 17+) replaces ObservableObject. Every property
// change automatically triggers view updates. No @Published needed.
//
// Extensions in separate files:
//   WorkoutManager+Analytics.swift  — PRs, progression, volume, stats, summary
//   WorkoutManager+BodyTracking.swift — Body weight, calorie estimates

import Foundation
import SwiftData
import SwiftUI

// MARK: - WorkoutManager

@Observable
final class WorkoutManager {

    // MARK: - Dependencies

    /// SwiftData model context for all database operations.
    var modelContext: ModelContext?

    // MARK: - Active Workout State

    /// Currently active workout, or nil if none in progress.
    var activeWorkout: Workout?

    /// The lift currently selected for input.
    var selectedLift: LiftDefinition?

    /// Most recently used lifts for circle buttons (max 10, newest first).
    var recentLifts: [LiftDefinition] = []

    // MARK: - Input State

    /// Weight value in the input field. Persists between sets.
    var weightInput: String = ""

    /// Reps value in the input field. Clears after each logged set.
    var repsInput: String = ""

    // MARK: - Comparison Data

    /// Sets from the PREVIOUS time the selected lift was performed.
    var previousSets: [WorkoutSet] = []

    /// Date when the selected lift was previously performed.
    var previousWorkoutDate: Date?

    // MARK: - User Profile

    /// The user's profile (singleton in the database).
    var userProfile: UserProfile?

    // MARK: - Database Seeding

    var hasSeededDatabase: Bool = false

    // MARK: - Progress Tab State

    /// When a PR is broken during a workout, this briefly shows which PR type.
    /// WorkoutView displays a 🏆 badge when this is non-nil.
    var newPRAlert: PRType? = nil

    // MARK: - Super Set State

    /// Whether the user is currently building a super set.
    var isSuperSetMode: Bool = false

    /// Ordered list of lifts in the current super set (max 5).
    var superSetLifts: [LiftDefinition] = []

    /// Per-lift weight input keyed by lift name.
    var superSetWeights: [String: String] = [:]

    /// Per-lift reps input keyed by lift name.
    var superSetReps: [String: String] = [:]

    // MARK: - Initialization

    /// Sets up the manager with a SwiftData context and loads initial state.
    ///
    /// LEARNING NOTE:
    /// Called from ContentView once the SwiftData environment is ready.
    /// Can't do this in init() because modelContext comes from SwiftUI's
    /// environment, which isn't available until the view hierarchy is built.
    func setup(context: ModelContext) {
        self.modelContext = context
        seedDatabaseIfNeeded()
        seedSplitsIfNeeded()
        loadActiveWorkout()
        loadRecentLifts()
        loadUserProfile()
    }

    // MARK: - Workout Lifecycle

    /// Start a new workout session.
    func startWorkout() {
        guard let context = modelContext else { return }

        let workout = Workout()
        context.insert(workout)
        activeWorkout = workout

        selectedLift = nil
        weightInput = ""
        repsInput = ""
        previousSets = []
        previousWorkoutDate = nil

        save()
    }

    /// End the current workout.
    /// - Parameter notes: Optional user notes.
    /// - Returns: The completed workout (for showing the summary).
    @discardableResult
    func endWorkout(notes: String? = nil) -> Workout? {
        guard let workout = activeWorkout else { return nil }

        workout.isActive = false
        workout.endDate = Date()
        workout.notes = notes?.isEmpty == true ? nil : notes

        exitSuperSetMode()

        let completed = workout
        activeWorkout = nil
        selectedLift = nil
        weightInput = ""
        repsInput = ""
        previousSets = []
        previousWorkoutDate = nil

        save()
        return completed
    }

    // MARK: - Set Logging

    /// Log a new set for the currently selected lift.
    /// Auto-calculates set number based on existing sets for this lift.
    ///
    /// - Returns: true if logged successfully, false if inputs were invalid.
    @discardableResult
    func logSet(
        isWarmUp: Bool = false,
        toFailure: Bool = false,
        intensityTechnique: IntensityTechnique? = nil
    ) -> Bool {
        guard let context = modelContext,
              let workout = activeWorkout,
              let lift = selectedLift,
              let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0,
              reps > 0
        else { return false }

        let existingSets = workout.sets.filter {
            $0.liftDefinition?.name == lift.name
        }
        let nextSetNumber = existingSets.count + 1

        let newSet = WorkoutSet(
            weight: weight,
            reps: reps,
            setNumber: nextSetNumber,
            workout: workout,
            liftDefinition: lift,
            isWarmUp: isWarmUp,
            toFailure: toFailure,
            intensityTechnique: intensityTechnique
        )

        context.insert(newSet)
        lift.lastUsedDate = Date()

        // Only check PRs for working sets, not warm-ups
        if !isWarmUp {
            checkForNewPR(weight: weight, reps: reps, lift: lift)
        }

        repsInput = ""

        save()
        return true
    }

    /// Delete a set and renumber remaining sets.
    func deleteSet(_ workoutSet: WorkoutSet) {
        guard let context = modelContext,
              let workout = activeWorkout,
              let lift = workoutSet.liftDefinition
        else { return }

        // LEARNING NOTE:
        // We must filter out the deleted set BEFORE calling context.delete(),
        // because workout.sets still includes the deleted object momentarily
        // after deletion. Filtering by timestamp identity avoids stale data.
        let deletedTimestamp = workoutSet.timestamp
        let remainingSets = workout.sets
            .filter { $0.liftDefinition?.name == lift.name && $0.timestamp != deletedTimestamp }
            .sorted { $0.timestamp < $1.timestamp }

        context.delete(workoutSet)

        // Renumber: #3→#2, #4→#3, etc.
        for (index, set) in remainingSets.enumerated() {
            set.setNumber = index + 1
        }

        save()
    }

    // MARK: - Lift Selection

    /// Select a lift for the current workout.
    /// In super set mode, toggles the lift in the SS group instead.
    /// Auto-starts a workout if none is active.
    func selectLift(_ lift: LiftDefinition) {
        if activeWorkout == nil {
            startWorkout()
        }

        if isSuperSetMode {
            toggleSuperSetLift(lift)
            return
        }

        selectedLift = lift
        loadComparisonData(for: lift)
        // Only add if not already on the ring (preserves ring positions for rotary)
        if !recentLifts.contains(where: { $0.name == lift.name }) {
            addToRecentLifts(lift)
        }

        lift.lastUsedDate = Date()
        save()
    }

    /// Index of the currently selected lift in recentLifts (for rotary ring positioning).
    var selectedLiftIndex: Int? {
        guard let selected = selectedLift else { return nil }
        return recentLifts.firstIndex(where: { $0.name == selected.name })
    }

    // MARK: - Comparison Data

    /// Load previous workout data for a specific lift.
    /// Finds the most recent COMPLETED time this lift was performed.
    ///
    /// LEARNING NOTE:
    /// This is the core of progressive overload tracking. We find the
    /// last time this specific lift was done (not the last workout —
    /// the last time THIS LIFT was performed) and load those sets
    /// for side-by-side comparison.
    func loadComparisonData(for lift: LiftDefinition) {
        guard let context = modelContext else {
            previousSets = []
            previousWorkoutDate = nil
            return
        }

        let liftName = lift.name

        // LEARNING NOTE:
        // FetchDescriptor with #Predicate creates a type-safe database query.
        // We want WorkoutSets where the lift name matches AND the workout
        // is completed (not active). Sorted newest-first to find the most recent.
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.liftDefinition?.name == liftName &&
                workoutSet.workout?.isActive == false
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            let allPastSets = try context.fetch(descriptor)

            guard let mostRecentSet = allPastSets.first,
                  let mostRecentWorkout = mostRecentSet.workout else {
                previousSets = []
                previousWorkoutDate = nil
                return
            }

            // Get all sets from that specific workout for this lift
            previousSets = allPastSets
                .filter { $0.workout?.date == mostRecentWorkout.date }
                .sorted { $0.setNumber < $1.setNumber }

            previousWorkoutDate = mostRecentWorkout.date

        } catch {
            print("Error fetching comparison data: \(error)")
            previousSets = []
            previousWorkoutDate = nil
        }
    }

    // MARK: - Current Workout Sets

    /// All sets for the selected lift in the active workout.
    var currentLiftSets: [WorkoutSet] {
        guard let workout = activeWorkout,
              let lift = selectedLift else { return [] }

        return workout.sets
            .filter { $0.liftDefinition?.name == lift.name }
            .sorted { $0.setNumber < $1.setNumber }
    }

    // MARK: - Recent Lifts Management

    /// Insert a new lift at the front of the ring (max 10). Does NOT reorder existing lifts.
    func addToRecentLifts(_ lift: LiftDefinition) {
        recentLifts.insert(lift, at: 0)
        if recentLifts.count > 10 {
            recentLifts = Array(recentLifts.prefix(10))
        }
    }

    // MARK: - Data Loading

    /// Load active workout from database (resume in-progress workout on app launch).
    private func loadActiveWorkout() {
        guard let context = modelContext else { return }

        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isActive == true }
        )
        descriptor.fetchLimit = 1

        do {
            let results = try context.fetch(descriptor)
            activeWorkout = results.first

            if let workout = activeWorkout,
               let lastSet = workout.sets.sorted(by: { $0.timestamp > $1.timestamp }).first,
               let lastLift = lastSet.liftDefinition {
                selectLift(lastLift)
            }
        } catch {
            print("Error loading active workout: \(error)")
        }
    }

    /// Load the 10 most recently used lifts for circle buttons.
    private func loadRecentLifts() {
        guard let context = modelContext else { return }

        var descriptor = FetchDescriptor<LiftDefinition>(
            predicate: #Predicate<LiftDefinition> { $0.lastUsedDate != nil },
            sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
        )
        descriptor.fetchLimit = 10

        do {
            recentLifts = try context.fetch(descriptor)
        } catch {
            print("Error loading recent lifts: \(error)")
        }
    }

    /// Load or create the user's profile.
    private func loadUserProfile() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<UserProfile>()

        do {
            let profiles = try context.fetch(descriptor)
            if let existing = profiles.first {
                userProfile = existing
            } else {
                let newProfile = UserProfile()
                context.insert(newProfile)
                userProfile = newProfile
                save()
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }

    // MARK: - Database Seeding

    /// Populate database with pre-loaded exercises on first launch.
    private func seedDatabaseIfNeeded() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<LiftDefinition>()

        do {
            let existingLifts = try context.fetch(descriptor)
            guard existingLifts.isEmpty else {
                hasSeededDatabase = true
                return
            }

            var totalInserted = 0
            for (muscleGroup, liftNames) in PreloadedLifts.catalog {
                for name in liftNames {
                    let lift = LiftDefinition(
                        name: name,
                        muscleGroup: muscleGroup,
                        isCustom: false
                    )
                    context.insert(lift)
                    totalInserted += 1
                }
            }

            try context.save()
            hasSeededDatabase = true

        } catch {
            print("Error seeding database: \(error)")
        }
    }

    // MARK: - Personal Record Detection

    /// Check if a just-logged set breaks any existing PRs for this lift.
    /// If so, sets `newPRAlert` to show the 🏆 badge in WorkoutView.
    ///
    /// LEARNING NOTE:
    /// We compare the new set against ALL historical completed sets for this lift.
    /// The check is cheap because we only fetch sets for one specific lift,
    /// and we bail early if any PR is beaten (showing the most impressive one).
    private func checkForNewPR(weight: Double, reps: Int, lift: LiftDefinition) {
        guard let context = modelContext else { return }

        let liftName = lift.name

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.liftDefinition?.name == liftName &&
                workoutSet.workout?.isActive == false
            }
        )

        do {
            let historicalSets = try context.fetch(descriptor)
            guard !historicalSets.isEmpty else { return } // First time = no PR to beat

            let newVolume = weight * Double(reps)
            let newEpley = reps == 1 ? weight : weight * (1.0 + Double(reps) / 30.0)

            // Find existing maxima
            let maxWeight = historicalSets.map(\.weight).max() ?? 0
            let maxVolume = historicalSets.map { $0.weight * Double($0.reps) }.max() ?? 0
            let maxReps = historicalSets.map(\.reps).max() ?? 0
            let maxEpley = historicalSets.map { set -> Double in
                set.reps == 1 ? set.weight : set.weight * (1.0 + Double(set.reps) / 30.0)
            }.max() ?? 0

            // Check in order of impressiveness: 1RM > weight > volume > reps
            if newEpley > maxEpley {
                newPRAlert = .estimated1RM
            } else if weight > maxWeight {
                newPRAlert = .heaviestWeight
            } else if newVolume > maxVolume {
                newPRAlert = .bestVolume
            } else if reps > maxReps {
                newPRAlert = .mostReps
            }

        } catch {
            print("Error checking PRs: \(error)")
        }
    }

    // MARK: - Super Set Methods

    /// Enter super set mode, seeding the group with the currently selected lift.
    func enterSuperSetMode() {
        isSuperSetMode = true
        superSetLifts = []
        superSetWeights = [:]
        superSetReps = [:]
        if let lift = selectedLift {
            superSetLifts.append(lift)
        }
    }

    /// Exit super set mode and discard any uncommitted input.
    func exitSuperSetMode() {
        isSuperSetMode = false
        superSetLifts = []
        superSetWeights = [:]
        superSetReps = [:]
    }

    /// Add or remove a lift from the current super set group.
    /// - Returns: true if the lift is now in the group, false if removed.
    @discardableResult
    func toggleSuperSetLift(_ lift: LiftDefinition) -> Bool {
        if let idx = superSetLifts.firstIndex(where: { $0.name == lift.name }) {
            // Don't remove the last lift
            if superSetLifts.count > 1 {
                superSetLifts.remove(at: idx)
                superSetWeights.removeValue(forKey: lift.name)
                superSetReps.removeValue(forKey: lift.name)
            }
            return false
        } else {
            guard superSetLifts.count < 5 else { return false }
            superSetLifts.append(lift)
            // Add to ring if not already present
            if !recentLifts.contains(where: { $0.name == lift.name }) {
                addToRecentLifts(lift)
            }
            return true
        }
    }

    /// Check if a lift is currently in the super set group.
    func isInSuperSet(_ lift: LiftDefinition) -> Bool {
        superSetLifts.contains(where: { $0.name == lift.name })
    }

    /// Index of a lift within the super set group (1-based for display).
    func superSetIndex(of lift: LiftDefinition) -> Int? {
        guard let idx = superSetLifts.firstIndex(where: { $0.name == lift.name }) else { return nil }
        return idx + 1
    }

    /// Log all lifts in the super set as one grouped action.
    /// Each lift gets its own WorkoutSet with a shared groupId.
    /// If only 1 lift remains, delegates to regular logSet().
    /// - Returns: true if logged successfully.
    @discardableResult
    func logSuperSet() -> Bool {
        guard let context = modelContext,
              let workout = activeWorkout,
              !superSetLifts.isEmpty
        else { return false }

        // If only 1 lift, delegate to regular log
        if superSetLifts.count == 1, let lift = superSetLifts.first {
            let w = superSetWeights[lift.name] ?? weightInput
            let r = superSetReps[lift.name] ?? repsInput
            weightInput = w
            repsInput = r
            selectedLift = lift
            return logSet()
        }

        // Validate all inputs
        var parsedSets: [(lift: LiftDefinition, weight: Double, reps: Int)] = []
        for lift in superSetLifts {
            guard let weightStr = superSetWeights[lift.name],
                  let weight = Double(weightStr),
                  let repsStr = superSetReps[lift.name],
                  let reps = Int(repsStr),
                  weight > 0,
                  reps > 0
            else { return false }
            parsedSets.append((lift: lift, weight: weight, reps: reps))
        }

        let groupId = UUID().uuidString

        for (order, entry) in parsedSets.enumerated() {
            let existingSets = workout.sets.filter {
                $0.liftDefinition?.name == entry.lift.name
            }
            let nextSetNumber = existingSets.count + 1

            let newSet = WorkoutSet(
                weight: entry.weight,
                reps: entry.reps,
                setNumber: nextSetNumber,
                workout: workout,
                liftDefinition: entry.lift,
                superSetGroupId: groupId,
                superSetOrder: order
            )
            context.insert(newSet)
            entry.lift.lastUsedDate = Date()

            // Check PR per lift
            checkForNewPR(weight: entry.weight, reps: entry.reps, lift: entry.lift)
        }

        // Clear reps (keep weights for convenience)
        for lift in superSetLifts {
            superSetReps[lift.name] = ""
        }

        save()
        return true
    }

    /// Delete all sets sharing a super set groupId and renumber per-lift.
    func deleteSuperSetGroup(_ groupId: String) {
        guard let context = modelContext,
              let workout = activeWorkout else { return }

        let groupSets = workout.sets.filter { $0.superSetGroupId == groupId }
        let affectedLiftNames = Set(groupSets.compactMap { $0.liftDefinition?.name })

        for set in groupSets {
            context.delete(set)
        }

        // Renumber remaining sets for each affected lift
        for liftName in affectedLiftNames {
            let remaining = workout.sets
                .filter { $0.liftDefinition?.name == liftName && $0.superSetGroupId != groupId }
                .sorted { $0.timestamp < $1.timestamp }
            for (index, set) in remaining.enumerated() {
                set.setNumber = index + 1
            }
        }

        save()
    }

    /// Builds display rows for the sets table, interleaving regular and grouped super set rows.
    var currentLiftDisplayRows: [SetDisplayRow] {
        guard let workout = activeWorkout,
              let lift = selectedLift else { return [] }

        let liftSets = workout.sets
            .filter { $0.liftDefinition?.name == lift.name }
            .sorted { $0.setNumber < $1.setNumber }

        var rows: [SetDisplayRow] = []
        var processedGroupIds = Set<String>()

        for set in liftSets {
            if let groupId = set.superSetGroupId {
                guard !processedGroupIds.contains(groupId) else { continue }
                processedGroupIds.insert(groupId)

                // Gather all sets in this SS group across all lifts
                let groupSets = workout.sets
                    .filter { $0.superSetGroupId == groupId }
                    .sorted { ($0.superSetOrder ?? 0) < ($1.superSetOrder ?? 0) }

                rows.append(.superSet(groupId: groupId, setNumber: set.setNumber, sets: groupSets))
            } else {
                rows.append(.regular(set))
            }
        }

        return rows
    }

    // MARK: - Workout Splits

    /// Load a workout split — adds all lifts to the ring in order.
    func loadSplit(_ split: WorkoutSplit) {
        guard let context = modelContext else { return }

        for liftName in split.liftNames {
            // Try to find the lift in the database first
            let descriptor = FetchDescriptor<LiftDefinition>(
                predicate: #Predicate<LiftDefinition> { $0.name == liftName }
            )

            if let existing = try? context.fetch(descriptor).first {
                if !recentLifts.contains(where: { $0.name == existing.name }) {
                    addToRecentLifts(existing)
                }
            } else {
                // If not in DB (catalog-only lift), check PreloadedLifts
                for (group, names) in PreloadedLifts.catalog {
                    if names.contains(liftName) {
                        let lift = LiftDefinition(name: liftName, muscleGroup: group, isCustom: false)
                        context.insert(lift)
                        addToRecentLifts(lift)
                        break
                    }
                }
            }
        }

        // Select the first lift
        if let first = recentLifts.first {
            selectLift(first)
        }
        save()
    }

    /// Save the current workout's lifts as a new split template.
    func saveSplitFromWorkout(_ workout: Workout, name: String) {
        guard let context = modelContext else { return }

        let liftNames = workout.setsGroupedByLift.map { $0.lift.name }
        guard !liftNames.isEmpty else { return }

        let split = WorkoutSplit(name: name, liftNames: liftNames)
        context.insert(split)
        save()
    }

    /// Seed preset workout splits if none exist.
    func seedSplitsIfNeeded() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<WorkoutSplit>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let presets: [(String, [String])] = [
            ("Push Day", [
                "Flat Barbell Bench Press", "Incline Dumbbell Press",
                "Cable Chest Fly", "Overhead Press", "Lateral Raises",
                "Tricep Pushdowns"
            ]),
            ("Pull Day", [
                "Barbell Rows", "Lat Pulldowns", "Seated Cable Rows",
                "Face Pulls", "Barbell Curls", "Hammer Curls"
            ]),
            ("Leg Day", [
                "Barbell Back Squat", "Romanian Deadlift", "Leg Press",
                "Leg Curls", "Leg Extensions", "Standing Calf Raises"
            ]),
            ("Upper Body", [
                "Flat Barbell Bench Press", "Barbell Rows",
                "Overhead Press", "Lat Pulldowns",
                "Barbell Curls", "Tricep Pushdowns"
            ]),
            ("Lower Body", [
                "Barbell Back Squat", "Romanian Deadlift",
                "Leg Press", "Leg Curls",
                "Standing Calf Raises", "Hip Thrusts"
            ])
        ]

        for (name, lifts) in presets {
            let split = WorkoutSplit(name: name, liftNames: lifts, isPreset: true)
            context.insert(split)
        }

        save()
    }

    // MARK: - Persistence

    /// Save pending changes to the database.
    func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
}
