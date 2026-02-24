//
//  CalendarView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Displays a monthly calendar grid showing workout dots on days with workouts.
//  Users can navigate months and tap workout days to see workout details.

import SwiftUI
import SwiftData

struct CalendarView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    // MARK: - State
    
    @State private var currentMonth = Date()
    @State private var selectedWorkout: Workout?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 5 circles indicator at top
                progressCircles
                
                // Today's workout comparison
                if let todaysWorkout = getTodaysWorkout() {
                    workoutComparisonView(todaysWorkout: todaysWorkout)
                }
                
                // Month navigation
                monthNavigationHeader
                
                // Calendar grid
                calendarGrid
                
                // Recent workouts list
                recentWorkoutsList
            }
            .padding()
            .padding(.bottom, 100)
        }
        .background(LiquidGlassBackground())
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
    
    
    // MARK: - Progress Circles
    
    private var progressCircles: some View {
        HStack(spacing: 20) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(circleColor(for: index))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    }
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private func circleColor(for index: Int) -> Color {
        let workoutsThisWeek = getWorkoutsThisWeek().count
        return index < workoutsThisWeek ? .green : .white.opacity(0.2)
    }
    
    private func getWorkoutsThisWeek() -> [Workout] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return []
        }
        
        return allWorkouts.filter { workout in
            !workout.isActive &&
            workout.date >= startOfWeek &&
            workout.date <= Date()
        }
    }
    
    // MARK: - Workout Comparison
    
    private func workoutComparisonView(todaysWorkout: Workout) -> some View {
        let previousWorkout = getPreviousWorkout(before: todaysWorkout)
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("Today's Workout")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 1)
                    .overlay(.white.opacity(0.3))
                
                Text("Previous Workout")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
                .overlay(.white.opacity(0.3))
            
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    // Today's sets
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(todaysWorkout.sets.enumerated()), id: \.element.id) { index, set in
                            setRow(index: index + 1, set: set)
                        }
                        
                        if todaysWorkout.sets.isEmpty {
                            Text("No sets yet")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    Divider()
                        .frame(width: 1)
                        .overlay(.white.opacity(0.3))
                    
                    // Previous workout sets
                    VStack(alignment: .leading, spacing: 12) {
                        if let previousWorkout = previousWorkout {
                            ForEach(Array(previousWorkout.sets.enumerated()), id: \.element.id) { index, set in
                                setRow(index: index + 1, set: set)
                            }
                        } else {
                            Text("No previous workout")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .frame(maxHeight: 400)
        }
        .liquidGlassPanel()
    }
    
    private func setRow(index: Int, set: WorkoutSet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(index). \(set.liftDefinition?.name ?? "Unknown")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text("Weight: \(String(format: "%.0f", set.weight))lbs, Reps: \(set.reps)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    private func getTodaysWorkout() -> Workout? {
        allWorkouts.first { workout in
            Calendar.current.isDateInToday(workout.date) && !workout.isActive
        }
    }
    
    private func getPreviousWorkout(before workout: Workout) -> Workout? {
        allWorkouts.first { w in
            !w.isActive &&
            w.date < workout.date &&
            Calendar.current.compare(w.date, to: workout.date, toGranularity: .day) != .orderedSame
        }
    }
    
    // MARK: - Month Navigation
    
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation(.liquidGlass) {
                currentMonth = newDate
            }
        }
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day names header
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        // Empty cell for padding
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    private func dayCell(for date: Date) -> some View {
        let hasWorkout = workoutExists(on: date)
        let isToday = Calendar.current.isDateInToday(date)
        
        return Button {
            if hasWorkout, let workout = getWorkout(for: date) {
                selectedWorkout = workout
            }
        } label: {
            VStack(spacing: 4) {
                Text(dayNumber(for: date))
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(.white)
                
                if hasWorkout {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background {
                if isToday {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .disabled(!hasWorkout)
    }
    
    // MARK: - Recent Workouts List
    
    @ViewBuilder
    private var recentWorkoutsList: some View {
        let completedWorkouts = allWorkouts.filter { !$0.isActive }
        
        if !completedWorkouts.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Workouts")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                ForEach(completedWorkouts.prefix(10)) { workout in
                    Button {
                        selectedWorkout = workout
                    } label: {
                        recentWorkoutRow(workout)
                    }
                }
            }
            .padding()
            .liquidGlassPanel()
        }
    }
    
    private func recentWorkoutRow(_ workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.date, style: .date)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: 16) {
                    Label("\(workout.sets.count) sets", systemImage: "list.number")
                    Label("\(workout.uniqueLifts) exercises", systemImage: "dumbbell.fill")
                    Label(workout.durationFormatted, systemImage: "clock.fill")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Helper Methods
    
    private var daysInMonth: [Date?] {
        // LEARNING NOTE: This creates an array with the correct number of days
        // plus empty spaces at the start to align with the weekday
        
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let days = Calendar.current.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        
        // Add padding at the start
        let firstWeekday = Calendar.current.component(.weekday, from: monthInterval.start)
        let paddingCount = firstWeekday - 1
        
        var result: [Date?] = Array(repeating: nil, count: paddingCount)
        result.append(contentsOf: days)
        
        return result
    }
    
    private func dayNumber(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }
    
    private func workoutExists(on date: Date) -> Bool {
        getWorkout(for: date) != nil
    }
    
    private func getWorkout(for date: Date) -> Workout? {
        allWorkouts.first { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: date) && !workout.isActive
        }
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
