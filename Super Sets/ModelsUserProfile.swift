//
//  UserProfile.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Stores the user's personal information including measurements and preferences.
//  Calculates Resting Metabolic Rate (RMR) using the Mifflin-St Jeor equation.
//  There should only be ONE UserProfile instance in the database.

import Foundation
import SwiftData

// MARK: - Weight Unit Enum

/// The user's preferred weight unit
enum WeightUnit: String, Codable, CaseIterable {
    case lbs
    case kg
    
    var displayName: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }
}

// MARK: - Biological Sex Enum

/// The user's biological sex (used for RMR calculation)
enum BiologicalSex: String, Codable, CaseIterable {
    case male
    case female
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

// MARK: - User Profile Model

@Model
final class UserProfile {
    
    // MARK: - Properties
    
    /// The user's name
    var name: String
    
    /// The user's age in years
    var age: Int
    
    /// Biological sex for metabolic calculations
    var biologicalSex: BiologicalSex
    
    /// Height in inches
    // LEARNING NOTE: We store in inches but will display as feet'inches" in the UI
    var heightInches: Int
    
    /// Current body weight in pounds (we'll convert for display if user prefers kg)
    var bodyWeightLbs: Double
    
    /// Waist measurement in inches
    var waistInches: Double
    
    /// Preferred weight unit for the app (defaults to lbs)
    var preferredUnit: WeightUnit
    
    /// When the user started tracking workouts
    var startDate: Date?
    
    /// Profile photo stored as Data
    // LEARNING NOTE: @Attribute(.externalStorage) tells SwiftData to store this
    // outside the main database file, which is better for large binary data like photos
    @Attribute(.externalStorage)
    var profilePhotoData: Data?
    
    // MARK: - Initialization
    
    /// Creates a new user profile
    /// - Parameters:
    ///   - name: User's name (default: empty)
    ///   - age: User's age (default: 25)
    ///   - biologicalSex: Biological sex (default: male)
    ///   - heightInches: Height in inches (default: 70, which is 5'10")
    ///   - bodyWeightLbs: Weight in pounds (default: 170)
    ///   - waistInches: Waist measurement (default: 32)
    ///   - preferredUnit: Preferred weight unit (default: lbs)
    ///   - startDate: When they started tracking (default: nil)
    init(
        name: String = "",
        age: Int = 25,
        biologicalSex: BiologicalSex = .male,
        heightInches: Int = 70,
        bodyWeightLbs: Double = 170,
        waistInches: Double = 32,
        preferredUnit: WeightUnit = .lbs,
        startDate: Date? = nil
    ) {
        self.name = name
        self.age = age
        self.biologicalSex = biologicalSex
        self.heightInches = heightInches
        self.bodyWeightLbs = bodyWeightLbs
        self.waistInches = waistInches
        self.preferredUnit = preferredUnit
        self.startDate = startDate
        self.profilePhotoData = nil
    }
    
    // MARK: - Computed Properties
    
    /// Height in centimeters (for RMR calculation)
    var heightCm: Double {
        Double(heightInches) * 2.54
    }
    
    /// Weight in kilograms (for RMR calculation)
    var bodyWeightKg: Double {
        bodyWeightLbs * 0.453592
    }
    
    /// Formatted height string (e.g., "5'10\"")
    var heightFormatted: String {
        let feet = heightInches / 12
        let inches = heightInches % 12
        return "\(feet)'\(inches)\""
    }
    
    /// Body weight in the user's preferred unit
    var bodyWeightInPreferredUnit: Double {
        switch preferredUnit {
        case .lbs:
            return bodyWeightLbs
        case .kg:
            return bodyWeightKg
        }
    }
    
    /// Resting Metabolic Rate calculated using Mifflin-St Jeor equation
    /// Returns calories burned per day at rest
    // LEARNING NOTE: The Mifflin-St Jeor equation is:
    // Men: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
    // Women: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
    var restingMetabolicRate: Int {
        let weightComponent = 10 * bodyWeightKg
        let heightComponent = 6.25 * heightCm
        let ageComponent = 5 * Double(age)
        
        let rmr: Double
        switch biologicalSex {
        case .male:
            rmr = weightComponent + heightComponent - ageComponent + 5
        case .female:
            rmr = weightComponent + heightComponent - ageComponent - 161
        }
        
        // LEARNING NOTE: Int() truncates decimals, rounding down to whole number
        return Int(rmr)
    }
}

// LEARNING NOTE: @Model automatically makes this class conform to Identifiable
// with an `id` property, so we can use it directly in SwiftUI ForEach loops.

