// WorkoutActivityAttributes.swift
// Super Sets — Widget Extension
//
// Duplicate of the shared Live Activity attributes model.
// Must stay in sync with SuperSets/Models/WorkoutActivityAttributes.swift.

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var currentLiftName: String
        var setCount: Int
        var lastSetDisplay: String
    }

    var workoutStartDate: Date
}
