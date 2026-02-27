// WorkoutSummaryView.swift
// Super Sets — The Workout Tracker
//
// Post-workout celebration screen.
//
// v2.0 — 10x LIQUID GLASS: Glass gem trophy with warm glow, deep glass stat tiles,
// glass gem icons, glass rows for exercise sets. All .glassCard() auto-upgraded.

import SwiftUI

// MARK: - WorkoutSummaryView

struct WorkoutSummaryView: View {

    let workout: Workout
    let workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveAsSplit = false
    @State private var splitName = ""

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
                    HStack(spacing: 12) {
                        Button {
                            showingSaveAsSplit = true
                        } label: {
                            Image(systemName: "rectangle.stack.badge.plus")
                        }

                        ShareLink(
                            item: workoutManager.generateSummaryText(for: workout)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .alert("Save as Split", isPresented: $showingSaveAsSplit) {
                TextField("Split name", text: $splitName)
                Button("Save") {
                    let name = splitName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        workoutManager.saveSplitFromWorkout(workout, name: name)
                        splitName = ""
                    }
                }
                Button("Cancel", role: .cancel) { splitName = "" }
            } message: {
                Text("Save this workout's exercises as a reusable split template.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Trophy in glass gem with warm yellow glow
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)
                .frame(width: 80, height: 80)
                .glassGem(.circle)
                .shadow(color: .yellow.opacity(0.3), radius: 12, y: 0)
                .shadow(color: .yellow.opacity(0.15), radius: 20, y: 0)

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

    /// Stat tile — deep glass for glass-on-glass.
    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.gold)

            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(AppColors.primaryText)

            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .deepGlass(.rect(cornerRadius: 14))
    }

    // MARK: - Duration

    private var durationSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.gold)
                .frame(width: 32, height: 32)
                .glassGem(.circle)

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
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 28, height: 28)
                    .glassGem(.circle)

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
                // Exercise icon — glass gem
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 32, height: 32)
                    .glassGem(.circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lift.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(lift.muscleGroup.displayName)
                        .font(.caption)
                        .foregroundStyle(AppColors.gold)
                }

                Spacer()

                Text("\(sets.count) sets")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
            }

            // Set rows — glass rows for depth-upon-depth
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
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .glassRow(cornerRadius: 10)
            }
        }
        .padding(16)
        .glassCard()
    }
}
