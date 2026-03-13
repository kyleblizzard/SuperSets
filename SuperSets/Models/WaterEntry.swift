// WaterEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks daily water intake toward a daily goal.

import Foundation
import SwiftData

// MARK: - WaterEntry Model

@Model
final class WaterEntry {
    var date: Date = Date()
    /// Amount in ounces.
    var amount: Double = 0
    /// Daily goal in ounces.
    var dailyGoal: Double = 128

    init(date: Date = Date(), amount: Double, dailyGoal: Double = 128) {
        self.date = date
        self.amount = amount
        self.dailyGoal = dailyGoal
    }
}
