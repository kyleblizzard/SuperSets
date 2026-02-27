// WorkoutManager+BodyTracking.swift
// Super Sets — The Workout Tracker
//
// Extension: Body weight logging, weight entry queries,
// and calorie estimation using the MET formula.

import Foundation
import SwiftData

// MARK: - WorkoutManager + Body Tracking

extension WorkoutManager {

    // MARK: Body Weight Tracking

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

    // MARK: Calorie Estimates

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
}
