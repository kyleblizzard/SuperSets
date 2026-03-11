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

    /// Delete a weight entry.
    func deleteWeightEntry(_ entry: WeightEntry) {
        guard let context = modelContext else { return }
        context.delete(entry)
        save()
    }

    // MARK: Body Measurements

    /// Log a body measurement.
    func logBodyMeasurement(type: MeasurementType, value: Double, unit: MeasurementUnit = .inches) {
        guard let context = modelContext else { return }
        let entry = BodyMeasurement(measurementType: type, value: value, unit: unit)
        context.insert(entry)
        save()
    }

    /// Fetch measurements for a specific type, sorted by date.
    func bodyMeasurements(for type: MeasurementType, days: Int = 365) -> [BodyMeasurement] {
        guard let context = modelContext else { return [] }
        let typeRaw = type.rawValue
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return [] }

        let descriptor = FetchDescriptor<BodyMeasurement>(
            predicate: #Predicate<BodyMeasurement> {
                $0.measurementTypeRaw == typeRaw && $0.date >= startDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Latest measurement for each type.
    func latestMeasurements() -> [MeasurementType: BodyMeasurement] {
        guard let context = modelContext else { return [:] }
        let descriptor = FetchDescriptor<BodyMeasurement>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor) else { return [:] }

        var result: [MeasurementType: BodyMeasurement] = [:]
        for m in all {
            if result[m.measurementType] == nil {
                result[m.measurementType] = m
            }
        }
        return result
    }

    /// Delete a body measurement.
    func deleteBodyMeasurement(_ entry: BodyMeasurement) {
        guard let context = modelContext else { return }
        context.delete(entry)
        save()
    }

    // MARK: Body Fat

    /// Log a body fat percentage entry.
    func logBodyFat(percentage: Double, method: BodyFatMethod = .scale) {
        guard let context = modelContext else { return }
        let entry = BodyFatEntry(percentage: percentage, method: method)
        context.insert(entry)
        save()
    }

    /// Fetch body fat entries sorted by date.
    func bodyFatEntries(days: Int = 365) -> [BodyFatEntry] {
        guard let context = modelContext else { return [] }
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return [] }

        let descriptor = FetchDescriptor<BodyFatEntry>(
            predicate: #Predicate<BodyFatEntry> { $0.date >= startDate },
            sortBy: [SortDescriptor(\.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Latest body fat entry.
    func latestBodyFat() -> BodyFatEntry? {
        guard let context = modelContext else { return nil }
        var descriptor = FetchDescriptor<BodyFatEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    /// Delete a body fat entry.
    func deleteBodyFat(_ entry: BodyFatEntry) {
        guard let context = modelContext else { return }
        context.delete(entry)
        save()
    }

    // MARK: Goal Setting

    /// Fetch the active goal setting.
    func activeGoal() -> GoalSetting? {
        guard let context = modelContext else { return nil }
        var descriptor = FetchDescriptor<GoalSetting>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: Calorie Estimates

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
