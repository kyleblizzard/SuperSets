// WorkoutView.swift
// Super Sets — The Workout Tracker
//
// The main workout tracking screen — the heart of the app.
// Layout from top to bottom:
//   1. Rotary lift ring — 10 glass circles that spin like a revolver cylinder
//   2. Add Lift button (fixed below ring)
//   3. Unit caption label
//   4. Compact timer bar (Workout Time + Rest Timer)
//   5. Combined sets view — Today (left) vs Previous (right) side-by-side
//   6. End Workout button
//
// ROTARY RING:
// The lift circles are arranged in a clock layout and rotate as a group.
// The circle at 12 o'clock is the "active" lift and glows. Drag to spin,
// tap a circle to rotate it to the top. Snaps to discrete positions with
// haptic detent clicks — like a revolver cylinder or rotary phone dial.
//
// BUTTON PHILOSOPHY:
// Every tappable element uses Liquid Glass with .interactive(). This gives
// each button real optical depth — lensing, specular highlights that track
// device motion, press-down scaling with bounce-back, shimmer on touch,
// and touch-point illumination.

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

    // MARK: Rotary Ring State

    /// Accumulated rotation angle in degrees. Each slot = 36 degrees.
    @State private var ringRotation: Double = 0
    /// Rotation value when the drag gesture started.
    @State private var dragStartRotation: Double = 0
    /// Whether a drag gesture is currently active.
    @State private var isDragging: Bool = false
    /// Finger angle (in radians) at the start of the drag.
    @State private var dragStartAngle: Double = 0
    /// Last slot index the finger crossed (for haptic detent clicks).
    @State private var lastDetentSlot: Int = 0

    // MARK: Constants

    private let ringSize: CGFloat = 320
    private let ringRadius: CGFloat = 135
    private let circleSize: CGFloat = 60
    /// 10 lift slots on the ring (Add Lift is separate, below the ring).
    private let slotCount = 10
    /// Degrees per slot: 360 / 10 = 36.
    private let slotAngle: Double = 36.0

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                radialLiftRing

                radialAddLiftButton

                // Unit label
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
            if showPRBadge, let pr = prType {
                VStack(spacing: 6) {
                    Text("\u{1F3C6}")
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
        .onAppear {
            // If a lift is already selected, rotate ring to show it at top
            if let idx = workoutManager.selectedLiftIndex {
                ringRotation = -Double(idx) * slotAngle
            }
        }
        .onChange(of: workoutManager.recentLifts.count) { oldCount, newCount in
            // New lift added — it was inserted at index 0, rotate to show it at top
            if newCount > oldCount {
                withAnimation(AppAnimation.spring) {
                    ringRotation = 0
                }
                // Select the newly added lift after animation settles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if let first = workoutManager.recentLifts.first {
                        workoutManager.selectLift(first)
                    }
                }
            }
        }
    }

    // MARK: - Rotary Ring Math

    /// Position angle for a given slot index, incorporating current ring rotation.
    /// Slot 0 starts at 12 o'clock (-90 deg) and proceeds clockwise.
    private func angleForSlot(_ index: Int) -> Angle {
        .degrees(-90 + Double(index) * slotAngle + ringRotation)
    }

    /// Which slot index is currently closest to the 12 o'clock (top) position.
    private var topSlotIndex: Int {
        // ringRotation moves the ring; slot 0 is at top when rotation == 0.
        // Each +slotAngle of rotation moves the NEXT slot to the top,
        // so we negate and wrap.
        let normalized = (-ringRotation).truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let raw = Int(round(positive / slotAngle)) % slotCount
        return raw
    }

    /// Snap `ringRotation` to the nearest multiple of `slotAngle`.
    private func snapToNearestSlot() {
        let nearest = (ringRotation / slotAngle).rounded() * slotAngle
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            ringRotation = nearest
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Select the lift at the top after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectLiftAtTop()
        }
    }

    /// Animate the ring to bring a specific slot index to the 12 o'clock position.
    /// Uses shortest-path rotation to avoid spinning the long way around.
    private func animateToSlot(_ index: Int) {
        // Target rotation: slot `index` at top means rotation = -index * slotAngle
        let target = -Double(index) * slotAngle

        // Compute shortest-path delta
        var delta = target - ringRotation
        // Normalize delta to [-180, 180] for shortest path
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            ringRotation += delta
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Select lift after animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            selectLiftAtTop()
        }
    }

    /// Select the lift that's currently at the 12 o'clock position.
    private func selectLiftAtTop() {
        let idx = topSlotIndex
        if idx < workoutManager.recentLifts.count {
            workoutManager.selectLift(workoutManager.recentLifts[idx])
        }
    }

    // MARK: - Drag Gesture

    /// Converts single-finger drag into angular rotation of the ring.
    private var ringDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Ring center is at the middle of the ZStack
                let center = CGPoint(x: ringSize / 2, y: ringSize / 2)
                let current = value.location
                let start = value.startLocation

                // Compute finger angles relative to center
                let currentAngle = atan2(current.y - center.y, current.x - center.x)
                let startAngle = atan2(start.y - center.y, start.x - center.x)

                if !isDragging {
                    isDragging = true
                    dragStartRotation = ringRotation
                    dragStartAngle = startAngle
                    lastDetentSlot = topSlotIndex
                }

                // Angular delta in radians, then convert to degrees
                var angleDelta = currentAngle - dragStartAngle
                // Handle atan2 wrap-around at +/- pi
                if angleDelta > .pi { angleDelta -= 2 * .pi }
                if angleDelta < -.pi { angleDelta += 2 * .pi }

                let angleDeltaDeg = angleDelta * 180 / .pi
                ringRotation = dragStartRotation + angleDeltaDeg

                // Haptic detent: fire when crossing into a new slot
                let currentDetent = topSlotIndex
                if currentDetent != lastDetentSlot {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    lastDetentSlot = currentDetent
                }
            }
            .onEnded { _ in
                isDragging = false
                snapToNearestSlot()
            }
    }

    // MARK: - Radial Lift Ring

    /// 10 glass circles arranged in a clock layout, rotatable as a group.
    /// The circle at 12 o'clock glows as the active lift.
    /// Center input panel stays fixed (does not rotate).
    private var radialLiftRing: some View {
        ZStack {
            // Lift circles around the ring
            ForEach(0..<slotCount, id: \.self) { index in
                let angle = angleForSlot(index)
                let x = cos(angle.radians) * ringRadius
                let y = sin(angle.radians) * ringRadius
                let isAtTop = (topSlotIndex == index)

                // Z-ordering: circles near the top render in front
                let distFromTop = abs(angleDifference(angle.degrees + 90, 0))
                let zOrder = Double(slotCount) - distFromTop / 36.0

                if index < workoutManager.recentLifts.count {
                    radialLiftCircle(
                        for: workoutManager.recentLifts[index],
                        size: circleSize,
                        isTop: isAtTop
                    )
                    .offset(x: x, y: y)
                    .zIndex(zOrder)
                    .onTapGesture {
                        animateToSlot(index)
                    }
                } else {
                    // Empty ghost placeholder — bare glass, no deepGlass
                    Circle()
                        .fill(.clear)
                        .frame(width: circleSize, height: circleSize)
                        .glassEffect(.regular, in: .circle)
                        .opacity(0.25)
                        .offset(x: x, y: y)
                        .zIndex(zOrder)
                }
            }

            // Center input panel (fixed, does NOT rotate)
            radialCenterInputPanel
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle().inset(by: -20))
        .gesture(isInputFocused ? nil : ringDragGesture)
    }

    /// Add Lift button — fixed below the ring, always tappable.
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
            .deepGlass(.circle)
        }
        .buttonStyle(.plain)
    }

    /// A lift circle on the ring. When `isTop` is true, it glows via deepGlass active state.
    private func radialLiftCircle(for lift: LiftDefinition, size: CGFloat, isTop: Bool) -> some View {
        Text(twoWordName(lift.name))
            .font(.system(size: 9, weight: .semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .foregroundStyle(isTop ? AppColors.accent : AppColors.primaryText)
            .frame(width: size, height: size)
            .deepGlass(.circle, isActive: isTop)
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
                            .frame(width: 58, height: 36)
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
                            .frame(width: 58, height: 36)
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                            .frame(width: 50, height: 50)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 140, height: 140)
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
                .frame(width: 140, height: 140)
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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(timerManager.isRunning ? AppColors.danger : AppColors.positive)
                        .frame(width: 46, height: 46)
                        .deepGlass(.circle)
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
                if workoutManager.selectedLift != nil {
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .deepGlass(.capsule)
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
                Text("First time doing this lift \u{2014} set a baseline!")
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.danger)
                            .frame(width: 40, height: 40)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\u{2014}")
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
                    Text("\u{2014}")
                        .foregroundStyle(AppColors.subtleText.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
    }

    /// Volume-based comparison: up green, down red, = gray, + extra set.
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
    /// "Barbell Bench Press" -> "Bench\nPress", "Squat" -> "Squat"
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

    /// Signed shortest angular difference between two angles in degrees.
    /// Returns a value in [-180, 180].
    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }
}
