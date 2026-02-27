// WorkoutView+Ring.swift
// Super Sets — The Workout Tracker
//
// Extension: Rotary lift ring — 10 glass circles that spin like a
// revolver cylinder. Includes ring math, drag gesture, lift circles,
// and the top buttons row (Add Lift + Super Set toggle).

import SwiftUI

// MARK: - WorkoutView + Ring

extension WorkoutView {

    // MARK: Rotary Ring Math

    func angleForSlot(_ index: Int) -> Angle {
        .degrees(-90 + Double(index) * slotAngle + ringRotation)
    }

    var topSlotIndex: Int {
        let normalized = (-ringRotation).truncatingRemainder(dividingBy: 360)
        let positive = normalized < 0 ? normalized + 360 : normalized
        let raw = Int(round(positive / slotAngle)) % slotCount
        return raw
    }

    func snapToNearestSlot() {
        let nearest = (ringRotation / slotAngle).rounded() * slotAngle
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        if reduceMotion {
            ringRotation = nearest
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                ringRotation = nearest
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.35)) {
            selectLiftAtTop()
        }
    }

    func animateToSlot(_ index: Int) {
        let target = -Double(index) * slotAngle
        var delta = target - ringRotation
        delta = delta.truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        if reduceMotion {
            ringRotation += delta
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                ringRotation += delta
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.4)) {
            selectLiftAtTop()
        }
    }

    func selectLiftAtTop() {
        // Don't change selected lift while building a super set
        guard !workoutManager.isSuperSetMode else { return }
        let idx = topSlotIndex
        if idx < workoutManager.recentLifts.count {
            workoutManager.selectLift(workoutManager.recentLifts[idx])
        }
    }

    // MARK: Drag Gesture

    var ringDragGesture: some Gesture {
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

    // MARK: Radial Lift Ring

    var radialLiftRing: some View {
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Exercise ring")
        .accessibilityHint("Drag to spin and select an exercise. \(workoutManager.recentLifts.count) exercises loaded.")
        .overlay {
            // First-time hint when the ring is empty
            if workoutManager.recentLifts.isEmpty {
                firstTimeHintOverlay
            }
        }
    }

    // MARK: First-Time Hint Overlay

    /// Shown when the ring is empty — guides new users to add their first lift.
    var firstTimeHintOverlay: some View {
        VStack(spacing: 12) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.accent)

                Text("Tap \"Add Lift\" or \"Quick\"\nto get started!")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Your exercises will appear\non the ring")
                    .font(.caption)
                    .foregroundStyle(AppColors.subtleText)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .glassSlab(.rect(cornerRadius: 16))

            Spacer()
            Spacer()
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: Top Buttons Row

    /// Top row: Add Lift + Quick Pick (left), unit label (center), Super Set (right).
    var topButtonsRow: some View {
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
            .accessibilityLabel("Add Lift")
            .accessibilityHint("Opens the exercise library to add a new lift to your ring")

            // Quick picker — searchable list
            Button {
                showingQuickPicker = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 14, weight: .bold))
                    Text("Quick")
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundStyle(AppColors.accent)
                .frame(width: 50, height: 50)
                .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quick Pick")
            .accessibilityHint("Opens a searchable list to quickly add an exercise")

            // Splits — load workout templates
            Button {
                showingSplits = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 14, weight: .bold))
                    Text("Splits")
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundStyle(AppColors.accent)
                .frame(width: 50, height: 50)
                .deepGlass(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Workout Splits")
            .accessibilityHint("Load or manage workout split templates")

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
                AppAnimation.perform(AppAnimation.spring) {
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
            .accessibilityLabel(workoutManager.isSuperSetMode ? "Exit Super Set mode" : "Super Set mode")
            .accessibilityHint("Group multiple exercises to log them together")
        }
    }

    // MARK: Lift Circle

    /// A lift circle on the ring.
    func radialLiftCircle(for lift: LiftDefinition, size: CGFloat, isTop: Bool, inSuperSet: Bool = false) -> some View {
        Text(twoWordName(lift.name))
            .font(.system(size: 9, weight: .semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .foregroundStyle(inSuperSet ? AppColors.gold : (isTop ? AppColors.accent : AppColors.primaryText))
            .frame(width: size, height: size)
            .deepGlass(.circle, isActive: isTop || inSuperSet)
            .accessibilityLabel(lift.name)
            .accessibilityValue(isTop ? "Selected" : (inSuperSet ? "In super set" : ""))
    }
}
