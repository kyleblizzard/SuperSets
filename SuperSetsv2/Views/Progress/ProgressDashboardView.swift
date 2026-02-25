// ProgressDashboardView.swift
// Super Sets — The Workout Tracker
//
// The Progress tab — a comprehensive dashboard for tracking fitness gains.
// This is where the "progressive" in "progressive overload" becomes visible.
//
// NAMING NOTE:
// We call this "ProgressDashboardView" instead of "ProgressView" because
// SwiftUI already has a built-in ProgressView (the spinning loading indicator).
// Naming our view the same would shadow the system type and cause confusing
// compiler errors any time we tried to use a loading spinner.
//
// Sections (top to bottom):
//   1. Workout Stats Summary — total workouts, weekly count, avg duration, total sets
//   2. Body Weight Tracking — current weight, 30-day chart, log button
//   3. Personal Records (PRs) — searchable list of all-time bests per lift
//   4. Lift Progression Charts — line graph of max weight over time per lift
//   5. Volume Trends — bar chart of total weekly volume for last 8 weeks
//   6. Calorie Estimates — TDEE, per-workout, and weekly workout calories
//
// LEARNING NOTE:
// This view uses Swift Charts (import Charts), Apple's framework for creating
// data visualizations. Charts was introduced in iOS 16 and uses a declarative
// syntax that feels natural in SwiftUI: Chart { ForEach(data) { LineMark(...) } }
//
// DESIGN RULES:
// - Glass cards (.glassCard()) wrap stat sections and charts — these are control surfaces
// - Content rows (PR list items) sit plain on the background — no glass
// - Use AppColors for all text/surface colors — never hardcode .white
// - Muscle group accent colors for lift-specific charts, AppColors.accent for general

import SwiftUI
import Charts
import SwiftData

// MARK: - ProgressDashboardView

struct ProgressDashboardView: View {
    
    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager

    // MARK: Queries

    // LEARNING NOTE:
    // We observe ALL workouts (no filter predicate) so that when a workout's
    // isActive flag changes from true → false, this view re-renders and
    // refreshData() is triggered via .onChange below. A predicate-filtered
    // @Query may not react to property changes on existing objects.
    @Query(sort: \Workout.date, order: .reverse)
    private var allWorkouts: [Workout]

    // MARK: State
    
    /// Search text for filtering PRs by lift name.
    @State private var searchText = ""
    
    /// The currently selected lift for the progression chart detail.
    @State private var selectedPRLift: PersonalRecord?
    
    /// Controls the body weight input sheet.
    @State private var showingWeightInput = false
    
    /// Text field value for logging body weight.
    @State private var weightInputText = ""
    
    /// How many days of weight data to show (30 default, expandable).
    @State private var weightChartDays = 30
    
    /// Cached PRs — recalculated when the view appears.
    ///
    /// LEARNING NOTE:
    /// We cache this in @State so we don't recalculate on every scroll.
    /// It updates on .onAppear and when returning from a workout.
    @State private var personalRecords: [PersonalRecord] = []
    
