// WaterEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks daily water intake toward a daily goal.

import Foundation
import SwiftData

// MARK: - WaterEntry Model

@Model
final class WaterEntry {
    var date: Date
    /// Amount in ounces.
    var amount: Double
    /// Daily goal in ounces.
    var dailyGoal: Double

    init(date: Date = Date(), amount: Double, dailyGoal: Double = 128) {
        self.date = date
        self.amount = amount
        self.dailyGoal = dailyGoal
    }
}
