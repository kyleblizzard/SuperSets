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
    }

    /// When the workout started — used for the live elapsed timer.
    var workoutStartDate: Date
}
