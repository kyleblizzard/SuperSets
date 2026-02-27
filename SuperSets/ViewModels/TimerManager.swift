// TimerManager.swift
// Super Sets — The Workout Tracker
//
// Manages the rest timer between sets. Countdown behavior:
// - User selects a duration (30s, 60s, 90s, 120s, 180s, 300s)
// - Timer counts DOWN from the selected duration
// - Haptic buzz when timer reaches 0
// - Stop resets back to selected duration
// - Restart resets and starts counting down again (used for auto-start on set log)
//
// LEARNING NOTE:
// @Observable is the modern replacement for ObservableObject (iOS 17+).
// ANY property change automatically triggers SwiftUI view updates.
// No @Published wrappers needed.

import Foundation
import SwiftUI

// MARK: - TimerManager

@Observable
final class TimerManager {

    // MARK: Duration Presets

    /// Available countdown duration presets in seconds.
    static let durationPresets: [Int] = [30, 60, 90, 120, 180, 300]

    // MARK: State

    /// The selected countdown duration in seconds.
    var countdownDuration: Int = 90

    /// Seconds remaining on the countdown. Resets to `countdownDuration` on stop.
    var remainingSeconds: Int = 90

    /// Whether the timer is currently counting down.
    var isRunning: Bool = false

    /// True when the countdown reached 0 (stays true until reset or new start).
    var isFinished: Bool = false

    // MARK: Private

    /// Reference to the background timer task.
    private var timerTask: Task<Void, Never>?

    // MARK: Computed Properties

    /// Formatted remaining time: "00:00" -> "59:59"
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Short label for a duration preset: "0:30", "1:00", "1:30", etc.
    static func durationLabel(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m):00" : "\(m):\(String(format: "%02d", s))"
    }

    // MARK: Actions

    /// Set the countdown duration and reset remaining seconds.
    func setDuration(_ seconds: Int) {
        countdownDuration = seconds
        if !isRunning {
            remainingSeconds = seconds
            isFinished = false
        }
    }

    /// Start counting down from current remaining value.
    func start() {
        guard !isRunning else { return }
        isFinished = false
        if remainingSeconds <= 0 {
            remainingSeconds = countdownDuration
        }
        isRunning = true

        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { break }

                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                }

                if self.remainingSeconds <= 0 {
                    self.isRunning = false
                    self.isFinished = true
                    self.timerTask?.cancel()
                    self.timerTask = nil
                    // Haptic buzz when timer finishes
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    break
                }
            }
        }
    }

    /// Stop the timer and reset to the selected duration.
    func stop() {
        isRunning = false
        isFinished = false
        timerTask?.cancel()
        timerTask = nil
        remainingSeconds = countdownDuration
    }

    /// Restart the timer from the selected duration.
    /// Used when auto-starting on set log.
    func restart() {
        stop()
        start()
    }

    /// Clean up on deallocation.
    deinit {
        timerTask?.cancel()
    }
}
