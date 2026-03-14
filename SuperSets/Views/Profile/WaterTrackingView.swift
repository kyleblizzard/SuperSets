// WaterTrackingView.swift
// Super Sets — The Workout Tracker
//
// Daily water intake tally with quick-add buttons and progress ring.

import SwiftUI
import SwiftData
import Charts

// MARK: - WaterTrackingView

struct WaterTrackingView: View {

    @Bindable var workoutManager: WorkoutManager
    @State private var dailyGoal: Double = 128 // oz
    @State private var customAmountDouble: Double = 16
    @State private var showingCustomInput = false

    @Query(sort: \WaterEntry.date, order: .reverse)
    private var allEntries: [WaterEntry]

    private var todayEntries: [WaterEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDateInToday($0.date) }
    }

    private var todayTotal: Double {
        todayEntries.reduce(0) { $0 + $1.amount }
    }

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayTotal / dailyGoal, 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress
                VStack(spacing: 12) {
                    sectionHeader("Today's Water", icon: "drop.fill")

                    ZStack {
                        Circle()
                            .stroke(AppColors.subtleText.opacity(0.2), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: progress)

                        VStack(spacing: 4) {
                            Text("\(Int(todayTotal))")
                                .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                            Text("/ \(Int(dailyGoal)) oz")
                                .font(.caption)
                                .foregroundStyle(AppColors.subtleText)
                        }
                    }
                    .frame(width: 150, height: 150)

                    // Quick add buttons
                    HStack(spacing: 12) {
                        quickAddButton(amount: 8, label: "8 oz")
                        quickAddButton(amount: 16, label: "16 oz")
                        quickAddButton(amount: 24, label: "24 oz")

                        Button {
                            showingCustomInput = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Custom")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 60, height: 50)
                            .deepGlass(.rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .glassCard()

                // 7-day history
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Last 7 Days", icon: "chart.bar.fill")

                    let weekData = last7DaysData
                    if !weekData.isEmpty {
                        Chart(weekData, id: \.date) { point in
                            BarMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Oz", point.amount)
                            )
                            .foregroundStyle(AppColors.accent.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(AppColors.subtleText)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) {
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    .foregroundStyle(AppColors.subtleText)
                            }
                        }
                        .frame(height: 160)
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
        .navigationTitle("Water Intake")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCustomInput) {
            customWaterSheet
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
    }

    private func quickAddButton(amount: Double, label: String) -> some View {
        Button {
            addWater(amount: amount)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(AppColors.accent)
            .frame(width: 60, height: 50)
            .deepGlass(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var customWaterSheet: some View {
        VStack(spacing: 20) {
            Text("Add Water")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            RulerSlider(
                value: $customAmountDouble,
                range: 1...64,
                step: 1,
                unit: "oz"
            )
            .padding(.horizontal, 16)

            Button {
                if customAmountDouble > 0 {
                    addWater(amount: customAmountDouble)
                    showingCustomInput = false
                    customAmountDouble = 16
                }
            } label: {
                Text("Add")
                    .font(.headline)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .deepGlass(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
        .appBackground()
    }

    private func addWater(amount: Double) {
        guard let context = workoutManager.modelContext else { return }
        let entry = WaterEntry(amount: amount, dailyGoal: dailyGoal)
        context.insert(entry)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var last7DaysData: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        var result: [(date: Date, amount: Double)] = []
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let total = allEntries
                .filter { calendar.isDate($0.date, inSameDayAs: startOfDay) }
                .reduce(0) { $0 + $1.amount }
            result.append((date: startOfDay, amount: total))
        }
        return result
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
