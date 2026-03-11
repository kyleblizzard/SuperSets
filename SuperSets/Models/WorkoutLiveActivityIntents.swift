// WorkoutLiveActivityIntents.swift
// Super Sets — The Workout Tracker
//
// AppIntents for interactive Live Activity controls (lock screen +/- buttons, LOG).
// LiveActivityIntent.perform() runs in the app's process, even when triggered
// from the lock screen — the system launches the app in the background if needed.
//
// Must stay in sync with SuperSetsWidgetExtension/WorkoutLiveActivityIntents.swift.

import ActivityKit
import AppIntents

// MARK: - Adjust Weight

/// Increments or decrements the pending weight on the lock screen.
struct AdjustWeightIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Weight"

    @Parameter(title: "Delta")
    var delta: Double

    init() { self.delta = 0 }

    init(delta: Double) { self.delta = delta }

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<WorkoutActivityAttributes>.activities.first else {
            return .result()
        }
        var state = activity.content.state
        state.pendingWeight = max(0, state.pendingWeight + delta)
        await activity.update(.init(state: state, staleDate: nil))
        return .result()
    }
}

// MARK: - Adjust Reps

/// Increments or decrements the pending reps on the lock screen.
struct AdjustRepsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Adjust Reps"

    @Parameter(title: "Delta")
    var delta: Int

    init() { self.delta = 0 }

    init(delta: Int) { self.delta = delta }

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<WorkoutActivityAttributes>.activities.first else {
            return .result()
        }
        var state = activity.content.state
        state.pendingReps = max(1, state.pendingReps + delta)
        await activity.update(.init(state: state, staleDate: nil))
        return .result()
    }
}

// MARK: - Log Set

/// Logs the current pending weight/reps as a new set.
/// The app registers a handler closure on launch so this intent
/// can call into WorkoutManager without importing SwiftData.
struct LogSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Log Set"

    /// Set by the app in ContentView.onAppear.
    /// Called with (weight, reps) when the user taps LOG on the lock screen.
    @MainActor static var handler: ((Double, Int) -> Void)?

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<WorkoutActivityAttributes>.activities.first else {
            return .result()
        }
        let state = activity.content.state
        await MainActor.run {
            Self.handler?(state.pendingWeight, state.pendingReps)
        }
        return .result()
    }
}
