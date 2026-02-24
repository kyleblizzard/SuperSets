//
//  AddLiftView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Sheet view for adding a new lift. Shows muscle group grid, then lifts for
//  that muscle group, plus option to create a custom lift.

import SwiftUI
import SwiftData

struct AddLiftView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    var workoutManager: WorkoutManager?
    
    // MARK: - State
    
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var showingCustomLift = false
    @State private var customLiftName = ""
    
    // MARK: - Queries
    
    @Query private var allLifts: [LiftDefinition]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                ScrollView {
                    if selectedMuscleGroup == nil {
                        muscleGroupGrid
                    } else {
                        liftsForSelectedMuscleGroup
                    }
                }
            }
            .navigationTitle(selectedMuscleGroup?.displayName ?? "Select Muscle Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedMuscleGroup != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Back") {
                            selectedMuscleGroup = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Muscle Group Grid
    
    private var muscleGroupGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                Button {
                    withAnimation(.liquidGlass) {
                        selectedMuscleGroup = muscleGroup
                    }
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: muscleGroup.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(muscleGroup.accentColor)
                        
                        Text(muscleGroup.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                }
                .liquidGlassPanel(accentColor: muscleGroup.accentColor)
            }
        }
        .padding()
    }
    
    // MARK: - Lifts for Selected Muscle Group
    
    @ViewBuilder
    private var liftsForSelectedMuscleGroup: some View {
        if let muscleGroup = selectedMuscleGroup {
            let liftsForGroup = allLifts.filter { $0.muscleGroup == muscleGroup }
            
            VStack(spacing: 16) {
                // Create Custom button
                Button {
                    showingCustomLift = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Custom Lift")
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                .liquidGlassPanel(accentColor: muscleGroup.accentColor)
                
                // List of lifts
                ForEach(liftsForGroup) { lift in
                    Button {
                        selectLift(lift)
                    } label: {
                        HStack {
                            Text(lift.name)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            if lift.isCustom {
                                Text("Custom")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        .padding()
                    }
                    .liquidGlassPanel()
                }
            }
            .padding()
            .alert("Create Custom Lift", isPresented: $showingCustomLift) {
                TextField("Lift Name", text: $customLiftName)
                
                Button("Cancel", role: .cancel) {
                    customLiftName = ""
                }
                
                Button("Create") {
                    createCustomLift()
                }
            } message: {
                Text("Enter a name for your custom lift")
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectLift(_ lift: LiftDefinition) {
        workoutManager?.selectLift(lift)
        dismiss()
    }
    
    private func createCustomLift() {
        guard let muscleGroup = selectedMuscleGroup,
              !customLiftName.isEmpty else {
            return
        }
        
        let newLift = LiftDefinition(
            name: customLiftName,
            muscleGroup: muscleGroup,
            isCustom: true
        )
        
        modelContext.insert(newLift)
        try? modelContext.save()
        
        workoutManager?.selectLift(newLift)
        
        customLiftName = ""
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddLiftView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
