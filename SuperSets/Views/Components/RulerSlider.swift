// RulerSlider.swift
// Super Sets — The Workout Tracker
//
// Horizontal draggable ruler — tick marks scroll past a fixed center indicator.
// Value animates above. Haptic feedback on each step crossing.

import SwiftUI

struct RulerSlider: View {

    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    var majorTickEvery: Int = 5
    var formatValue: ((Double) -> String)?

    @State private var dragStartValue: Double = 0
    private let tickSpacing: CGFloat = 12
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private var displayValue: String {
        if let formatValue {
            return formatValue(value)
        }
        if step.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Value display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(displayValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: value)
                Text(unit)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
            }

            // Ruler
            GeometryReader { geo in
                let width = geo.size.width
                let centerX = width / 2

                ZStack {
                    // Tick marks canvas
                    Canvas { context, size in
                        let stepsFromMin = (value - range.lowerBound) / step
                        let offsetPx = stepsFromMin * tickSpacing

                        let totalSteps = Int((range.upperBound - range.lowerBound) / step)
                        let visibleRange = Int(size.width / tickSpacing) + 4
                        let centerStep = Int(stepsFromMin)
                        let startStep = max(0, centerStep - visibleRange / 2)
                        let endStep = min(totalSteps, centerStep + visibleRange / 2)

                        for i in startStep...endStep {
                            let tickX = centerX - offsetPx + CGFloat(i) * tickSpacing
                            guard tickX > -tickSpacing && tickX < size.width + tickSpacing else { continue }

                            let isMajor = i % majorTickEvery == 0
                            let tickHeight: CGFloat = isMajor ? 20 : 10
                            let tickColor = isMajor
                                ? Color.white.resolve(in: .init())
                                : Color.gray.resolve(in: .init())

                            let topY = (size.height - tickHeight) / 2
                            var path = Path()
                            path.move(to: CGPoint(x: tickX, y: topY))
                            path.addLine(to: CGPoint(x: tickX, y: topY + tickHeight))
                            context.stroke(
                                path,
                                with: .color(Color(tickColor)),
                                lineWidth: isMajor ? 1.5 : 0.75
                            )
                        }
                    }
                    .frame(height: 28)
                    .contentShape(Rectangle())

                    // Center indicator
                    VStack(spacing: 0) {
                        Triangle()
                            .fill(AppColors.accent)
                            .frame(width: 10, height: 6)
                        Rectangle()
                            .fill(AppColors.accent)
                            .frame(width: 2, height: 28)
                    }
                    .position(x: centerX, y: 17)
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { drag in
                            if drag.translation.width == 0 {
                                dragStartValue = value
                            }
                            let stepsChanged = -drag.translation.width / tickSpacing
                            let newRawValue = dragStartValue + stepsChanged * step
                            let clamped = min(max(newRawValue, range.lowerBound), range.upperBound)
                            let snapped = (clamped / step).rounded() * step

                            if snapped != value {
                                haptic.impactOccurred()
                                value = snapped
                            }
                        }
                )
            }
            .frame(height: 34)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassField(cornerRadius: 12)
    }
}

// Small triangle shape for the center indicator
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
