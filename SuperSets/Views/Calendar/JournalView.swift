// JournalView.swift
// Super Sets — The Workout Tracker
//
// The Journal tab — replaces Calendar with a richer workout journal.
// Shows a monthly calendar with workout-day highlights, streak counter,
// muscle group heatmap, and full workout history.

import SwiftUI
import SwiftData

// MARK: - JournalView

struct JournalView: View {

    // MARK: Dependencies

    var workoutManager: WorkoutManager

    // MARK: State

    @State private var displayedMonth = Date()
    @State private var selectedWorkout: Workout?

    // MARK: Queries

    @Query(sort: \Workout.date, order: .reverse)
    private var allWorkouts: [Workout]

    private var completedWorkouts: [Workout] {
        allWorkouts.filter { !$0.isActive }
    }

    // MARK: Private

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
    private let daySymbols = Calendar.current.veryShortWeekdaySymbols

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                streakCard
                monthHeader
                calendarGrid
                muscleHeatmapCard
                workoutHistoryList
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .id(completedWorkouts.count)
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.gold)
                Text("Day Streak")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .deepGlass(.rect(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("\(workoutsThisMonth)")
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.accent)
                Text("This Month")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .deepGlass(.rect(cornerRadius: 16))

            VStack(spacing: 4) {
                Text("\(completedWorkouts.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                Text("Total")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .deepGlass(.rect(cornerRadius: 16))
        }
        .padding(12)
        .glassCard()
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                AppAnimation.perform(AppAnimation.spring) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 44, height: 44)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthYearString)
                .font(.title3.bold())
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .glassSlab(.capsule)

            Spacer()

            Button {
                AppAnimation.perform(AppAnimation.spring) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 44, height: 44)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 5) {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(daySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.bold())
                        .foregroundStyle(AppColors.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .glassGem(.rect(cornerRadius: 6))
                }
            }

            GlassEffectContainer(spacing: 8.0) {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    private func dayCell(for date: Date) -> some View {
        let foundWorkout = workout(for: date)
        let hasWorkout = foundWorkout != nil
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)
        let splitDay = workoutManager.activeSplitSchedule()?.splitDay(for: date)

        return Button {
            if let w = foundWorkout {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedWorkout = w
            }
        } label: {
            dayCellContent(day: day, isToday: isToday, hasWorkout: hasWorkout, splitDay: splitDay)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayCellContent(day: Int, isToday: Bool, hasWorkout: Bool, splitDay: SplitDay? = nil) -> some View {
        let content = VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 16, weight: isToday || hasWorkout ? .bold : .regular).monospacedDigit())
                .foregroundStyle(hasWorkout || isToday ? AppColors.accent : AppColors.primaryText)

            if hasWorkout {
                Circle()
                    .fill(AppColors.gold)
                    .frame(width: 5, height: 5)
            } else if let split = splitDay, split != .rest {
                Text(String(split.rawValue.prefix(1)))
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(width: 52, height: 52)

        if hasWorkout {
            content.deepGlass(.circle)
        } else {
            content.glassGem(.circle)
        }
    }

    // MARK: - Muscle Heatmap

    private var muscleHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 26, height: 26)
                    .glassGem(.circle)

                Text("Muscle Groups This Month")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }

            let heatmap = muscleGroupHeatmap
            if heatmap.isEmpty {
                Text("Train this month to see your heatmap")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                let maxCount = heatmap.values.max() ?? 1
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(heatmap.sorted(by: { $0.value > $1.value }), id: \.key) { group, count in
                        VStack(spacing: 4) {
                            Text(group.displayName)
                                .font(.caption2.bold())
                                .foregroundStyle(AppColors.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("\(count)")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(AppColors.accent)
                            Text("sets")
                                .font(.system(size: 8))
                                .foregroundStyle(AppColors.subtleText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .opacity(0.4 + 0.6 * Double(count) / Double(maxCount))
                        .deepGlass(.rect(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Workout History List

    private var workoutHistoryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 26, height: 26)
                    .glassGem(.circle)

                Text("Workout History")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.horizontal, 4)

            if completedWorkouts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .foregroundStyle(AppColors.subtleText.opacity(0.4))
                    Text("No completed workouts yet")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.subtleText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .glassCard()
            } else {
                GlassEffectContainer(spacing: 10.0) {
                    ForEach(completedWorkouts.prefix(20), id: \.date) { workout in
                        workoutHistoryRow(workout)
                    }
                }
            }
        }
    }

    private func workoutHistoryRow(_ workout: Workout) -> some View {
        Button {
            selectedWorkout = workout
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.formattedDate)
                        .font(.body.bold())
                        .foregroundStyle(AppColors.primaryText)

                    let muscleNames = workout.uniqueLifts.map(\.muscleGroup.displayName)
                    let uniqueMuscles = Array(Set(muscleNames)).prefix(3).joined(separator: ", ")
                    Text("\(workout.totalExercises) exercises · \(workout.totalSets) sets · \(workout.formattedDuration)")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)

                    if !uniqueMuscles.isEmpty {
                        Text(uniqueMuscles)
                            .font(.caption2)
                            .foregroundStyle(AppColors.accent)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .deepGlass(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var monthYearString: String {
        Formatters.monthYear.string(from: displayedMonth)
    }

    private var daysInMonth: [Date?] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let emptyDays = firstWeekday - calendar.firstWeekday
        let paddedEmptyDays = (emptyDays + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: paddedEmptyDays)

        for day in range {
            var dayComponents = components
            dayComponents.day = day
            days.append(calendar.date(from: dayComponents))
        }

        return days
    }

    private func workout(for date: Date) -> Workout? {
        allWorkouts.first { w in
            calendar.isDate(w.date, inSameDayAs: date)
        }
    }

    /// Consecutive workout days ending today (or yesterday).
    private var currentStreak: Int {
        var streak = 0
        var checkDate = Date()

        // If no workout today, start from yesterday
        if !completedWorkouts.contains(where: { calendar.isDateInToday($0.date) }) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while true {
            let hasWorkout = completedWorkouts.contains { w in
                calendar.isDate(w.date, inSameDayAs: checkDate)
            }
            if hasWorkout {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    /// Workouts completed in the displayed month.
    private var workoutsThisMonth: Int {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return completedWorkouts.filter { w in
            let wComponents = calendar.dateComponents([.year, .month], from: w.date)
            return wComponents.year == components.year && wComponents.month == components.month
        }.count
    }

    /// Muscle group → set count for the displayed month.
    private var muscleGroupHeatmap: [MuscleGroup: Int] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let monthWorkouts = completedWorkouts.filter { w in
            let wComponents = calendar.dateComponents([.year, .month], from: w.date)
            return wComponents.year == components.year && wComponents.month == components.month
        }

        var counts: [MuscleGroup: Int] = [:]
        for workout in monthWorkouts {
            for set in workout.sets {
                if let group = set.liftDefinition?.muscleGroup {
                    counts[group, default: 0] += 1
                }
            }
        }
        return counts
    }
}
