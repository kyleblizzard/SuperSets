// LiftLibraryView.swift
// Super Sets — The Workout Tracker
//
// Two-step exercise picker:
//   Step 1: ALL 13 muscle groups as frosted glass orbs with visible icons
//   Step 2: Tap an orb → exercises appear as glass capsule buttons
//
// v0.003 GLASS FIX: Removed all .tint() from glass effects.
// The previous version used .tint(AppColors.accent) which made every
// glass element opaque blue — hiding icons and killing the frosted look.
//
// THE RULE: Glass is always CLEAR frosted. Color comes from CONTENT
// (icons, text) sitting on/inside the glass, never from tinting the
// glass material itself. This gives proper depth, refraction, and
// the translucent "liquid glass" feel.
//
// EXERCISE DATA: The drill-in list uses PreloadedLifts.catalog directly
// (merged with any custom lifts from @Query) so the list is NEVER empty
// on first launch. SwiftData's @Query can lag behind on first open.

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
    
    /// Custom lifts only — we merge these with the static catalog.
    @Query(sort: \LiftDefinition.name) private var allLifts: [LiftDefinition]
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            Group {
                if let group = selectedGroup {
                    liftList(for: group)
                } else {
                    muscleGroupOrbs
                }
            }
            .appBackground()
            .navigationTitle(selectedGroup?.displayName ?? "Add Lift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedGroup != nil {
                        Button {
                            withAnimation(AppAnimation.spring) {
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
    
    // MARK: - Step 1: Muscle Group Orbs
    
    /// All 13 muscle groups as CLEAR frosted glass circles.
    /// Icons show through the glass. Color comes from the icon, not the glass.
    private var muscleGroupOrbs: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tap a muscle group")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.top, 4)
                
                GlassEffectContainer(spacing: 16.0) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 14
                    ) {
                        ForEach(MuscleGroup.allCases) { group in
                            muscleOrb(for: group)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Global search
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.subtleText)
                        
                        TextField("Search all exercises...", text: $searchText)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primaryText)
                    }
                    .padding(12)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.horizontal, 16)
                    
                    if !searchText.isEmpty {
                        globalSearchResults
                    }
                }
                .padding(.top, 4)
                
                Spacer().frame(height: 20)
            }
        }
    }
    
    /// A single muscle group orb — CLEAR glass circle with icon visible inside.
    ///
    /// LEARNING NOTE:
    /// .glassEffect(.regular.interactive(), in: .circle) creates CLEAR frosted
    /// glass. The .interactive() adds press-down scaling and shimmer on tap.
    /// The icon's .foregroundStyle(AppColors.accent) provides the blue color —
    /// the glass itself has NO tint, so it stays translucent and refractive.
    private func muscleOrb(for group: MuscleGroup) -> some View {
        let catalogCount = PreloadedLifts.catalog[group]?.count ?? 0
        let customCount = allLifts.filter { $0.muscleGroup == group && $0.isCustom }.count
        let totalCount = catalogCount + customCount
        
        return Button {
            withAnimation(AppAnimation.spring) {
                selectedGroup = group
            }
        } label: {
            VStack(spacing: 6) {
                // Clear glass orb — icon shows through
                Image(systemName: group.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 72, height: 72)
                    .glassEffect(.regular.interactive(), in: .circle)
                
                Text(group.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(totalCount)")
                    .font(.system(size: 9, weight: .bold).monospacedDigit())
                    .foregroundStyle(AppColors.subtleText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
    
    /// Global search across ALL exercises (catalog + custom).
    private var globalSearchResults: some View {
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
    
    // MARK: - Step 2: Lift List
    
    /// Exercise list for a muscle group. Uses catalog as the guaranteed data
    /// source, merged with any custom lifts from @Query.
    ///
    /// LEARNING NOTE:
    /// On first launch, SwiftData seeds exercises in setup() but @Query
    /// might not have refreshed by the time this sheet opens. By reading
    /// directly from PreloadedLifts.catalog (a static [MuscleGroup: [String]]
    /// dictionary), we always have data immediately. Custom lifts from @Query
    /// are merged in so user-created exercises also appear.
    private func liftList(for group: MuscleGroup) -> some View {
        let groupLifts = mergedLifts(for: group).filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return ScrollView {
            VStack(spacing: 10) {
                // Context orb — clear glass
                Image(systemName: group.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 64, height: 64)
                    .glassEffect(.regular, in: .circle)
                    .padding(.top, 4)
                
                Text("\(groupLifts.count) exercises")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.bottom, 4)
                
                // Search — glass capsule
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.subtleText)
                    
                    TextField("Search \(group.displayName) exercises", text: $searchText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(12)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 16)
                
                // Create Custom — glass capsule with accent icon
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
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                
                // Exercise buttons — clear glass capsules
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
    }
    
    /// A single exercise row — clear glass capsule. Accent icon + readable text.
    private func exerciseGlassButton(lift: LiftDefinition) -> some View {
        Button {
            workoutManager.selectLift(lift)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 24, height: 24)
                
                Text(lift.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.primaryText)
                
                if lift.isCustom {
                    Text("Custom")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule().fill(AppColors.accent.opacity(0.15))
                        }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Merged Data Source
    
    /// Merges the static catalog with any custom lifts from @Query.
    /// This guarantees exercises are always available, even if @Query
    /// hasn't caught up with SwiftData's seeding on first launch.
    ///
    /// LEARNING NOTE:
    /// We create lightweight LiftDefinition objects from the catalog strings.
    /// These are NOT inserted into SwiftData — they're ephemeral view-layer
    /// objects used only for display. The actual SwiftData objects exist in
    /// the database; we just can't always rely on @Query timing.
    private func mergedLifts(for group: MuscleGroup? = nil) -> [LiftDefinition] {
        var result: [LiftDefinition] = []
        var seenNames = Set<String>()
        
        // First: add all lifts from @Query (these are the real SwiftData objects)
        for lift in allLifts {
            if let group = group, lift.muscleGroup != group { continue }
            if !seenNames.contains(lift.name) {
                seenNames.insert(lift.name)
                result.append(lift)
            }
        }
        
        // Second: fill in from catalog if @Query missed any
        let groups: [MuscleGroup] = group.map { [$0] } ?? MuscleGroup.allCases.map { $0 }
        for g in groups {
            for name in (PreloadedLifts.catalog[g] ?? []) {
                if !seenNames.contains(name) {
                    seenNames.insert(name)
                    // Create ephemeral LiftDefinition for display
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
