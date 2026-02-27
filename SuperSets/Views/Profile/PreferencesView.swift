// PreferencesView.swift
// Super Sets — The Workout Tracker
//
// App preferences: weight unit, theme, input method, default rest timer duration.
// Pushed via NavigationLink from MeView.

import SwiftUI

// MARK: - PreferencesView

struct PreferencesView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                unitsSection
                displaySection
                inputSection
                timerSection
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Preferences")
    }

    // MARK: - Units

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Units", icon: "scalemass.fill")

            if let profile = workoutManager.userProfile {
                HStack {
                    Text("Weight Unit")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { profile.preferredUnit },
                        set: { profile.preferredUnit = $0 }
                    )) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Display

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Display", icon: "paintbrush.fill")

            if let profile = workoutManager.userProfile {
                HStack {
                    Text("Theme")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Picker("", selection: Binding<AppThemeOption>(
                        get: { profile.preferredTheme },
                        set: { newTheme in
                            AppAnimation.perform(AppAnimation.smooth) {
                                profile.preferredTheme = newTheme
                            }
                        }
                    )) {
                        ForEach(AppThemeOption.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Input", icon: "keyboard.fill")

            if let profile = workoutManager.userProfile {
                HStack {
                    Text("Input Method")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Picker("", selection: Binding<Bool>(
                        get: { profile.useScrollWheelInput },
                        set: { profile.useScrollWheelInput = $0 }
                    )) {
                        Text("Wheels").tag(true)
                        Text("Keyboard").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Rest Timer", icon: "timer")

            if let profile = workoutManager.userProfile {
                HStack {
                    Text("Default Duration")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Text(TimerManager.durationLabel(profile.defaultRestTimerDuration))
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                }

                // Duration preset buttons
                HStack(spacing: 8) {
                    ForEach(TimerManager.durationPresets, id: \.self) { duration in
                        Button {
                            profile.defaultRestTimerDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(TimerManager.durationLabel(duration))
                                .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(
                                    profile.defaultRestTimerDuration == duration
                                    ? AppColors.accent : AppColors.subtleText
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .deepGlass(
                                    .capsule,
                                    isActive: profile.defaultRestTimerDuration == duration
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Reusable Components

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
