// CalendarView.swift
// Super Sets — The Workout Tracker
//
// A monthly calendar built from glass gems and deep glass circles.
// Every day is a polished glass gem. Workout days get full deep glass treatment.
//
// v2.0 — 10x LIQUID GLASS: 52pt cells, glass gems on all days, deep glass
// workout days, slab month label, gem day-of-week headers, gem recent header icon.

import SwiftUI
import SwiftData

// MARK: - CalendarView

struct CalendarView: View {

    // MARK: Dependencies

    var workoutManager: WorkoutManager

    // MARK: State

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingDetail = false

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
                monthHeader
                calendarGrid
                recentWorkoutsList
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .id(completedWorkouts.count)
        .onChange(of: allWorkouts.count) { _, _ in
            displayedMonth = displayedMonth
        }
        .sheet(isPresented: $showingDetail) {
            if let date = selectedDate, let workout = workout(for: date) {
                WorkoutDetailView(workout: workout)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        GlassEffectContainer(spacing: 16.0) {
            HStack {
                Button {
                    withAnimation(AppAnimation.spring) {
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

                // Month label in a glass slab capsule
                Text(monthYearString)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .glassSlab(.capsule)

                Spacer()

                Button {
                    withAnimation(AppAnimation.spring) {
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
    }

    // MARK: - Calendar Grid

    /// 52pt day cells, glass gem day-of-week headers, glass gem non-workout days,
    /// deep glass workout days.
    private var calendarGrid: some View {
        VStack(spacing: 5) {
            // Day-of-week headers — glass gems
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

            // Date cells — 52pt
            GlassEffectContainer(spacing: 8.0) {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            Color.clear
                                .frame(height: 52)
                        }
                    }
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    /// A single day — 52pt. Workout days = deep glass, non-workout = glass gem.
    private func dayCell(for date: Date) -> some View {
        let hasWorkout = workout(for: date) != nil
        let isToday = calendar.isDateInToday(date)
        let day = calendar.component(.day, from: date)

        return Button {
            if hasWorkout {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedDate = date
                showingDetail = true
            }
        } label: {
            dayCellContent(day: day, isToday: isToday, hasWorkout: hasWorkout)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayCellContent(day: Int, isToday: Bool, hasWorkout: Bool) -> some View {
        let content = VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 16, weight: isToday || hasWorkout ? .bold : .regular).monospacedDigit())
                .foregroundStyle(
                    hasWorkout || isToday ? AppColors.accent : AppColors.primaryText
                )

            // Workout indicator dot — 5pt
            Circle()
                .fill(hasWorkout ? AppColors.gold : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 52, height: 52)

        if hasWorkout {
            content.deepGlass(.circle)
        } else {
            content.glassGem(.circle)
        }
    }

    // MARK: - Recent Workouts List

    private var recentWorkoutsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.gold)
                    .frame(width: 26, height: 26)
                    .glassGem(.circle)

                Text("Recent Workouts")
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
                    ForEach(completedWorkouts.prefix(10), id: \.date) { workout in
                        recentWorkoutRow(workout)
                    }
                }
            }
        }
    }

    private func recentWorkoutRow(_ workout: Workout) -> some View {
        Button {
            selectedDate = workout.date
            showingDetail = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.formattedDate)
                        .font(.body.bold())
                        .foregroundStyle(AppColors.primaryText)

                    Text("\(workout.totalExercises) exercises · \(workout.totalSets) sets · \(workout.formattedDuration)")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
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
        completedWorkouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
}
