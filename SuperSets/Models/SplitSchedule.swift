// SplitSchedule.swift
// Super Sets — The Workout Tracker
//
// Defines a repeating workout split schedule (e.g., Push/Pull/Legs/Rest).

import Foundation
import SwiftData

// MARK: - SplitDay

enum SplitDay: String, CaseIterable, Codable, Identifiable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case upper = "Upper"
    case lower = "Lower"
    case fullBody = "Full Body"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case cardio = "Cardio"
    case rest = "Rest"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .legs: return "figure.walk"
        case .upper: return "figure.arms.open"
        case .lower: return "figure.run"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .chest: return "figure.arms.open"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.boxing"
        case .cardio: return "heart.fill"
        case .rest: return "bed.double.fill"
        }
    }
}

// MARK: - SplitSchedule Model

@Model
final class SplitSchedule {
    var name: String
    /// Stored as comma-separated SplitDay raw values.
    var patternRaw: String
    var startDate: Date
    var isActive: Bool
    var reminderEnabled: Bool
    /// Hour and minute stored as "HH:mm" for simplicity.
    var reminderTimeRaw: String

    var pattern: [SplitDay] {
        get {
            patternRaw.split(separator: ",").compactMap { SplitDay(rawValue: String($0)) }
        }
        set {
            patternRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var reminderHour: Int {
        let parts = reminderTimeRaw.split(separator: ":")
        return Int(parts.first ?? "8") ?? 8
    }

    var reminderMinute: Int {
        let parts = reminderTimeRaw.split(separator: ":")
        return Int(parts.last ?? "0") ?? 0
    }

    /// What day of the pattern falls on a given date.
    func splitDay(for date: Date) -> SplitDay? {
        guard !pattern.isEmpty else { return nil }
        let calendar = Calendar.current
        let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0
        guard daysSinceStart >= 0 else { return nil }
        let index = daysSinceStart % pattern.count
        return pattern[index]
    }

    init(name: String, pattern: [SplitDay], startDate: Date = Date(), isActive: Bool = true, reminderEnabled: Bool = false, reminderTime: String = "08:00") {
        self.name = name
        self.patternRaw = pattern.map(\.rawValue).joined(separator: ",")
        self.startDate = startDate
        self.isActive = isActive
        self.reminderEnabled = reminderEnabled
        self.reminderTimeRaw = reminderTime
    }
}
