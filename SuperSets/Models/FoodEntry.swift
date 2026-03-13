// FoodEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks individual food entries with calories and macronutrients.
// Each entry represents a single food item logged at a specific time.

import Foundation
import SwiftData

// MARK: - ServingUnit Enum

enum ServingUnit: String, Codable, CaseIterable {
    case g = "g"
    case oz = "oz"
    case cup = "cup"
    case tbsp = "tbsp"
    case pc = "pc"
    case serving = "serving"
}

// MARK: - FoodEntry Model

@Model
final class FoodEntry {
    var date: Date = Date()
    var name: String = ""
    var calories: Int = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var servingSize: Double = 1
    var servingUnitRaw: String = "serving"

    var servingUnit: ServingUnit {
        get { ServingUnit(rawValue: servingUnitRaw) ?? .serving }
        set { servingUnitRaw = newValue.rawValue }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var macroSummary: String {
        "\(calories) cal · \(Int(protein))P · \(Int(carbs))C · \(Int(fat))F"
    }

    init(
        date: Date = Date(),
        name: String,
        calories: Int,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        servingSize: Double = 1,
        servingUnit: ServingUnit = .serving
    ) {
        self.date = date
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnitRaw = servingUnit.rawValue
    }
}
