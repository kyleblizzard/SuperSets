//
//  LiftDefinition.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Represents a specific exercise (e.g., "Bench Press", "Squat").
//  Can be pre-loaded from our catalog or custom-created by the user.
//  Tracks when it was created and last used for sorting recent lifts.

import Foundation
import SwiftData

// LEARNING NOTE: @Model is a SwiftData macro that turns this class into a database entity.
// This means SwiftData will automatically save and retrieve LiftDefinition objects.
@Model
final class LiftDefinition {
    
    // MARK: - Properties
    
    /// The name of the lift (e.g., "Bench Press")
    var name: String
    
    /// Which muscle group this lift primarily targets
    var muscleGroup: MuscleGroup
    
    /// Whether this lift was created by the user (vs pre-loaded)
    var isCustom: Bool
    
    /// When this lift was first created/added to the database
    var dateCreated: Date
    
    /// The last time this lift was selected/used in a workout
    // LEARNING NOTE: The `?` means this is optional - it might be nil if never used
    var lastUsedDate: Date?
    
    // LEARNING NOTE: @Relationship tells SwiftData how this model relates to others.
    // This creates a one-to-many relationship: one lift can have many sets.
    // The `deleteRule: .cascade` means if we delete a lift, all its sets are deleted too.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.liftDefinition)
    var sets: [WorkoutSet] = []
    
    // MARK: - Initialization
    
    /// Creates a new lift definition
    /// - Parameters:
    ///   - name: The name of the lift
    ///   - muscleGroup: Which muscle group this targets
    ///   - isCustom: Whether this is user-created (default: true)
    ///   - dateCreated: When this was created (default: now)
    init(
        name: String,
        muscleGroup: MuscleGroup,
        isCustom: Bool = true,
        dateCreated: Date = Date()
    ) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.isCustom = isCustom
        self.dateCreated = dateCreated
        self.lastUsedDate = nil
    }
}

// LEARNING NOTE: @Model automatically makes this class conform to Identifiable
// with an `id` property, so we can use it directly in SwiftUI ForEach loops.

