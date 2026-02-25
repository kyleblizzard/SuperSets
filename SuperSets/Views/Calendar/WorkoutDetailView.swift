// WorkoutDetailView.swift
// Super Sets — The Workout Tracker
//
// Full details of a past completed workout. Clear glass cards,
// clear glass stat tiles, clear glass section icons.
//
// v0.003 GLASS FIX: All glass is CLEAR (no .tint()). Color comes from
// text and icons, not the glass material.

import SwiftUI

// MARK: - WorkoutDetailView

struct WorkoutDetailView: View {
    
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        notesCard(notes)
                    }
                    
                    ForEach(workout.setsGroupedByLift, id: \.lift.name) { group in
                        exerciseCard(lift: group.lift, sets: group.sets)
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .appBackground()
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerCard: some View {
        VStack(spacing: 14) {
            Text(workout.fullFormattedDate)
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
            
            GlassEffectContainer(spacing: 12.0) {
                HStack(spacing: 12) {
                    statTile(value: workout.formattedDuration, label: "Duration", icon: "clock.fill")
                    statTile(value: "\(workout.totalExercises)", label: "Exercises", icon: "figure.strengthtraining.traditional")
                    statTile(value: "\(workout.totalSets)", label: "Sets", icon: "number")
                }
            }
        }
        .padding(16)
        .glassCard()
    }
    
    /// Stat tile — clear glass rounded rect with colored text inside.
    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.accent)
            
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
    
    // MARK: - Notes
    
    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 28, height: 28)
                    .glassEffect(.regular, in: .circle)
                
                Text("Notes")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            
            Text(notes)
                .font(.body)
                .foregroundStyle(AppColors.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
    
    // MARK: - Exercise Card
    
    private func exerciseCard(lift: LiftDefinition, sets: [WorkoutSet]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                // Clear glass circle with accent icon
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular, in: .circle)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(lift.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Text("\(sets.count) sets · \(lift.muscleGroup.displayName)")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                }
                
                Spacer()
            }
            
            ForEach(sets, id: \.timestamp) { set in
                HStack {
                    Text("Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                        .frame(width: 50, alignment: .leading)
                    
                    Text(set.formattedDisplay)
                        .font(.body.monospacedDigit().bold())
                        .foregroundStyle(AppColors.primaryText)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .glassCard()
    }
}
