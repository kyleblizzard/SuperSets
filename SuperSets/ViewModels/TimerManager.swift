// TimerManager.swift
// Super Sets — The Workout Tracker
//
// Manages the rest timer between sets. Simple start/stop behavior:
// - Start begins counting up from 0
// - Stop resets back to 0 (not pause — full reset)
// - Restart stops then immediately starts (used for auto-start on set log)
//
// v1.1 UPDATE: Added restart() for auto-start timer on set log.
//
// LEARNING NOTE:
// @Observable is the modern replacement for ObservableObject (iOS 17+).
// ANY property change automatically triggers SwiftUI view updates.
// No @Published wrappers needed.
//
// The timer uses Swift's modern concurrency (async/await with Task)
// instead of the older Timer.scheduledTimer. This is cleaner and
// automatically avoids retain cycle issues with [weak self].

import Foundation
import SwiftUI

// MARK: - TimerManager

@Observable
final class TimerManager {
    
    // MARK: State
    
    /// Seconds elapsed since timer started. Resets to 0 on stop.
    var elapsedSeconds: Int = 0
    
    /// Whether the timer is currently counting.
    var isRunning: Bool = false
    
    // MARK: Private
    
    /// Reference to the background timer task.
    ///
    /// LEARNING NOTE:
    /// Task is a lightweight concurrent unit. task?.cancel() tells it
    /// to stop at the next await point (Task.sleep). Much safer than
    /// the old NSTimer which could leak memory.
    private var timerTask: Task<Void, Never>?
    
    // MARK: Computed Properties
    
    /// Formatted time: "00:00" → "59:59"
    ///
    /// LEARNING NOTE:
    /// %02d formats an integer with leading zeros to 2 digits.
    /// So 5 becomes "05", 12 stays "12".
    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: Actions
    
    /// Start counting up from current value (usually 0).
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        // LEARNING NOTE:
        // @MainActor ensures UI state changes happen on the main thread.
        // [weak self] prevents a retain cycle between Task and TimerManager.
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self?.elapsedSeconds += 1
            }
        }
    }
    
    /// Stop the timer and reset to 0.
    /// Intentionally NOT a pause — bodybuilders want a fresh timer each rest.
    func stop() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        elapsedSeconds = 0
    }
    
    /// Restart the timer from 0. Used when auto-starting on set log.
    /// Equivalent to stop() then start(), but in one call.
    func restart() {
        stop()
        start()
    }
    
    /// Clean up on deallocation.
    deinit {
        timerTask?.cancel()
    }
}
