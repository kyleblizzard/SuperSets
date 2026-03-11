// SuperSetsLiveActivity.swift
// Super Sets — Widget Extension
//
// Live Activity UI for the lock screen and Dynamic Island.
// Shows current lift, set count, last set, and elapsed workout time.

import ActivityKit
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
                        // Set count
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(context.state.setCount) sets")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.white.opacity(0.7))

                        Spacer()

                        // Last set
                        if !context.state.lastSetDisplay.isEmpty {
                            Text(context.state.lastSetDisplay)
                                .font(.caption.monospacedDigit().bold())
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        // Open app button
                        if let url = URL(string: "supersets://workout") {
                            Link(destination: url) {
                                Text("LOG")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange, in: Capsule())
                            }
                        }
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
        HStack(spacing: 12) {
            // Left: Lift icon + name
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("SuperSets")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(context.state.currentLiftName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(context.state.setCount) sets")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))

                    if !context.state.lastSetDisplay.isEmpty {
                        Text(context.state.lastSetDisplay)
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            // Right: Timer + LOG button
            VStack(alignment: .trailing, spacing: 6) {
                Text(
                    timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                    countsDown: false
                )
                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)

                if let url = URL(string: "supersets://workout") {
                    Link(destination: url) {
                        Text("LOG")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.orange, in: Capsule())
                    }
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.85))
    }
}
