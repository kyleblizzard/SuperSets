//
//  WorkoutSet.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Represents a single set in a workout (e.g., "225 lbs × 8 reps").
//  Each set belongs to both a Workout and a LiftDefinition.
//  The set number is auto-incremented per lift per workout.

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    
    // MARK: - Properties
    
    /// Weight lifted (in the user's preferred unit - lbs or kg)
    var weight: Double
    
    /// Number of repetitions performed
    var reps: Int
    
    /// Which set number this is for the current lift in the current workout
    // LEARNING NOTE: This is automatically calculated when adding a set
    // (e.g., first set = 1, second set = 2, etc.)
    var setNumber: Int
    
    /// When this set was logged
    var timestamp: Date
    
    // MARK: - Relationships
    
    /// The workout this set belongs to
    // LEARNING NOTE: The inverse relationship is defined in Workout.sets
    var workout: Workout?
    
    /// The lift definition (exercise) this set is for
    var liftDefinition: LiftDefinition?
    
    // MARK: - Initialization
    
    /// Creates a new workout set
    /// - Parameters:
    ///   - weight: Weight lifted in user's preferred unit
    ///   - reps: Number of repetitions
    ///   - setNumber: Which set this is (1-indexed)
    ///   - timestamp: When this set was logged (default: now)
    ///   - workout: The workout this belongs to
    ///   - liftDefinition: The lift this set is for
    init(
        weight: Double,
        reps: Int,
        setNumber: Int,
        timestamp: Date = Date(),
        workout: Workout? = nil,
        liftDefinition: LiftDefinition? = nil
    ) {
        self.weight = weight
        self.reps = reps
        self.setNumber = setNumber
        self.timestamp = timestamp
        self.workout = workout
        self.liftDefinition = liftDefinition
    }
    
    // MARK: - Computed Properties
    
    /// A formatted string showing weight and reps (e.g., "225 × 8")
    var formattedSet: String {
        // LEARNING NOTE: String interpolation with \() lets us insert values into strings
        let weightString = String(format: "%.1f", weight)
        return "\(weightString) × \(reps)"
    }
    
    /// Total volume for this set (weight × reps)
    var volume: Double {
        weight * Double(reps)
    }
}

// LEARNING NOTE: @Model automatically makes this class conform to Identifiable
// with an `id` property, so we can use it directly in SwiftUI ForEach loops.

