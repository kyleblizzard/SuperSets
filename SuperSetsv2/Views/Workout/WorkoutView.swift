// WorkoutView.swift
// Super Sets — The Workout Tracker
//
// The main workout tracking screen — the heart of the app.
// Layout from top to bottom:
//   1. Lift circle buttons (Add Lift + 4 recent lifts) — glossy interactive glass
//   2. Compact timer bar (Workout Time + Rest Timer)
//   3. Weight/Reps input with circular Log Set button (inline)
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
    
    @State private var showingLiftLibrary = false
    @State private var showingEndConfirmation = false
    @State private var showingSummary = false
    @State private var completedWorkout: Workout?
    @State private var endNotes = ""
    @State private var showSetLogged = false
    @State private var showPRBadge = false
    @State private var prType: PRType?
    
    // MARK: Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                liftCirclesSection
                
                if workoutManager.activeWorkout != nil {
                    timerBar
                }
                
                if workoutManager.selectedLift != nil {
                    setInputSection
                    combinedSetsView
                } else {
                    selectLiftHint
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
    }
    
    // MARK: - Lift Circle Buttons
    
    /// Horizontal scrolling row of glossy glass circle buttons.
    /// Each circle is a fully interactive glass element — press it and you'll
    /// see it scale down, shimmer, and illuminate at the touch point.
    ///
    /// LEARNING NOTE:
    /// GlassEffectContainer groups these circles into a shared sampling region.
    /// This means the glass knows about its siblings and can do morphing
    /// transitions between them. The spacing parameter controls how close
    /// elements need to be before they visually merge.
    private var liftCirclesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 20.0) {
                HStack(spacing: 12) {
                    // Add Lift — accent-tinted glass circle
                    addLiftButton
                    
                    // Recent lifts — muscle-group-tinted glass circles
                    ForEach(workoutManager.recentLifts, id: \.name) { lift in
                        liftCircle(for: lift)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        }
    }
    
    /// The "Add Lift" circle button with accent-tinted glass.
    private var addLiftButton: some View {
        Button {
            showingLiftLibrary = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 56, height: 56)
                    .glassEffect(
                        .regular.interactive(),
                        in: .circle
                    )
                
                Text("Add Lift")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.accent)
                    .lineLimit(1)
                    .frame(width: 56)
            }
        }
        .buttonStyle(.plain)
    }
    
    /// A single lift circle button. Selected state gets a deeper tint.
    ///
    /// LEARNING NOTE:
    /// .tint() on glass conveys meaning, not decoration. Here the muscle
    /// group color tells the user at a glance which body part each circle
    /// represents. The selected circle gets a stronger tint so it's obvious
    /// which lift is active. .interactive() adds the press/bounce/shimmer.
    private func liftCircle(for lift: LiftDefinition) -> some View {
        let isSelected = workoutManager.selectedLift?.name == lift.name
        
        return Button {
            withAnimation(AppAnimation.quick) {
                workoutManager.selectLift(lift)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 56, height: 56)
                    .glassEffect(.regular.interactive(), in: .circle)
                
                Text(shortName(lift.name))
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.subtleText)
                    .lineLimit(1)
                    .frame(width: 56)
            }
        }
        .buttonStyle(.plain)
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
                
                Text(timerManager.formattedTime)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(AppColors.primaryText)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.1), value: timerManager.elapsedSeconds)
                
                // Play/Stop as a small glossy glass circle
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
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(timerManager.isRunning ? AppColors.danger : AppColors.positive)
                        .frame(width: 30, height: 30)
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
    
    // MARK: - Select Lift Hint
    
    private var selectLiftHint: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.accent.opacity(0.6))
                .symbolEffect(.bounce, options: .repeating.speed(0.5))
            
            VStack(spacing: 8) {
                Text("Select a Lift to Begin")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.primaryText)
                
                Text("Tap \"Add Lift\" above to choose an exercise")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Set Input Section
    
    /// Weight and reps input with inline circular Log button.
    ///
    /// LEARNING NOTE:
    /// The Log button is a circle using .glassProminent — opaque glass that
    /// stands out from the translucent glass around it. This visual weight
    /// signals "this is the primary action." The checkmark animation on
    /// success gives immediate feedback without needing to read text.
    private var setInputSection: some View {
        VStack(spacing: 12) {
            if let lift = workoutManager.selectedLift {
                Text(lift.name)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)
            }
            
            HStack(spacing: 12) {
                // Weight input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                    
                    TextField("0", text: $workoutManager.weightInput)
                        .keyboardType(.decimalPad)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.inputFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.inputBorder, lineWidth: 0.5)
                                }
                        }
                }
                
                // Reps input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                    
                    TextField("0", text: $workoutManager.repsInput)
                        .keyboardType(.numberPad)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.inputFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.inputBorder, lineWidth: 0.5)
                                }
                        }
                }
                
                // Log Set — glossy glass circle (inline, same row as inputs)
                //
                // LEARNING NOTE:
                // .glassProminent makes this circle opaque glass — no background
                // shows through. This contrasts with the .regular (translucent)
                // glass on the surrounding card, making the button visually pop.
                // Combined with .interactive(), pressing it gives a satisfying
                // scale-bounce with a glossy shimmer at the touch point.
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
                        
                        // LEARNING NOTE:
                        // Check if WorkoutManager flagged a new PR during logSet().
                        // If so, show the 🏆 badge with a heavier haptic for celebration.
                        // We clear the alert from the manager immediately so it doesn't
                        // fire again on the next view update.
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
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                        .frame(width: 56, height: 56)
                        .glassEffect(
                            .regular.interactive(),
                            in: .circle
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Unit label
            if let unit = workoutManager.userProfile?.preferredUnit {
                Text("Weight in \(unit.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
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
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.subtleText.opacity(0.4))
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
    
    private func shortName(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count <= 2 { return name }
        let skipWords: Set<String> = [
            "flat", "incline", "decline", "barbell", "dumbbell",
            "cable", "machine", "seated", "standing", "lying", "overhead"
        ]
        for word in words {
            if !skipWords.contains(word.lowercased()) {
                return String(word)
            }
        }
        return String(words.first ?? "")
    }
}
