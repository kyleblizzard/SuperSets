// SplitScheduleView.swift
// Super Sets — The Workout Tracker
//
// Create and edit repeating split schedule patterns.
// Presets: PPL, Upper/Lower, Full Body, Bro Split.

import SwiftUI

// MARK: - SplitScheduleView

struct SplitScheduleView: View {

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss

    @State private var scheduleName = ""
    @State private var pattern: [SplitDay] = [.push, .pull, .legs, .rest]
    @State private var reminderEnabled = false
    @State private var reminderDate = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var showingPresets = false

    // Presets
    private let presets: [(String, [SplitDay])] = [
        ("Push / Pull / Legs", [.push, .pull, .legs, .rest]),
        ("Upper / Lower", [.upper, .lower, .rest, .upper, .lower, .rest, .rest]),
        ("Full Body 3x", [.fullBody, .rest, .fullBody, .rest, .fullBody, .rest, .rest]),
        ("Bro Split", [.chest, .back, .shoulders, .arms, .legs, .rest, .rest]),
        ("PPL 6-Day", [.push, .pull, .legs, .push, .pull, .legs, .rest])
    ]

    var body: some View {
        ScrollView {
                VStack(spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("Schedule Name", icon: "tag.fill")
                        TextField("My Split", text: $scheduleName)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(12)
                            .glassField(cornerRadius: 12)
                    }
                    .padding(16)
                    .glassCard()

                    // Presets
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Presets", icon: "rectangle.stack.fill")

                        ForEach(presets, id: \.0) { name, days in
                            Button {
                                scheduleName = name
                                pattern = days
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack {
                                    Text(name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                    Spacer()
                                    Text(days.map(\.rawValue).joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundStyle(AppColors.subtleText)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .deepGlass(.rect(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .glassCard()

                    // Pattern builder
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Pattern", icon: "calendar.badge.plus")

                        ForEach(Array(pattern.enumerated()), id: \.offset) { index, day in
                            HStack {
                                Text("Day \(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppColors.subtleText)
                                    .frame(width: 50, alignment: .leading)

                                Picker("", selection: Binding(
                                    get: { day },
                                    set: { pattern[index] = $0 }
                                )) {
                                    ForEach(SplitDay.allCases) { splitDay in
                                        HStack {
                                            Image(systemName: splitDay.iconName)
                                            Text(splitDay.rawValue)
                                        }
                                        .tag(splitDay)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(AppColors.accent)

                                Spacer()

                                if pattern.count > 1 {
                                    Button {
                                        pattern.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(AppColors.danger)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .glassRow(cornerRadius: 10)
                        }

                        if pattern.count < 14 {
                            Button {
                                pattern.append(.rest)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Day")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.accent)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .glassCard()

                    // Reminders
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Reminders", icon: "bell.fill")

                        Toggle("Daily Reminder", isOn: $reminderEnabled)
                            .tint(AppColors.accent)
                            .foregroundStyle(AppColors.primaryText)

                        if reminderEnabled {
                            DatePicker("Reminder Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                                .foregroundStyle(AppColors.primaryText)
                        }
                    }
                    .padding(16)
                    .glassCard()

                    // Existing schedules
                    existingSchedulesSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .appBackground()
            .navigationTitle("Split Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.hour, .minute], from: reminderDate)
                        let timeStr = String(format: "%02d:%02d", components.hour ?? 8, components.minute ?? 0)

                        workoutManager.createSplitSchedule(
                            name: scheduleName.isEmpty ? "My Split" : scheduleName,
                            pattern: pattern,
                            reminderEnabled: reminderEnabled,
                            reminderTime: timeStr
                        )
                        dismiss()
                    }
                    .disabled(pattern.isEmpty)
                }
            }
    }

    private var existingSchedulesSection: some View {
        let schedules = workoutManager.allSplitSchedules()
        return Group {
            if !schedules.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("Saved Schedules", icon: "list.bullet")

                    ForEach(schedules, id: \.name) { schedule in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(schedule.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                Text(schedule.pattern.map(\.rawValue).joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.subtleText)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if schedule.isActive {
                                Text("Active")
                                    .font(.caption2.bold())
                                    .foregroundStyle(AppColors.positive)
                            }

                            Button {
                                workoutManager.toggleSplitScheduleActive(schedule)
                            } label: {
                                Image(systemName: schedule.isActive ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(schedule.isActive ? AppColors.positive : AppColors.subtleText)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .deepGlass(.rect(cornerRadius: 12))
                    }
                }
                .padding(16)
                .glassCard()
            }
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
