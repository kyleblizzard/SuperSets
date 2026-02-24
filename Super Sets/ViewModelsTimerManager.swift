//
//  TimerManager.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Manages the rest timer between sets. Supports start, stop (which resets to 0),
//  and displays the elapsed time in MM:SS format.

import Foundation
import Observation

// LEARNING NOTE: @Observable makes this class's properties observable by SwiftUI
@Observable
final class TimerManager {
    
    // MARK: - Properties
    
    /// Total elapsed seconds
    private(set) var elapsedSeconds: Int = 0
    
    /// Whether the timer is currently running
    private(set) var isRunning: Bool = false
    
    /// The timer object (we use Timer for simplicity)
    // LEARNING NOTE: Timer is a Foundation class that fires at intervals
    private var timer: Timer?
    
    // MARK: - Computed Properties
    
    /// Formatted time string (MM:SS)
    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        
        // LEARNING NOTE: %02d means "format as 2-digit integer with leading zeros"
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Control
    
    /// Starts the timer
    func start() {
        // Don't start if already running
        guard !isRunning else { return }
        
        isRunning = true
        
        // LEARNING NOTE: Timer.scheduledTimer creates a timer that fires every 1 second
        // The [weak self] capture list prevents memory leaks
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    /// Stops and resets the timer to 0
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
    }
    
    /// Called every second to increment elapsed time
    private func tick() {
        elapsedSeconds += 1
    }
    
    // MARK: - Cleanup
    
    deinit {
        // LEARNING NOTE: deinit is called when this object is destroyed
        // We clean up the timer to prevent memory leaks
        timer?.invalidate()
    }
}
