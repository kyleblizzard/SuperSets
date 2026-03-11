// CalorieEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks daily calories burned and consumed.

import Foundation
import SwiftData

// MARK: - CalorieSource

enum CalorieSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
    case workout = "Workout"
}

// MARK: - CalorieEntry Model

@Model
final class CalorieEntry {
    var date: Date
    /// Active calories burned.
    var burned: Double
    /// Calories consumed (optional — user may not track food).
    var consumed: Double?
    var sourceRaw: String

    var source: CalorieSource {
        get { CalorieSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(date: Date = Date(), burned: Double, consumed: Double? = nil, source: CalorieSource = .manual) {
        self.date = date
        self.burned = burned
        self.consumed = consumed
        self.sourceRaw = source.rawValue
    }
}
