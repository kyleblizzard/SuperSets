// NutritionView.swift
// Super Sets — The Workout Tracker
//
// The Nutrition tab — health and wellness tracking links.
// Water, sleep, medications, injections, and split schedule.

import SwiftUI

// MARK: - NutritionView

struct NutritionView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    healthSection
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Health", icon: "heart.fill")

            healthLink("Water Intake", icon: "drop.fill", color: AppColors.accent) {
                WaterTrackingView(workoutManager: workoutManager)
            }

            healthLink("Sleep", icon: "bed.double.fill", color: AppColors.accent) {
                SleepView(workoutManager: workoutManager)
            }

            healthLink("Medications & Supplements", icon: "pill.fill", color: AppColors.accent) {
                MedicationView(workoutManager: workoutManager)
            }

            healthLink("Injections", icon: "syringe.fill", color: AppColors.accent) {
                InjectionsView(workoutManager: workoutManager)
            }

            healthLink("Split Schedule", icon: "calendar.badge.clock", color: AppColors.accent) {
                SplitScheduleView(workoutManager: workoutManager)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func healthLink<Destination: View>(_ title: String, icon: String, color: Color, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 28, height: 28)
                    .glassGem(.circle)

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .deepGlass(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
