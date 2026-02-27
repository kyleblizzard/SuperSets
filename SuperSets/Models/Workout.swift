// Workout.swift
// Super Sets — The Workout Tracker
//
// A Workout represents a single training session. When the user taps
// "Start Workout," we create one of these. When they tap "End Workout,"
// we set the endDate and mark isActive = false.
//
// Only ONE workout can be active at a time. This is enforced by
// WorkoutManager, not by the model itself.

import Foundation
import SwiftData

// MARK: - Workout Model

@Model
final class Workout {
    
    // MARK: Properties
    
    /// When this workout session started.
    var date: Date
    
    /// When the user tapped "End Workout." nil while the workout is in progress.
    var endDate: Date?
    
    /// Optional notes the user can add when ending the workout.
    var notes: String?
    
    /// true while the workout is happening, false after it's ended.
    /// Only one Workout should have isActive == true at any time.
    var isActive: Bool
    
    // MARK: Relationships
    
    /// Every set logged during this workout.
    ///
    /// LEARNING NOTE:
    /// The inverse relationship connects back to WorkoutSet.workout,
    /// creating a two-way link. When you access workout.sets, SwiftData
    /// automatically fetches all WorkoutSets that reference this Workout.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    var sets: [WorkoutSet] = []
    
    // MARK: Computed Properties
    
    /// How long the workout lasted, formatted as "1h 23m" or "45m".
    /// Returns nil if the workout hasn't ended yet and falls back to
    /// the elapsed time since start.
    var formattedDuration: String {
        let end = endDate ?? Date()
        let interval = end.timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Duration in seconds (for calculations, not display).
    var durationSeconds: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(date)
    }
    
    /// All unique lifts performed in this workout, preserving the order
    /// they were first performed.
    ///
    /// LEARNING NOTE:
    /// We can't just use a Set here because we want to preserve ORDER
    /// (the sequence the user did exercises). We use an array and check
    /// for duplicates manually using `contains(where:)`.
    var uniqueLifts: [LiftDefinition] {
        var seen: [String] = []
        var result: [LiftDefinition] = []
        
        let sortedSets = sets.sorted { $0.timestamp < $1.timestamp }
        for workoutSet in sortedSets {
            if let lift = workoutSet.liftDefinition, !seen.contains(lift.name) {
                seen.append(lift.name)
                result.append(lift)
            }
        }
        return result
    }
    
    /// Groups all sets by their lift definition, preserving lift order.
    /// Returns tuples of (lift, sets) sorted by when each lift was first performed.
    ///
    /// LEARNING NOTE:
    /// This is a common pattern — you have a flat list of items and need to
    /// group them. Dictionary(grouping:by:) is the Swift standard library way
    /// to do this, but we need ordered results, so we build it manually.
    var setsGroupedByLift: [(lift: LiftDefinition, sets: [WorkoutSet])] {
        let lifts = uniqueLifts
        return lifts.map { lift in
            let liftSets = sets
                .filter { $0.liftDefinition?.name == lift.name }
                .sorted { $0.setNumber < $1.setNumber }
            return (lift: lift, sets: liftSets)
        }
    }
    
    /// The total number of sets across all exercises.
    var totalSets: Int { sets.count }
    
    /// The total number of unique exercises performed.
    var totalExercises: Int { uniqueLifts.count }
    
    /// Date formatted for display: "Mon, Jan 15"
    var formattedDate: String {
        Formatters.weekdayShortDate.string(from: date)
    }

    /// Full date for detail views: "Monday, January 15, 2026"
    var fullFormattedDate: String {
        Formatters.fullDate.string(from: date)
    }
    
    // MARK: Initializer
    
    init() {
        self.date = Date()
        self.endDate = nil
        self.notes = nil
        self.isActive = true
    }
}
