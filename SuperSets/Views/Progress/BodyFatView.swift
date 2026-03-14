// BodyFatView.swift
// Super Sets — The Workout Tracker
//
// Log and graph body fat percentage over time.

import SwiftUI
import Charts

// MARK: - BodyFatView

struct BodyFatView: View {

    @Bindable var workoutManager: WorkoutManager

    @State private var inputDouble: Double = 20.0
    @State private var selectedMethod: BodyFatMethod = .scale
    @State private var showingInput = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current + chart
                VStack(spacing: 12) {
                    HStack {
                        sectionHeader("Body Fat %", icon: "percent")
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

                    let entries = workoutManager.bodyFatEntries()

                    if let latest = entries.last {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", latest.percentage))
                                .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                            Text("%")
                                .font(.title3)
                                .foregroundStyle(AppColors.subtleText)
                        }

                        Text("via \(latest.method.rawValue)")
                            .font(.caption)
                            .foregroundStyle(AppColors.subtleText)
                    }

                    if entries.count >= 2 {
                        bodyFatChart(entries: entries)
                    } else if entries.isEmpty {
                        Text("Log your body fat % to see trends")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 16)
                    }
                }
                .padding(16)
                .glassCard()

                // History
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("History", icon: "clock.fill")

                    let entries = workoutManager.bodyFatEntries()
                    if entries.isEmpty {
                        Text("No entries yet")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(entries.reversed().prefix(20), id: \.date) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Formatters.shortDate.string(from: entry.date))
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.primaryText)
                                    Text(entry.method.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(AppColors.subtleText)
                                }
                                Spacer()
                                Text(String(format: "%.1f%%", entry.percentage))
                                    .font(.body.bold().monospacedDigit())
                                    .foregroundStyle(AppColors.primaryText)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .glassRow(cornerRadius: 10)
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
        .navigationTitle("Body Fat")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInput) {
            bodyFatInputSheet
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    private func bodyFatChart(entries: [BodyFatEntry]) -> some View {
        Chart(entries, id: \.date) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("BF%", entry.percentage)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppColors.accent)

            PointMark(
                x: .value("Date", entry.date),
                y: .value("BF%", entry.percentage)
            )
            .foregroundStyle(AppColors.accent)
            .symbolSize(30)
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel().foregroundStyle(AppColors.subtleText)
                AxisGridLine().foregroundStyle(AppColors.divider)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(AppColors.subtleText)
            }
        }
        .frame(height: 160)
    }

    private var bodyFatInputSheet: some View {
        VStack(spacing: 20) {
            Text("Log Body Fat")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            RulerSlider(
                value: $inputDouble,
                range: 3...50,
                step: 0.5,
                unit: "%"
            )
            .padding(.horizontal, 16)

            Picker("Method", selection: $selectedMethod) {
                ForEach(BodyFatMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 32)

            Button {
                if inputDouble > 0, inputDouble <= 100 {
                    workoutManager.logBodyFat(percentage: inputDouble, method: selectedMethod)
                    showingInput = false
                }
            } label: {
                Text("Save")
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
