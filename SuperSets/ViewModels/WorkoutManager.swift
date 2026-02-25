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

import Foundation
import SwiftData
import SwiftUI

// MARK: - Personal Record Types

/// Represents the four types of personal records tracked per lift.
///
/// LEARNING NOTE:
/// Using a struct instead of a tuple gives us named fields, Identifiable
/// conformance for SwiftUI lists, and the ability to add computed properties.
/// Tuples are convenient but don't scale — once you need more than 2-3 fields
/// or want to pass them around, a struct is the way to go.
struct PersonalRecord: Identifiable {
    let id = UUID()
    let liftName: String
    let muscleGroup: MuscleGroup
    
    /// Heaviest single set ever performed (max weight regardless of reps).
    var heaviestWeight: Double = 0
    var heaviestWeightDate: Date?
    
    /// Best volume from a single set (weight × reps).
    var bestVolume: Double = 0
    var bestVolumeDate: Date?
    
    /// Most reps in a single set at any weight.
    var mostReps: Int = 0
    var mostRepsDate: Date?
    
    /// Estimated 1RM using the Epley formula: weight × (1 + reps / 30).
    /// Calculated from whichever set produces the highest estimate.
    var estimated1RM: Double = 0
    var estimated1RMDate: Date?
}

/// Which PR category was beaten (for the 🏆 badge in WorkoutView).
enum PRType: String {
    case heaviestWeight = "Heaviest Set"
    case bestVolume     = "Best Volume"
    case mostReps       = "Most Reps"
    case estimated1RM   = "Est. 1RM"
}

/// A data point for lift progression charts: one dot per workout session.
struct LiftProgressionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
}

/// Weekly volume for the volume trends bar chart.
struct WeeklyVolume: Identifiable {
    let id = UUID()
    let weekStart: Date
    let totalVolume: Double
    
    /// Short label like "Jan 6" for the x-axis.
    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStart)
    }
}

// MARK: - WorkoutManager

@Observable
final class WorkoutManager {
    
    // MARK: - Dependencies
    
