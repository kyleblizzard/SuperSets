// MedicationLog.swift
// Super Sets — The Workout Tracker
//
// Tracks medications, supplements, vitamins, and injections.

import Foundation
import SwiftData

// MARK: - MedicationType

enum MedicationType: String, CaseIterable, Codable, Identifiable {
    case medication = "Medication"
    case supplement = "Supplement"
    case vitamin = "Vitamin"
    case injection = "Injection"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .medication: return "pill.fill"
        case .supplement: return "cross.vial.fill"
        case .vitamin: return "leaf.fill"
        case .injection: return "syringe.fill"
        }
    }
}

// MARK: - MedicationFrequency

enum MedicationFrequency: String, CaseIterable, Codable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case asNeeded = "As Needed"

    var id: Self { self }
}

// MARK: - MedicationLog Model

@Model
final class MedicationLog {
    var date: Date = Date()
    var name: String = ""
    var dosage: String = ""
    var typeRaw: String = "Supplement"
    var frequencyRaw: String = "Daily"
    /// 1-5 optional effectiveness rating.
    var effectivenessRating: Int?
    var notes: String?

    var type: MedicationType {
        get { MedicationType(rawValue: typeRaw) ?? .supplement }
        set { typeRaw = newValue.rawValue }
    }

    var frequency: MedicationFrequency {
        get { MedicationFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    init(date: Date = Date(), name: String, dosage: String, type: MedicationType = .supplement, frequency: MedicationFrequency = .daily, effectivenessRating: Int? = nil, notes: String? = nil) {
        self.date = date
        self.name = name
        self.dosage = dosage
        self.typeRaw = type.rawValue
        self.frequencyRaw = frequency.rawValue
        self.effectivenessRating = effectivenessRating
        self.notes = notes
    }
}
