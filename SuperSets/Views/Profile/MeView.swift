// MeView.swift
// Super Sets — The Workout Tracker
//
// Personal profile: photo, name, age, sex, measurements, RMR/TDEE.
// Navigates to PreferencesView via gear button.
//
// Liquid Glass: Deep glass photo frame, deep glass RMR orb,
// glass gem section header icons, glass slab cards.

import SwiftUI
import PhotosUI

// MARK: - MeView

struct MeView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: State

    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    personalInfoSection
                    measurementsSection
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        PreferencesView(workoutManager: workoutManager)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.subtleText)
                    }
                }
            }
        }
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Age", selection: Binding(
                        get: { profile.age },
                        set: { profile.age = $0 }
                    )) {
                        ForEach(13...100, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .glassField(cornerRadius: 12)
                }

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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    RulerSlider(
                        value: Binding(
                            get: { profile.heightInches },
                            set: { profile.heightInches = $0 }
                        ),
                        range: 48...96,
                        step: 1,
                        unit: "",
                        formatValue: { val in
                            let feet = Int(val) / 12
                            let inches = Int(val) % 12
                            return "\(feet)'\(inches)\""
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    RulerSlider(
                        value: Binding(
                            get: { profile.bodyWeight },
                            set: { profile.bodyWeight = $0 }
                        ),
                        range: profile.preferredUnit == .kg ? 25...250 : 50...500,
                        step: 1,
                        unit: profile.preferredUnit.rawValue
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Waist")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                    RulerSlider(
                        value: Binding(
                            get: { profile.waistInches },
                            set: { profile.waistInches = $0 }
                        ),
                        range: 20...60,
                        step: 0.5,
                        unit: "\""
                    )
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

}
