//
//  EndWorkoutView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Sheet that appears when ending a workout. Allows adding notes and shows
//  a complete summary with share functionality.

import SwiftUI
import SwiftData

struct EndWorkoutView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    var workout: Workout
    var workoutManager: WorkoutManager?
    
    // MARK: - State
    
    @State private var notes = ""
    @State private var showingSummary = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Confirmation message
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.green)
                            
                            Text("End Workout?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("Add optional notes below")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding()
                        
                        // Notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (Optional)")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                }
                        }
                        .padding()
                        .liquidGlassPanel()
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                endWorkout()
                            } label: {
                                Text("Finish Workout")
                            }
                            .buttonStyle(PrimaryActionButtonStyle(color: .green))
                            
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationTitle("End Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingSummary) {
            WorkoutSummaryView(workout: workout)
        }
    }
    
    // MARK: - Actions
    
    private func endWorkout() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        workoutManager?.endWorkout(
            for: workout,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        
        dismiss()
        
        // Show summary after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingSummary = true
        }
    }
}

// MARK: - Workout Summary View

struct WorkoutSummaryView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    var workout: Workout
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header stats
                        statsSection
                        
                        // Lifts breakdown
                        liftsBreakdownSection
                        
                        // Notes
                        if let notes = workout.notes {
                            notesSection(notes)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: generateShareText(),
                        subject: Text("Workout Summary"),
                        message: Text("Check out my workout!")
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text(workout.date, style: .date)
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 32) {
                statItem(
                    value: workout.durationFormatted,
                    label: "Duration",
                    icon: "clock.fill"
                )
                
                statItem(
                    value: "\(workout.sets.count)",
                    label: "Total Sets",
                    icon: "list.number"
                )
                
                statItem(
                    value: "\(workout.uniqueLifts)",
                    label: "Exercises",
                    icon: "dumbbell.fill"
                )
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    // MARK: - Lifts Breakdown
    
    private var liftsBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .foregroundStyle(.white)
            
            let groupedSets = workout.setsGroupedByLift()
            
            ForEach(Array(groupedSets.keys.sorted()), id: \.self) { liftName in
                if let sets = groupedSets[liftName], let firstSet = sets.first {
                    liftDetailRow(liftName: liftName, sets: sets, lift: firstSet.liftDefinition)
                }
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private func liftDetailRow(liftName: String, sets: [WorkoutSet], lift: LiftDefinition?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let muscleGroup = lift?.muscleGroup {
                    Circle()
                        .fill(muscleGroup.accentColor)
                        .frame(width: 12, height: 12)
                }
                
                Text(liftName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            
            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                Text("\(set.setNumber). \(set.formattedSet)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Share Text Generation
    
    private func generateShareText() -> String {
        var text = "💪 Workout Summary\n\n"
        text += "Date: \(workout.date.formatted(date: .long, time: .omitted))\n"
        text += "Duration: \(workout.durationFormatted)\n"
        text += "Total Sets: \(workout.sets.count)\n"
        text += "Exercises: \(workout.uniqueLifts)\n\n"
        
        let groupedSets = workout.setsGroupedByLift()
        
        for liftName in groupedSets.keys.sorted() {
            if let sets = groupedSets[liftName] {
                text += "\(liftName):\n"
                for set in sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    text += "  \(set.setNumber). \(set.formattedSet)\n"
                }
                text += "\n"
            }
        }
        
        if let notes = workout.notes {
            text += "Notes: \(notes)\n"
        }
        
        return text
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Workout.self, WorkoutSet.self, LiftDefinition.self,
        configurations: config
    )
    
    let workout = Workout(date: Date(), isActive: false)
    workout.endDate = Date().addingTimeInterval(3600)
    
    return EndWorkoutView(workout: workout)
        .modelContainer(container)
}
