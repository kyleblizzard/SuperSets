// SwipeRating.swift
// Super Sets — The Workout Tracker
//
// Drag finger across stars to rate. Stars fill/empty as you go.
// Tapping a star also works.

import SwiftUI

struct SwipeRating: View {

    @Binding var rating: Int
    var maxRating: Int = 5

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 8) {
                ForEach(1...maxRating, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(star <= rating ? AppColors.gold : AppColors.subtleText)
                        .scaleEffect(star == rating ? 1.3 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: rating)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let starWidth = geo.size.width / CGFloat(maxRating)
                        let newRating = max(1, min(maxRating, Int(drag.location.x / starWidth) + 1))
                        if newRating != rating {
                            haptic.impactOccurred()
                            rating = newRating
                        }
                    }
            )
        }
        .frame(height: 36)
    }
}
