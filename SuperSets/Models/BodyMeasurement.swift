// BodyMeasurement.swift
// Super Sets — The Workout Tracker
//
// Tracks body measurements over time (neck, chest, waist, etc.)
// for monitoring body composition changes.

import Foundation
import SwiftData

// MARK: - MeasurementType

enum MeasurementType: String, CaseIterable, Codable, Identifiable {
    case neck
    case shoulders
    case chest
    case leftBicep
    case rightBicep
    case leftForearm
    case rightForearm
    case waist
    case hips
    case leftThigh
    case rightThigh
    case leftCalf
    case rightCalf

    var id: Self { self }

    var displayName: String {
        switch self {
        case .neck: return "Neck"
        case .shoulders: return "Shoulders"
        case .chest: return "Chest"
        case .leftBicep: return "Left Bicep"
        case .rightBicep: return "Right Bicep"
        case .leftForearm: return "Left Forearm"
        case .rightForearm: return "Right Forearm"
        case .waist: return "Waist"
        case .hips: return "Hips"
        case .leftThigh: return "Left Thigh"
        case .rightThigh: return "Right Thigh"
        case .leftCalf: return "Left Calf"
        case .rightCalf: return "Right Calf"
        }
    }

    /// Group measurements for display.
    var bodyRegion: String {
        switch self {
        case .neck, .shoulders, .chest: return "Upper Body"
        case .leftBicep, .rightBicep, .leftForearm, .rightForearm: return "Arms"
        case .waist, .hips: return "Core"
        case .leftThigh, .rightThigh, .leftCalf, .rightCalf: return "Legs"
        }
    }
}

// MARK: - MeasurementUnit

enum MeasurementUnit: String, Codable, CaseIterable {
    case inches = "in"
    case cm = "cm"
}

// MARK: - BodyMeasurement Model

@Model
final class BodyMeasurement {
    var date: Date
    var measurementTypeRaw: String
    var value: Double
    var unitRaw: String

    var measurementType: MeasurementType {
        get { MeasurementType(rawValue: measurementTypeRaw) ?? .chest }
        set { measurementTypeRaw = newValue.rawValue }
    }

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .inches }
        set { unitRaw = newValue.rawValue }
    }

    init(date: Date = Date(), measurementType: MeasurementType, value: Double, unit: MeasurementUnit = .inches) {
        self.date = date
        self.measurementTypeRaw = measurementType.rawValue
        self.value = value
        self.unitRaw = unit.rawValue
    }
}
