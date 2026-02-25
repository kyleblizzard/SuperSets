// WeightEntry.swift
// Super Sets — The Workout Tracker
//
// A simple model for tracking body weight over time.
// Each entry is a single weigh-in with a date and weight value.
//
// This powers the body weight chart on the Progress tab, showing
// trends over the last 30 days (or more if the user expands).
//
// LEARNING NOTE:
// This is one of the simplest SwiftData models possible — just two
// stored properties plus a relationship-free schema. SwiftData handles
// all the SQLite table creation, indexing, and query generation for us.
// No migration code needed because this is a brand-new model.

import Foundation
import SwiftData

// MARK: - WeightEntry Model

@Model
final class WeightEntry {
    
    // MARK: Properties
    
    /// The date of this weigh-in.
    /// We store the full Date but typically only care about the calendar day.
    var date: Date
    
    /// The body weight value, in the user's preferred unit (lbs or kg).
    ///
    /// LEARNING NOTE:
    /// We store this as Double to support decimal weights (e.g., 185.5 lbs).
    /// The unit (lbs vs kg) is determined by UserProfile.preferredUnit —
    /// we don't store the unit per-entry because all entries should use
    /// the same unit system for chart consistency.
    var weight: Double
    
    // MARK: Initializer
    
    /// Creates a new weight entry for today's date.
    /// - Parameters:
    ///   - date: When the weigh-in occurred (defaults to now)
    ///   - weight: The body weight value in the user's preferred unit
    init(date: Date = Date(), weight: Double) {
        self.date = date
        self.weight = weight
    }
}
