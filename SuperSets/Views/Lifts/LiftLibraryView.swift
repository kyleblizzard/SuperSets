// LiftLibraryView.swift
// Super Sets — The Workout Tracker
//
// Single-screen exercise picker with:
//   1. Search bar at top (glass slab capsule)
//   2. Recent lifts (horizontal scroll capsules)
//   3. Grouped muscle grid (4-column, organized by section)
//   4. Tap a group → exercise list with circular icons
//
// v3.0 — Merged Quick Pick into Add Lift. Search + recents + grouped grid.

import SwiftUI
import SwiftData

// MARK: - LiftLibraryView

struct LiftLibraryView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: State

    @State private var selectedGroup: MuscleGroup?
    @State private var searchText = ""
    @State private var showingCustomLift = false
    @State private var customLiftName = ""

    // MARK: Queries

    @Query(sort: \LiftDefinition.name) private var allLifts: [LiftDefinition]

    // MARK: Body

    var body: some View {
        NavigationStack {
            Group {
                if let group = selectedGroup {
                    liftList(for: group)
                } else {
                    mainPickerView
                }
            }
            .appBackground()
            .navigationTitle(selectedGroup?.displayName ?? "Add Lift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedGroup != nil {
                        Button {
                            AppAnimation.perform(AppAnimation.spring) {
                                selectedGroup = nil
                                searchText = ""
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.caption.bold())
                                Text("Back")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(AppColors.accent)
                        }
                    } else {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .alert("Create Custom Lift", isPresented: $showingCustomLift) {
            TextField("Exercise name", text: $customLiftName)
            Button("Create") { createCustomLift() }
            Button("Cancel", role: .cancel) { customLiftName = "" }
        } message: {
            if let group = selectedGroup {
                Text("New \(group.displayName) exercise")
            }
        }
    }

    // MARK: - Main Picker View (Search + Recents + Grouped Grid)

    private var mainPickerView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search bar — glass slab capsule
                searchBar

                if !searchText.isEmpty {
                    // Search results
                    searchResultsList
                } else {
                    // Recent lifts (when not searching, when recents exist)
                    if !workoutManager.recentLifts.isEmpty {
                        recentLiftsRow
                    }

                    // Grouped muscle grid
                    groupedMuscleGrid
                }

                Spacer().frame(height: 20)
            }
            .padding(.top, 4)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.subtleText)

            TextField("Search all exercises...", text: $searchText)
                .font(.subheadline)
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
        .padding(12)
        .glassSlab(.capsule)
        .padding(.horizontal, 16)
    }

    // MARK: - Recent Lifts

    private var recentLiftsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.caption.bold())
                .foregroundStyle(AppColors.subtleText)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(workoutManager.recentLifts, id: \.name) { lift in
                        Button {
                            workoutManager.selectLift(lift)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: lift.muscleGroup.iconName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.gold)

                                Text(lift.name)
                                    .font(.caption.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .deepGlass(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        let matches = mergedLifts().filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }

        return VStack(spacing: 6) {
            if matches.isEmpty {
                Text("No exercises match \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.vertical, 12)
            } else {
                GlassEffectContainer(spacing: 12.0) {
                    ForEach(matches.prefix(15), id: \.name) { lift in
                        exerciseGlassButton(lift: lift)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Grouped Muscle Grid

    private var groupedMuscleGrid: some View {
        VStack(spacing: 20) {
            ForEach(MuscleGroup.groupedSections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.subtleText)
                        .padding(.horizontal, 16)

                    GlassEffectContainer(spacing: 12.0) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ],
                            spacing: 12
                        ) {
                            ForEach(section.groups) { group in
                                muscleGroupCell(for: group)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    /// 60×60 muscle group circle with icon, name, and exercise count.
    private func muscleGroupCell(for group: MuscleGroup) -> some View {
        let catalogCount = PreloadedLifts.catalog[group]?.count ?? 0
        let customCount = allLifts.filter { $0.muscleGroup == group && $0.isCustom }.count
        let totalCount = catalogCount + customCount

        return Button {
            AppAnimation.perform(AppAnimation.spring) {
                selectedGroup = group
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: group.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 60, height: 60)
                    .deepGlass(.circle)

                Text(group.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                Text("\(totalCount)")
                    .font(.system(size: 8, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppColors.subtleText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lift List (Step 2)

    private func liftList(for group: MuscleGroup) -> some View {
        let groupLifts = mergedLifts(for: group).filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }

        return ScrollView {
            VStack(spacing: 10) {
                // Context orb — glass gem
                Image(systemName: group.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 64, height: 64)
                    .glassGem(.circle)
                    .padding(.top, 4)

                Text("\(groupLifts.count) exercises")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.bottom, 4)

                // Search — glass slab capsule
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.subtleText)

                    TextField("Search \(group.displayName) exercises", text: $searchText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(12)
                .glassSlab(.capsule)
                .padding(.horizontal, 16)

                // Create Custom — deep glass capsule with accent icon
                Button {
                    customLiftName = ""
                    showingCustomLift = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.accent)

                        Text("Create Custom Exercise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primaryText)

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .deepGlass(.capsule)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)

                // Exercise buttons
                GlassEffectContainer(spacing: 10.0) {
                    ForEach(groupLifts, id: \.name) { lift in
                        exerciseGlassButton(lift: lift)
                    }
                }
                .padding(.horizontal, 16)

                if groupLifts.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(AppColors.subtleText.opacity(0.5))
                        Text("No exercises match \"\(searchText)\"")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                    }
                    .padding(.vertical, 30)
                }

                Spacer().frame(height: 20)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// Exercise row — deep glass capsule with glass gem icon.
    private func exerciseGlassButton(lift: LiftDefinition) -> some View {
        Button {
            workoutManager.selectLift(lift)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                // Glass gem icon
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 24, height: 24)
                    .glassGem(.circle)

                Text(lift.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.primaryText)

                if lift.isCustom {
                    Text("Custom")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .glassGem(.capsule)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .deepGlass(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Merged Data Source

    private func mergedLifts(for group: MuscleGroup? = nil) -> [LiftDefinition] {
        var result: [LiftDefinition] = []
        var seenNames = Set<String>()

        for lift in allLifts {
            if let group = group, lift.muscleGroup != group { continue }
            if !seenNames.contains(lift.name) {
                seenNames.insert(lift.name)
                result.append(lift)
            }
        }

        let groups: [MuscleGroup] = group.map { [$0] } ?? MuscleGroup.allCases.map { $0 }
        for g in groups {
            for name in (PreloadedLifts.catalog[g] ?? []) {
                if !seenNames.contains(name) {
                    seenNames.insert(name)
                    let lift = LiftDefinition(name: name, muscleGroup: g, isCustom: false)
                    result.append(lift)
                }
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Custom Lift Creation

    private func createCustomLift() {
        guard let group = selectedGroup,
              !customLiftName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        let newLift = LiftDefinition(
            name: customLiftName.trimmingCharacters(in: .whitespaces),
            muscleGroup: group,
            isCustom: true
        )

        modelContext.insert(newLift)
        try? modelContext.save()

        workoutManager.selectLift(newLift)
        customLiftName = ""
        dismiss()
    }
}
