// WorkoutLiveActivityIntents.swift
// Super Sets — Widget Extension
//
// Duplicate of the Live Activity intents.
// Must stay in sync with SuperSets/Models/WorkoutLiveActivityIntents.swift.

import ActivityKit
import AppIntents

// MARK: - Adjust Weight

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

struct LogSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Log Set"

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
