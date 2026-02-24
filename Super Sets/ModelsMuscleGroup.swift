//
//  MuscleGroup.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Defines the 13 muscle groups used throughout the app for categorizing lifts.
//  Each muscle group has a display name, an SF Symbol icon, and a unique accent color
//  that follows the liquid glass design language with bright, happy colors.

import SwiftUI

// LEARNING NOTE: An enum is a type that represents a fixed set of related values.
// Here we use it to ensure muscle groups are consistently named throughout the app.
// The `String` conformance allows us to get a string value for each case.
// `Codable` makes it work with SwiftData, and `CaseIterable` lets us loop through all cases.
enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case lats
    case lowerBack
    case traps
    case neck
    case shoulders
    case abs
    case quads
    case legBiceps
    case glutes
    case calves
    case biceps
    case triceps
    
    // MARK: - Display Properties
    
    /// Human-readable name for the muscle group
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .lats: return "Lats"
        case .lowerBack: return "Lower Back"
        case .traps: return "Traps"
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .abs: return "Abs"
        case .quads: return "Quads"
        case .legBiceps: return "Leg Biceps"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        }
    }
    
    /// SF Symbol icon name for the muscle group
    var iconName: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .lats: return "figure.flexibility"
        case .lowerBack: return "figure.stand"
        case .traps: return "figure.walk"
        case .neck: return "figure.mind.and.body"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .abs: return "figure.core.training"
        case .quads: return "figure.run"
        case .legBiceps: return "figure.run"
        case .glutes: return "figure.stairs"
        case .calves: return "figure.jumprope"
        case .biceps: return "dumbbell.fill"
        case .triceps: return "dumbbell"
        }
    }
    
    /// Bright, happy accent color unique to each muscle group
    // LEARNING NOTE: Color is a SwiftUI type that represents colors.
    // We return specific colors for each muscle group to make the UI vibrant and helpful.
    var accentColor: Color {
        switch self {
        case .chest: return Color(red: 1.0, green: 0.45, blue: 0.45) // Coral
        case .lats: return Color(red: 0.4, green: 0.7, blue: 1.0) // Sky blue
        case .lowerBack: return Color(red: 0.6, green: 0.4, blue: 0.8) // Purple
        case .traps: return Color(red: 1.0, green: 0.6, blue: 0.2) // Orange
        case .neck: return Color(red: 0.5, green: 0.8, blue: 0.6) // Mint green
        case .shoulders: return Color(red: 1.0, green: 0.7, blue: 0.3) // Golden
        case .abs: return Color(red: 1.0, green: 0.3, blue: 0.6) // Pink
        case .quads: return Color(red: 0.3, green: 0.8, blue: 0.9) // Cyan
        case .legBiceps: return Color(red: 0.5, green: 0.6, blue: 1.0) // Periwinkle
        case .glutes: return Color(red: 1.0, green: 0.5, blue: 0.8) // Rose
        case .calves: return Color(red: 0.7, green: 0.9, blue: 0.4) // Lime
        case .biceps: return Color(red: 0.2, green: 0.8, blue: 0.6) // Teal
        case .triceps: return Color(red: 1.0, green: 0.4, blue: 0.3) // Tomato
        }
    }
}
