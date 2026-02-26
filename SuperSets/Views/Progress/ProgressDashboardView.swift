// ProgressDashboardView.swift
// Super Sets — The Workout Tracker
//
// The Progress tab — a comprehensive dashboard for tracking fitness gains.
//
// v2.0 — 10x LIQUID GLASS: Deep glass stat tiles, glass rows for PRs,
// glass gem section headers, glass slab search, deep glass TDEE box.

import SwiftUI
import Charts
import SwiftData

// MARK: - ProgressDashboardView

struct ProgressDashboardView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: Queries

    @Query(sort: \Workout.date, order: .reverse)
    private var allWorkouts: [Workout]

    private var completedCount: Int {
        allWorkouts.filter { !$0.isActive }.count
    }

    // MARK: State

    @FocusState private var isInputFocused: Bool
    @State private var searchText = ""
    @State private var selectedPRLift: PersonalRecord?
    @State private var showingWeightInput = false
    @State private var weightInputText = ""
    @State private var weightChartDays = 30
    @State private var personalRecords: [PersonalRecord] = []
    @State private var weeklyVolumes: [WeeklyVolume] = []

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsCard
                bodyWeightSection
                personalRecordsSection
                volumeTrendsSection
                calorieEstimatesSection

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
        .onAppear {
            refreshData()
        }
        .onChange(of: allWorkouts) { _, _ in
            refreshData()
        }
        .onChange(of: completedCount) { _, _ in
            refreshData()
        }
        .sheet(isPresented: $showingWeightInput) {
            weightInputSheet
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedPRLift) { pr in
            liftDetailSheet(pr)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Refresh Data

    private func refreshData() {
        personalRecords = workoutManager.calculateAllPRs()
        weeklyVolumes = workoutManager.weeklyVolumeTrends()
    }

    // MARK: - Section 1: Workout Stats Summary

    private var statsCard: some View {
        VStack(spacing: 12) {
            sectionHeader("Workout Stats", icon: "flame.fill")

            GlassEffectContainer(spacing: 10.0) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    statTile(
                        value: "\(workoutManager.totalCompletedWorkouts())",
                        label: "Total Workouts",
                        icon: "figure.strengthtraining.traditional"
                    )
                    statTile(
                        value: "\(workoutManager.workoutsThisWeek())",
                        label: "This Week",
                        icon: "calendar.badge.clock"
                    )
                    statTile(
                        value: "\(workoutManager.averageWorkoutDuration())m",
                        label: "Avg Duration",
                        icon: "timer"
                    )
                    statTile(
                        value: "\(workoutManager.totalSetsAllTime())",
                        label: "Total Sets",
                        icon: "number"
                    )
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    /// Stat tile — deep glass for glass-on-glass effect inside the slab card.
    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(AppColors.gold)
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .deepGlass(.rect(cornerRadius: 12))
    }

    // MARK: - Section 2: Body Weight Tracking

    private var bodyWeightSection: some View {
        VStack(spacing: 12) {
            HStack {
                sectionHeader("Body Weight", icon: "scalemass.fill")
                Spacer()

                Button {
                    if let latest = workoutManager.latestWeight() {
                        weightInputText = String(format: "%.1f", latest.weight)
                    } else if let profileWeight = workoutManager.userProfile?.bodyWeight {
                        weightInputText = String(format: "%.0f", profileWeight)
                    }
                    showingWeightInput = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption2.bold())
                        Text("Log")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .deepGlass(.capsule)
                }
                .buttonStyle(.plain)
            }

            if let latest = workoutManager.latestWeight() {
                let unit = workoutManager.userProfile?.preferredUnit ?? .lbs
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", latest.weight))
                        .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                    Text(unit.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
            }

            let entries = workoutManager.weightEntries(days: weightChartDays)
            if entries.count >= 2 {
                bodyWeightChart(entries: entries)

                HStack {
                    Spacer()
                    Button {
                        withAnimation(AppAnimation.quick) {
                            weightChartDays = weightChartDays == 30 ? 90 : 30
                        }
                    } label: {
                        Text(weightChartDays == 30 ? "Show 90 Days" : "Show 30 Days")
                            .font(.caption2)
                            .foregroundStyle(AppColors.accent)
                    }
                }
            } else if entries.isEmpty {
                Text("Log your weight to see trends")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.vertical, 8)
            } else {
                Text("Need 2+ entries for chart")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func bodyWeightChart(entries: [WeightEntry]) -> some View {
        Chart(entries, id: \.date) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("Weight", entry.weight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(AppColors.accent)

            AreaMark(
                x: .value("Date", entry.date),
                y: .value("Weight", entry.weight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.accent.opacity(0.3), AppColors.accent.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: weightChartDays <= 30 ? 7 : 14)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(AppColors.subtleText)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider)
            }
        }
        .chartYAxis {
            AxisMarks { mark in
                AxisValueLabel()
                    .foregroundStyle(AppColors.subtleText)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider)
            }
        }
        .frame(height: 160)
    }

    private var weightInputSheet: some View {
        VStack(spacing: 20) {
            Text("Log Weight")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            let unit = workoutManager.userProfile?.preferredUnit ?? .lbs

            HStack {
                TextField("0.0", text: $weightInputText)
                    .keyboardType(.decimalPad)
                    .focused($isInputFocused)
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text(unit.rawValue)
                    .font(.title3)
                    .foregroundStyle(AppColors.subtleText)
            }
            .padding(.horizontal, 32)

            Button {
                if let value = Double(weightInputText), value > 0 {
                    workoutManager.logWeight(value)
                    showingWeightInput = false
                    weightInputText = ""
                }
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .deepGlass(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
        .appBackground()
    }

    // MARK: - Section 3: Personal Records

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Personal Records", icon: "trophy.fill")

            // Search bar — glass slab capsule
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)

                TextField("Search lifts...", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(10)
            .glassSlab(.capsule)

            if personalRecords.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundStyle(AppColors.subtleText.opacity(0.5))
                    Text("Complete a workout to see your PRs")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                let filtered = filteredRecords
                let grouped = Dictionary(grouping: filtered) { $0.muscleGroup }

                ForEach(MuscleGroup.allCases.filter { grouped[$0] != nil }, id: \.self) { group in
                    if let records = grouped[group] {
                        muscleGroupPRSection(group: group, records: records)
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private var filteredRecords: [PersonalRecord] {
        if searchText.isEmpty {
            return personalRecords
        }
        return personalRecords.filter {
            $0.liftName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func muscleGroupPRSection(group: MuscleGroup, records: [PersonalRecord]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Muscle group header with glass gem dot
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.gold)
                    .frame(width: 8, height: 8)
                    .glassGem(.circle)
                Text(group.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.top, 4)

            // PR rows — glass rows for depth-upon-depth
            ForEach(records) { pr in
                Button {
                    selectedPRLift = pr
                } label: {
                    prRow(pr)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// PR row floating inside the slab card via glass row.
    private func prRow(_ pr: PersonalRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.liftName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)

                let weightStr = formatWeight(pr.heaviestWeight)
                let e1rm = formatWeight(pr.estimated1RM)
                Text("Best: \(weightStr)  ·  Est 1RM: \(e1rm)")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColors.subtleText.opacity(0.5))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .glassRow(cornerRadius: 12)
    }

    // MARK: - Section 4: Lift Progression Chart (in Detail Sheet)

    private func liftDetailSheet(_ pr: PersonalRecord) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.gold)
                        .frame(width: 10, height: 10)
                    Text(pr.liftName)
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(.top, 8)

                // Four PR tiles — deep glass for glass-on-glass
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    prTile("Heaviest Set", value: formatWeight(pr.heaviestWeight), date: pr.heaviestWeightDate, color: AppColors.accent)
                    prTile("Best Volume", value: formatWeight(pr.bestVolume), date: pr.bestVolumeDate, color: AppColors.positive)
                    prTile("Most Reps", value: "\(pr.mostReps)", date: pr.mostRepsDate, color: AppColors.accentSecondary)
                    prTile("Est. 1RM", value: formatWeight(pr.estimated1RM), date: pr.estimated1RMDate, color: AppColors.accent)
                }

                let progression = workoutManager.liftProgression(for: pr.liftName)
                if progression.count >= 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight Over Time")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)

                        liftProgressionChart(data: progression, color: AppColors.accent)
                    }
                    .padding(16)
                    .glassCard()
                } else if progression.count == 1 {
                    Text("Need 2+ sessions for chart")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                        .padding(.vertical, 8)
                } else {
                    Text("No completed sessions yet")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                        .padding(.vertical, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .appBackground()
    }

    /// PR tile — deep glass for glass-on-glass effect.
    private func prTile(_ label: String, value: String, date: Date?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(AppColors.subtleText)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            if let date = date {
                Text(shortDate(date))
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .deepGlass(.rect(cornerRadius: 14))
    }

    private func liftProgressionChart(data: [LiftProgressionPoint], color: Color) -> some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(color)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.maxWeight)
            )
            .foregroundStyle(color)
            .symbolSize(30)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(AppColors.subtleText)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider)
            }
        }
        .chartYAxis {
            AxisMarks { mark in
                AxisValueLabel()
                    .foregroundStyle(AppColors.subtleText)
                AxisGridLine()
                    .foregroundStyle(AppColors.divider)
            }
        }
        .frame(height: 180)
    }

    // MARK: - Section 5: Volume Trends

    private var volumeTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Volume Trends", icon: "chart.bar.fill")

            Text("Total weight x reps per week")
                .font(.caption)
                .foregroundStyle(AppColors.subtleText)

            if weeklyVolumes.isEmpty || weeklyVolumes.allSatisfy({ $0.totalVolume == 0 }) {
                Text("Complete workouts to see trends")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Chart(weeklyVolumes) { week in
                    BarMark(
                        x: .value("Week", week.label),
                        y: .value("Volume", week.totalVolume)
                    )
                    .foregroundStyle(AppColors.accent.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { mark in
                        AxisValueLabel()
                            .foregroundStyle(AppColors.subtleText)
                    }
                }
                .chartYAxis {
                    AxisMarks { mark in
                        AxisValueLabel()
                            .foregroundStyle(AppColors.subtleText)
                        AxisGridLine()
                            .foregroundStyle(AppColors.divider)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Section 6: Calorie Estimates

    private var calorieEstimatesSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Calorie Estimates", icon: "flame.fill")

            if let profile = workoutManager.userProfile {
                // TDEE display — deep glass
                VStack(spacing: 4) {
                    Text("\(profile.totalDailyEnergyExpenditure)")
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.accent)

                    Text("TDEE (cal/day)")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)

                    Text("RMR \(profile.restingMetabolicRate) × \(profile.activityLevel.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(AppColors.subtleText.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .deepGlass(.rect(cornerRadius: 16))

                Divider().background(AppColors.divider)

                HStack {
                    Text("Activity Level")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)

                    Spacer()

                    Picker("", selection: Binding(
                        get: { profile.activityLevel },
                        set: { profile.activityLevel = $0 }
                    )) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text("\(level.rawValue) (\(level.description))")
                                .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.accent)
                }

                Divider().background(AppColors.divider)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Cal This Week")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)

                        Text("MET 5.5 x body weight x duration")
                            .font(.caption2)
                            .foregroundStyle(AppColors.subtleText.opacity(0.6))
                    }

                    Spacer()

                    Text("\(workoutManager.weeklyWorkoutCalories())")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)

                    Text("cal")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Reusable Components

    /// Section header with glass gem icon — gold for 60-30-10 secondary tone.
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.gold)
                .frame(width: 26, height: 26)
                .glassGem(.circle)

            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
        }
    }

    // MARK: - Helpers

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
