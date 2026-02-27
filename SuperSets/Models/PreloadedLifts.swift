// PreloadedLifts.swift
// Super Sets — The Workout Tracker
//
// This file contains the full catalog of pre-loaded exercises.
// On first app launch, WorkoutManager checks if the database is empty
// and seeds it with all of these lifts.
//
// LEARNING NOTE:
// We use a static property on a struct (not an instance). This means
// the data exists once in memory and doesn't require creating an object.
// The dictionary maps MuscleGroup → [String], where each string is a lift name.

import Foundation

// MARK: - Preloaded Lift Catalog

struct PreloadedLifts {
    
    /// The complete exercise catalog, organized by muscle group.
    /// Each muscle group has between 5-10 common exercises.
    ///
    /// These were chosen to cover:
    /// - Free weight basics (barbells, dumbbells)
    /// - Cable/machine variations
    /// - Bodyweight movements
    /// - Common variations experienced lifters use
    static let catalog: [MuscleGroup: [String]] = [
        
        .chest: [
            "Flat Barbell Bench Press",
            "Incline Barbell Bench Press",
            "Decline Barbell Bench Press",
            "Flat Dumbbell Press",
            "Incline Dumbbell Press",
            "Dumbbell Flyes",
            "Cable Crossover",
            "Pec Deck Machine",
            "Push-ups",
            "Chest Dips",
            "Machine Chest Press",
            "Incline Cable Flye"
        ],
        
        .lats: [
            "Pull-ups",
            "Chin-ups",
            "Lat Pulldown",
            "Barbell Bent-Over Row",
            "Dumbbell Single-Arm Row",
            "Seated Cable Row",
            "T-Bar Row",
            "Straight-Arm Pulldown",
            "Machine Row",
            "Close-Grip Lat Pulldown",
            "Meadows Row"
        ],
        
        .lowerBack: [
            "Deadlift",
            "Romanian Deadlift",
            "Good Mornings",
            "Back Extension",
            "Hyperextension",
            "Reverse Hyperextension",
            "Superman Hold"
        ],
        
        .traps: [
            "Barbell Shrugs",
            "Dumbbell Shrugs",
            "Face Pulls",
            "Upright Row",
            "Farmer's Walk",
            "Rack Pulls"
        ],
        
        .neck: [
            "Neck Curl",
            "Neck Extension",
            "Neck Lateral Flexion",
            "Neck Harness",
            "Plate Neck Flexion"
        ],
        
        .shoulders: [
            "Overhead Press (Barbell)",
            "Overhead Press (Dumbbell)",
            "Arnold Press",
            "Lateral Raises",
            "Front Raises",
            "Reverse Flyes",
            "Cable Lateral Raise",
            "Machine Shoulder Press",
            "Upright Cable Row",
            "Machine Lateral Raise",
            "Rear Delt Machine"
        ],
        
        .abs: [
            "Crunches",
            "Hanging Leg Raises",
            "Cable Crunches",
            "Ab Wheel Rollout",
            "Plank",
            "Russian Twist",
            "Decline Sit-ups",
            "Leg Raises"
        ],
        
        .quads: [
            "Barbell Back Squat",
            "Front Squat",
            "Leg Press",
            "Leg Extension",
            "Hack Squat",
            "Bulgarian Split Squat",
            "Goblet Squat",
            "Walking Lunges",
            "Sissy Squat",
            "Pendulum Squat",
            "Belt Squat"
        ],
        
        .legBiceps: [
            "Lying Leg Curl",
            "Seated Leg Curl",
            "Standing Leg Curl",
            "Stiff-Leg Deadlift",
            "Nordic Hamstring Curl",
            "Glute-Ham Raise",
            "Cable Leg Curl",
            "Single-Leg Lying Curl"
        ],
        
        .glutes: [
            "Hip Thrust (Barbell)",
            "Hip Thrust (Machine)",
            "Cable Kickback",
            "Glute Bridge",
            "Step-ups",
            "Sumo Deadlift",
            "Cable Pull-Through"
        ],
        
        .calves: [
            "Standing Calf Raise",
            "Seated Calf Raise",
            "Leg Press Calf Raise",
            "Donkey Calf Raise",
            "Smith Machine Calf Raise",
            "Single-Leg Calf Raise"
        ],
        
        .biceps: [
            "Barbell Curl",
            "Dumbbell Curl",
            "Hammer Curl",
            "Preacher Curl",
            "Concentration Curl",
            "Cable Curl",
            "Incline Dumbbell Curl",
            "EZ-Bar Curl",
            "Spider Curl",
            "Machine Curl",
            "Bayesian Curl"
        ],
        
        .triceps: [
            "Close-Grip Bench Press",
            "Skull Crushers",
            "Tricep Pushdown",
            "Overhead Tricep Extension",
            "Dumbbell Kickback",
            "Dips (Tricep)",
            "Cable Overhead Extension",
            "Diamond Push-ups",
            "Machine Tricep Extension",
            "JM Press"
        ]
    ]
    
    /// Total number of exercises in the catalog.
    /// Used in the UI to show "X exercises available."
    static var totalCount: Int {
        catalog.values.reduce(0) { $0 + $1.count }
    }
}