    /// Cached weekly volume data for the bar chart.
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
        .onAppear {
            refreshData()
        }
        .onChange(of: allWorkouts) { _, _ in
            // LEARNING NOTE:
            // .onChange fires whenever allWorkouts changes — including when a
            // workout's isActive flips to false after "End Workout." This keeps
            // personalRecords, weeklyVolumes, and all stat tiles in sync even
            // if the user is already on this tab when the workout ends.
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
    
    /// Recalculate all progress data. Called on appear and when workout data changes.
    private func refreshData() {
        personalRecords = workoutManager.calculateAllPRs()
        weeklyVolumes = workoutManager.weeklyVolumeTrends()
    }
    
    // MARK: - Section 1: Workout Stats Summary
    
    /// A compact card showing high-level workout stats.
    ///
    /// LEARNING NOTE:
    /// LazyVGrid with two columns creates an even 2×2 grid layout.
    /// .flexible() means each column takes equal available width.
    /// This is more maintainable than nested HStacks because adding
    /// a 5th stat automatically wraps to a new row.
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
    
    /// A single stat tile in a tinted glass rounded rect — big number + small label.
    ///
    /// LEARNING NOTE:
    /// Each stat is its own glass element rather than just a VStack inside the
    /// parent glass card. This creates "glass on glass" — the outer card is one
    /// layer, and each stat tile is a nested glass layer. The system renders these
    /// with proper depth compositing so inner elements appear to float slightly
    /// above the outer card surface.
    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(AppColors.accent)
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
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
    
    // MARK: - Section 2: Body Weight Tracking
    
    /// Current weight display, trend chart, and log button.
    private var bodyWeightSection: some View {
        VStack(spacing: 12) {
            HStack {
                sectionHeader("Body Weight", icon: "scalemass.fill")
                Spacer()
                
                // Log Weight button — glossy glass capsule
                Button {
                    // Pre-fill with the user's profile weight if no entries exist
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(
                        .regular.interactive(),
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Current weight display
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
            
            // Weight chart
            let entries = workoutManager.weightEntries(days: weightChartDays)
            if entries.count >= 2 {
                bodyWeightChart(entries: entries)
                
                // Expand/collapse button
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
    
    /// Line chart of body weight over time.
    ///
    /// LEARNING NOTE:
    /// Swift Charts uses a declarative builder syntax similar to SwiftUI views.
    /// LineMark creates a line connecting data points, AreaMark fills below it.
    /// .interpolationMethod(.catmullRom) makes the line smooth (curved) instead
    /// of jagged straight lines between points — much more visually appealing.
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
    
    /// Sheet for logging a new body weight entry.
    private var weightInputSheet: some View {
        VStack(spacing: 20) {
            Text("Log Weight")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
            
            let unit = workoutManager.userProfile?.preferredUnit ?? .lbs
            
            HStack {
                TextField("0.0", text: $weightInputText)
                    .keyboardType(.decimalPad)
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
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
        .appBackground()
    }
    
    // MARK: - Section 3: Personal Records
    
    /// Searchable list of PRs grouped by muscle group.
    /// Tap a lift to see its detail card with all four PR values.
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Personal Records", icon: "trophy.fill")
            
            // Search bar — glass capsule (consistent with LiftLibraryView)
            //
            // LEARNING NOTE:
            // We use a glass capsule instead of a plain inputFill background.
            // This keeps the search bar visually consistent with the glass
            // capsule search bars in LiftLibraryView and CalendarView.
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                
                TextField("Search lifts...", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(10)
            .glassEffect(.regular, in: .capsule)
            
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
                
                // LEARNING NOTE:
                // MuscleGroup.allCases gives us a consistent ordering (the order
                // they're declared in the enum). We filter to only show groups
                // that have matching PRs, then iterate in that fixed order.
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
    
    /// Filtered PRs based on search text.
    private var filteredRecords: [PersonalRecord] {
        if searchText.isEmpty {
            return personalRecords
        }
        return personalRecords.filter {
            $0.liftName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// A section for one muscle group showing its lifts.
    private func muscleGroupPRSection(group: MuscleGroup, records: [PersonalRecord]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Muscle group header
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 8, height: 8)
                Text(group.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.top, 4)
            
            // Individual lift rows — plain on background, no glass
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
    
    /// A single PR row showing lift name and headline stats.
    ///
    /// DESIGN RULE:
    /// Content rows sit plain on the background — no glass.
    /// Only control/navigation surfaces get glass treatment.
    private func prRow(_ pr: PersonalRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.liftName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                
                // Show the two most useful stats inline
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
        .padding(.horizontal, 4)
    }
    
    // MARK: - Section 4: Lift Progression Chart (in Detail Sheet)
    
    /// Sheet showing all four PR values and a line chart for a specific lift.
    private func liftDetailSheet(_ pr: PersonalRecord) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppColors.accent)
                        .frame(width: 10, height: 10)
                    Text(pr.liftName)
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(.top, 8)
                
                // Four PR tiles in a 2×2 grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    prTile("Heaviest Set", value: formatWeight(pr.heaviestWeight), date: pr.heaviestWeightDate, color: AppColors.accent)
                    prTile("Best Volume", value: formatWeight(pr.bestVolume), date: pr.bestVolumeDate, color: AppColors.positive)
                    prTile("Most Reps", value: "\(pr.mostReps)", date: pr.mostRepsDate, color: AppColors.accentSecondary)
                    prTile("Est. 1RM", value: formatWeight(pr.estimated1RM), date: pr.estimated1RMDate, color: AppColors.accent)
                }
                
                // Progression chart
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
    
    /// A single PR value tile with label, value, and date.
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
        .glassCard()
    }
    
    /// Swift Charts line graph for a lift's max weight progression.
    ///
    /// LEARNING NOTE:
    /// PointMark adds dots at each data point on top of the LineMark line.
    /// Without PointMark, you'd see a line but wouldn't know exactly where
    /// the data points are — especially important when sessions are weeks apart.
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
    
    /// Bar chart showing total weekly volume for the last 8 weeks.
    ///
    /// LEARNING NOTE:
    /// BarMark creates vertical bars. The x-axis is categorical (week labels)
    /// and the y-axis is quantitative (volume). This "macro" view helps users
    /// see if their overall training load is increasing, decreasing, or stable.
    private var volumeTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Volume Trends", icon: "chart.bar.fill")
            
            Text("Total weight × reps per week")
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
    
    /// TDEE, per-workout calories, and weekly workout calories.
    private var calorieEstimatesSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Calorie Estimates", icon: "flame.fill")
            
            if let profile = workoutManager.userProfile {
                // TDEE display in a tinted glass orb
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
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                
                Divider().background(AppColors.divider)
                
                // Activity level picker
                //
                // LEARNING NOTE:
                // Picker with .segmented style works well for 2-3 options, but
                // with 5 options it gets cramped. .menu style shows a dropdown
                // that reveals all options on tap — better for longer lists.
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
                
                // Weekly workout calories
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout Cal This Week")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                        
                        Text("MET 5.5 × body weight × duration")
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
    
    /// Section header with icon in a glass circle and title (matches ProfileView style).
    ///
    /// LEARNING NOTE:
    /// By wrapping the icon in its own glass circle, every section header
    /// has a small "gem" of color that gives it visual weight and depth.
    /// This pattern is consistent across all tabs: Profile, Progress, Calendar.
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.accent)
                .frame(width: 26, height: 26)
                .glassEffect(.regular, in: .circle)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
        }
    }
    
    // MARK: - Helpers
    
    /// Format a weight value: show decimal only if needed.
    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    /// Short date format: "Jan 15"
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
