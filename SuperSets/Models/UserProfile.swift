// UserProfile.swift
// Super Sets — The Workout Tracker
//
// Stores the user's personal info, body measurements, and preferences.
// There should only ever be ONE UserProfile in the database — it's a singleton
// pattern at the data level. WorkoutManager handles creating it on first launch.
//
// LEARNING NOTE:
// We define WeightUnit as a separate enum outside the model class because
// SwiftData @Model classes have restrictions on nested types. Keeping it
// at the top level also makes it accessible from anywhere in the app.

import Foundation
import SwiftData

// MARK: - WeightUnit Enum

/// The user's preferred unit for displaying weight.
/// Defaults to pounds (lbs) — standard in US bodybuilding culture.
enum WeightUnit: String, Codable, CaseIterable {
    case lbs = "lbs"
    case kg = "kg"
}

/// Biological sex, used for the Mifflin-St Jeor RMR calculation.
/// The formula uses different constants for male vs female.
enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

/// Activity level multipliers for TDEE (Total Daily Energy Expenditure) calculation.
///
/// LEARNING NOTE:
/// TDEE = RMR × activity multiplier. This gives a more realistic daily calorie
/// estimate than RMR alone, because RMR only accounts for basic body functions
/// (breathing, circulation, etc.), not movement or exercise.
///
/// The multiplier values come from the Harris-Benedict activity factor scale,
/// which is the standard used in sports nutrition.
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary     = "Sedentary"       // desk job, little exercise
    case light         = "Light"           // light exercise 1-3 days/week
    case moderate      = "Moderate"        // moderate exercise 3-5 days/week
    case active        = "Active"          // hard exercise 6-7 days/week
    case veryActive    = "Very Active"     // athlete, physical job + training
    
    /// The multiplier applied to RMR to estimate total daily calories.
    var multiplier: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
    
    /// Short description shown in the UI picker.
    var description: String {
        switch self {
        case .sedentary:  return "Little or no exercise"
        case .light:      return "1-3 days/week"
        case .moderate:   return "3-5 days/week"
        case .active:     return "6-7 days/week"
        case .veryActive: return "Athlete / physical job"
        }
    }
}

/// Weight goal direction — affects daily calorie target.
enum WeightGoal: String, Codable, CaseIterable {
    case lose     = "Lose"
    case maintain = "Maintain"
    case gain     = "Gain"

    /// Calorie adjustment applied to TDEE.
    /// -500 for ~1 lb/week loss, +500 for ~1 lb/week gain.
    var calorieAdjustment: Int {
        switch self {
        case .lose:     return -500
        case .maintain: return 0
        case .gain:     return 500
        }
    }
}

// MARK: - UserProfile Model

@Model
final class UserProfile {
    
    // MARK: Personal Info
    
    var name: String = ""
    var age: Int = 25
    var biologicalSexRaw: String = "Male"

    // MARK: Measurements

    /// Height in total inches. Displayed as feet'inches" in the UI.
    var heightInches: Double = 70

    /// Body weight in the user's preferred unit (lbs by default).
    var bodyWeight: Double = 180

    /// Waist measurement in inches.
    var waistInches: Double = 34

    // MARK: Preferences

    /// Whether the user prefers lbs or kg. Defaults to lbs.
    var preferredUnitRaw: String = "lbs"

    /// Unused — app is now dark-only. Kept to avoid SwiftData schema migration.
    var preferredThemeRaw: String = "Dark"

    /// The user's activity level for TDEE calculation.
    var activityLevelRaw: String = "Moderate"

    /// Whether the user prefers scroll wheel (slot machine) input for weight/reps
    /// or keyboard text fields. Defaults to true (wheel).
    var useScrollWheelInput: Bool = true

    /// Default rest timer countdown duration in seconds. Defaults to 90.
    var defaultRestTimerDuration: Int = 90

    // MARK: Nutrition Goals

    /// Weight goal direction: lose, maintain, or gain.
    var weightGoalRaw: String = "Maintain"

    /// Daily calorie goal. 0 = use TDEE estimate.
    var calorieGoal: Int = 0
    /// Daily protein goal in grams. 0 = auto (30% of calories / 4).
    var proteinGoal: Double = 0
    /// Daily carbs goal in grams. 0 = auto (40% of calories / 4).
    var carbsGoal: Double = 0
    /// Daily fat goal in grams. 0 = auto (30% of calories / 9).
    var fatGoal: Double = 0
    
    // MARK: Profile Photo
    
