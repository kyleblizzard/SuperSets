// HealthKitManager.swift
// Super Sets — The Workout Tracker
//
// @Observable singleton for HealthKit integration.
// Reads steps, active energy, and sleep analysis.

import Foundation
import HealthKit
import SwiftData

// MARK: - HealthKitManager

@Observable
final class HealthKitManager {

    // MARK: State

    var isAuthorized = false
    var todaySteps: Int = 0
    var todayActiveCalories: Double = 0

    // MARK: Private

    private let healthStore = HKHealthStore()
    private var modelContext: ModelContext?

    // MARK: Setup

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKCategoryType(.sleepAnalysis)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchTodayData()
        } catch {
            print("HealthKit authorization error: \(error)")
        }
    }

    // MARK: Fetch Today's Data

    @MainActor
    func fetchTodayData() async {
        await fetchTodaySteps()
        await fetchTodayActiveCalories()
    }

    // MARK: Steps

    @MainActor
    func fetchTodaySteps() async {
        let stepsType = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        do {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: stepsType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            todaySteps = Int(steps)

            // Save to SwiftData
            saveStepsEntry(count: Int(steps), date: startOfDay)
        } catch {
            print("Steps fetch error: \(error)")
        }
    }

    @MainActor
    func fetchSteps(for date: Date) async -> Int {
        let stepsType = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        do {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: stepsType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            return Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch {
            return 0
        }
    }

    // MARK: Active Calories

    @MainActor
    func fetchTodayActiveCalories() async {
        let calorieType = HKQuantityType(.activeEnergyBurned)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        do {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: .quantitySample(type: calorieType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            let cal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            todayActiveCalories = cal

            saveCalorieEntry(burned: cal, date: startOfDay)
        } catch {
            print("Calorie fetch error: \(error)")
        }
    }

    // MARK: Sleep

    @MainActor
    func fetchSleep(for date: Date) async -> (bedtime: Date, wakeTime: Date, duration: Double)? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay),
              let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: previousDay, end: nextDay, options: .strictStartDate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            guard let first = samples.first, let last = samples.last else { return nil }
            let bedtime = first.startDate
            let wakeTime = last.endDate
            let duration = wakeTime.timeIntervalSince(bedtime) / 3600.0
            return (bedtime: bedtime, wakeTime: wakeTime, duration: duration)
        } catch {
            return nil
        }
    }

    // MARK: Fetch Week of Steps

    @MainActor
    func fetchWeeklySteps() async -> [(date: Date, count: Int)] {
        var results: [(date: Date, count: Int)] = []
        let calendar = Calendar.current

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let steps = await fetchSteps(for: date)
            results.append((date: calendar.startOfDay(for: date), count: steps))
        }
        return results
    }

    // MARK: Persistence Helpers

    private func saveStepsEntry(count: Int, date: Date) {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Check for existing entry today
        let descriptor = FetchDescriptor<StepsEntry>(
            predicate: #Predicate<StepsEntry> { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.count = count
        } else {
            let entry = StepsEntry(date: startOfDay, count: count, source: .healthKit)
            context.insert(entry)
        }
        try? context.save()
    }

    private func saveCalorieEntry(burned: Double, date: Date) {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<CalorieEntry>(
            predicate: #Predicate<CalorieEntry> { $0.date >= startOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        if let existing = (try? context.fetch(descriptor))?.first {
            existing.burned = burned
        } else {
            let entry = CalorieEntry(date: startOfDay, burned: burned, source: .healthKit)
            context.insert(entry)
        }
        try? context.save()
    }
}
