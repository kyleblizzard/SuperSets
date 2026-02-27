// WorkoutView+SuperSet.swift
// Super Sets — The Workout Tracker
//
// Extension: Super set cycle-through center panel — shows one lift
// at a time with weight/reps pickers and prev/next/LOG navigation.

import SwiftUI

// MARK: - WorkoutView + Super Set

extension WorkoutView {

    // MARK: Super Set Center Panel

    /// Cycle-through center panel for super set mode.
    /// Shows one lift at a time with weight/reps pickers and prev/next/LOG navigation.
    var superSetCenterPanel: some View {
        let lifts = workoutManager.superSetLifts
        let safeIndex = min(superSetInputIndex, max(lifts.count - 1, 0))
        let currentLift = lifts.isEmpty ? nil : lifts[safeIndex]
        let isLastLift = safeIndex == lifts.count - 1

        return VStack(spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 8, weight: .bold))
                Text("SUPER SET")
                    .font(.system(size: 8, weight: .black, design: .rounded))
            }
            .foregroundStyle(AppColors.gold)

            if let lift = currentLift {
                // Lift name with index
                Text("\(lift.name) (\(safeIndex + 1)/\(lifts.count))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // Wheel pickers with labels
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text("Weight")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                        Picker("Weight", selection: superSetWeightBinding(for: lift.name)) {
                            ForEach(weightOptions, id: \.self) { value in
                                Text(formatWheelWeight(value))
                                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 72, height: 80)
                        .clipped()
                    }

                    VStack(spacing: 0) {
                        Text("Reps")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                        Picker("Reps", selection: superSetRepsBinding(for: lift.name)) {
                            ForEach(1...99, id: \.self) { value in
                                Text("\(value)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 72, height: 80)
                        .clipped()
                    }
                }

                // Navigation row: prev / LOG or Next / next
                HStack(spacing: 6) {
                    Button {
                        saveSuperSetWheelValues()
                        AppAnimation.perform(AppAnimation.quick) {
                            superSetInputIndex = max(0, safeIndex - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(safeIndex > 0 ? AppColors.accent : AppColors.subtleText.opacity(0.3))
                            .frame(width: 30, height: 28)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                    .disabled(safeIndex == 0)

                    // LOG (circle) or Next
                    Button {
                        saveSuperSetWheelValues()
                        if isLastLift {
                            logSuperSetAction()
                        } else {
                            AppAnimation.perform(AppAnimation.quick) {
                                superSetInputIndex = safeIndex + 1
                            }
                        }
                    } label: {
                        Text(isLastLift ? (showSetLogged ? "\u{2713}" : "LOG") : "Next")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isLastLift
                                ? (showSetLogged ? AppColors.positive : AppColors.gold)
                                : AppColors.accent)
                            .frame(width: 44, height: 44)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveSuperSetWheelValues()
                        AppAnimation.perform(AppAnimation.quick) {
                            superSetInputIndex = min(lifts.count - 1, safeIndex + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(!isLastLift ? AppColors.accent : AppColors.subtleText.opacity(0.3))
                            .frame(width: 30, height: 28)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLastLift)
                }
            }
        }
        .frame(width: centerSize, height: centerSize)
    }

    // MARK: Super Set Bindings

    /// Binding for the super set wheel weight for a given lift name.
    func superSetWeightBinding(for liftName: String) -> Binding<Double> {
        Binding<Double>(
            get: { superSetWheelWeights[liftName] ?? 135.0 },
            set: { newValue in
                superSetWheelWeights[liftName] = newValue
                workoutManager.superSetWeights[liftName] = formatWheelWeight(newValue)
            }
        )
    }

    /// Binding for the super set wheel reps for a given lift name.
    func superSetRepsBinding(for liftName: String) -> Binding<Int> {
        Binding<Int>(
            get: { superSetWheelReps[liftName] ?? 8 },
            set: { newValue in
                superSetWheelReps[liftName] = newValue
                workoutManager.superSetReps[liftName] = "\(newValue)"
            }
        )
    }

    /// Persist current wheel picker values into workoutManager before switching lifts.
    func saveSuperSetWheelValues() {
        for lift in workoutManager.superSetLifts {
            let name = lift.name
            if let w = superSetWheelWeights[name] {
                workoutManager.superSetWeights[name] = formatWheelWeight(w)
            }
            if let r = superSetWheelReps[name] {
                workoutManager.superSetReps[name] = "\(r)"
            }
        }
    }

    // MARK: Log Super Set Action

    /// Log the super set with haptic feedback and confirmation animation.
    func logSuperSetAction() {
        saveSuperSetWheelValues()
        let success = workoutManager.logSuperSet()
        if success {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            AppAnimation.perform(AppAnimation.quick) {
                showSetLogged = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { showSetLogged = false }
            }

            // Reset to first lift for next round
            superSetInputIndex = 0

            // Reset reps wheels (weights persist)
            for lift in workoutManager.superSetLifts {
                superSetWheelReps[lift.name] = 8
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
        }
    }
}
