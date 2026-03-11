// SuperSetsLiveActivity.swift
// Super Sets — Widget Extension
//
// Live Activity UI for the lock screen and Dynamic Island.
// Lock screen: interactive weight/reps controls + LOG button.
// Dynamic Island expanded: lift name + timer + LOG button.
// Compact / minimal: unchanged (icon + timer).

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct SuperSetsLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // MARK: Lock Screen Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.currentLiftName)
                            .font(.caption.bold())
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "figure.strengthtraining.traditional")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(
                        timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                        countsDown: false
                    )
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 56)
                    .multilineTextAlignment(.trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(context.state.setCount) sets")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        if !context.state.lastSetDisplay.isEmpty {
                            Text(context.state.lastSetDisplay)
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        // LOG from Dynamic Island
                        Button(intent: LogSetIntent()) {
                            Text("LOG")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.orange, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                // MARK: Compact Leading
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                // MARK: Compact Trailing
                Text(
                    timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                    countsDown: false
                )
                .font(.caption.monospacedDigit())
                .frame(width: 40)
                .foregroundStyle(.orange)
            } minimal: {
                // MARK: Minimal
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let increment = context.state.weightIncrement

        VStack(spacing: 8) {
            // Row 1: App name + timer
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("SuperSets")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text(
                    timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                    countsDown: false
                )
                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
            }

            // Row 2: Lift name
            Text(context.state.currentLiftName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Row 3: Weight +/−  ·  Reps +/−  ·  LOG
            HStack(spacing: 10) {
                // Weight controls
                HStack(spacing: 4) {
                    Button(intent: AdjustWeightIntent(delta: -increment)) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text(formatWeight(context.state.pendingWeight))
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 40)

                    Button(intent: AdjustWeightIntent(delta: increment)) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Reps controls
                HStack(spacing: 4) {
                    Button(intent: AdjustRepsIntent(delta: -1)) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Text("\(context.state.pendingReps)")
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 24)

                    Button(intent: AdjustRepsIntent(delta: 1)) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // LOG button
                Button(intent: LogSetIntent()) {
                    Text("LOG")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.orange, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            // Row 4: Set count + last set + SWITCH
            HStack {
                HStack(spacing: 8) {
                    Text("\(context.state.setCount) sets")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))

                    if !context.state.lastSetDisplay.isEmpty {
                        Text("Last: \(context.state.lastSetDisplay)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                if let url = URL(string: "supersets://workout") {
                    Link(destination: url) {
                        Text("SWITCH")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.85))
    }

    // MARK: - Helpers

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}
