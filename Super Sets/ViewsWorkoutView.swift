//
//  WorkoutView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  The main workout tracking view. Displays lift selector circles at the top,
//  weight/reps input, current sets, rest timer, and comparison with previous workout.

import SwiftUI
import SwiftData

struct WorkoutView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    // LEARNING NOTE: @State creates the WorkoutManager and TimerManager instances
    @State private var workoutManager: WorkoutManager?
    @State private var timerManager = TimerManager()
    
    @State private var showingAddLift = false
    @State private var showingAllLifts = false
    @State private var showingEndWorkout = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // If no active workout, show start button
                if workoutManager?.activeWorkout == nil {
                    startWorkoutSection
                } else {
                    // Active workout UI
                    liftSelectorRow
                    
                    if workoutManager?.selectedLift != nil {
                        setInputSection
                        currentSetsSection
                        restTimerSection
                        comparisonSection
                    }
                }
            }
            .padding()
            .padding(.bottom, 100) // Space for tab bar
        }
        .onAppear {
            // Initialize WorkoutManager on appear
            if workoutManager == nil {
                let manager = WorkoutManager(modelContext: modelContext)
                manager.loadActiveWorkout()
                workoutManager = manager
            }
        }
        .sheet(isPresented: $showingAddLift) {
            AddLiftView(workoutManager: workoutManager)
        }
        .sheet(isPresented: $showingAllLifts) {
            AllLiftsView(workoutManager: workoutManager)
        }
        .sheet(isPresented: $showingEndWorkout) {
            if let workout = workoutManager?.activeWorkout {
                EndWorkoutView(workout: workout, workoutManager: workoutManager)
            }
        }
    }
    
    // MARK: - Start Workout Section
    
    private var startWorkoutSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("Start Your Workout")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Track your sets, compare with previous workouts, and crush your goals")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                workoutManager?.startWorkout()
            } label: {
                Text("Start Workout")
            }
            .buttonStyle(PrimaryActionButtonStyle(color: .green))
            .padding(.top, 8)
        }
        .padding(32)
        .liquidGlassPanel()
    }
    
    // MARK: - Lift Selector Row
    
    private var liftSelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // 1. Add Lift button (fixed position)
                addLiftButton
                
                // 2-5. Recent lifts (up to 4)
                recentLiftsButtons
                
                // 6. All Lifts button (fixed position)
                allLiftsButton
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var addLiftButton: some View {
        Button {
            showingAddLift = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                
                Text("Add")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .foregroundStyle(.white)
        }
        .buttonStyle(GlassButtonStyle())
    }
    
    @ViewBuilder
    private var recentLiftsButtons: some View {
        let recentLifts = workoutManager?.getRecentLifts() ?? []
        
        ForEach(recentLifts) { lift in
            liftCircleButton(for: lift)
        }
    }
    
    private var allLiftsButton: some View {
        Button {
            showingAllLifts = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "list.bullet")
                    .font(.title)
                
                Text("All")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .foregroundStyle(.white)
        }
        .buttonStyle(GlassButtonStyle())
    }
    
    private func liftCircleButton(for lift: LiftDefinition) -> some View {
        let isSelected = workoutManager?.selectedLift?.persistentModelID == lift.persistentModelID
        
        return Button {
            workoutManager?.selectLift(lift)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: lift.muscleGroup.iconName)
                    .font(.title2)
                
                Text(lift.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80, height: 80)
            .foregroundStyle(.white)
        }
        .buttonStyle(GlassButtonStyle(
            accentColor: lift.muscleGroup.accentColor,
            isSelected: isSelected
        ))
    }
    
    // MARK: - Set Input Section
    
    private var setInputSection: some View {
        VStack(spacing: 16) {
            if let lift = workoutManager?.selectedLift {
                Text(lift.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            HStack(spacing: 16) {
                // Weight input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("0", text: Binding(
                        get: { workoutManager?.currentWeight ?? "" },
                        set: { workoutManager?.currentWeight = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                }
                
                // Reps input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    TextField("0", text: Binding(
                        get: { workoutManager?.currentReps ?? "" },
                        set: { workoutManager?.currentReps = $0 }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                }
            }
            
            Button {
                workoutManager?.logSet()
            } label: {
                Text("Log Set")
            }
            .buttonStyle(PrimaryActionButtonStyle(color: .blue))
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Current Sets Section
    
    @ViewBuilder
    private var currentSetsSection: some View {
        if let lift = workoutManager?.selectedLift,
           let workout = workoutManager?.activeWorkout {
            let sets = workout.sets(for: lift)
            
            if !sets.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Sets")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    ForEach(sets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text(set.formattedSet)
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(.white)
                            
                            Button {
                                workoutManager?.deleteSet(set)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .liquidGlassPanel()
            }
        }
    }
    
    // MARK: - Rest Timer Section
    
    private var restTimerSection: some View {
        VStack(spacing: 16) {
            Text("Rest Timer")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text(timerManager.formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            HStack(spacing: 16) {
                if !timerManager.isRunning {
                    Button {
                        timerManager.start()
                    } label: {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle(color: .green))
                } else {
                    Button {
                        timerManager.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle(color: .red))
                }
            }
        }
        .padding()
        .liquidGlassPanel()
    }
    
    // MARK: - Comparison Section
    
    @ViewBuilder
    private var comparisonSection: some View {
        if let lift = workoutManager?.selectedLift,
           let workout = workoutManager?.activeWorkout {
            let todaySets = workout.sets(for: lift)
            let previousData = workoutManager?.getPreviousData(for: lift)
            
            VStack(alignment: .leading, spacing: 16) {
                // End Workout button in upper right
                HStack {
                    Text("Comparison")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        showingEndWorkout = true
                    } label: {
                        Text("End Workout")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.3))
                            }
                    }
                }
                
                if let previous = previousData {
                    HStack(alignment: .top, spacing: 16) {
                        // Today column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            ForEach(todaySets) { set in
                                Text("\(set.setNumber). \(set.formattedSet)")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .background(.white.opacity(0.3))
                        
                        // Previous column
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Previous")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(previous.workout.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            ForEach(previous.sets) { set in
                                Text("\(set.setNumber). \(set.formattedSet)")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text("No previous data for this lift")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding()
            .liquidGlassPanel()
        }
    }
}

// MARK: - Preview

#Preview {
    WorkoutView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