    /// SwiftData model context for all database operations.
    ///
    /// LEARNING NOTE:
    /// ModelContext is SwiftData's database connection. All inserts, deletes,
    /// and queries go through this. Changes auto-persist (SwiftData auto-saves),
    /// but we call save() explicitly after important mutations for certainty.
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
    func logSet() -> Bool {
        guard let context = modelContext,
              let workout = activeWorkout,
              let lift = selectedLift,
              let weight = Double(weightInput),
              let reps = Int(repsInput),
              weight > 0,
              reps > 0
        else { return false }
        
        // LEARNING NOTE:
        // Auto-numbering: count existing sets of this lift in the current
        // workout, then add 1. User never manually enters set numbers.
        let existingSets = workout.sets.filter {
            $0.liftDefinition?.name == lift.name
        }
        let nextSetNumber = existingSets.count + 1
        
        let newSet = WorkoutSet(
            weight: weight,
            reps: reps,
            setNumber: nextSetNumber,
            workout: workout,
            liftDefinition: lift
        )
        
        context.insert(newSet)
        lift.lastUsedDate = Date()
        
        // LEARNING NOTE:
        // After logging a set, check if it beats any existing personal records.
        // We do this BEFORE clearing repsInput so we still have the values.
        // The PR check runs against all completed (non-active) workout sets,
        // so the current active workout's sets are compared against history.
        checkForNewPR(weight: weight, reps: reps, lift: lift)
        
        // Clear only reps — weight persists for convenience
        // (bodybuilders often repeat the same weight across sets)
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
    /// Auto-starts a workout if none is active.
    func selectLift(_ lift: LiftDefinition) {
        if activeWorkout == nil {
            startWorkout()
        }
        
        selectedLift = lift
        loadComparisonData(for: lift)
        updateRecentLifts(with: lift)
        
        lift.lastUsedDate = Date()
        save()
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
    
    /// Move a lift to the front of the recent lifts list (max 10).
    private func updateRecentLifts(with lift: LiftDefinition) {
        recentLifts.removeAll { $0.name == lift.name }
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
    
    // MARK: - Workout Summary Text
    
    /// Generate plain text summary for sharing.
    func generateSummaryText(for workout: Workout) -> String {
        var text = "🏋️ Super Sets Workout Summary\n"
        text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        text += "📅 \(workout.fullFormattedDate)\n"
        text += "⏱ Duration: \(workout.formattedDuration)\n"
        text += "💪 \(workout.totalExercises) exercises · \(workout.totalSets) total sets\n"
        
        if let notes = workout.notes, !notes.isEmpty {
            text += "📝 \(notes)\n"
        }
        
        text += "\n"
        
        for group in workout.setsGroupedByLift {
            let color = group.lift.muscleGroup.displayName
            text += "▸ \(group.lift.name) (\(color))\n"
            
            for set in group.sets {
                text += "   Set \(set.setNumber): \(set.formattedDisplay)\n"
            }
            text += "\n"
        }
        
        text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        text += "Tracked with Super Sets 💪"
        
        return text
    }
    
    // MARK: - Personal Records
    
    /// Calculate personal records for EVERY lift the user has ever performed.
    /// Returns an array of PersonalRecord structs, one per unique lift.
    ///
    /// LEARNING NOTE:
    /// This is a "compute on read" approach — we calculate PRs fresh each time
    /// the Progress tab appears, rather than caching them. For most users (even
    /// with hundreds of workouts), this is fast enough because SwiftData queries
    /// are backed by SQLite. If performance ever becomes an issue, we could add
    /// a cached @Model for PRs and update them incrementally on each logSet().
    func calculateAllPRs() -> [PersonalRecord] {
        guard let context = modelContext else { return [] }
        
        // Fetch ALL completed sets (from non-active workouts)
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.workout?.isActive == false
            }
        )
        
        do {
            let allSets = try context.fetch(descriptor)
            
            // LEARNING NOTE:
            // Dictionary(grouping:by:) is a powerful Swift standard library method.
            // It takes a collection and a key function, and returns a dictionary
            // where each key maps to an array of matching elements.
            // Here we group all sets by their lift name.
            let grouped = Dictionary(grouping: allSets) { $0.liftDefinition?.name ?? "Unknown" }
            
            var records: [PersonalRecord] = []
            
            for (liftName, sets) in grouped {
                guard let firstSet = sets.first,
                      let lift = firstSet.liftDefinition else { continue }
                
                var pr = PersonalRecord(
                    liftName: liftName,
                    muscleGroup: lift.muscleGroup
                )
                
                for set in sets {
                    // Heaviest single set
                    if set.weight > pr.heaviestWeight {
                        pr.heaviestWeight = set.weight
                        pr.heaviestWeightDate = set.timestamp
                    }
                    
                    // Best volume set (weight × reps)
                    let volume = set.weight * Double(set.reps)
                    if volume > pr.bestVolume {
                        pr.bestVolume = volume
                        pr.bestVolumeDate = set.timestamp
                    }
                    
                    // Most reps in a single set
                    if set.reps > pr.mostReps {
                        pr.mostReps = set.reps
                        pr.mostRepsDate = set.timestamp
                    }
                    
                    // Estimated 1RM (Epley formula)
                    // LEARNING NOTE:
                    // The Epley formula: weight × (1 + reps / 30)
                    // This estimates the maximum weight you could lift for
                    // exactly 1 rep, based on a set at a given weight and rep count.
                    // It's most accurate for sets of 2-10 reps.
                    let epley1RM: Double
                    if set.reps == 1 {
                        epley1RM = set.weight
                    } else {
                        epley1RM = set.weight * (1.0 + Double(set.reps) / 30.0)
                    }
                    if epley1RM > pr.estimated1RM {
                        pr.estimated1RM = epley1RM
                        pr.estimated1RMDate = set.timestamp
                    }
                }
                
                records.append(pr)
            }
            
            // Sort by muscle group, then lift name for consistent display
            return records.sorted {
                if $0.muscleGroup.displayName == $1.muscleGroup.displayName {
                    return $0.liftName < $1.liftName
                }
                return $0.muscleGroup.displayName < $1.muscleGroup.displayName
            }
            
        } catch {
            print("Error calculating PRs: \(error)")
            return []
        }
    }
    
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
    
    // MARK: - Lift Progression Data
    
    /// Get progression data points for a specific lift (for line charts).
    /// Returns one data point per workout session: the max weight used that day.
    ///
    /// LEARNING NOTE:
    /// We group completed sets by their workout date, then take the max weight
    /// from each group. This gives us a clean "max weight over time" trend line.
    func liftProgression(for liftName: String) -> [LiftProgressionPoint] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.liftDefinition?.name == liftName &&
                workoutSet.workout?.isActive == false
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        
        do {
            let sets = try context.fetch(descriptor)
            
            // Group by workout (using workout date as key)
            // LEARNING NOTE:
            // We use Calendar.startOfDay() to normalize all timestamps from the
            // same workout to the same date key. Without this, sets logged at
            // slightly different times would be treated as separate sessions.
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: sets) { set in
                calendar.startOfDay(for: set.workout?.date ?? set.timestamp)
            }
            
            return grouped.map { date, daySets in
                let maxWeight = daySets.map(\.weight).max() ?? 0
                return LiftProgressionPoint(date: date, maxWeight: maxWeight)
            }
            .sorted { $0.date < $1.date }
            
        } catch {
            print("Error fetching lift progression: \(error)")
            return []
        }
    }
    
    // MARK: - Volume Trends
    
    /// Calculate total weekly volume (weight × reps) for the last 8 weeks.
    /// Used for the volume trends bar chart on the Progress tab.
    func weeklyVolumeTrends() -> [WeeklyVolume] {
        guard let context = modelContext else { return [] }
        
        let calendar = Calendar.current
        
        // LEARNING NOTE:
        // date(byAdding: .weekOfYear, value: -8) goes back 8 weeks from today.
        // We use Calendar for all date math because it correctly handles
        // daylight saving, month boundaries, and leap years.
        guard let eightWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) else {
            return []
        }
        
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { workoutSet in
                workoutSet.workout?.isActive == false &&
                workoutSet.timestamp >= eightWeeksAgo
            }
        )
        
        do {
            let sets = try context.fetch(descriptor)
            
            // Group by week
            let grouped = Dictionary(grouping: sets) { set -> Date in
                // Find the Monday of this set's week
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: set.timestamp)
                return calendar.date(from: components) ?? set.timestamp
            }
            
            // Build volume for each week
            var weeks: [WeeklyVolume] = []
            for i in 0..<8 {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -7 + i, to: Date()) else { continue }
                let normalizedStart = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
                let weekKey = calendar.date(from: normalizedStart) ?? weekStart
                
                let weekSets = grouped[weekKey] ?? []
                let totalVolume = weekSets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                
                weeks.append(WeeklyVolume(weekStart: weekKey, totalVolume: totalVolume))
            }
            
            return weeks
            
        } catch {
            print("Error calculating weekly volume: \(error)")
            return []
        }
    }
    
    // MARK: - Workout Stats Summary
    
    /// Total number of completed workouts.
    func totalCompletedWorkouts() -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isActive == false }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    /// Number of completed workouts this calendar week (Monday–Sunday).
    func workoutsThisWeek() -> Int {
        guard let context = modelContext else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isActive == false &&
                workout.date >= weekStart
            }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    /// Average workout duration in minutes across all completed workouts.
    func averageWorkoutDuration() -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.isActive == false }
        )
        
        do {
            let workouts = try context.fetch(descriptor)
            guard !workouts.isEmpty else { return 0 }
            
            let totalSeconds = workouts.reduce(0.0) { $0 + $1.durationSeconds }
            return Int(totalSeconds / Double(workouts.count) / 60.0)
        } catch {
            return 0
        }
    }
    
    /// Total sets logged across all completed workouts.
    func totalSetsAllTime() -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate<WorkoutSet> { $0.workout?.isActive == false }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Body Weight Tracking
    
    /// Log a new body weight entry.
    /// - Parameter weight: The weight value in the user's preferred unit.
    func logWeight(_ weight: Double) {
        guard let context = modelContext else { return }
        let entry = WeightEntry(weight: weight)
        context.insert(entry)
        save()
    }
    
    /// Fetch weight entries for the last N days (default 30).
    func weightEntries(days: Int = 30) -> [WeightEntry] {
        guard let context = modelContext else { return [] }
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate<WeightEntry> { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// The most recent weight entry, or nil if none exist.
    func latestWeight() -> WeightEntry? {
        guard let context = modelContext else { return nil }
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
    
    // MARK: - Calorie Estimates
    
    /// Estimated calories burned during a workout using MET formula.
    ///
    /// LEARNING NOTE:
    /// MET (Metabolic Equivalent of Task) is a standard measure of exercise intensity.
    /// MET × bodyWeight(kg) × duration(hours) = estimated calories burned.
    /// Resistance training ≈ 5.5 METs (moderate to vigorous weight lifting).
    /// For comparison: walking ≈ 3.5 METs, running ≈ 9.8 METs.
    func workoutCalories(for workout: Workout) -> Int {
        guard let profile = userProfile else { return 0 }
        let met = 5.5  // MET value for resistance training
        let durationHours = workout.durationSeconds / 3600.0
        return Int(met * profile.bodyWeightKg * durationHours)
    }
    
    /// Total estimated workout calories burned this week.
    func weeklyWorkoutCalories() -> Int {
        guard let context = modelContext else { return 0 }
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.isActive == false &&
                workout.date >= weekStart
            }
        )
        
        do {
            let workouts = try context.fetch(descriptor)
            return workouts.reduce(0) { $0 + workoutCalories(for: $1) }
        } catch {
            return 0
        }
    }
    
    // MARK: - Persistence
    
    /// Save pending changes to the database.
    private func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }
}
