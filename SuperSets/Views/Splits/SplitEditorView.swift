// SplitEditorView.swift
// Super Sets — The Workout Tracker
//
// Create or edit a workout split template.
// Users name the split and pick exercises from a searchable list.

import SwiftUI
import SwiftData

// MARK: - SplitEditorView

struct SplitEditorView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: State

    @State private var splitName = ""
    @State private var selectedLifts: [String] = []
    @State private var searchText = ""
    @Query(sort: \LiftDefinition.name) private var allLifts: [LiftDefinition]

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Split name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Split Name")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.subtleText)

                        TextField("e.g., Push Day", text: $splitName)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .glassField(cornerRadius: 10)
                    }
                    .padding(16)
                    .glassCard()

                    // Selected exercises
                    if !selectedLifts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selected (\(selectedLifts.count))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.subtleText)
                                Spacer()
                            }

                            ForEach(selectedLifts, id: \.self) { name in
                                HStack {
                                    Text(name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)

                                    Spacer()

                                    Button {
                                        AppAnimation.perform(AppAnimation.quick) {
                                            selectedLifts.removeAll { $0 == name }
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppColors.danger)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .glassRow(cornerRadius: 10)
                            }
                        }
                        .padding(16)
                        .glassCard()
                    }

                    // Add exercises
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Exercises")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.subtleText)

                        // Search bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.subtleText)

                            TextField("Search...", text: $searchText)
                                .font(.body)
                                .foregroundStyle(AppColors.primaryText)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassField(cornerRadius: 10)

                        // Available lifts
                        let available = availableLifts
                        ForEach(available.prefix(20), id: \.name) { lift in
                            Button {
                                AppAnimation.perform(AppAnimation.quick) {
                                    selectedLifts.append(lift.name)
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack {
                                    Image(systemName: lift.muscleGroup.iconName)
                                        .font(.system(size: 11))
                                        .foregroundStyle(lift.muscleGroup.accentColor)
                                        .frame(width: 24, height: 24)
                                        .glassGem(.circle)

                                    Text(lift.name)
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.primaryText)

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppColors.positive)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .glassRow(cornerRadius: 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .glassCard()

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSplit()
                    }
                    .disabled(splitName.trimmingCharacters(in: .whitespaces).isEmpty || selectedLifts.isEmpty)
                }
            }
        }
    }

    // MARK: - Computed

    /// All lifts not yet selected, filtered by search text.
    private var availableLifts: [LiftDefinition] {
        let merged = mergedLifts()
        let available = merged.filter { !selectedLifts.contains($0.name) }

        if searchText.isEmpty {
            return available
        }
        return available.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Merges custom lifts from database with the preloaded catalog.
    private func mergedLifts() -> [LiftDefinition] {
        var result: [LiftDefinition] = []
        var seenNames = Set<String>()

        for lift in allLifts {
            if !seenNames.contains(lift.name) {
                seenNames.insert(lift.name)
                result.append(lift)
            }
        }

        for group in MuscleGroup.allCases {
            for name in (PreloadedLifts.catalog[group] ?? []) {
                if !seenNames.contains(name) {
                    seenNames.insert(name)
                    let lift = LiftDefinition(name: name, muscleGroup: group, isCustom: false)
                    result.append(lift)
                }
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Actions

    private func saveSplit() {
        let name = splitName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !selectedLifts.isEmpty else { return }

        let split = WorkoutSplit(name: name, liftNames: selectedLifts)
        modelContext.insert(split)
        try? modelContext.save()
        dismiss()
    }
}
