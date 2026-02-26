// WorkoutView.swift
// Super Sets — The Workout Tracker
//
// The main workout tracking screen — the heart of the app.
// Layout from top to bottom:
//   1. Rotary lift ring — 10 glass circles that spin like a revolver cylinder
//   2. Add Lift button (fixed below ring)
//   3. Unit caption label
//   4. Centered Rest Timer — standalone glass slab with big time display
//   5. Combined sets view — Today (left) vs Previous (right) side-by-side
//      with workout elapsed time at the bottom
//   6. End Workout button
//
// v2.0 — 10x LIQUID GLASS: Glass fields, glass rows, glass slab containers,
// centered rest timer as standalone element, workout time moved to bottom
// of sets comparison area.

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

    // MARK: Slot Machine State

    @State private var wheelWeight: Double = 135.0
    @State private var wheelReps: Int = 8

    // MARK: Super Set State

    /// Index of the lift currently being edited in the SS cycle-through panel.
    @State private var superSetInputIndex: Int = 0
    /// Per-lift wheel weight values keyed by lift name.
    @State private var superSetWheelWeights: [String: Double] = [:]
    /// Per-lift wheel reps values keyed by lift name.
    @State private var superSetWheelReps: [String: Int] = [:]

    // MARK: Timer State

    /// When true, the center panel shows the rest timer instead of weight/reps input.
    @State private var showTimerInCenter: Bool = false

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

    /// Whether to use scroll wheel (slot machine) input vs keyboard text fields.
    private var useWheelInput: Bool {
        workoutManager.userProfile?.useScrollWheelInput ?? true
    }

    /// Weight options for the wheel picker, based on preferred unit.
    private var weightOptions: [Double] {
        let unit = workoutManager.userProfile?.preferredUnit ?? .lbs
        switch unit {
        case .lbs: return stride(from: 0.0, through: 500.0, by: 2.5).map { $0 }
        case .kg: return stride(from: 0.0, through: 250.0, by: 1.0).map { $0 }
        }
    }

    /// Unit label string for display.
    private var unitLabel: String {
        workoutManager.userProfile?.preferredUnit.rawValue ?? "lbs"
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top row: Add Lift (left) — unit label (center) — Super Set (right)
                topButtonsRow

                radialLiftRing

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
                .glassSlab(.rect(cornerRadius: 20))
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
            if let idx = workoutManager.selectedLiftIndex {
                ringRotation = -Double(idx) * slotAngle
            }
            syncWheelsFromInput()
        }
        .onChange(of: workoutManager.selectedLift?.name) { _, _ in
            syncWheelsFromInput()
        }
        .onChange(of: workoutManager.recentLifts.count) { oldCount, newCount in
            if newCount > oldCount {
                withAnimation(AppAnimation.spring) {
                    ringRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if let first = workoutManager.recentLifts.first {
                        workoutManager.selectLift(first)
                    }
                }
            }
        }
    }

    // MARK: - Rotary Ring Math

    private func angleForSlot(_ index: Int) -> Angle {
        .degrees(-90 + Double(index) * slotAngle + ringRotation)
    }

    private var topSlotIndex: Int {
        let normalized = (-ringRotation).truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let raw = Int(round(positive / slotAngle)) % slotCount
        return raw
    }

    private func snapToNearestSlot() {
        let nearest = (ringRotation / slotAngle).rounded() * slotAngle
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            ringRotation = nearest
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectLiftAtTop()
        }
    }

    private func animateToSlot(_ index: Int) {
        let target = -Double(index) * slotAngle
        var delta = target - ringRotation
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            ringRotation += delta
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            selectLiftAtTop()
        }
    }

    private func selectLiftAtTop() {
        // Don't change selected lift while building a super set
        guard !workoutManager.isSuperSetMode else { return }
        let idx = topSlotIndex
        if idx < workoutManager.recentLifts.count {
            workoutManager.selectLift(workoutManager.recentLifts[idx])
        }
    }

    // MARK: - Drag Gesture

    private var ringDragGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let center = CGPoint(x: ringSize / 2, y: ringSize / 2)
                let current = value.location
                let start = value.startLocation

                let currentAngle = atan2(current.y - center.y, current.x - center.x)
                let startAngle = atan2(start.y - center.y, start.x - center.x)

                if !isDragging {
                    isDragging = true
                    dragStartRotation = ringRotation
                    dragStartAngle = startAngle
                    lastDetentSlot = topSlotIndex
                }

                var angleDelta = currentAngle - dragStartAngle
                if angleDelta > .pi { angleDelta -= 2 * .pi }
                if angleDelta < -.pi { angleDelta += 2 * .pi }

                let angleDeltaDeg = angleDelta * 180 / .pi
                ringRotation = dragStartRotation + angleDeltaDeg

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

    private var radialLiftRing: some View {
        ZStack {
            ForEach(0..<slotCount, id: \.self) { index in
                let angle = angleForSlot(index)
                let x = cos(angle.radians) * ringRadius
                let y = sin(angle.radians) * ringRadius
                let isAtTop = (topSlotIndex == index)

                let distFromTop = abs(angleDifference(angle.degrees + 90, 0))
                let zOrder = Double(slotCount) - distFromTop / 36.0

                if index < workoutManager.recentLifts.count {
                    let lift = workoutManager.recentLifts[index]
                    let inSS = workoutManager.isSuperSetMode && workoutManager.isInSuperSet(lift)

                    radialLiftCircle(
                        for: lift,
                        size: circleSize,
                        isTop: isAtTop,
                        inSuperSet: inSS
                    )
                    .overlay {
                        // Gold number badge for SS-selected orbs
                        if inSS, let ssIdx = workoutManager.superSetIndex(of: lift) {
                            Text("\(ssIdx)")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(AppColors.gold, in: Circle())
                                .offset(x: circleSize / 2 - 6, y: -circleSize / 2 + 6)
                        }
                    }
                    .onTapGesture {
                        if workoutManager.isSuperSetMode {
                            workoutManager.toggleSuperSetLift(lift)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .offset(x: x, y: y)
                    .zIndex(zOrder)
                } else {
                    // Empty ghost placeholder — glass gem
                    Circle()
                        .fill(.clear)
                        .frame(width: circleSize, height: circleSize)
                        .glassGem(.circle)
                        .opacity(0.25)
                        .offset(x: x, y: y)
                        .zIndex(zOrder)
                }
            }

            // Center input panel (fixed, does NOT rotate)
            if workoutManager.isSuperSetMode && !workoutManager.superSetLifts.isEmpty {
                superSetCenterPanel
            } else {
                radialCenterInputPanel
            }
        }
        .frame(width: ringSize, height: ringSize)
        .contentShape(Circle().inset(by: -20))
        .gesture(isInputFocused ? nil : ringDragGesture)
    }

    /// Top row: Add Lift (left), unit label (center), Super Set (right).
    private var topButtonsRow: some View {
        HStack {
            // Add Lift — upper left
            Button {
                showingLiftLibrary = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add Lift")
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundStyle(AppColors.accent)
                .frame(width: 50, height: 50)
                .deepGlass(.circle)
            }
            .buttonStyle(.plain)

            Spacer()

            // Unit label (center)
            if let unit = workoutManager.userProfile?.preferredUnit {
                Text("Weight in \(unit.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText)
            }

            Spacer()

            // Super Set — upper right
            Button {
                withAnimation(AppAnimation.spring) {
                    if workoutManager.isSuperSetMode {
                        workoutManager.exitSuperSetMode()
                        superSetInputIndex = 0
                        superSetWheelWeights = [:]
                        superSetWheelReps = [:]
                    } else {
                        workoutManager.enterSuperSetMode()
                        superSetInputIndex = 0
                        superSetWheelWeights = [:]
                        superSetWheelReps = [:]
                    }
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 14, weight: .bold))
                    Text("Super Set")
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundStyle(workoutManager.isSuperSetMode ? AppColors.gold : AppColors.accent)
                .frame(width: 50, height: 50)
                .deepGlass(.circle, isActive: workoutManager.isSuperSetMode)
            }
            .buttonStyle(.plain)
        }
    }

    /// A lift circle on the ring.
    private func radialLiftCircle(for lift: LiftDefinition, size: CGFloat, isTop: Bool, inSuperSet: Bool = false) -> some View {
        Text(twoWordName(lift.name))
            .font(.system(size: 9, weight: .semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .foregroundStyle(inSuperSet ? AppColors.gold : (isTop ? AppColors.accent : AppColors.primaryText))
            .frame(width: size, height: size)
            .deepGlass(.circle, isActive: isTop || inSuperSet)
    }

    /// Center of the rotary ring.
    /// Three modes: timer overlay, weight/reps wheel input, or keyboard text fields.
    private var radialCenterInputPanel: some View {
        Group {
            if showTimerInCenter && workoutManager.activeWorkout != nil {
                centerTimerPanel
            } else if let lift = workoutManager.selectedLift {
                if useWheelInput {
                    // Wheel mode — compact pickers + circular LOG
                    VStack(spacing: 0) {
                        Text(lift.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        HStack(spacing: 4) {
                            // Weight column with label
                            VStack(spacing: 0) {
                                Text("Weight")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(AppColors.subtleText)
                                Picker("Weight", selection: $wheelWeight) {
                                    ForEach(weightOptions, id: \.self) { value in
                                        Text(formatWheelWeight(value))
                                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 72, height: 90)
                                .clipped()
                            }

                            // Reps column with label
                            VStack(spacing: 0) {
                                Text("Reps")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(AppColors.subtleText)
                                Picker("Reps", selection: $wheelReps) {
                                    ForEach(1...99, id: \.self) { value in
                                        Text("\(value)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 72, height: 90)
                                .clipped()
                            }
                        }

                        // Circular LOG button + timer shortcut
                        HStack(spacing: 8) {
                            // Timer button
                            if workoutManager.activeWorkout != nil {
                                Button {
                                    withAnimation(AppAnimation.spring) {
                                        showTimerInCenter = true
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "timer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(timerManager.isRunning ? AppColors.positive : AppColors.subtleText)
                                        .frame(width: 32, height: 32)
                                        .deepGlass(.circle)
                                }
                                .buttonStyle(.plain)
                            }

                            Button { logSetAction() } label: {
                                Text(showSetLogged ? "\u{2713}" : "LOG")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                                    .frame(width: 50, height: 50)
                                    .deepGlass(.circle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 160, height: 160)
                    .onChange(of: wheelWeight) { _, newValue in
                        workoutManager.weightInput = formatWheelWeight(newValue)
                    }
                    .onChange(of: wheelReps) { _, newValue in
                        workoutManager.repsInput = "\(newValue)"
                    }
                } else {
                    // Keyboard mode — text fields + circular log button
                    VStack(spacing: 6) {
                        Text(lift.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        HStack(spacing: 4) {
                            VStack(spacing: 2) {
                                Text("Weight")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(AppColors.subtleText)
                                TextField("Wt", text: $workoutManager.weightInput)
                                    .keyboardType(.decimalPad)
                                    .focused($isInputFocused)
                                    .font(.system(size: 14, weight: .bold).monospacedDigit())
                                    .foregroundStyle(AppColors.primaryText)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 58, height: 36)
                                    .glassField(cornerRadius: 8)
                            }

                            VStack(spacing: 2) {
                                Text("Reps")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(AppColors.subtleText)
                                TextField("Rps", text: $workoutManager.repsInput)
                                    .keyboardType(.numberPad)
                                    .focused($isInputFocused)
                                    .font(.system(size: 14, weight: .bold).monospacedDigit())
                                    .foregroundStyle(AppColors.primaryText)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 58, height: 36)
                                    .glassField(cornerRadius: 8)
                            }
                        }

                        HStack(spacing: 8) {
                            if workoutManager.activeWorkout != nil {
                                Button {
                                    withAnimation(AppAnimation.spring) {
                                        showTimerInCenter = true
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "timer")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(timerManager.isRunning ? AppColors.positive : AppColors.subtleText)
                                        .frame(width: 32, height: 32)
                                        .deepGlass(.circle)
                                }
                                .buttonStyle(.plain)
                            }

                            Button { logSetAction() } label: {
                                Image(systemName: showSetLogged ? "checkmark" : "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(showSetLogged ? AppColors.positive : AppColors.accent)
                                    .frame(width: 50, height: 50)
                                    .deepGlass(.circle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 160, height: 160)
                }
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

    // MARK: - Super Set Center Panel

    /// Cycle-through center panel for super set mode.
    /// Shows one lift at a time with weight/reps pickers and prev/next/LOG navigation.
    private var superSetCenterPanel: some View {
        let lifts = workoutManager.superSetLifts
        let safeIndex = min(superSetInputIndex, max(lifts.count - 1, 0))
        let currentLift = lifts.isEmpty ? nil : lifts[safeIndex]
        let isLastLift = safeIndex == lifts.count - 1

        return VStack(spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 8, weight: .bold))
                Text("SUPER SET")
                    .font(.system(size: 8, weight: .black, design: .rounded))
            }
            .foregroundStyle(AppColors.gold)

            if let lift = currentLift {
                // Lift name with index
                Text("\(lift.name) (\(safeIndex + 1)/\(lifts.count))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(AppColors.subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                // Wheel pickers with labels
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text("Weight")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                        Picker("Weight", selection: superSetWeightBinding(for: lift.name)) {
                            ForEach(weightOptions, id: \.self) { value in
                                Text(formatWheelWeight(value))
                                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 72, height: 80)
                        .clipped()
                    }

                    VStack(spacing: 0) {
                        Text("Reps")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppColors.subtleText)
                        Picker("Reps", selection: superSetRepsBinding(for: lift.name)) {
                            ForEach(1...99, id: \.self) { value in
                                Text("\(value)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                    .tag(value)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 72, height: 80)
                        .clipped()
                    }
                }

                // Navigation row: prev / LOG or Next / next
                HStack(spacing: 6) {
                    Button {
                        saveSuperSetWheelValues()
                        withAnimation(AppAnimation.quick) {
                            superSetInputIndex = max(0, safeIndex - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(safeIndex > 0 ? AppColors.accent : AppColors.subtleText.opacity(0.3))
                            .frame(width: 30, height: 28)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                    .disabled(safeIndex == 0)

                    // LOG (circle) or Next
                    Button {
                        saveSuperSetWheelValues()
                        if isLastLift {
                            logSuperSetAction()
                        } else {
                            withAnimation(AppAnimation.quick) {
                                superSetInputIndex = safeIndex + 1
                            }
                        }
                    } label: {
                        Text(isLastLift ? (showSetLogged ? "\u{2713}" : "LOG") : "Next")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isLastLift
                                ? (showSetLogged ? AppColors.positive : AppColors.gold)
                                : AppColors.accent)
                            .frame(width: 44, height: 44)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)

                    Button {
                        saveSuperSetWheelValues()
                        withAnimation(AppAnimation.quick) {
                            superSetInputIndex = min(lifts.count - 1, safeIndex + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(!isLastLift ? AppColors.accent : AppColors.subtleText.opacity(0.3))
                            .frame(width: 30, height: 28)
                            .deepGlass(.circle)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLastLift)
                }
            }
        }
        .frame(width: 160, height: 160)
    }

    /// Binding for the super set wheel weight for a given lift name.
    private func superSetWeightBinding(for liftName: String) -> Binding<Double> {
        Binding<Double>(
            get: { superSetWheelWeights[liftName] ?? 135.0 },
            set: { newValue in
                superSetWheelWeights[liftName] = newValue
                workoutManager.superSetWeights[liftName] = formatWheelWeight(newValue)
            }
        )
    }

    /// Binding for the super set wheel reps for a given lift name.
    private func superSetRepsBinding(for liftName: String) -> Binding<Int> {
        Binding<Int>(
            get: { superSetWheelReps[liftName] ?? 8 },
            set: { newValue in
                superSetWheelReps[liftName] = newValue
                workoutManager.superSetReps[liftName] = "\(newValue)"
            }
        )
    }

    /// Persist current wheel picker values into workoutManager before switching lifts.
    private func saveSuperSetWheelValues() {
        for lift in workoutManager.superSetLifts {
            let name = lift.name
            if let w = superSetWheelWeights[name] {
                workoutManager.superSetWeights[name] = formatWheelWeight(w)
            }
            if let r = superSetWheelReps[name] {
                workoutManager.superSetReps[name] = "\(r)"
            }
        }
    }

    /// Log the super set with haptic feedback and confirmation animation.
    private func logSuperSetAction() {
        saveSuperSetWheelValues()
        let success = workoutManager.logSuperSet()
        if success {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            withAnimation(AppAnimation.quick) {
                showSetLogged = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { showSetLogged = false }
            }

            // Reset to first lift for next round
            superSetInputIndex = 0

            // Reset reps wheels (weights persist)
            for lift in workoutManager.superSetLifts {
                superSetWheelReps[lift.name] = 8
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
    }

    // MARK: - Center Timer Panel

    /// Timer view that takes over the ring center when activated.
    private var centerTimerPanel: some View {
        VStack(spacing: 8) {
            // Close button
            HStack {
                Spacer()
                Button {
                    withAnimation(AppAnimation.spring) {
                        showTimerInCenter = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.subtleText)
                        .frame(width: 24, height: 24)
                        .deepGlass(.circle)
                }
                .buttonStyle(.plain)
            }

            Text("Rest Timer")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.subtleText)

            Text(timerManager.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: timerManager.elapsedSeconds)

            // Play / Stop button
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
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(timerManager.isRunning ? AppColors.danger : AppColors.positive)
                    .frame(width: 50, height: 50)
                    .deepGlass(.circle)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 160, height: 160)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Combined Sets View (Today + Comparison Side-by-Side)

    private var combinedSetsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with End Workout button
            HStack {
                if workoutManager.selectedLift != nil {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.gold)
                            .frame(width: 8, height: 8)
                            .glassGem(.circle)

                        Text("Sets")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.primaryText)
                    }
                }

                Spacer()

                // End Workout button
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

            // Column headers in a glass row
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
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .glassRow(cornerRadius: 10)

            // Set rows — mixed regular + super set display
            let displayRows = workoutManager.currentLiftDisplayRows
            let previousSets = workoutManager.previousSets

            if !displayRows.isEmpty {
                ForEach(displayRows) { row in
                    switch row {
                    case .regular(let set):
                        let prevIndex = set.setNumber - 1
                        setRow(
                            index: prevIndex,
                            todaySet: set,
                            previousSet: prevIndex < previousSets.count ? previousSets[prevIndex] : nil
                        )
                    case .superSet(let groupId, let setNumber, let sets):
                        superSetDisplayGroup(groupId: groupId, setNumber: setNumber, sets: sets)
                    }
                }
            } else if previousSets.isEmpty {
                Text("First time doing this lift \u{2014} set a baseline!")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.subtleText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            // Previous-only rows (if previous has more sets than today)
            let todayCount = workoutManager.currentLiftSets.count
            if previousSets.count > todayCount {
                ForEach(todayCount..<previousSets.count, id: \.self) { index in
                    setRow(
                        index: index,
                        todaySet: nil,
                        previousSet: previousSets[index]
                    )
                }
            }

            // Workout elapsed time at the bottom of sets area
            if workoutManager.activeWorkout != nil {
                Divider().background(AppColors.divider)

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
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(16)
        .glassSlab(.rect(cornerRadius: 20))
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
        .padding(.horizontal, 4)
        .glassRow(cornerRadius: 10)
    }

    /// A grouped super set display block: header row + sub-rows per lift.
    private func superSetDisplayGroup(groupId: String, setNumber: Int, sets: [WorkoutSet]) -> some View {
        VStack(spacing: 4) {
            // Header row
            HStack {
                Text("#\(setNumber)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(AppColors.subtleText)

                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 9, weight: .bold))
                    Text("Super Set")
                        .font(.caption.bold())
                }
                .foregroundStyle(AppColors.gold)

                Spacer()

                Button {
                    withAnimation(AppAnimation.quick) {
                        workoutManager.deleteSuperSetGroup(groupId)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.danger)
                        .frame(width: 32, height: 32)
                        .deepGlass(.circle)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            // Sub-rows for each lift in the super set
            ForEach(sets, id: \.timestamp) { set in
                HStack(spacing: 8) {
                    Text(set.liftDefinition?.name ?? "")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.subtleText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Text(set.formattedDisplay)
                        .font(.body.monospacedDigit().bold())
                        .foregroundStyle(AppColors.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .glassRow(cornerRadius: 8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .glassRow(cornerRadius: 10)
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

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }


    // MARK: - Shared Log Action

    /// Handles logging a set with haptic feedback, confirmation animation, and PR detection.
    private func logSetAction() {
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

            // Re-sync wheels after logging (reps may reset)
            if useWheelInput {
                syncWheelsFromInput()
            }
        }
    }

    /// Syncs wheel picker values from workoutManager string inputs.
    private func syncWheelsFromInput() {
        if let weight = Double(workoutManager.weightInput), weight > 0 {
            let options = weightOptions
            if let closest = options.min(by: { abs($0 - weight) < abs($1 - weight) }) {
                wheelWeight = closest
            }
        }
        if let reps = Int(workoutManager.repsInput), reps >= 1, reps <= 99 {
            wheelReps = reps
        } else {
            wheelReps = 8
        }
    }

    /// Formats a weight value for display (no trailing .0).
    private func formatWheelWeight(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
