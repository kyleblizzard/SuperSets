// SleepView.swift
// Super Sets — The Workout Tracker
//
// Sleep logging — manual bedtime/wake picker or HealthKit auto-import.
// Duration calc, quality rating, 7-day trend.

import SwiftUI
import SwiftData
import Charts

// MARK: - SleepView

struct SleepView: View {

    @Bindable var workoutManager: WorkoutManager
    @Environment(HealthKitManager.self) private var healthKitManager: HealthKitManager?

    @Query(sort: \SleepEntry.date, order: .reverse)
    private var allEntries: [SleepEntry]

    @State private var showingInput = false
    @State private var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @State private var wakeTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
    @State private var quality: Int = 3

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Latest sleep
                VStack(spacing: 12) {
                    HStack {
                        sectionHeader("Sleep", icon: "bed.double.fill")
                        Spacer()
                        Button {
                            showingInput = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption2.bold())
                                Text("Log")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(AppColors.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .deepGlass(.capsule)
                        }
                        .buttonStyle(.plain)
                    }

                    if let latest = allEntries.first {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(latest.formattedDuration)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)
                        }

                        if let q = latest.quality {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= q ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundStyle(star <= q ? AppColors.gold : AppColors.subtleText)
                                }
                            }
                        }

                        Text("Last night: \(timeString(latest.bedtime)) → \(timeString(latest.wakeTime))")
                            .font(.caption)
                            .foregroundStyle(AppColors.subtleText)
                    } else {
                        Text("Log your sleep to see trends")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .glassCard()

                // 7-day chart
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Last 7 Days", icon: "chart.bar.fill")

                    let recentEntries = Array(allEntries.prefix(7).reversed())
                    if recentEntries.count >= 2 {
                        Chart(recentEntries, id: \.date) { entry in
                            BarMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Hours", entry.durationHours)
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

                        let avg = recentEntries.reduce(0.0) { $0 + $1.durationHours } / Double(recentEntries.count)
                        HStack {
                            Text("Avg")
                                .font(.caption)
                                .foregroundStyle(AppColors.subtleText)
                            Spacer()
                            Text(String(format: "%.1f hrs/night", avg))
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                }
                .padding(16)
                .glassCard()

                // History
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("History", icon: "clock.fill")

                    ForEach(allEntries.prefix(14), id: \.date) { entry in
                        HStack {
                            Text(Formatters.shortDate.string(from: entry.date))
                                .font(.caption)
                                .foregroundStyle(AppColors.subtleText)
                            Spacer()
                            Text(entry.formattedDuration)
                                .font(.body.bold())
                                .foregroundStyle(AppColors.primaryText)
                            if let q = entry.quality {
                                HStack(spacing: 1) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= q ? "star.fill" : "star")
                                            .font(.system(size: 6))
                                            .foregroundStyle(star <= q ? AppColors.gold : AppColors.subtleText)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .glassRow(cornerRadius: 8)
                    }
                }
                .padding(16)
                .glassCard()

                // HealthKit import button
                if let hk = healthKitManager, hk.isHealthKitAvailable {
                    Button {
                        Task {
                            if let data = await hk.fetchSleep(for: Date()) {
                                saveSleep(bedtime: data.bedtime, wakeTime: data.wakeTime, source: .healthKit)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(AppColors.danger)
                            Text("Import from HealthKit")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .deepGlass(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInput) {
            sleepInputSheet
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }

    private var sleepInputSheet: some View {
        VStack(spacing: 16) {
            Text("Log Sleep")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                .foregroundStyle(AppColors.primaryText)

            DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 8) {
                Text("Quality")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                Spacer()
                ForEach(1...5, id: \.self) { star in
                    Button {
                        quality = star
                    } label: {
                        Image(systemName: star <= quality ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(star <= quality ? AppColors.gold : AppColors.subtleText)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                saveSleep(bedtime: bedtime, wakeTime: wakeTime, quality: quality, source: .manual)
                showingInput = false
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .deepGlass(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .appBackground()
    }

    private func saveSleep(bedtime: Date, wakeTime: Date, quality: Int? = nil, source: SleepSource = .manual) {
        guard let context = workoutManager.modelContext else { return }
        let entry = SleepEntry(bedtime: bedtime, wakeTime: wakeTime, quality: quality, source: source)
        context.insert(entry)
        workoutManager.save()
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
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
