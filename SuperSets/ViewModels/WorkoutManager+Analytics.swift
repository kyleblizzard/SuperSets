// WorkoutManager+Analytics.swift
// Super Sets — The Workout Tracker
//
// Extension: Personal records, lift progression, volume trends,
// workout stats, and summary text generation.
//
// LEARNING NOTE:
// Splitting a large class into extensions across multiple files is
// standard Swift practice. Each file focuses on a related group of
// methods, making the codebase easier to navigate. All extensions
// share the same stored properties defined in WorkoutManager.swift.

import Foundation
import SwiftData

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
        Formatters.shortDate.string(from: weekStart)
    }
}

// MARK: - SetDisplayRow

/// Represents either a regular set or a grouped super set block in the sets table.
enum SetDisplayRow: Identifiable {
    case regular(WorkoutSet)
    case superSet(groupId: String, setNumber: Int, sets: [WorkoutSet])

    var id: String {
        switch self {
        case .regular(let set):
            return "regular-\(set.timestamp.timeIntervalSince1970)"
        case .superSet(let groupId, _, _):
            return "ss-\(groupId)"
        }
    }
}

// MARK: - WorkoutManager + Analytics

extension WorkoutManager {

    // MARK: Personal Records

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

    // MARK: Lift Progression

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

    // MARK: Volume Trends

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

    // MARK: Workout Stats Summary

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

    // MARK: Workout Summary Text

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
}
