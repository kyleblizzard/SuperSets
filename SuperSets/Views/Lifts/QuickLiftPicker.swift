// QuickLiftPicker.swift
// Super Sets — The Workout Tracker
//
// A fast, searchable half-sheet lift picker. Shows recent lifts first,
// then all exercises in a flat alphabetical list. Simpler and quicker
// than the two-step muscle group flow in LiftLibraryView.

import SwiftUI
import SwiftData

// MARK: - QuickLiftPicker

struct QuickLiftPicker: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: State

    @State private var searchText = ""
    @Query(sort: \LiftDefinition.name) private var allLifts: [LiftDefinition]

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.subtleText)

                TextField("Search lifts...", text: $searchText)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText)
                    .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.subtleText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassField(cornerRadius: 12)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    // Recent lifts section (only when not searching)
                    if searchText.isEmpty && !workoutManager.recentLifts.isEmpty {
                        sectionLabel("Recent")

                        ForEach(workoutManager.recentLifts, id: \.name) { lift in
                            liftRow(lift, isRecent: true)
                        }
                    }

                    // All lifts section
                    let filtered = filteredLifts
                    if !filtered.isEmpty {
                        if searchText.isEmpty {
                            sectionLabel("All Exercises")
                        }

                        ForEach(filtered, id: \.name) { lift in
                            liftRow(lift, isRecent: false)
                        }
                    } else if !searchText.isEmpty {
                        Text("No exercises match \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Filtered Lifts

    /// All lifts merged from database + catalog, filtered by search text.
    private var filteredLifts: [LiftDefinition] {
        let merged = mergedLifts()

        if searchText.isEmpty {
            return merged
        }

        return merged.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Merges custom (SwiftData) lifts with the preloaded catalog.
    private func mergedLifts() -> [LiftDefinition] {
        var result: [LiftDefinition] = []
        var seenNames = Set<String>()

        // Custom lifts first (from database)
        for lift in allLifts {
            if !seenNames.contains(lift.name) {
                seenNames.insert(lift.name)
                result.append(lift)
            }
        }

        // Catalog lifts (skip duplicates)
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

    // MARK: - Components

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(AppColors.subtleText)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func liftRow(_ lift: LiftDefinition, isRecent: Bool) -> some View {
        Button {
            workoutManager.selectLift(lift)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(lift.muscleGroup.accentColor)
                    .frame(width: 28, height: 28)
                    .glassGem(.circle)

                Text(lift.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                Spacer()

                Text(lift.muscleGroup.displayName)
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText)

                if isRecent {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.subtleText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassRow(cornerRadius: 10)
        }
        .buttonStyle(.plain)
    }
}
