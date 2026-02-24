//
//  ProfileView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  User profile view displaying personal info, measurements, and RMR calculation.
//  Users can edit their profile, change weight unit preference, and add a photo.

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    // LEARNING NOTE: @Query fetches the user profile from SwiftData
    @Query private var profiles: [UserProfile]
    
    // MARK: - State
    
    @State private var isEditing = false
    @State private var editedProfile: UserProfile?
    @State private var photoItem: PhotosPickerItem?
    
    // MARK: - Computed Profile
    
    // Get or create the user profile (should only be one)
    private var userProfile: UserProfile {
        if let existing = profiles.first {
            return existing
        } else {
            // Create default profile
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            try? modelContext.save()
            return newProfile
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header with photo
                profileHeader
                
                // Personal info section
                personalInfoSection
                
                // Measurements section
                measurementsSection
                
                // Preferences section
                preferencesSection
                
                // RMR section
                rmrSection
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(LiquidGlassBackground())
        .sheet(isPresented: $isEditing) {
            ProfileEditView(profile: userProfile)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile photo
            if let photoData = userProfile.profilePhotoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    }
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.6))
                    }
            }
            
            // Name
            Text(userProfile.name.isEmpty ? "Your Name" : userProfile.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            // Edit button
            Button {
                isEditing = true
            } label: {
                Label("Edit Profile", systemImage: "pencil")
            }
            .buttonStyle(PrimaryActionButtonStyle(color: .blue))
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Personal Info Section
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Personal Info")
            
            infoRow(label: "Age", value: "\(userProfile.age) years")
            infoRow(label: "Sex", value: userProfile.biologicalSex.displayName)
            
            if let startDate = userProfile.startDate {
                infoRow(
                    label: "Tracking Since",
                    value: startDate.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Measurements Section
    
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Measurements")
            
            infoRow(label: "Height", value: userProfile.heightFormatted)
            
            infoRow(
                label: "Weight",
                value: String(format: "%.1f %@",
                            userProfile.bodyWeightInPreferredUnit,
                            userProfile.preferredUnit.displayName)
            )
            
            infoRow(label: "Waist", value: String(format: "%.1f in", userProfile.waistInches))
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Preferences")
            
            infoRow(label: "Weight Unit", value: userProfile.preferredUnit.displayName)
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - RMR Section
    
    private var rmrSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            Text("\(userProfile.restingMetabolicRate)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Resting Metabolic Rate")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Calories burned per day at rest")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            
            // RMR explanation
            Text("Based on the Mifflin-St Jeor equation using your age, sex, height, and weight")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .liquidGlassPanel(accentColor: .orange)
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    var profile: UserProfile
    
    // MARK: - State
    
    @State private var name: String
    @State private var age: Int
    @State private var biologicalSex: BiologicalSex
    @State private var heightFeet: Int
    @State private var heightInches: Int
    @State private var bodyWeight: Double
    @State private var waistInches: Double
    @State private var preferredUnit: WeightUnit
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    
    // MARK: - Initialization
    
    init(profile: UserProfile) {
        self.profile = profile
        
        // Initialize state from profile
        _name = State(initialValue: profile.name)
        _age = State(initialValue: profile.age)
        _biologicalSex = State(initialValue: profile.biologicalSex)
        
        let feet = profile.heightInches / 12
        let inches = profile.heightInches % 12
        _heightFeet = State(initialValue: feet)
        _heightInches = State(initialValue: inches)
        
        _bodyWeight = State(initialValue: profile.bodyWeightInPreferredUnit)
        _waistInches = State(initialValue: profile.waistInches)
        _preferredUnit = State(initialValue: profile.preferredUnit)
        _hasStartDate = State(initialValue: profile.startDate != nil)
        _startDate = State(initialValue: profile.startDate ?? Date())
        _photoData = State(initialValue: profile.profilePhotoData)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                Form {
                    // Photo section
                    Section {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack {
                                if let data = photoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(.gray.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "camera")
                                                .foregroundStyle(.white)
                                        }
                                }
                                
                                Text("Change Photo")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .onChange(of: photoItem) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    photoData = data
                                }
                            }
                        }
                    }
                    
                    // Personal info
                    Section("Personal Information") {
                        TextField("Name", text: $name)
                        
                        Picker("Age", selection: $age) {
                            ForEach(13...100, id: \.self) { age in
                                Text("\(age)").tag(age)
                            }
                        }
                        
                        Picker("Biological Sex", selection: $biologicalSex) {
                            ForEach(BiologicalSex.allCases, id: \.self) { sex in
                                Text(sex.displayName).tag(sex)
                            }
                        }
                    }
                    
                    // Measurements
                    Section("Measurements") {
                        HStack {
                            Text("Height")
                            Spacer()
                            
                            Picker("Feet", selection: $heightFeet) {
                                ForEach(4...7, id: \.self) { feet in
                                    Text("\(feet)'").tag(feet)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Inches", selection: $heightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches)\"").tag(inches)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("Weight", value: $bodyWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(preferredUnit.displayName)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Waist")
                            Spacer()
                            TextField("Waist", value: $waistInches, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("in")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Preferences
                    Section("Preferences") {
                        Picker("Weight Unit", selection: $preferredUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        
                        Toggle("Set Start Date", isOn: $hasStartDate)
                        
                        if hasStartDate {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        profile.name = name
        profile.age = age
        profile.biologicalSex = biologicalSex
        profile.heightInches = (heightFeet * 12) + heightInches
        profile.waistInches = waistInches
        
        // Convert weight back to lbs if needed
        if preferredUnit == .kg {
            profile.bodyWeightLbs = bodyWeight / 0.453592
        } else {
            profile.bodyWeightLbs = bodyWeight
        }
        
        profile.preferredUnit = preferredUnit
        profile.startDate = hasStartDate ? startDate : nil
        profile.profilePhotoData = photoData
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
