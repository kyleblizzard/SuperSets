//
//  PreloadedLifts.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Contains the catalog of ~90 pre-loaded exercises organized by muscle group.
//  These lifts are inserted into the database on first launch.
//  Users can also create custom lifts beyond this catalog.

import Foundation
import SwiftData

/// Contains all pre-loaded lift definitions organized by muscle group
struct PreloadedLifts {
    
    /// Creates and returns all pre-loaded lift definitions
    /// - Returns: Array of LiftDefinition objects marked as non-custom
    // LEARNING NOTE: `static` means this function belongs to the struct itself,
    // not to an instance. We can call it with PreloadedLifts.allLifts()
    static func allLifts() -> [LiftDefinition] {
        var lifts: [LiftDefinition] = []
        
        // LEARNING NOTE: We iterate through each muscle group and its exercises
        for (muscleGroup, exerciseNames) in exercisesByMuscleGroup {
            for name in exerciseNames {
                let lift = LiftDefinition(
                    name: name,
                    muscleGroup: muscleGroup,
                    isCustom: false,
                    dateCreated: Date()
                )
                lifts.append(lift)
            }
        }
        
        return lifts
    }
    
    /// Dictionary mapping muscle groups to their exercise names
    // LEARNING NOTE: `private static let` means this is a constant that belongs
    // to the struct and can't be accessed from outside this file
    private static let exercisesByMuscleGroup: [MuscleGroup: [String]] = [
        
        // MARK: - Chest (8 exercises)
        .chest: [
            "Bench Press",
            "Incline Bench Press",
            "Decline Bench Press",
            "Dumbbell Press",
            "Incline Dumbbell Press",
            "Cable Fly",
            "Dumbbell Fly",
            "Push-up"
        ],
        
        // MARK: - Lats (7 exercises)
        .lats: [
            "Pull-up",
            "Chin-up",
            "Lat Pulldown",
            "Bent-Over Barbell Row",
            "Dumbbell Row",
            "Seated Cable Row",
            "T-Bar Row"
        ],
        
        // MARK: - Lower Back (5 exercises)
        .lowerBack: [
            "Deadlift",
            "Romanian Deadlift",
            "Good Morning",
            "Back Extension",
            "Hyperextension"
        ],
        
        // MARK: - Traps (5 exercises)
        .traps: [
            "Barbell Shrug",
            "Dumbbell Shrug",
            "Cable Shrug",
            "Upright Row",
            "Face Pull"
        ],
        
        // MARK: - Neck (4 exercises)
        .neck: [
            "Neck Curl",
            "Neck Extension",
            "Neck Side Bend",
            "Neck Bridge"
        ],
        
        // MARK: - Shoulders (9 exercises)
        .shoulders: [
            "Overhead Press",
            "Seated Dumbbell Press",
            "Arnold Press",
            "Lateral Raise",
            "Front Raise",
            "Rear Delt Fly",
            "Cable Lateral Raise",
            "Machine Shoulder Press",
            "Behind the Neck Press"
        ],
        
        // MARK: - Abs (8 exercises)
        .abs: [
            "Crunch",
            "Sit-up",
            "Leg Raise",
            "Hanging Leg Raise",
            "Plank",
            "Side Plank",
            "Cable Crunch",
            "Ab Wheel Rollout"
        ],
        
        // MARK: - Quads (7 exercises)
        .quads: [
            "Squat",
            "Front Squat",
            "Leg Press",
            "Hack Squat",
            "Leg Extension",
            "Bulgarian Split Squat",
            "Goblet Squat"
        ],
        
        // MARK: - Leg Biceps (Hamstrings) (6 exercises)
        .legBiceps: [
            "Leg Curl",
            "Romanian Deadlift",
            "Stiff-Leg Deadlift",
            "Nordic Curl",
            "Glute-Ham Raise",
            "Seated Leg Curl"
        ],
        
        // MARK: - Glutes (7 exercises)
        .glutes: [
            "Hip Thrust",
            "Barbell Hip Thrust",
            "Glute Bridge",
            "Cable Pull-Through",
            "Kickback",
            "Step-up",
            "Bulgarian Split Squat"
        ],
        
        // MARK: - Calves (5 exercises)
        .calves: [
            "Standing Calf Raise",
            "Seated Calf Raise",
            "Donkey Calf Raise",
            "Calf Press on Leg Press",
            "Single-Leg Calf Raise"
        ],
        
        // MARK: - Biceps (9 exercises)
        .biceps: [
            "Barbell Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Preacher Curl",
            "Cable Curl",
            "Concentration Curl",
            "Incline Dumbbell Curl",
            "EZ-Bar Curl",
            "21s"
        ],
        
        // MARK: - Triceps (9 exercises)
        .triceps: [
            "Close-Grip Bench Press",
            "Tricep Dip",
            "Tricep Pushdown",
            "Overhead Tricep Extension",
            "Skull Crusher",
            "Diamond Push-up",
            "Dumbbell Kickback",
            "Cable Overhead Extension",
            "Bench Dip"
        ]
    ]
    
    /// Seeds the database with pre-loaded lifts if they don't already exist
    /// - Parameter modelContext: The SwiftData model context
    // LEARNING NOTE: This function checks if lifts already exist before inserting
    // to avoid duplicates when the app launches multiple times
    static func seedIfNeeded(modelContext: ModelContext) {
        // Check if we already have lifts in the database
        let descriptor = FetchDescriptor<LiftDefinition>()
        
        // LEARNING NOTE: try? means "try this and return nil if it fails"
        // We use optional binding to safely unwrap the result
        if let existingLifts = try? modelContext.fetch(descriptor),
           !existingLifts.isEmpty {
            // Already seeded, nothing to do
            return
        }
        
        // No lifts exist yet, insert all pre-loaded lifts
        let lifts = allLifts()
        for lift in lifts {
            modelContext.insert(lift)
        }
        
        // LEARNING NOTE: Save the context to persist changes to disk
        try? modelContext.save()
    }
}
