// WorkoutSummaryView.swift
// Super Sets — The Workout Tracker
//
// Post-workout celebration. Trophy in clear glass orb, stats in clear
// glass tiles, exercises with clear glass section icons.
//
// v0.003 GLASS FIX: No .tint() anywhere. Glass is clear/frosted.
// The trophy's yellow and stat icons' blue show through the glass.

import SwiftUI

// MARK: - WorkoutSummaryView

struct WorkoutSummaryView: View {
    
    let workout: Workout
    let workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    ForEach(workout.setsGroupedByLift, id: \.lift.name) { group in
                        exerciseSection(lift: group.lift, sets: group.sets)
                    }
                    
                    // Duration at the bottom
                    durationSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .appBackground()
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: workoutManager.generateSummaryText(for: workout)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Trophy in clear glass circle — yellow shows through
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)
                .frame(width: 80, height: 80)
                .glassEffect(.regular, in: .circle)
            
            Text(workout.fullFormattedDate)
                .font(.subheadline)
                .foregroundStyle(AppColors.subtleText)
            
            GlassEffectContainer(spacing: 12.0) {
                HStack(spacing: 12) {
                    statTile(value: "\(workout.totalExercises)", label: "Exercises", icon: "figure.strengthtraining.traditional")
                    statTile(value: "\(workout.totalSets)", label: "Sets", icon: "number")
                }
            }
        }
        .padding(20)
        .glassCard()
    }
    
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
    
    // MARK: - Duration

    private var durationSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.accent)
                .frame(width: 32, height: 32)
                .glassEffect(.regular, in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text("Workout Duration")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                Text(workout.formattedDuration)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(AppColors.accent)
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Notes
    
    private func notesSection(_ notes: String) -> some View {
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
    
    // MARK: - Exercise Section
    
    private func exerciseSection(lift: LiftDefinition, sets: [WorkoutSet]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular, in: .circle)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(lift.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    
                    Text(lift.muscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(AppColors.accent)
                }
                
                Spacer()
                
                Text("\(sets.count) sets")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
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
            }
        }
        .padding(16)
        .glassCard()
    }
}
