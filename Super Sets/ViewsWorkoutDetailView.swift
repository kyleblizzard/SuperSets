//
//  WorkoutDetailView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Shows the complete details of a past workout including all exercises,
//  sets, notes, and statistics. Accessed from the calendar view.

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    var workout: Workout
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats overview
                        statsSection
                        
                        // Exercise breakdown
                        exercisesSection
                        
                        // Notes
                        if let notes = workout.notes {
                            notesSection(notes)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Workout Details")
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
                        subject: Text("Workout Details"),
                        message: Text("Check out this workout!")
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text(workout.date, style: .date)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(workout.date, style: .time)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            
            Divider()
                .background(.white.opacity(0.3))
            
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
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .foregroundStyle(.white)
            
            let groupedSets = workout.setsGroupedByLift()
            
            ForEach(Array(groupedSets.keys.sorted()), id: \.self) { liftName in
                if let sets = groupedSets[liftName], let firstSet = sets.first {
                    exerciseCard(liftName: liftName, sets: sets, lift: firstSet.liftDefinition)
                }
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private func exerciseCard(liftName: String, sets: [WorkoutSet], lift: LiftDefinition?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header
            HStack {
                if let muscleGroup = lift?.muscleGroup {
                    Image(systemName: muscleGroup.iconName)
                        .foregroundStyle(muscleGroup.accentColor)
                    
                    Text(liftName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(muscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(muscleGroup.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(muscleGroup.accentColor.opacity(0.2))
                        }
                } else {
                    Text(liftName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            
            // Sets
            VStack(alignment: .leading, spacing: 6) {
                ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack {
                        Text("Set \(set.setNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(set.formattedSet)
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }
            }
            
            // Total volume
            let totalVolume = sets.reduce(0.0) { $0 + $1.volume }
            
            Divider()
                .background(.white.opacity(0.2))
            
            HStack {
                Text("Total Volume")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Text(String(format: "%.1f", totalVolume))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
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
    
    // MARK: - Share Text
    
    private func generateShareText() -> String {
        var text = "💪 Workout Details\n\n"
        text += "Date: \(workout.date.formatted(date: .long, time: .shortened))\n"
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
                
                let totalVolume = sets.reduce(0.0) { $0 + $1.volume }
                text += "  Total Volume: \(String(format: "%.1f", totalVolume))\n\n"
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
    workout.notes = "Great workout today!"
    
    return WorkoutDetailView(workout: workout)
        .modelContainer(container)
}
