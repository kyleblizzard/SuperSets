// BodyMeasurementsView.swift
// Super Sets — The Workout Tracker
//
// Log and graph body measurements by type.

import SwiftUI
import Charts

// MARK: - BodyMeasurementsView

struct BodyMeasurementsView: View {

    @Bindable var workoutManager: WorkoutManager

    @State private var selectedType: MeasurementType = .chest
    @State private var inputValue = ""
    @State private var showingInput = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Type picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MeasurementType.allCases) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Text(type.displayName)
                                    .font(.caption.bold())
                                    .foregroundStyle(selectedType == type ? AppColors.gold : AppColors.subtleText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .deepGlass(.capsule, isActive: selectedType == type)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Latest value + log button
                VStack(spacing: 12) {
                    HStack {
                        sectionHeader(selectedType.displayName, icon: "ruler.fill")
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

                    let entries = workoutManager.bodyMeasurements(for: selectedType)

                    if let latest = entries.last {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", latest.value))
                                .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                            Text(latest.unit.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.subtleText)
                        }
                    }

                    if entries.count >= 2 {
                        measurementChart(entries: entries)
                    } else if entries.isEmpty {
                        Text("No measurements yet")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 16)
                    }

                    // History list
                    ForEach(entries.reversed().prefix(10), id: \.date) { entry in
                        HStack {
                            Text(Formatters.shortDate.string(from: entry.date))
                                .font(.subheadline)
                                .foregroundStyle(AppColors.subtleText)
                            Spacer()
                            Text(String(format: "%.1f", entry.value) + " " + entry.unit.rawValue)
                                .font(.body.bold().monospacedDigit())
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .glassRow(cornerRadius: 10)
                    }
                }
                .padding(16)
                .glassCard()

                // All latest measurements summary
                latestSummaryCard

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Body Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInput) {
            measurementInputSheet
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isInputFocused = false }
            }
        }
    }

    private func measurementChart(entries: [BodyMeasurement]) -> some View {
        Chart(entries, id: \.date) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Value", entry.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppColors.accent)

            PointMark(
                x: .value("Date", entry.date),
                y: .value("Value", entry.value)
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

    private var latestSummaryCard: some View {
        let latest = workoutManager.latestMeasurements()
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("All Measurements", icon: "list.bullet")

            if latest.isEmpty {
                Text("Log measurements to see your summary")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.vertical, 8)
            } else {
                let regions = Dictionary(grouping: latest) { $0.key.bodyRegion }
                ForEach(regions.keys.sorted(), id: \.self) { region in
                    Text(region)
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.gold)
                        .padding(.top, 4)

                    if let items = regions[region] {
                        ForEach(items.sorted(by: { $0.key.displayName < $1.key.displayName }), id: \.key) { type, measurement in
                            HStack {
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.subtleText)
                                Spacer()
                                Text(String(format: "%.1f", measurement.value) + " " + measurement.unit.rawValue)
                                    .font(.body.bold().monospacedDigit())
                                    .foregroundStyle(AppColors.primaryText)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .glassRow(cornerRadius: 8)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var measurementInputSheet: some View {
        VStack(spacing: 20) {
            Text("Log \(selectedType.displayName)")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            HStack {
                TextField("0.0", text: $inputValue)
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("in")
                    .font(.title3)
                    .foregroundStyle(AppColors.subtleText)
            }
            .padding(.horizontal, 32)

            Button {
                if let value = Double(inputValue), value > 0 {
                    workoutManager.logBodyMeasurement(type: selectedType, value: value)
                    showingInput = false
                    inputValue = ""
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
