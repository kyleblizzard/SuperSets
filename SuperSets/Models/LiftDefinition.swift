// LiftDefinition.swift
// Super Sets — The Workout Tracker
//
// A LiftDefinition is a template for an exercise — like "Bench Press" or "Squat."
// It does NOT store any actual workout data. Think of it as the dictionary entry
// for a lift. The actual sets/reps/weight are stored in WorkoutSet.
//
// LEARNING NOTE:
// @Model is SwiftData's way of marking a class for database persistence.
// Unlike Core Data (the older Apple framework), SwiftData uses plain Swift
// classes with this single macro. Behind the scenes, SwiftData generates all
// the database schema, migration, and query code for you.

import Foundation
import SwiftData

// MARK: - LiftDefinition Model

@Model
final class LiftDefinition {
    
    // MARK: Properties
    
    /// The name of the exercise (e.g., "Bench Press", "Barbell Curl")
    var name: String
    
    /// Which muscle group this lift targets.
    /// Stored as a String in the database (because of the enum's String raw value),
    /// but we work with MuscleGroup in code for type safety.
    var muscleGroupRaw: String
    
    /// Whether this lift was created by the user (true) or came pre-loaded (false).
    var isCustom: Bool
    
    /// When this lift definition was first created.
    var dateCreated: Date
    
    /// The last time this lift was used in any workout.
    /// Used to populate the "recent lifts" circle buttons on the workout screen.
    /// nil means it has never been used.
    var lastUsedDate: Date?
    
    // MARK: Relationships
    
    /// All the sets that have ever been performed for this lift, across all workouts.
    ///
    /// LEARNING NOTE:
    /// @Relationship tells SwiftData about the connection between models.
    /// .cascade means: if we delete this LiftDefinition, also delete all its sets.
    /// The `inverse:` parameter tells SwiftData which property on WorkoutSet
    /// points back to this LiftDefinition, so the relationship works both ways.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.liftDefinition)
    var sets: [WorkoutSet] = []
    
    // MARK: Computed Properties
    
    /// Type-safe access to the muscle group.
    /// We store the raw string in the database but use this computed property
    /// everywhere in the app so we get the benefits of Swift's type system.
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }
    
    // MARK: Initializer
    
    /// Creates a new lift definition.
    /// - Parameters:
    ///   - name: The exercise name (e.g., "Deadlift")
    ///   - muscleGroup: Which body part this targets
    ///   - isCustom: true if user-created, false if from the pre-loaded catalog
    init(name: String, muscleGroup: MuscleGroup, isCustom: Bool = false) {
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.isCustom = isCustom
        self.dateCreated = Date()
        self.lastUsedDate = nil
    }
}
