// GoalSetting.swift
// Super Sets — The Workout Tracker
//
// User's weight/fitness goal with calorie target calculation.

import Foundation
import SwiftData

// MARK: - GoalType

enum GoalType: String, CaseIterable, Codable, Identifiable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case maintenance = "Maintenance"

    var id: Self { self }
}

// MARK: - GoalSetting Model

@Model
final class GoalSetting {
    var typeRaw: String
    /// Target weight in user's preferred unit.
    var targetWeight: Double
    /// Rate of change in lbs per week (e.g. 1.0 for 1 lb/week).
    var weeklyRate: Double
    /// Calculated daily calorie target.
    var dailyCalorieTarget: Int
    var startDate: Date

    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .maintenance }
        set { typeRaw = newValue.rawValue }
    }

    /// Calorie adjustment per day: weeklyRate × 3500 / 7.
    var dailyCalorieAdjustment: Int {
        Int(weeklyRate * 3500.0 / 7.0)
    }

    init(type: GoalType = .maintenance, targetWeight: Double = 180, weeklyRate: Double = 1.0, dailyCalorieTarget: Int = 2000, startDate: Date = Date()) {
        self.typeRaw = type.rawValue
        self.targetWeight = targetWeight
        self.weeklyRate = weeklyRate
        self.dailyCalorieTarget = dailyCalorieTarget
        self.startDate = startDate
    }
}