    /// The user's profile photo stored as raw image data (JPEG/PNG bytes).
    /// Stored inline (no .externalStorage) for CloudKit compatibility.
    var profilePhotoData: Data?
    
    // MARK: Dates
    
    /// When the user first started using the app / training.
    var startDate: Date?
    
    // MARK: Computed Properties
    
    /// Type-safe access to biological sex.
    var biologicalSex: BiologicalSex {
        get { BiologicalSex(rawValue: biologicalSexRaw) ?? .male }
        set { biologicalSexRaw = newValue.rawValue }
    }
    
    /// Type-safe access to weight unit preference.
    var preferredUnit: WeightUnit {
        get { WeightUnit(rawValue: preferredUnitRaw) ?? .lbs }
        set { preferredUnitRaw = newValue.rawValue }
    }
    
    /// Type-safe access to activity level.
    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .moderate }
        set { activityLevelRaw = newValue.rawValue }
    }

    /// Type-safe access to weight goal direction.
    var weightGoal: WeightGoal {
        get { WeightGoal(rawValue: weightGoalRaw) ?? .maintain }
        set { weightGoalRaw = newValue.rawValue }
    }
    
    /// Height displayed as feet and inches: 5'10"
    var formattedHeight: String {
        let feet = Int(heightInches) / 12
        let inches = Int(heightInches) % 12
        return "\(feet)'\(inches)\""
    }
    
    /// Body weight in kilograms (for RMR calculation).
    var bodyWeightKg: Double {
        switch preferredUnit {
        case .lbs: return bodyWeight * 0.453592
        case .kg:  return bodyWeight
        }
    }
    
    /// Height in centimeters (for RMR calculation).
    var heightCm: Double {
        return heightInches * 2.54
    }
    
    /// Resting Metabolic Rate using the Mifflin-St Jeor equation.
    ///
    /// This is considered the most accurate RMR estimation formula:
    /// - Male:   (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
    /// - Female: (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
    ///
    /// Returns the estimated calories burned per day at complete rest.
    var restingMetabolicRate: Int {
        let base = (10.0 * bodyWeightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        switch biologicalSex {
        case .male:   return Int(base + 5.0)
        case .female: return Int(base - 161.0)
        }
    }
    
    /// Total Daily Energy Expenditure = RMR × activity multiplier.
    ///
    /// LEARNING NOTE:
    /// TDEE estimates how many calories you burn in a full day INCLUDING
    /// your normal activity level. It's more useful than RMR for diet
    /// planning because RMR only covers basal functions (breathing,
    /// circulation, cell repair) — not walking, working, or exercising.
    var totalDailyEnergyExpenditure: Int {
        Int(Double(restingMetabolicRate) * activityLevel.multiplier)
    }

    /// Calorie goal: user override, or TDEE + weight goal adjustment.
    var effectiveCalorieGoal: Int {
        if calorieGoal > 0 { return calorieGoal }
        return max(1200, totalDailyEnergyExpenditure + weightGoal.calorieAdjustment)
    }

    /// Protein goal in grams: user override or 30% of calories / 4.
    var effectiveProteinGoal: Double {
        proteinGoal > 0 ? proteinGoal : Double(effectiveCalorieGoal) * 0.30 / 4.0
    }

    /// Carbs goal in grams: user override or 40% of calories / 4.
    var effectiveCarbsGoal: Double {
        carbsGoal > 0 ? carbsGoal : Double(effectiveCalorieGoal) * 0.40 / 4.0
    }

    /// Fat goal in grams: user override or 30% of calories / 9.
    var effectiveFatGoal: Double {
        fatGoal > 0 ? fatGoal : Double(effectiveCalorieGoal) * 0.30 / 9.0
    }

    // MARK: Initializer
    
    /// Creates a new user profile with sensible defaults.
    init() {
        self.name = ""
        self.age = 25
        self.biologicalSexRaw = BiologicalSex.male.rawValue
        self.heightInches = 70  // 5'10"
        self.bodyWeight = 180
        self.waistInches = 34
        self.preferredUnitRaw = WeightUnit.lbs.rawValue
        self.preferredThemeRaw = "Dark"
        self.activityLevelRaw = ActivityLevel.moderate.rawValue
        self.profilePhotoData = nil
        self.startDate = Date()
        self.weightGoalRaw = WeightGoal.maintain.rawValue
        self.calorieGoal = 0
        self.proteinGoal = 0
        self.carbsGoal = 0
        self.fatGoal = 0
    }
}
