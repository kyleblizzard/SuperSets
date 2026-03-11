// WorkoutActivityAttributes.swift
// Super Sets — The Workout Tracker
//
// Shared data model for the Live Activity (lock screen workout widget).
// Used by both the main app (to start/update) and the widget extension (to render).

import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {

    /// Dynamic state — updated during the workout.
    struct ContentState: Codable, Hashable {
        /// Name of the currently selected lift (e.g. "Bench Press").
        var currentLiftName: String
        /// Total number of sets logged so far in this workout.
        var setCount: Int
        /// Formatted display of the last logged set (e.g. "185 x 8" or "30 min").
        var lastSetDisplay: String
        /// Weight value shown in the lock screen input.
        var pendingWeight: Double
        /// Reps value shown in the lock screen input.
        var pendingReps: Int
        /// Step size for weight +/- buttons (5.0 for lbs, 2.5 for kg).
        var weightIncrement: Double
        /// Display label for weight unit ("lbs" or "kg").
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

        /// Backward-compatible decoding — new fields fall back to defaults
        /// if absent (e.g. an activity started before this update).
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

    /// When the workout started — used for the live elapsed timer.
    var workoutStartDate: Date
}
