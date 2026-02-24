//
//  WorkoutManager.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Manages the current workout state and provides functions for logging sets,
//  selecting lifts, and ending workouts. This is the main business logic for
//  the workout tracking feature.

import Foundation
import SwiftData
import Observation

// LEARNING NOTE: @Observable is the modern Swift way to make a class observable.
// When properties change, SwiftUI views automatically update. This replaces
// the older ObservableObject protocol.
@Observable
final class WorkoutManager {
    
    // MARK: - Properties
    
    /// The currently active workout (nil if no workout in progress)
    var activeWorkout: Workout?
    
    /// The currently selected lift for input
    var selectedLift: LiftDefinition?
    
    /// Current weight input value
    var currentWeight: String = ""
    
    /// Current reps input value
    var currentReps: String = ""
    
    /// Reference to the SwiftData model context
    // LEARNING NOTE: We need the model context to save changes to the database
    private var modelContext: ModelContext
    
    // MARK: - Initialization
    
    /// Creates a new WorkoutManager
    /// - Parameter modelContext: The SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Workout Management
    
    /// Starts a new workout
    func startWorkout() {
        // End any existing active workout first
        if let existing = activeWorkout {
            endWorkout(for: existing, notes: nil)
        }
        
        // Create new workout
        let newWorkout = Workout(date: Date(), isActive: true)
        modelContext.insert(newWorkout)
        activeWorkout = newWorkout
        
        // Save to database
        try? modelContext.save()
    }
    
    /// Ends the current workout
    /// - Parameters:
    ///   - workout: The workout to end
    ///   - notes: Optional notes to add
    func endWorkout(for workout: Workout, notes: String?) {
        workout.endDate = Date()
        workout.isActive = false
        workout.notes = notes
        
        // Clear active workout
        if activeWorkout?.persistentModelID == workout.persistentModelID {
            activeWorkout = nil
            selectedLift = nil
            currentWeight = ""
            currentReps = ""
        }
        
        // Save to database
        try? modelContext.save()
    }
    
    /// Loads the active workout from the database (call this on app launch)
    func loadActiveWorkout() {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isActive == true }
        )
        descriptor.fetchLimit = 1
        
        // LEARNING NOTE: try? returns nil if the fetch fails
        if let workouts = try? modelContext.fetch(descriptor),
           let workout = workouts.first {
            activeWorkout = workout
        }
    }
    
    // MARK: - Lift Selection
    
    /// Selects a lift for the current workout
    /// - Parameter lift: The lift to select
    func selectLift(_ lift: LiftDefinition) {
        selectedLift = lift
        
        // Update last used date
        lift.lastUsedDate = Date()
        try? modelContext.save()
    }
    
    // MARK: - Set Logging
    
    /// Logs a new set for the selected lift
    /// - Returns: True if successful, false if validation fails
    @discardableResult
    func logSet() -> Bool {
        // Validate inputs
        guard let workout = activeWorkout,
              let lift = selectedLift,
              let weight = Double(currentWeight),
              let reps = Int(currentReps),
              weight > 0,
              reps > 0 else {
            return false
        }
        
        // Calculate set number (how many sets for this lift in this workout + 1)
        let existingSets = workout.sets(for: lift)
        let setNumber = existingSets.count + 1
        
        // Create the set
        let newSet = WorkoutSet(
            weight: weight,
            reps: reps,
            setNumber: setNumber,
            timestamp: Date(),
            workout: workout,
            liftDefinition: lift
        )
        
        modelContext.insert(newSet)
        
        // Clear reps but keep weight (bodybuilders often use same weight)
        currentReps = ""
        
        // Save to database
        try? modelContext.save()
        
        return true
    }
    
    /// Deletes a set and renumbers remaining sets
    /// - Parameter set: The set to delete
    func deleteSet(_ set: WorkoutSet) {
        guard let workout = set.workout,
              let lift = set.liftDefinition else {
            return
        }
        
        let setNumberDeleted = set.setNumber
        
        // Delete the set
        modelContext.delete(set)
        
        // Renumber remaining sets for this lift
        let remainingSets = workout.sets(for: lift)
        for remainingSet in remainingSets {
            if remainingSet.setNumber > setNumberDeleted {
                remainingSet.setNumber -= 1
            }
        }
        
        // Save to database
        try? modelContext.save()
    }
    
    // MARK: - Recent Lifts
    
    /// Gets the 4 most recently used lifts
    /// - Returns: Array of up to 4 lift definitions, most recent first
    func getRecentLifts() -> [LiftDefinition] {
        var descriptor = FetchDescriptor<LiftDefinition>(
            predicate: #Predicate { $0.lastUsedDate != nil },
            sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
        )
        descriptor.fetchLimit = 4
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Previous Workout Data
    
    /// Gets the previous workout data for a specific lift
    /// - Parameter lift: The lift to look up
    /// - Returns: Tuple of (previous workout, sets for that lift) or nil if none exists
    func getPreviousData(for lift: LiftDefinition) -> (workout: Workout, sets: [WorkoutSet])? {
        // Get all completed workouts that included this lift
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.isActive == false && $0.endDate != nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let allWorkouts = try? modelContext.fetch(descriptor) else {
            return nil
        }
        
        // Find the most recent workout that has sets for this lift
        for workout in allWorkouts {
            let setsForLift = workout.sets(for: lift)
            if !setsForLift.isEmpty {
                return (workout, setsForLift)
            }
        }
        
        return nil
    }
}
