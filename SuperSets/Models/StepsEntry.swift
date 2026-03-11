// StepsEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks daily step count.

import Foundation
import SwiftData

// MARK: - StepsSource

enum StepsSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

// MARK: - StepsEntry Model

@Model
final class StepsEntry {
    var date: Date
    var count: Int
    var sourceRaw: String

    var source: StepsSource {
        get { StepsSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(date: Date = Date(), count: Int, source: StepsSource = .manual) {
        self.date = date
        self.count = count
        self.sourceRaw = source.rawValue
    }
}
