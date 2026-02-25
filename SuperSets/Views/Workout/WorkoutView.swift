// WorkoutView.swift
// Super Sets — The Workout Tracker
//
// The main workout tracking screen — the heart of the app.
// Layout from top to bottom:
//   1. Radial lift ring — 11 glass circles in a clock layout with center input
//   2. Unit caption label
//   3. Compact timer bar (Workout Time + Rest Timer)
//   4. Combined sets view — Today (left) vs Previous (right) side-by-side
//   5. End Workout button
//
// BUTTON PHILOSOPHY:
// Every tappable element uses Liquid Glass with .interactive(). This gives
// each button real optical depth — lensing, specular highlights that track
// device motion, press-down scaling with bounce-back, shimmer on touch,
// and touch-point illumination. It's the modern equivalent of Aqua's
// glossy gel buttons, but achieved through actual light simulation.
//
// LEARNING NOTE:
// .glassEffect(.regular.interactive()) = translucent glass, tappable
// .glassEffect(.regular.tint(color).interactive()) = tinted translucent, tappable
// .buttonStyle(.glassProminent) = opaque glass for primary actions
// .buttonStyle(.glass) = translucent glass for secondary actions

import SwiftUI
import SwiftData

// MARK: - WorkoutView

struct WorkoutView: View {
    
    // MARK: Dependencies
    
    @Bindable var workoutManager: WorkoutManager
    var timerManager: TimerManager
    
    // MARK: State

    @FocusState private var isInputFocused: Bool
    @State private var showingLiftLibrary = false
    @State private var showingEndConfirmation = false
    @State private var showingSummary = false
    @State private var completedWorkout: Workout?
    @State private var endNotes = ""
    @State private var showSetLogged = false
    @State private var showPRBadge = false
    @State private var prType: PRType?
    
    // MARK: Constants

    private let ringSize: CGFloat = 288
    private let ringRadius: CGFloat = 120
    private let circleSize: CGFloat = 48
    private let slotCount = 11

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                radialLiftRing

