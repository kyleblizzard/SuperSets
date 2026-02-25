// WorkoutSet.swift
// Super Sets — The Workout Tracker
//
// A WorkoutSet is one individual set within a workout. For example:
// "Bench Press — Set 2: 185 lbs × 8 reps"
//
// This is the most granular piece of data in the app. Everything builds
// up from here: a Workout contains many WorkoutSets, and each WorkoutSet
// references which LiftDefinition it belongs to.
//
// LEARNING NOTE:
// The name "WorkoutSet" avoids conflicting with Swift's built-in Set type.
// Naming collisions with standard library types is a common pitfall.

import Foundation
import SwiftData

// MARK: - WorkoutSet Model

@Model
final class WorkoutSet {
    
    // MARK: Properties
    
    /// The weight used for this set, in the user's preferred unit (lbs or kg).
    var weight: Double
    
    /// How many repetitions were completed.
    var reps: Int
    
    /// Which set number this is for this particular lift within this workout.
    /// Auto-incremented by WorkoutManager — the user never types this.
    ///
    /// Example: If the user does 4 sets of Bench Press, they'll be numbered 1, 2, 3, 4.
    /// If they then switch to Incline Press, that starts fresh at 1.
    var setNumber: Int
    
    /// When this set was logged. Used for ordering and time-based analysis.
    var timestamp: Date
    
    // MARK: Relationships
    
    /// The workout session this set belongs to.
    /// Every set MUST belong to a workout.
    ///
    /// LEARNING NOTE:
    /// This is the "child" side of the Workout ↔ WorkoutSet relationship.
    /// SwiftData uses the `inverse` parameter on the parent side (Workout.sets)
    /// to wire these together automatically.
    var workout: Workout?
    
    /// Which exercise this set is for.
    /// Every set MUST be linked to a LiftDefinition.
    var liftDefinition: LiftDefinition?
    
    // MARK: Computed Properties
    
    /// Formatted display string: "185 × 8" (weight × reps)
    var formattedDisplay: String {
        let weightStr: String
        // LEARNING NOTE:
        // truncatingRemainder checks if a Double is a whole number.
        // If weight is 185.0, we show "185". If it's 185.5, we show "185.5".
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            weightStr = String(format: "%.0f", weight)
        } else {
            weightStr = String(format: "%.1f", weight)
        }
        return "\(weightStr) × \(reps)"
    }
    
    /// Estimated one-rep max using the Brzycki formula.
    /// Useful for comparing strength across different rep ranges.
    var estimatedOneRepMax: Double {
        guard reps > 0, reps < 37 else { return weight }
        if reps == 1 { return weight }
        return weight * (36.0 / (37.0 - Double(reps)))
    }
    
    // MARK: Initializer
    
    /// Creates a new workout set.
    /// - Parameters:
    ///   - weight: Weight used (in user's preferred unit)
    ///   - reps: Number of repetitions
    ///   - setNumber: Auto-assigned set number for this lift in this workout
    ///   - workout: The workout this set belongs to
    ///   - liftDefinition: Which exercise this set is for
    init(
        weight: Double,
        reps: Int,
        setNumber: Int,
        workout: Workout,
        liftDefinition: LiftDefinition
    ) {
        self.weight = weight
        self.reps = reps
        self.setNumber = setNumber
        self.timestamp = Date()
        self.workout = workout
        self.liftDefinition = liftDefinition
    }
}
