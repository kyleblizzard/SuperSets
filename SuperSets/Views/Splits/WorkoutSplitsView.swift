// WorkoutSplitsView.swift
// Super Sets — The Workout Tracker
//
// Displays all workout split templates. Users can load a split to
// populate the ring, create new splits, or delete existing ones.
// Presented as a sheet from the Workout tab.

import SwiftUI
import SwiftData

// MARK: - WorkoutSplitsView

struct WorkoutSplitsView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: State

    @Query(sort: \WorkoutSplit.name) private var splits: [WorkoutSplit]
    @State private var showingEditor = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if splits.isEmpty {
                        emptyState
                    } else {
                        // Preset splits
                        let presets = splits.filter { $0.isPreset }
                        if !presets.isEmpty {
                            sectionLabel("Templates")
                            ForEach(presets) { split in
                                splitCard(split)
                            }
                        }

                        // Custom splits
                        let custom = splits.filter { !$0.isPreset }
                        if !custom.isEmpty {
                            sectionLabel("My Splits")
                            ForEach(custom) { split in
                                splitCard(split)
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Workout Splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                SplitEditorView(workoutManager: workoutManager)
            }
        }
    }

    // MARK: - Components

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.subtleText)

            Text("No splits yet")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            Text("Create a split template to quickly\nload your favorite exercises")
                .font(.caption)
                .foregroundStyle(AppColors.subtleText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppColors.subtleText)
            Spacer()
        }
        .padding(.top, 8)
    }

    private func splitCard(_ split: WorkoutSplit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(split.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text("\(split.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                }

                Spacer()

                // Load button
                Button {
                    workoutManager.loadSplit(split)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                } label: {
                    Text("Load")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .deepGlass(.capsule)
                }
                .buttonStyle(.plain)

                // Delete button (only for custom splits)
                if !split.isPreset {
                    Button {
                        AppAnimation.perform(AppAnimation.quick) {
                            modelContext.delete(split)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.danger)
                            .frame(width: 32, height: 32)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Exercise list preview
            Text(split.liftNames.joined(separator: " \u{2022} "))
                .font(.caption2)
                .foregroundStyle(AppColors.subtleText)
                .lineLimit(2)
        }
        .padding(14)
        .glassCard()
    }
}
