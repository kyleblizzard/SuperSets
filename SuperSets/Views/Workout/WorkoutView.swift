// WorkoutView.swift
// Super Sets — The Workout Tracker
//
// The main workout tracking screen — the heart of the app.
// Layout from top to bottom:
//   1. Top buttons row — Add Lift (left), unit label (center), Super Set (right)
//   2. Rotary lift ring — 10 glass circles that spin like a revolver cylinder
//   3. Combined sets view — Today (left) vs Previous (right) side-by-side
//      with workout elapsed time at the bottom
//   4. End Workout button
//
// v2.0 — 10x LIQUID GLASS: Glass fields, glass rows, glass slab containers,
// centered rest timer as standalone element, workout time moved to bottom
// of sets comparison area.
//
// Extensions in separate files:
//   WorkoutView+Ring.swift       — Rotary ring, drag gesture, ring math, top buttons
//   WorkoutView+CenterInput.swift — Weight/reps input, LOG button, timer panel
//   WorkoutView+SuperSet.swift   — Super set cycle-through panel
//   WorkoutView+SetsView.swift   — Sets comparison table, set rows, End Workout

import SwiftUI
import SwiftData

// MARK: - WorkoutView

struct WorkoutView: View {

    // MARK: Dependencies

    @Bindable var workoutManager: WorkoutManager
    var timerManager: TimerManager

    // MARK: State

    @FocusState var isInputFocused: Bool
    @State var showingLiftLibrary = false
    @State var showingSplits = false
    @State var showingEndConfirmation = false
    @State var showingSummary = false
    @State var completedWorkout: Workout?
    @State var endNotes = ""
    @State var showSetLogged = false
    @State var showPRBadge = false
    @State var prType: PRType?

    // MARK: Slot Machine State

    @State var wheelWeight: Double = 135.0
    @State var wheelReps: Int = 8

    // MARK: Super Set State

    /// Index of the lift currently being edited in the SS cycle-through panel.
    @State var superSetInputIndex: Int = 0
    /// Per-lift wheel weight values keyed by lift name.
    @State var superSetWheelWeights: [String: Double] = [:]
    /// Per-lift wheel reps values keyed by lift name.
    @State var superSetWheelReps: [String: Int] = [:]

    // MARK: Inline Set Editing State

    /// ID of the set currently being edited inline (nil = no editing).
    @State var editingSetId: String? = nil
    /// Editing fields for inline set editing.
    @State var editWeight = ""
    @State var editReps = ""
    @State var editIsWarmUp = false
    @State var editToFailure = false
    @State var editTechnique: IntensityTechnique? = nil

    // MARK: Timer State

    /// When true, the center panel shows the rest timer instead of weight/reps input.
    @State var showTimerInCenter: Bool = false

    // MARK: Rotary Ring State

    /// Accumulated rotation angle in degrees. Each slot = 36 degrees.
    @State var ringRotation: Double = 0
    /// Rotation value when the drag gesture started.
    @State var dragStartRotation: Double = 0
    /// Whether a drag gesture is currently active.
    @State var isDragging: Bool = false
    /// Finger angle (in radians) at the start of the drag.
    @State var dragStartAngle: Double = 0
    /// Last slot index the finger crossed (for haptic detent clicks).
    @State var lastDetentSlot: Int = 0

    // MARK: Ring Momentum State

    @State var coastingTask: Task<Void, Never>? = nil
    @State var isCoasting: Bool = false
    @State var angleSamples: [(time: TimeInterval, angle: Double)] = []
    @State var coastHapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: Layout State

    /// Available width from GeometryReader, drives responsive ring sizing.
    @State var availableWidth: CGFloat = 320

    // MARK: Ring Dimensions (computed from available width)

    var ringSize: CGFloat { min(availableWidth, 380) }
    var ringRadius: CGFloat { ringSize * 0.42 }
    var circleSize: CGFloat { ringSize * 0.19 }
    var centerSize: CGFloat { ringSize * 0.5 }
    /// Number of lift slots on the ring, derived from WorkoutManager constant.
    var slotCount: Int { WorkoutManager.ringSlotCount }
    /// Degrees per slot: 360 / slotCount.
    var slotAngle: Double { 360.0 / Double(slotCount) }

    /// Whether to use scroll wheel (slot machine) input vs keyboard text fields.
    var useWheelInput: Bool {
        workoutManager.userProfile?.useScrollWheelInput ?? true
    }

    /// Weight options for the wheel picker, based on preferred unit.
    var weightOptions: [Double] {
        let unit = workoutManager.userProfile?.preferredUnit ?? .lbs
        switch unit {
        case .lbs: return stride(from: 0.0, through: 500.0, by: 2.5).map { $0 }
        case .kg: return stride(from: 0.0, through: 250.0, by: 1.0).map { $0 }
        }
    }

    /// Unit label string for display.
    var unitLabel: String {
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
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { availableWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, newWidth in
                            availableWidth = newWidth
                        }
                }
            }
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
        .sheet(isPresented: $showingSplits) {
            WorkoutSplitsView(workoutManager: workoutManager)
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
                AppAnimation.perform(AppAnimation.spring) {
                    ringRotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if let first = workoutManager.recentLifts.first {
                        workoutManager.selectLift(first)
                    }
                }
            }
        }
        .onDisappear {
            coastingTask?.cancel()
            coastingTask = nil
        }
    }

    // MARK: - Helpers

    func twoWordName(_ name: String) -> String {
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

    func angleDifference(_ a: Double, _ b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }

    /// Formats a weight value for display (no trailing .0).
    func formatWheelWeight(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
