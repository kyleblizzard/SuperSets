// MuscleGroup.swift
// Super Sets — The Workout Tracker
//
// This enum defines every muscle group the app supports.
// Enums in Swift are far more powerful than in most languages — they can
// have computed properties, methods, and conform to protocols.
//
// We conform to String so SwiftData can persist enum values as text.
// We conform to CaseIterable so we can loop over all muscle groups in the UI.
// We conform to Codable so SwiftData can encode/decode them automatically.
// We conform to Identifiable so SwiftUI Lists/ForEach work without extra id: params.

import SwiftUI

// MARK: - MuscleGroup Enum

/// Every muscle group a bodybuilder would train.
/// Used to organize lifts and color-code the UI.
enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest
    case lats
    case lowerBack
    case traps
    case neck
    case shoulders
    case abs
    case quads
    case legBiceps   // hamstrings
    case glutes
    case calves
    case biceps
    case triceps
    case cardio
    case stretching

    // LEARNING NOTE:
    // Identifiable requires an `id` property. Since our raw value is already
    // a unique String, we can just return self. This lets SwiftUI identify
    // each case without us providing an explicit id in ForEach loops.
    var id: Self { self }

    // MARK: - Display Properties

    /// Human-readable name shown in the UI.
    /// We use a switch instead of just rawValue because some names
    /// need spaces or different formatting (e.g., "lowerBack" → "Lower Back").
    var displayName: String {
        switch self {
        case .chest:      return "Chest"
        case .lats:       return "Lats"
        case .lowerBack:  return "Lower Back"
        case .traps:      return "Traps"
        case .neck:       return "Neck"
        case .shoulders:  return "Shoulders"
        case .abs:        return "Abs"
        case .quads:      return "Quads"
        case .legBiceps:  return "Hamstrings"
        case .glutes:     return "Glutes"
        case .calves:     return "Calves"
        case .biceps:     return "Biceps"
        case .triceps:    return "Triceps"
        case .cardio:     return "Cardio"
        case .stretching: return "Stretching"
        }
    }

    /// SF Symbol icon name for each muscle group.
    /// These appear in the Add Lift picker and the lift library.
    var iconName: String {
        switch self {
        case .chest:      return "figure.arms.open"
        case .lats:       return "figure.rowing"
        case .lowerBack:  return "figure.core.training"
        case .traps:      return "chevron.up.2"
        case .neck:       return "head.profile.fill"
        case .shoulders:  return "figure.boxing"
        case .abs:        return "square.grid.3x3.fill"
        case .quads:      return "figure.lunges"
        case .legBiceps:  return "figure.strengthtraining.traditional"
        case .glutes:     return "figure.stairs"
        case .calves:     return "figure.run"
        case .biceps:     return "dumbbell.fill"
        case .triceps:    return "figure.cooldown"
        case .cardio:     return "figure.mixed.cardio"
        case .stretching: return "figure.flexibility"
        }
    }

    // MARK: - Accent Colors

    /// Each muscle group gets a unique accent color.
    /// This creates visual variety throughout the app and helps users
    /// quickly identify which body part they're working.
    ///
    /// LEARNING NOTE:
    /// Color can be created from a hex value using the Color(red:green:blue:)
    /// initializer with values from 0.0 to 1.0. We use an extension at the
    /// bottom of this file to make hex initialization cleaner.
    var accentColor: Color {
        switch self {
        case .chest:      return Color(hex: 0xFF6B6B)  // coral red
        case .lats:       return Color(hex: 0x4ECDC4)  // teal
        case .lowerBack:  return Color(hex: 0xFFBE0B)  // golden amber
        case .traps:      return Color(hex: 0x845EC2)  // deep purple
        case .neck:       return Color(hex: 0xF9A8D4)  // pink
        case .shoulders:  return Color(hex: 0xFF9F43)  // tangerine
        case .abs:        return Color(hex: 0x54A0FF)  // bright blue
        case .quads:      return Color(hex: 0x00D2D3)  // cyan
        case .legBiceps:  return Color(hex: 0xA3CB38)  // lime green
        case .glutes:     return Color(hex: 0xF368E0)  // magenta
        case .calves:     return Color(hex: 0x10AC84)  // emerald
        case .biceps:     return Color(hex: 0xEE5A24)  // burnt orange
        case .triceps:    return Color(hex: 0x0ABDE3)  // sky blue
        case .cardio:     return Color(hex: 0xFF5722)  // deep orange
        case .stretching: return Color(hex: 0x8BC34A)  // light green
        }
    }

    // MARK: - Grouped Sections

    /// Sections for the muscle group grid in LiftLibraryView.
    static let groupedSections: [MuscleGroupSection] = [
        MuscleGroupSection(title: "Upper Body", groups: [.chest, .lats, .biceps, .shoulders, .triceps, .traps, .lowerBack, .neck]),
        MuscleGroupSection(title: "Lower Body", groups: [.quads, .legBiceps, .glutes, .calves, .abs]),
        MuscleGroupSection(title: "Cardio", groups: [.cardio]),
        MuscleGroupSection(title: "Stretching", groups: [.stretching]),
    ]
}

// MARK: - MuscleGroupSection

/// A named section of muscle groups for the grouped grid layout.
struct MuscleGroupSection: Identifiable {
    let id = UUID()
    let title: String
    let groups: [MuscleGroup]
}

// MARK: - Color Hex Extension

/// A convenience initializer for creating Colors from hex values.
/// This is a very common Swift extension you'll see in professional codebases.
///
/// Usage: Color(hex: 0xFF6B6B) instead of Color(red: 1.0, green: 0.42, blue: 0.42)
///
/// LEARNING NOTE:
/// The >> and & operators here are "bitwise" operations. They extract the
/// red, green, and blue components from a single hex integer:
///   0xFF6B6B → red: 0xFF (255), green: 0x6B (107), blue: 0x6B (107)
///
/// NOTE: For adaptive colors that change in light/dark mode, use Color(light:dark:)
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            UIColor(hex: hex, opacity: opacity)
        )
    }
}
