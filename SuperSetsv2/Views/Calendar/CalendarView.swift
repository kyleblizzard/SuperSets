// CalendarView.swift
// Super Sets — The Workout Tracker
//
// A monthly calendar built from frosted glass circles.
// Every surface is CLEAR glass — no tinting. Color comes from text/icons.
//
// v0.003 GLASS FIX: Removed all .tint() from glass effects.
// Glass is always clear/frosted. Blue chevron icons show through.
// Day cells are subtle glass circles — workout days get a small
// accent dot below the number. Today is bold blue text.
//
// LEARNING NOTE:
// .glassEffect(.regular, in: .circle) = clear frosted glass circle
// .glassEffect(.regular.interactive(), in: .circle) = same + tap feedback
// These create the translucent, refractive "liquid glass" look.
// Adding .tint() makes glass opaque — the opposite of what we want.

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

    // LEARNING NOTE:
    // We fetch ALL workouts (no filter predicate) and filter in Swift below.
    // This is because @Query with a predicate filter on an existing object's
    // property (isActive: true → false) may not always trigger a reactive
    // update. Fetching everything ensures any workout change — including
    // ending an active workout — immediately refreshes the calendar.
    @Query(sort: \Workout.date, order: .reverse)
    private var allWorkouts: [Workout]

    private var completedWorkouts: [Workout] {
        allWorkouts.filter { !$0.isActive }
    }
    
    // MARK: Private
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
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
        .sheet(isPresented: $showingDetail) {
            if let date = selectedDate, let workout = workout(for: date) {
                WorkoutDetailView(workout: workout)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Month Header
    
    /// Navigation arrows are CLEAR glass circles with visible blue chevrons.
    /// Month label sits in a clear glass capsule.
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
                        .frame(width: 38, height: 38)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
                
                Spacer()
                
                Button {
                    withAnimation(AppAnimation.spring) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 38, height: 38)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Calendar Grid
    
    /// Day-of-week headers + date cells inside a glass card.
    /// Each day is a small clear glass circle.
    private var calendarGrid: some View {
        VStack(spacing: 6) {
            // Day-of-week headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.bold())
                        .foregroundStyle(AppColors.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            
            // Date cells
            GlassEffectContainer(spacing: 8.0) {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            dayCell(for: date)
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
            }
        }
        .padding(12)
        .glassCard()
    }
    
    /// A single day — clear glass circle. Color comes from text, not glass.
    ///
    /// States:
    /// - **Workout day**: accent-colored number + small dot below
    /// - **Today**: bold accent number
    /// - **Regular day**: normal text on clear glass
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
            VStack(spacing: 1) {
                Text("\(day)")
                    .font(.system(size: 14, weight: isToday || hasWorkout ? .bold : .regular).monospacedDigit())
                    .foregroundStyle(
                        hasWorkout || isToday ? AppColors.accent : AppColors.primaryText
                    )
                
                // Workout indicator dot
                Circle()
                    .fill(hasWorkout ? AppColors.accent : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 44)
            .glassEffect(
                hasWorkout ? .regular.interactive() : .regular,
                in: .circle
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recent Workouts List
    
    /// Recent workouts as clear glass capsule buttons.
    private var recentWorkoutsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 26, height: 26)
                    .glassEffect(.regular, in: .circle)
                
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
    
    /// A recent workout row — clear glass rounded rect with readable text.
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
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
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
