//
//  AllLiftsView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Searchable catalog view showing all lifts organized by muscle group.
//  Users can search and select any lift from the complete catalog.

import SwiftUI
import SwiftData

struct AllLiftsView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    var workoutManager: WorkoutManager?
    
    // MARK: - State
    
    @State private var searchText = ""
    
    // MARK: - Queries
    
    // LEARNING NOTE: @Query automatically fetches data from SwiftData
    @Query(sort: \LiftDefinition.name) private var allLifts: [LiftDefinition]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
                            muscleGroupSection(for: muscleGroup)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("All Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search lifts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Muscle Group Section
    
    @ViewBuilder
    private func muscleGroupSection(for muscleGroup: MuscleGroup) -> some View {
        let liftsForGroup = filteredLifts(for: muscleGroup)
        
        if !liftsForGroup.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack {
                    Image(systemName: muscleGroup.iconName)
                        .foregroundStyle(muscleGroup.accentColor)
                    
                    Text(muscleGroup.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
                
                // Lifts
                VStack(spacing: 8) {
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
            }
        }
    }
    
    // MARK: - Filtered Lifts
    
    private func filteredLifts(for muscleGroup: MuscleGroup) -> [LiftDefinition] {
        let liftsForGroup = allLifts.filter { $0.muscleGroup == muscleGroup }
        
        if searchText.isEmpty {
            return liftsForGroup
        } else {
            // LEARNING NOTE: localizedCaseInsensitiveContains ignores case when searching
            return liftsForGroup.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectLift(_ lift: LiftDefinition) {
        workoutManager?.selectLift(lift)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AllLiftsView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
