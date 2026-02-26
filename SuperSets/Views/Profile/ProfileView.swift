// ProfileView.swift
// Super Sets — The Workout Tracker
//
// User profile with personal info, measurements, preferences, and RMR.
//
// v2.0 — 10x LIQUID GLASS: Deep glass photo frame, deep glass RMR orb,
// glass gem section header icons. All .glassCard() auto-upgraded to slabs.

import SwiftUI
import PhotosUI
import SwiftData

// MARK: - ProfileView

struct ProfileView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: State

    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                profileHeader
                personalInfoSection
                measurementsSection
                preferencesSection
                rmrSection
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Profile Header

    /// Profile photo in a deep glass circle frame.
    private var profileHeader: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Group {
                    if let photoData = workoutManager.userProfile?.profilePhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(AppColors.subtleText)
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .deepGlass(.circle)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        workoutManager.userProfile?.profilePhotoData = data
                    }
                }
            }

            Text("Tap to change photo")
                .font(.caption2)
                .foregroundStyle(AppColors.subtleText)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Personal Info

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Personal Info", icon: "person.fill")

            if let profile = workoutManager.userProfile {
                profileField("Name", binding: Binding(
                    get: { profile.name },
                    set: { profile.name = $0 }
                ))

                profileStepper("Age", value: Binding(
                    get: { profile.age },
                    set: { profile.age = $0 }
                ), range: 13...100)

                HStack {
                    Text("Sex")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)

                    Spacer()

                    Picker("", selection: Binding(
                        get: { profile.biologicalSex },
                        set: { profile.biologicalSex = $0 }
                    )) {
                        ForEach(BiologicalSex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Measurements

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Measurements", icon: "ruler.fill")

            if let profile = workoutManager.userProfile {
                HStack {
                    Text("Height")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Text(profile.formattedHeight)
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                    Stepper("", value: Binding(
                        get: { profile.heightInches },
                        set: { profile.heightInches = $0 }
                    ), in: 48...96, step: 1)
                    .labelsHidden()
                    .frame(width: 100)
                }

                HStack {
                    Text("Weight")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Text("\(String(format: "%.0f", profile.bodyWeight)) \(profile.preferredUnit.rawValue)")
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                    Stepper("", value: Binding(
                        get: { profile.bodyWeight },
                        set: { profile.bodyWeight = $0 }
                    ), in: 50...500, step: 1)
                    .labelsHidden()
                    .frame(width: 100)
                }

                HStack {
                    Text("Waist")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Text("\(String(format: "%.1f", profile.waistInches))\"")
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                    Stepper("", value: Binding(
                        get: { profile.waistInches },
                        set: { profile.waistInches = $0 }
                    ), in: 20...60, step: 0.5)
                    .labelsHidden()
                    .frame(width: 100)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Preferences", icon: "gearshape.fill")

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

                Divider().background(AppColors.divider)

                HStack {
                    Text("Theme")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    Picker("", selection: Binding<AppThemeOption>(
                        get: { profile.preferredTheme },
                        set: { newTheme in
                            withAnimation(AppAnimation.smooth) {
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

                Divider().background(AppColors.divider)

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

    // MARK: - RMR Section

    /// Resting Metabolic Rate displayed in a deep glass orb.
    private var rmrSection: some View {
        VStack(spacing: 14) {
            sectionHeader("Resting Metabolic Rate", icon: "flame.fill")

            if let profile = workoutManager.userProfile {
                // RMR value in a deep glass rounded rect
                VStack(spacing: 4) {
                    Text("\(profile.restingMetabolicRate)")
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.accent)

                    Text("calories / day at rest")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .deepGlass(.rect(cornerRadius: 16))

                Text("Mifflin-St Jeor equation")
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText.opacity(0.6))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Reusable Components

    /// Section header with a glass gem icon — gold for 60-30-10 secondary tone.
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

    private func profileField(_ label: String, binding: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.subtleText)
            Spacer()
            TextField(label, text: binding)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func profileStepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppColors.subtleText)
            Spacer()
            Text("\(value.wrappedValue)")
                .font(.body.bold().monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
            Stepper("", value: value, in: range)
                .labelsHidden()
                .frame(width: 100)
        }
    }
}
