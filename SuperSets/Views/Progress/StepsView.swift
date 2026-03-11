// StepsView.swift
// Super Sets — The Workout Tracker
//
// Daily steps display with bar chart (last 7 days).

import SwiftUI
import Charts

// MARK: - StepsView

struct StepsView: View {

    var healthKitManager: HealthKitManager

    @State private var weeklySteps: [(date: Date, count: Int)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Today
                VStack(spacing: 8) {
                    sectionHeader("Today's Steps", icon: "figure.walk")

                    Text("\(healthKitManager.todaySteps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.accent)

                    Text("steps")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .glassCard()

                // Weekly chart
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Last 7 Days", icon: "chart.bar.fill")

                    if weeklySteps.isEmpty {
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 16)
                    } else {
                        Chart(weeklySteps, id: \.date) { point in
                            BarMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Steps", point.count)
                            )
                            .foregroundStyle(AppColors.accent.gradient)
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) {
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    .foregroundStyle(AppColors.subtleText)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(AppColors.subtleText)
                                AxisGridLine()
                                    .foregroundStyle(AppColors.divider)
                            }
                        }
                        .frame(height: 200)

                        let avg = weeklySteps.isEmpty ? 0 : weeklySteps.reduce(0) { $0 + $1.count } / weeklySteps.count
                        HStack {
                            Text("Weekly Avg")
                                .font(.caption)
                                .foregroundStyle(AppColors.subtleText)
                            Spacer()
                            Text("\(avg) steps/day")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                }
                .padding(16)
                .glassCard()

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            weeklySteps = await healthKitManager.fetchWeeklySteps()
        }
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
