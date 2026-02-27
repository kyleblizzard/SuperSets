// Formatters.swift
// Super Sets — The Workout Tracker
//
// Static DateFormatters to avoid re-allocating on every call.
// DateFormatter is expensive to create — reuse shared instances.

import Foundation

enum Formatters {

    // MARK: - Date Formatters

    /// "MMM d" — e.g. "Jan 15"
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// "MMMM yyyy" — e.g. "January 2026"
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// "EEE, MMM d" — e.g. "Mon, Jan 15"
    static let weekdayShortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    /// Full date style — e.g. "Monday, January 15, 2026"
    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
}
