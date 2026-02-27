// WorkoutView+SetsView.swift
// Super Sets — The Workout Tracker
//
// Extension: Combined sets view — Today (left) vs Previous (right)
// side-by-side comparison table, set rows, super set display groups,
// End Workout button, and workout elapsed time.

import SwiftUI

// MARK: - WorkoutView + Sets View

extension WorkoutView {

    // MARK: Combined Sets View (Today + Comparison Side-by-Side)

    var combinedSetsView: some View {
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
                .accessibilityLabel("End Workout")
                .accessibilityHint("Saves your workout and shows a summary")
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
                    Text(Formatters.shortDate.string(from: date))
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

    // MARK: Set Row

    /// A single row: Today (left), arrow (center), Previous (right).
    func setRow(index: Int, todaySet: WorkoutSet?, previousSet: WorkoutSet?) -> some View {
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
                        .foregroundStyle(today.isWarmUp ? AppColors.subtleText : AppColors.primaryText)

                    Button {
                        AppAnimation.perform(AppAnimation.quick) {
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

    // MARK: Super Set Display Group

    /// A grouped super set display block: header row + sub-rows per lift.
    func superSetDisplayGroup(groupId: String, setNumber: Int, sets: [WorkoutSet]) -> some View {
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
                    AppAnimation.perform(AppAnimation.quick) {
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

    // MARK: Comparison Arrow

    /// Volume-based comparison: up green, down red, = gray, + extra set.
    @ViewBuilder
    func comparisonArrow(today: WorkoutSet?, previous: WorkoutSet?) -> some View {
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
}
