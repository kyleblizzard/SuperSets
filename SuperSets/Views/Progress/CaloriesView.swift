// CaloriesView.swift
// Super Sets — The Workout Tracker
//
// Daily burned calories, workout calorie estimates, TDEE.

import SwiftUI

// MARK: - CaloriesView

struct CaloriesView: View {

    @Bindable var workoutManager: WorkoutManager
    var healthKitManager: HealthKitManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active calories today
                VStack(spacing: 8) {
                    sectionHeader("Active Calories Today", icon: "flame.fill")

                    Text("\(Int(healthKitManager.todayActiveCalories))")
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.accent)

                    Text("kcal burned")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .glassCard()

                // TDEE
                if let profile = workoutManager.userProfile {
                    VStack(spacing: 12) {
                        sectionHeader("Daily Energy", icon: "bolt.fill")

                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("\(profile.restingMetabolicRate)")
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(AppColors.primaryText)
                                Text("RMR")
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppColors.subtleText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .deepGlass(.rect(cornerRadius: 12))

                            VStack(spacing: 4) {
                                Text("\(profile.totalDailyEnergyExpenditure)")
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(AppColors.accent)
                                Text("TDEE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppColors.subtleText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .deepGlass(.rect(cornerRadius: 12))

                            VStack(spacing: 4) {
                                Text("\(workoutManager.weeklyWorkoutCalories())")
                                    .font(.title2.bold().monospacedDigit())
                                    .foregroundStyle(AppColors.gold)
                                Text("Workout/wk")
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppColors.subtleText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .deepGlass(.rect(cornerRadius: 12))
                        }

                        Text("RMR × \(profile.activityLevel.rawValue) = TDEE")
                            .font(.caption2)
                            .foregroundStyle(AppColors.subtleText.opacity(0.6))
                    }
                    .padding(16)
                    .glassCard()
                }

                // Goal target
                if let goal = workoutManager.activeGoal() {
                    VStack(spacing: 8) {
                        sectionHeader("Daily Target", icon: "target")

                        Text("\(goal.dailyCalorieTarget)")
                            .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(AppColors.positive)

                        Text("kcal/day (\(goal.type.rawValue))")
                            .font(.caption)
                            .foregroundStyle(AppColors.subtleText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .glassCard()
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Calories")
        .navigationBarTitleDisplayMode(.inline)
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
