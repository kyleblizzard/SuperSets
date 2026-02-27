// WorkoutSplit.swift
// Super Sets — The Workout Tracker
//
// A workout split is a template that defines which exercises to perform
// in a workout session. Examples: "Push Day", "Upper Body A", "Leg Day".
//
// Users can create splits manually, save them from completed workouts,
// or use pre-seeded templates like Push/Pull/Legs.

import Foundation
import SwiftData

// MARK: - WorkoutSplit Model

@Model
final class WorkoutSplit {

    // MARK: Properties

    /// The name of this split (e.g., "Push Day", "Upper Body A").
    var name: String

    /// JSON-encoded array of lift names in workout order.
    var liftNamesJSON: Data

    /// When this split was created.
    var dateCreated: Date

    /// True for pre-seeded templates, false for user-created splits.
    var isPreset: Bool

    // MARK: Computed Properties

    /// Type-safe access to the ordered list of lift names.
    var liftNames: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: liftNamesJSON)) ?? []
        }
        set {
            liftNamesJSON = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Number of exercises in this split.
    var exerciseCount: Int { liftNames.count }

    // MARK: Initializer

    init(name: String, liftNames: [String], isPreset: Bool = false) {
        self.name = name
        self.liftNamesJSON = (try? JSONEncoder().encode(liftNames)) ?? Data()
        self.dateCreated = Date()
        self.isPreset = isPreset
    }
}
