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
            } else if workoutManager.activeWorkout != nil, let lift = workoutManager.selectedLift {
                // Active workout — show input panel
                if workoutManager.isCardioLift(lift) {
                    cardioInputPanel(for: lift)
                } else if useWheelInput {
                    wheelInputPanel(for: lift)
                } else {
                    keyboardInputPanel(for: lift)
                }
            } else {
                // No active workout — branding + Begin Lift
                VStack(spacing: 10) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.gold)

                    Text("SuperSets")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    if workoutManager.selectedLift != nil || !workoutManager.recentLifts.isEmpty {
                        Button {
                            // selectLift auto-starts a workout
                            guard let lift = workoutManager.selectedLift ?? workoutManager.recentLifts.first else { return }
                            workoutManager.selectLift(lift)
                            if let idx = workoutManager.selectedLiftIndex {
                                animateToSlot(idx)
                            }
                        } label: {
                            Text("Begin Lift")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.gold)
                                .frame(width: 100, height: 40)
                                .deepGlass(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: centerSize * 0.875, height: centerSize * 0.875)
            }
        }
    }

    // MARK: Wheel Input Mode

    /// Wheel mode — compact pickers + circular LOG.
    func wheelInputPanel(for lift: LiftDefinition) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Weight column with label
                VStack(spacing: 0) {
                    Text("Weight")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Weight", selection: $wheelWeight) {
                        ForEach(weightOptions, id: \.self) { value in
                            Text(formatWheelWeight(value))
                                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 132)
                    .clipped()
                    .glassField(cornerRadius: 12)
                }

                // Reps column with label
                VStack(spacing: 0) {
                    Text("Reps")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Reps", selection: $wheelReps) {
                        ForEach(1...99, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100, height: 132)
                    .clipped()
                    .glassField(cornerRadius: 12)
                }
            }
            .offset(y: -8)

            // LOG button (centered)
            Button { logSetAction() } label: {
                Text(showSetLogged ? "\u{2713}" : "LOG")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.gold)
                    .frame(width: 50, height: 50)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showSetLogged ? "Set logged" : "Log set")
            .accessibilityHint("Records the current weight and reps as a set")
        }
        .frame(width: centerSize, height: centerSize)
        .onAppear {
            // Ensure input strings match wheel defaults so LOG works
            // without the user having to scroll first.
            if workoutManager.weightInput.isEmpty {
                workoutManager.weightInput = formatWheelWeight(wheelWeight)
            }
            if workoutManager.repsInput.isEmpty {
                workoutManager.repsInput = "\(wheelReps)"
            }
        }
        .onChange(of: wheelWeight) { _, newValue in
            workoutManager.weightInput = formatWheelWeight(newValue)
        }
        .onChange(of: wheelReps) { _, newValue in
            workoutManager.repsInput = "\(newValue)"
        }
    }

    // MARK: Cardio Input Mode

    /// Cardio mode — single "Minutes" wheel picker + LOG button.
    /// Stores minutes as weight and auto-sets reps to 1.
    func cardioInputPanel(for lift: LiftDefinition) -> some View {
        VStack(spacing: 6) {
            VStack(spacing: 0) {
                Text("Minutes")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
                Picker("Minutes", selection: $wheelMinutes) {
                    ForEach(1...120, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100, height: 132)
                .clipped()
                .glassField(cornerRadius: 12)
            }
            .offset(y: -8)

            // LOG button
            Button { logCardioAction() } label: {
                Text(showSetLogged ? "\u{2713}" : "LOG")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.gold)
                    .frame(width: 50, height: 50)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showSetLogged ? "Set logged" : "Log cardio")
            .accessibilityHint("Records the current minutes as a cardio set")
        }
        .frame(width: centerSize, height: centerSize)
    }

    /// Log a cardio set: minutes stored as weight, reps = 1.
    func logCardioAction() {
        workoutManager.weightInput = "\(wheelMinutes)"
        workoutManager.repsInput = "1"
        logSetAction()
    }

    // MARK: Keyboard Input Mode

    /// Keyboard mode — text fields + circular log button.
    func keyboardInputPanel(for lift: LiftDefinition) -> some View {
        VStack(spacing: 6) {
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

            // LOG button (centered)
            Button { logSetAction() } label: {
                Image(systemName: showSetLogged ? "checkmark" : "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.gold)
                    .frame(width: 50, height: 50)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showSetLogged ? "Set logged" : "Log set")
            .accessibilityHint("Records the current weight and reps as a set")
        }
        .frame(width: centerSize, height: centerSize)
    }

    // MARK: Center Timer Panel

    /// Timer view that takes over the ring center when activated.
    var centerTimerPanel: some View {
        VStack(spacing: 6) {
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
                    AppAnimation.perform(AppAnimation.spring) {
                        showTimerInCenter = false
                    }
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
                .frame(width: 40, height: 28)
                .deepGlass(.capsule, isActive: timerManager.countdownDuration == duration)
        }
        .buttonStyle(.plain)
    }

    // MARK: Log Set Action

    /// Handles logging a set with haptic feedback, confirmation animation, and PR detection.
    func logSetAction() {
        let success = workoutManager.logSet(
            isWarmUp: false,
            toFailure: false,
            intensityTechnique: nil
        )
        if success {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            AppAnimation.perform(AppAnimation.quick) {
                showSetLogged = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                AppAnimation.perform(AppAnimation.quick) { showSetLogged = false }
            }

            if let pr = workoutManager.newPRAlert {
                prType = pr
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                AppAnimation.perform(AppAnimation.spring) {
                    showPRBadge = true
                }
                workoutManager.newPRAlert = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    AppAnimation.perform(AppAnimation.quick) { showPRBadge = false }
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
