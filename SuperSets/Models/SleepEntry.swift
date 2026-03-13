// SleepEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks sleep data — bedtime, wake time, quality rating.

import Foundation
import SwiftData

// MARK: - SleepSource

enum SleepSource: String, Codable, CaseIterable {
    case manual = "Manual"
    case healthKit = "HealthKit"
}

// MARK: - SleepEntry Model

@Model
final class SleepEntry {
    var date: Date = Date()
    var bedtime: Date = Date()
    var wakeTime: Date = Date()
    /// 1-5 quality rating (optional).
    var quality: Int?
    var sourceRaw: String = "Manual"

    var source: SleepSource {
        get { SleepSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// Duration in hours.
    var durationHours: Double {
        wakeTime.timeIntervalSince(bedtime) / 3600.0
    }

    var formattedDuration: String {
        let hours = Int(durationHours)
        let minutes = Int((durationHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    init(date: Date = Date(), bedtime: Date, wakeTime: Date, quality: Int? = nil, source: SleepSource = .manual) {
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = quality
        self.sourceRaw = source.rawValue
    }
}
