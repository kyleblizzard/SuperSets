// BodyFatEntry.swift
// Super Sets — The Workout Tracker
//
// Tracks body fat percentage over time with the method used.

import Foundation
import SwiftData

// MARK: - BodyFatMethod

enum BodyFatMethod: String, CaseIterable, Codable, Identifiable {
    case caliper = "Caliper"
    case scale = "Smart Scale"
    case visual = "Visual Estimate"
    case dexa = "DEXA Scan"

    var id: Self { self }
}

// MARK: - BodyFatEntry Model

@Model
final class BodyFatEntry {
    var date: Date = Date()
    var percentage: Double = 0
    var methodRaw: String = "Smart Scale"

    var method: BodyFatMethod {
        get { BodyFatMethod(rawValue: methodRaw) ?? .scale }
        set { methodRaw = newValue.rawValue }
    }

    init(date: Date = Date(), percentage: Double, method: BodyFatMethod = .scale) {
        self.date = date
        self.percentage = percentage
        self.methodRaw = method.rawValue
    }
}