                // Unit label (moved below ring)
                if let unit = workoutManager.userProfile?.preferredUnit {
                    Text("Weight in \(unit.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(AppColors.subtleText)
                }

                if workoutManager.activeWorkout != nil {
                    timerBar
                }

                if workoutManager.selectedLift != nil {
                    combinedSetsView
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .overlay {
            // LEARNING NOTE:
            // This overlay sits on top of the entire scroll view.
            // It's a brief celebratory badge that appears when a PR is broken.
            // Using .transition(.scale.combined(with: .opacity)) makes it
            // pop in from the center and fade out — eye-catching but brief.
            if showPRBadge, let pr = prType {
                VStack(spacing: 6) {
                    Text("🏆")
                        .font(.system(size: 40))
                    Text("New PR!")
                        .font(.headline.bold())
                        .foregroundStyle(AppColors.primaryText)
                    Text(pr.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                }
                .padding(20)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
                .transition(.scale.combined(with: .opacity))
                .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showingLiftLibrary) {
            LiftLibraryView(workoutManager: workoutManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSummary) {
            if let workout = completedWorkout {
                WorkoutSummaryView(workout: workout, workoutManager: workoutManager)
            }
        }
        .alert("End Workout?", isPresented: $showingEndConfirmation) {
            TextField("Add notes (optional)", text: $endNotes)
            Button("End Workout", role: .destructive) {
                completedWorkout = workoutManager.endWorkout(notes: endNotes)
                timerManager.stop()
                endNotes = ""
                if completedWorkout != nil {
                    showingSummary = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will save your workout and show a summary.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
    }
    
    // MARK: - Radial Lift Ring

    /// 11 glass circles arranged in a clock layout with weight/reps input in the center.
    /// Index 0 = Add Lift at 12 o'clock, indices 1–10 = lift slots.
    private var radialLiftRing: some View {
        ZStack {
            // Positioned circles around the ring
            ForEach(0..<slotCount, id: \.self) { index in
                let angle = Angle.degrees(-90 + Double(index) * (360.0 / Double(slotCount)))
                let x = cos(angle.radians) * ringRadius
                let y = sin(angle.radians) * ringRadius

                if index == 0 {
                    radialAddLiftButton
                        .offset(x: x, y: y)
                } else {
                    let liftIndex = index - 1
                    if liftIndex < workoutManager.recentLifts.count {
                        radialLiftCircle(for: workoutManager.recentLifts[liftIndex], size: circleSize)
                            .offset(x: x, y: y)
                    } else {
                        // Empty placeholder slot
                        Circle()
                            .fill(.clear)
                            .frame(width: circleSize, height: circleSize)
                            .glassEffect(.regular, in: .circle)
                            .opacity(0.35)
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                            .offset(x: x, y: y)
                    }
                }
            }

            // Center input panel
            radialCenterInputPanel
        }
        .frame(width: ringSize, height: ringSize)
    }

    /// Add Lift button at 12 o'clock — 48pt glass circle.
    private var radialAddLiftButton: some View {
        Button {
            showingLiftLibrary = true
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add\nLift")
                    .font(.system(size: 7, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(AppColors.accent)
            .frame(width: circleSize, height: circleSize)
            .glassEffect(.regular.interactive(), in: .circle)
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    /// A filled lift circle in the ring. Shows two-word name inside.
    private func radialLiftCircle(for lift: LiftDefinition, size: CGFloat) -> some View {
        let isSelected = workoutManager.selectedLift?.name == lift.name

        return Button {
            withAnimation(AppAnimation.quick) {
                workoutManager.selectLift(lift)
            }
        } label: {
            Text(twoWordName(lift.name))
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? AppColors.accent : AppColors.primaryText)
                .frame(width: size, height: size)
                .glassEffect(.regular.interactive(), in: .circle)
                .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(AppColors.accent.opacity(0.6), lineWidth: 1.5)
                            .shadow(color: AppColors.accent.opacity(0.5), radius: 10)
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 20)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    /// Center input panel — weight/reps fields + log button, or a "Select a lift" hint.
    private var radialCenterInputPanel: some View {
        Group {
            if let lift = workoutManager.selectedLift {
                VStack(spacing: 6) {
                    // Lift name label
                    Text(lift.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    // Side-by-side weight + reps fields
                    HStack(spacing: 4) {
                        TextField("Wt", text: $workoutManager.weightInput)
                            .keyboardType(.decimalPad)
                            .focused($isInputFocused)
                            .font(.system(size: 14, weight: .bold).monospacedDigit())
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .frame(width: 52, height: 30)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.inputFill)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.inputBorder, lineWidth: 0.5)
                                    }
                            }

                        TextField("Rps", text: $workoutManager.repsInput)
                            .keyboardType(.numberPad)
                            .focused($isInputFocused)
                            .font(.system(size: 14, weight: .bold).monospacedDigit())
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .frame(width: 52, height: 30)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.inputFill)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppColors.inputBorder, lineWidth: 0.5)
                                    }
                            }
                    }

                    // Log set button
                    Button {
                        let success = workoutManager.logSet()
                        if success {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                            withAnimation(AppAnimation.quick) {
                                showSetLogged = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation { showSetLogged = false }
                            }

                            if let pr = workoutManager.newPRAlert {
                                prType = pr
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation(AppAnimation.spring) {
                                    showPRBadge = true
                                }
                                workoutManager.newPRAlert = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation { showPRBadge = false }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: showSetLogged ? "checkmark" : "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                            .frame(width: 40, height: 40)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 130, height: 130)
            } else {
                // No lift selected hint
                VStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.accent.opacity(0.6))
                    Text("Select\na lift")
                        .font(.caption2)
                        .foregroundStyle(AppColors.subtleText)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 130, height: 130)
            }
        }
    }

    // MARK: - Compact Timer Bar
    
    /// Single compact row: Workout Time on left, Rest Timer on right.
    private var timerBar: some View {
        HStack(spacing: 12) {
            // Workout elapsed time
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let workout = workoutManager.activeWorkout {
                    let elapsed = context.date.timeIntervalSince(workout.date)
                    let hours = Int(elapsed) / 3600
                    let minutes = (Int(elapsed) % 3600) / 60
                    let seconds = Int(elapsed) % 60
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.positive)
                            .frame(width: 6, height: 6)
                        
                        Text("Workout Time")
                            .font(.caption2.bold())
                            .foregroundStyle(AppColors.subtleText)
                        
                        Text(hours > 0
                             ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
                             : String(format: "%02d:%02d", minutes, seconds))
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(AppColors.primaryText)
                            .contentTransition(.numericText())
                    }
                }
            }
            
            Spacer()
            
            // Rest timer with glossy glass play/stop
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.subtleText)

                Text("Rest Timer")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColors.subtleText)

                Text(timerManager.formattedTime)
                    .font(.callout.monospacedDigit().bold())
                    .foregroundStyle(AppColors.primaryText)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: timerManager.elapsedSeconds)

                // Play/Stop as a glossy glass circle
                Button {
                    if timerManager.isRunning {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        timerManager.stop()
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        timerManager.start()
                    }
                } label: {
                    Image(systemName: timerManager.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(timerManager.isRunning ? AppColors.danger : AppColors.positive)
                        .frame(width: 36, height: 36)
                        .glassEffect(
                            .regular.interactive(),
                            in: .circle
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
    
    // MARK: - Combined Sets View (Today + Comparison Side-by-Side)
    
    /// Today on left, Previous on right, comparison arrows between them.
    /// Switching lifts via circle buttons updates both columns instantly.
    private var combinedSetsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with End Workout button
            HStack {
                if let lift = workoutManager.selectedLift {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 8, height: 8)
                        
                        Text("Sets")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
                
                Spacer()
                
                // End Workout — glossy glass button with danger tint
                Button {
                    showingEndConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text("End")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(AppColors.danger)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(
                        .regular.interactive(),
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Column headers
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 24, alignment: .leading)
                Text("Today")
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 24)
                
                if let date = workoutManager.previousWorkoutDate {
                    let formatter: DateFormatter = {
                        let f = DateFormatter()
                        f.dateFormat = "MMM d"
                        return f
                    }()
                    Text(formatter.string(from: date))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Previous")
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.caption.bold())
            .foregroundStyle(AppColors.subtleText)
            
            // Set rows
            let todaySets = workoutManager.currentLiftSets
            let previousSets = workoutManager.previousSets
            let maxSets = max(todaySets.count, previousSets.count)
            
            if maxSets > 0 {
                ForEach(0..<maxSets, id: \.self) { index in
                    setRow(
                        index: index,
                        todaySet: index < todaySets.count ? todaySets[index] : nil,
                        previousSet: index < previousSets.count ? previousSets[index] : nil
                    )
                }
            } else if previousSets.isEmpty {
                Text("First time doing this lift — set a baseline!")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    /// A single row: Today (left), arrow (center), Previous (right).
    private func setRow(index: Int, todaySet: WorkoutSet?, previousSet: WorkoutSet?) -> some View {
        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(AppColors.subtleText)
                .frame(width: 24, alignment: .leading)
            
            // Today's set with inline delete
            HStack(spacing: 6) {
                if let today = todaySet {
                    Text(today.formattedDisplay)
                        .font(.body.monospacedDigit().bold())
                        .foregroundStyle(AppColors.primaryText)
                    
                    Button {
                        withAnimation(AppAnimation.quick) {
                            workoutManager.deleteSet(today)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.danger)
                            .frame(width: 28, height: 28)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("—")
                        .foregroundStyle(AppColors.subtleText.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
            
            comparisonArrow(today: todaySet, previous: previousSet)
                .frame(width: 24)
            
            Group {
                if let prev = previousSet {
                    Text(prev.formattedDisplay)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(AppColors.subtleText)
                } else {
                    Text("—")
                        .foregroundStyle(AppColors.subtleText.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }
    
    /// Volume-based comparison: ↑ green, ↓ red, = gray, + extra set.
    @ViewBuilder
    private func comparisonArrow(today: WorkoutSet?, previous: WorkoutSet?) -> some View {
        if let today = today, let previous = previous {
            let todayVolume = today.weight * Double(today.reps)
            let prevVolume = previous.weight * Double(previous.reps)
            
            if todayVolume > prevVolume {
                Image(systemName: "arrow.up")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.positive)
            } else if todayVolume < prevVolume {
                Image(systemName: "arrow.down")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.danger)
            } else {
                Image(systemName: "equal")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.neutral)
            }
        } else if today != nil {
            Image(systemName: "plus")
                .font(.caption.bold())
                .foregroundStyle(AppColors.positive)
        } else {
            Text("")
        }
    }
    
    // MARK: - Helpers

    /// Extract up to 2 meaningful words from a lift name for compact display.
    /// Strips filler/equipment words and joins with newline.
    /// "Barbell Bench Press" → "Bench\nPress", "Squat" → "Squat"
    private func twoWordName(_ name: String) -> String {
        let filler: Set<String> = [
            "barbell", "dumbbell", "cable", "machine", "seated",
            "standing", "lying", "overhead", "flat", "incline", "decline"
        ]
        let meaningful = name.split(separator: " ")
            .filter { !filler.contains($0.lowercased()) }

        if meaningful.isEmpty {
            return name.split(separator: " ").first.map(String.init) ?? name
        }

        return meaningful.prefix(2).map(String.init).joined(separator: "\n")
    }
}
