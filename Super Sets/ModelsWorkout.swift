//
//  Workout.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Represents a complete workout session. A workout has a start date, optional end date,
//  optional notes, and contains multiple sets. Only one workout can be active at a time.

import Foundation
import SwiftData

@Model
final class Workout {
    
    // MARK: - Properties
    
    /// When this workout was started
    var date: Date
    
    /// When this workout was finished (nil if still in progress)
    var endDate: Date?
    
    /// Optional notes added by the user at the end of the workout
    var notes: String?
    
    /// Whether this workout is currently active (in progress)
    // LEARNING NOTE: Only ONE workout should have isActive = true at any time
    var isActive: Bool
    
    // LEARNING NOTE: This establishes a one-to-many relationship with WorkoutSet.
    // One workout contains many sets. The inverse tells SwiftData that WorkoutSet
    // has a property called `workout` that points back to this Workout.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workout)
    var sets: [WorkoutSet] = []
    
    // MARK: - Initialization
    
    /// Creates a new workout
    /// - Parameters:
    ///   - date: When the workout started (default: now)
    ///   - isActive: Whether this workout is currently in progress (default: true)
    init(date: Date = Date(), isActive: Bool = true) {
        self.date = date
        self.endDate = nil
        self.notes = nil
        self.isActive = isActive
        self.sets = []
    }
    
    // MARK: - Computed Properties
    
    /// The duration of the workout in seconds
    // LEARNING NOTE: A computed property doesn't store a value, it calculates it on demand.
    // The `var` keyword with just a getter (get { }) makes this computed.
    var duration: TimeInterval {
        // LEARNING NOTE: guard is used for early exit. If endDate is nil, we return 0.
        guard let endDate = endDate else { return 0 }
        return endDate.timeIntervalSince(date)
    }
    
    /// A formatted string showing the workout duration (e.g., "1h 23m")
    var durationFormatted: String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// The number of unique lifts performed in this workout
    var uniqueLifts: Int {
        // LEARNING NOTE: Set is a collection that only stores unique values.
        // We use Set to count how many different lifts were used.
        // compactMap removes any nil values before creating the set.
        let liftIDs = Set(sets.compactMap { $0.liftDefinition?.persistentModelID })
        return liftIDs.count
    }
    
    /// Groups sets by their lift definition
    /// - Returns: A dictionary where keys are lift names and values are arrays of sets
    func setsGroupedByLift() -> [String: [WorkoutSet]] {
        // LEARNING NOTE: Dictionary(grouping:by:) is a built-in function that
        // groups an array into a dictionary based on some key.
        Dictionary(grouping: sets) { set in
            set.liftDefinition?.name ?? "Unknown"
        }
    }
    
    /// Gets all sets for a specific lift in this workout, sorted by timestamp
    /// - Parameter lift: The lift to filter by
    /// - Returns: Array of sets for that lift, oldest first
    func sets(for lift: LiftDefinition) -> [WorkoutSet] {
        sets
            .filter { $0.liftDefinition?.persistentModelID == lift.persistentModelID }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

// LEARNING NOTE: @Model automatically makes this class conform to Identifiable
// with an `id` property, so we can use it directly in SwiftUI ForEach loops.

