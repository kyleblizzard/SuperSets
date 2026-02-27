// WorkoutView+CenterInput.swift
// Super Sets — The Workout Tracker
//
// Extension: Center input panel — weight/reps pickers (wheel or keyboard),
// circular LOG button, timer shortcut, and the rest timer overlay.

import SwiftUI

// MARK: - WorkoutView + Center Input

extension WorkoutView {

    // MARK: Center Input Panel

    /// Center of the rotary ring.
    /// Three modes: timer overlay, weight/reps wheel input, or keyboard text fields.
    var radialCenterInputPanel: some View {
        Group {
            if showTimerInCenter && workoutManager.activeWorkout != nil {
                centerTimerPanel
            } else if let lift = workoutManager.selectedLift {
                if useWheelInput {
                    wheelInputPanel(for: lift)
                } else {
                    keyboardInputPanel(for: lift)
                }
            } else {
                // No lift selected hint
                VStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.accent.opacity(0.6))
                    Text("Select\na lift")
                        .font(.caption2)
                        .foregroundStyle(AppColors.subtleText)
                        .multilineTextAlignment(.center)
                }
                .frame(width: centerSize * 0.875, height: centerSize * 0.875)
            }
        }
    }

    // MARK: Wheel Input Mode

    /// Wheel mode — compact pickers + circular LOG.
    func wheelInputPanel(for lift: LiftDefinition) -> some View {
        VStack(spacing: 0) {
            Text(lift.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.subtleText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 4) {
                // Weight column with label
                VStack(spacing: 0) {
                    Text("Weight")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Weight", selection: $wheelWeight) {
                        ForEach(weightOptions, id: \.self) { value in
                            Text(formatWheelWeight(value))
                                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 72, height: 90)
                    .clipped()
                }

                // Reps column with label
                VStack(spacing: 0) {
                    Text("Reps")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Reps", selection: $wheelReps) {
                        ForEach(1...99, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 72, height: 90)
                    .clipped()
                }
            }

            // Tag row: W, F, technique
            intensityTagRow

            // LOG + timer row
            HStack(spacing: 6) {
                timerShortcutButton

                Button { logSetAction() } label: {
                    Text(showSetLogged ? "\u{2713}" : "LOG")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                        .frame(width: 50, height: 50)
                        .deepGlass(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showSetLogged ? "Set logged" : "Log set")
                .accessibilityHint("Records the current weight and reps as a set")
            }
        }
        .frame(width: centerSize, height: centerSize)
        .onChange(of: wheelWeight) { _, newValue in
            workoutManager.weightInput = formatWheelWeight(newValue)
        }
        .onChange(of: wheelReps) { _, newValue in
            workoutManager.repsInput = "\(newValue)"
        }
    }

    // MARK: Keyboard Input Mode

    /// Keyboard mode — text fields + circular log button.
    func keyboardInputPanel(for lift: LiftDefinition) -> some View {
        VStack(spacing: 6) {
            Text(lift.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.subtleText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 4) {
                VStack(spacing: 2) {
                    Text("Weight")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    TextField("Wt", text: $workoutManager.weightInput)
                        .keyboardType(.decimalPad)
                        .focused($isInputFocused)
                        .font(.system(size: 14, weight: .bold).monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(width: 58, height: 36)
                        .glassField(cornerRadius: 8)
                }

                VStack(spacing: 2) {
                    Text("Reps")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    TextField("Rps", text: $workoutManager.repsInput)
                        .keyboardType(.numberPad)
                        .focused($isInputFocused)
                        .font(.system(size: 14, weight: .bold).monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .frame(width: 58, height: 36)
                        .glassField(cornerRadius: 8)
                }
            }

            // Tag row: W, F, technique
            intensityTagRow

            HStack(spacing: 6) {
                timerShortcutButton

                Button { logSetAction() } label: {
                    Image(systemName: showSetLogged ? "checkmark" : "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                        .frame(width: 50, height: 50)
                        .deepGlass(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showSetLogged ? "Set logged" : "Log set")
                .accessibilityHint("Records the current weight and reps as a set")
            }
        }
        .frame(width: centerSize, height: centerSize)
    }

    // MARK: Intensity Tag Row

    /// Compact row of tag buttons: Warm-up, Failure, Technique picker.
    var intensityTagRow: some View {
        HStack(spacing: 4) {
            warmUpToggleButton

            // Failure toggle
            Button {
                toFailureToggled.toggle()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("F")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(toFailureToggled ? AppColors.danger : AppColors.subtleText)
                    .frame(width: 28, height: 28)
                    .deepGlass(.circle, isActive: toFailureToggled)
            }
            .buttonStyle(.plain)

            // Technique picker menu
            Menu {
                Button("None") { selectedTechnique = nil }
                ForEach(IntensityTechnique.allCases) { tech in
                    Button(tech.rawValue) { selectedTechnique = tech }
                }
            } label: {
                Text(selectedTechnique?.shortLabel ?? "IT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedTechnique != nil ? AppColors.accent : AppColors.subtleText)
                    .frame(width: 28, height: 28)
                    .deepGlass(.circle, isActive: selectedTechnique != nil)
            }
        }
    }

    // MARK: Warm-Up Toggle Button

    /// Small "W" button that toggles warm-up mode for the next set.
    var warmUpToggleButton: some View {
        Button {
            isWarmUpToggled.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text("W")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isWarmUpToggled ? AppColors.gold : AppColors.subtleText)
                .frame(width: 32, height: 32)
                .deepGlass(.circle, isActive: isWarmUpToggled)
        }
        .buttonStyle(.plain)
    }

    // MARK: Timer Shortcut Button

    /// Small timer button that opens the center timer panel.
    @ViewBuilder
    var timerShortcutButton: some View {
        if workoutManager.activeWorkout != nil {
            Button {
                AppAnimation.perform(AppAnimation.spring) {
                    showTimerInCenter = true
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(timerManager.isRunning ? AppColors.positive : AppColors.subtleText)
                    .frame(width: 32, height: 32)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rest timer")
            .accessibilityValue(timerManager.isRunning ? "Running, \(timerManager.formattedTime) remaining" : "Stopped")
        }
    }

    // MARK: Center Timer Panel

    /// Timer view that takes over the ring center when activated.
    var centerTimerPanel: some View {
        VStack(spacing: 6) {
            // Close button
            HStack {
                Spacer()
                Button {
                    AppAnimation.perform(AppAnimation.spring) {
                        showTimerInCenter = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                        .frame(width: 24, height: 24)
                        .deepGlass(.circle)
                }
                .buttonStyle(.plain)
            }

            Text("Rest Timer")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.subtleText)

            // Countdown display
            Text(timerManager.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(timerManager.isFinished ? AppColors.positive : AppColors.primaryText)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: timerManager.remainingSeconds)

            // Duration preset buttons (two rows of 3)
            if !timerManager.isRunning {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(TimerManager.durationPresets.prefix(3), id: \.self) { duration in
                            timerDurationButton(duration)
                        }
                    }
                    HStack(spacing: 4) {
                        ForEach(TimerManager.durationPresets.suffix(3), id: \.self) { duration in
                            timerDurationButton(duration)
                        }
                    }
                }
            }

            // Play / Stop button
            Button {
                if timerManager.isRunning {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    timerManager.stop()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    timerManager.start()
                }
            } label: {
                Image(systemName: timerManager.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(timerManager.isRunning ? AppColors.danger : AppColors.positive)
                    .frame(width: 50, height: 50)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
        }
        .frame(width: centerSize, height: centerSize)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Timer Duration Button

    /// A single duration preset button for the rest timer.
    func timerDurationButton(_ duration: Int) -> some View {
        Button {
            timerManager.setDuration(duration)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(TimerManager.durationLabel(duration))
                .font(.system(size: 10, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(timerManager.countdownDuration == duration ? AppColors.accent : AppColors.subtleText)
                .frame(width: 40, height: 24)
                .deepGlass(.capsule, isActive: timerManager.countdownDuration == duration)
        }
        .buttonStyle(.plain)
    }

    // MARK: Log Set Action

    /// Handles logging a set with haptic feedback, confirmation animation, and PR detection.
    func logSetAction() {
        let success = workoutManager.logSet(
            isWarmUp: isWarmUpToggled,
            toFailure: toFailureToggled,
            intensityTechnique: selectedTechnique
        )
        if success {
            // Reset toggles after logging
            isWarmUpToggled = false
            toFailureToggled = false
            selectedTechnique = nil
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            AppAnimation.perform(AppAnimation.quick) {
                showSetLogged = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { showSetLogged = false }
            }

            if let pr = workoutManager.newPRAlert {
                prType = pr
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                AppAnimation.perform(AppAnimation.spring) {
                    showPRBadge = true
                }
                workoutManager.newPRAlert = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation { showPRBadge = false }
                }
            }

            // Re-sync wheels after logging (reps may reset)
            if useWheelInput {
                syncWheelsFromInput()
            }
        }
    }

    // MARK: Wheel Sync

    /// Syncs wheel picker values from workoutManager string inputs.
    func syncWheelsFromInput() {
        if let weight = Double(workoutManager.weightInput), weight > 0 {
            let options = weightOptions
            if let closest = options.min(by: { abs($0 - weight) < abs($1 - weight) }) {
                wheelWeight = closest
            }
        }
        if let reps = Int(workoutManager.repsInput), reps >= 1, reps <= 99 {
            wheelReps = reps
        } else {
            wheelReps = 8
        }
    }
}
