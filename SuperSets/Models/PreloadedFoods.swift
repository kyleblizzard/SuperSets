// PreloadedFoods.swift
// Super Sets — The Workout Tracker
//
// Static database of ~35 common foods for quick entry.
// Values are approximate per-serving nutritional data.

import Foundation

// MARK: - FoodCategory

enum FoodCategory: String, CaseIterable, Identifiable {
    case protein       = "Protein"
    case carbsGrains   = "Carbs & Grains"
    case dairy         = "Dairy"
    case fruits        = "Fruits"
    case vegetables    = "Vegetables"
    case fatsNuts      = "Fats & Nuts"
    case commonMeals   = "Common Meals"
    case snacks        = "Snacks"

    var id: String { rawValue }
}

// MARK: - FoodTemplate

struct FoodTemplate: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: Double
    let servingUnit: ServingUnit
    let category: FoodCategory
}

// MARK: - PreloadedFoods

enum PreloadedFoods {

    static let catalog: [FoodTemplate] = [
        // Protein
        FoodTemplate(name: "Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, servingSize: 4, servingUnit: .oz, category: .protein),
        FoodTemplate(name: "Ground Beef (90/10)", calories: 200, protein: 26, carbs: 0, fat: 11, servingSize: 4, servingUnit: .oz, category: .protein),
        FoodTemplate(name: "Salmon Fillet", calories: 208, protein: 20, carbs: 0, fat: 13, servingSize: 4, servingUnit: .oz, category: .protein),
        FoodTemplate(name: "Eggs (whole)", calories: 70, protein: 6, carbs: 0.5, fat: 5, servingSize: 1, servingUnit: .pc, category: .protein),
        FoodTemplate(name: "Egg Whites", calories: 17, protein: 3.6, carbs: 0.2, fat: 0, servingSize: 1, servingUnit: .pc, category: .protein),
        FoodTemplate(name: "Turkey Breast", calories: 135, protein: 30, carbs: 0, fat: 1, servingSize: 4, servingUnit: .oz, category: .protein),
        FoodTemplate(name: "Protein Shake", calories: 120, protein: 24, carbs: 3, fat: 1, servingSize: 1, servingUnit: .serving, category: .protein),
        FoodTemplate(name: "Tuna (canned)", calories: 100, protein: 22, carbs: 0, fat: 1, servingSize: 3, servingUnit: .oz, category: .protein),

        // Carbs & Grains
        FoodTemplate(name: "White Rice (cooked)", calories: 205, protein: 4.3, carbs: 45, fat: 0.4, servingSize: 1, servingUnit: .cup, category: .carbsGrains),
        FoodTemplate(name: "Brown Rice (cooked)", calories: 215, protein: 5, carbs: 45, fat: 1.8, servingSize: 1, servingUnit: .cup, category: .carbsGrains),
        FoodTemplate(name: "Oats (dry)", calories: 150, protein: 5, carbs: 27, fat: 3, servingSize: 0.5, servingUnit: .cup, category: .carbsGrains),
        FoodTemplate(name: "Whole Wheat Bread", calories: 80, protein: 4, carbs: 14, fat: 1, servingSize: 1, servingUnit: .pc, category: .carbsGrains),
        FoodTemplate(name: "Pasta (cooked)", calories: 220, protein: 8, carbs: 43, fat: 1.3, servingSize: 1, servingUnit: .cup, category: .carbsGrains),
        FoodTemplate(name: "Sweet Potato", calories: 103, protein: 2, carbs: 24, fat: 0, servingSize: 1, servingUnit: .pc, category: .carbsGrains),
        FoodTemplate(name: "Tortilla (flour)", calories: 140, protein: 4, carbs: 24, fat: 3, servingSize: 1, servingUnit: .pc, category: .carbsGrains),

        // Dairy
        FoodTemplate(name: "Greek Yogurt (plain)", calories: 100, protein: 17, carbs: 6, fat: 0.7, servingSize: 170, servingUnit: .g, category: .dairy),
        FoodTemplate(name: "Whole Milk", calories: 150, protein: 8, carbs: 12, fat: 8, servingSize: 1, servingUnit: .cup, category: .dairy),
        FoodTemplate(name: "Cheddar Cheese", calories: 113, protein: 7, carbs: 0.4, fat: 9, servingSize: 1, servingUnit: .oz, category: .dairy),
        FoodTemplate(name: "Cottage Cheese", calories: 110, protein: 12, carbs: 5, fat: 5, servingSize: 0.5, servingUnit: .cup, category: .dairy),

        // Fruits
        FoodTemplate(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, servingSize: 1, servingUnit: .pc, category: .fruits),
        FoodTemplate(name: "Apple", calories: 95, protein: 0.5, carbs: 25, fat: 0.3, servingSize: 1, servingUnit: .pc, category: .fruits),
        FoodTemplate(name: "Blueberries", calories: 85, protein: 1, carbs: 21, fat: 0.5, servingSize: 1, servingUnit: .cup, category: .fruits),
        FoodTemplate(name: "Strawberries", calories: 50, protein: 1, carbs: 12, fat: 0.5, servingSize: 1, servingUnit: .cup, category: .fruits),

        // Vegetables
        FoodTemplate(name: "Broccoli", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, servingSize: 1, servingUnit: .cup, category: .vegetables),
        FoodTemplate(name: "Spinach (raw)", calories: 7, protein: 0.9, carbs: 1, fat: 0.1, servingSize: 1, servingUnit: .cup, category: .vegetables),
        FoodTemplate(name: "Mixed Salad", calories: 20, protein: 1.5, carbs: 3, fat: 0.2, servingSize: 2, servingUnit: .cup, category: .vegetables),

        // Fats & Nuts
        FoodTemplate(name: "Almonds", calories: 164, protein: 6, carbs: 6, fat: 14, servingSize: 1, servingUnit: .oz, category: .fatsNuts),
        FoodTemplate(name: "Peanut Butter", calories: 190, protein: 7, carbs: 7, fat: 16, servingSize: 2, servingUnit: .tbsp, category: .fatsNuts),
        FoodTemplate(name: "Avocado", calories: 240, protein: 3, carbs: 13, fat: 22, servingSize: 1, servingUnit: .pc, category: .fatsNuts),
        FoodTemplate(name: "Olive Oil", calories: 120, protein: 0, carbs: 0, fat: 14, servingSize: 1, servingUnit: .tbsp, category: .fatsNuts),

        // Common Meals
        FoodTemplate(name: "Chicken & Rice Bowl", calories: 450, protein: 35, carbs: 50, fat: 10, servingSize: 1, servingUnit: .serving, category: .commonMeals),
        FoodTemplate(name: "Turkey Sandwich", calories: 350, protein: 24, carbs: 35, fat: 12, servingSize: 1, servingUnit: .serving, category: .commonMeals),
        FoodTemplate(name: "Burrito Bowl", calories: 550, protein: 30, carbs: 60, fat: 18, servingSize: 1, servingUnit: .serving, category: .commonMeals),
        FoodTemplate(name: "Steak & Veggies", calories: 400, protein: 38, carbs: 10, fat: 22, servingSize: 1, servingUnit: .serving, category: .commonMeals),

        // Snacks
        FoodTemplate(name: "Protein Bar", calories: 200, protein: 20, carbs: 22, fat: 7, servingSize: 1, servingUnit: .pc, category: .snacks),
        FoodTemplate(name: "Rice Cakes", calories: 35, protein: 1, carbs: 7, fat: 0.3, servingSize: 1, servingUnit: .pc, category: .snacks),
        FoodTemplate(name: "Beef Jerky", calories: 80, protein: 13, carbs: 3, fat: 1, servingSize: 1, servingUnit: .oz, category: .snacks),
    ]

    static func search(_ query: String) -> [FoodTemplate] {
        guard !query.isEmpty else { return catalog }
        let lowered = query.lowercased()
        return catalog.filter { $0.name.lowercased().contains(lowered) }
    }

    static var byCategory: [(category: FoodCategory, foods: [FoodTemplate])] {
        FoodCategory.allCases.compactMap { category in
            let foods = catalog.filter { $0.category == category }
            return foods.isEmpty ? nil : (category: category, foods: foods)
        }
    }
}
