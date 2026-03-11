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
        var pendingWeight: Double
        var pendingReps: Int
        var weightIncrement: Double
        var unitLabel: String

        init(
            currentLiftName: String,
            setCount: Int,
            lastSetDisplay: String,
            pendingWeight: Double = 0,
            pendingReps: Int = 8,
            weightIncrement: Double = 5.0,
            unitLabel: String = "lbs"
        ) {
            self.currentLiftName = currentLiftName
            self.setCount = setCount
            self.lastSetDisplay = lastSetDisplay
            self.pendingWeight = pendingWeight
            self.pendingReps = pendingReps
            self.weightIncrement = weightIncrement
            self.unitLabel = unitLabel
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            currentLiftName = try c.decode(String.self, forKey: .currentLiftName)
            setCount        = try c.decode(Int.self, forKey: .setCount)
            lastSetDisplay  = try c.decode(String.self, forKey: .lastSetDisplay)
            pendingWeight   = try c.decodeIfPresent(Double.self, forKey: .pendingWeight) ?? 0
            pendingReps     = try c.decodeIfPresent(Int.self, forKey: .pendingReps) ?? 8
            weightIncrement = try c.decodeIfPresent(Double.self, forKey: .weightIncrement) ?? 5.0
            unitLabel       = try c.decodeIfPresent(String.self, forKey: .unitLabel) ?? "lbs"
        }
    }

    var workoutStartDate: Date
}
