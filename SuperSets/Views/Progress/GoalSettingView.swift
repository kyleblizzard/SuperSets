// GoalSettingView.swift
// Super Sets — The Workout Tracker
//
// Set weight goal, weekly rate, calculate daily calorie target.
// Uses Mifflin-St Jeor for RMR: (10 x wt_kg) + (6.25 x ht_cm) - (5 x age) +/- offset.

import SwiftUI
import SwiftData

// MARK: - GoalSettingView

struct GoalSettingView: View {

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss

    @State private var goalType: GoalType = .maintenance
    @State private var targetWeight: String = "170"
    @State private var weeklyRate: Double = 1.0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Goal type
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Goal Type", icon: "target")

                    Picker("Goal", selection: $goalType) {
                        ForEach(GoalType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .glassCard()

                // Target weight
                if goalType != .maintenance {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Target Weight", icon: "scalemass.fill")

                        let unit = workoutManager.userProfile?.preferredUnit ?? .lbs
                        HStack {
                            TextField("170", text: $targetWeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                                .multilineTextAlignment(.center)

                            Text(unit.rawValue)
                                .font(.title3)
                                .foregroundStyle(AppColors.subtleText)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(16)
                    .glassCard()

                    // Weekly rate
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Weekly Rate", icon: "speedometer")

                        HStack {
                            Text(String(format: "%.1f", weeklyRate))
                                .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                            Text("lbs/week")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.subtleText)
                        }

                        Slider(value: $weeklyRate, in: 0.5...2.0, step: 0.25)
                            .tint(AppColors.accent)
                    }
                    .padding(16)
                    .glassCard()
                }

                // Calculated target
                VStack(spacing: 8) {
                    sectionHeader("Daily Calorie Target", icon: "flame.fill")

                    Text("\(calculatedDailyCalories)")
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.accent)

                    Text("kcal / day")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)

                    if goalType != .maintenance {
                        let adjustment = Int(weeklyRate * 3500.0 / 7.0)
                        Text("TDEE \(goalType == .weightLoss ? "-" : "+")\(adjustment)")
                            .font(.caption)
                            .foregroundStyle(AppColors.subtleText.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .glassCard()

                // Save
                Button {
                    saveGoal()
                    dismiss()
                } label: {
                    Text("Save Goal")
                        .font(.headline)
                        .foregroundStyle(AppColors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .deepGlass(.rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Weight Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let goal = workoutManager.activeGoal() {
                goalType = goal.type
                targetWeight = String(format: "%.0f", goal.targetWeight)
                weeklyRate = goal.weeklyRate
            }
        }
    }

    private var calculatedDailyCalories: Int {
        guard let profile = workoutManager.userProfile else { return 2000 }
        let tdee = profile.totalDailyEnergyExpenditure
        let adjustment = Int(weeklyRate * 3500.0 / 7.0)

        switch goalType {
        case .weightLoss: return max(1200, tdee - adjustment)
        case .weightGain: return tdee + adjustment
        case .maintenance: return tdee
        }
    }

    private func saveGoal() {
        guard let context = workoutManager.modelContext else { return }
        let goal = GoalSetting(
            type: goalType,
            targetWeight: Double(targetWeight) ?? 170,
            weeklyRate: weeklyRate,
            dailyCalorieTarget: calculatedDailyCalories
        )
        context.insert(goal)
        workoutManager.save()
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.gold)
                .frame(width: 26, height: 26)
                .glassGem(.circle)

            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
        }
    }
}
