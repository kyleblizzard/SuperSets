// AnatomyFigureView.swift
// Super Sets — The Workout Tracker
//
// Interactive front/back muscle anatomy figure for the lift picker.
// Tapping a muscle group selects it; muscles trained today glow gold.
// Front/back toggle with 3D flip animation.

import SwiftUI

// MARK: - AnatomyFigureView

struct AnatomyFigureView: View {

    let trainedMuscleGroups: Set<MuscleGroup>
    let onSelectGroup: (MuscleGroup) -> Void

    @State private var currentSide: AnatomySide = .front
    @State private var flipAngle: Double = 0
    @State private var isFlipping = false

    var body: some View {
        VStack(spacing: 16) {
            sideToggle
            figureCanvas
            activityPills
        }
    }

    // MARK: - Side Toggle

    private var sideToggle: some View {
        HStack(spacing: 0) {
            toggleButton("Front", side: .front)
            toggleButton("Back", side: .back)
        }
        .padding(3)
        .glassSlab(.capsule)
        .frame(width: 180)
    }

    private func toggleButton(_ title: String, side: AnatomySide) -> some View {
        Button {
            guard currentSide != side, !isFlipping else { return }
            flipToSide(side)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(currentSide == side ? AppColors.gold : AppColors.subtleText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    if currentSide == side {
                        Capsule()
                            .fill(AppColors.gold.opacity(0.15))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flip Animation

    private func flipToSide(_ newSide: AnatomySide) {
        isFlipping = true

        // Phase 1: rotate to edge
        withAnimation(.easeIn(duration: 0.15)) {
            flipAngle = 90
        }

        // Swap side at midpoint, then reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentSide = newSide
            flipAngle = -90

            withAnimation(.easeOut(duration: 0.20)) {
                flipAngle = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                isFlipping = false
            }
        }
    }

    // MARK: - Figure Canvas

    private var figureCanvas: some View {
        GeometryReader { geo in
            let rect = geo.frame(in: .local)
            let patches = AnatomyMusclePaths.patches(for: currentSide, in: rect)

            ZStack {
                // Body outline silhouette
                bodyOutlineLayer(in: rect)

                // Decorative head
                headLayer(in: rect)

                // Tappable muscle patches
                ForEach(patches) { patch in
                    muscleRegion(for: patch)
                }
            }
        }
        .aspectRatio(1.0 / 2.2, contentMode: .fit)
        .frame(maxHeight: 420)
        .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))
        .padding(.horizontal, 40)
    }

    // MARK: - Body Outline

    private func bodyOutlineLayer(in rect: CGRect) -> some View {
        let outline = AnatomyMusclePaths.bodyOutline(side: currentSide, in: rect)
        return outline
            .fill(Color.white.opacity(0.06))
            .overlay(outline.stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Head Layer

    private func headLayer(in rect: CGRect) -> some View {
        let head = AnatomyMusclePaths.headShape(in: rect)
        return head
            .fill(Color.white.opacity(0.06))
            .overlay(head.stroke(Color.white.opacity(0.15), lineWidth: 1))
            .allowsHitTesting(false)
    }

    // MARK: - Muscle Region

    private func muscleRegion(for patch: MusclePatch) -> some View {
        let isTrained = trainedMuscleGroups.contains(patch.group)

        return ZStack {
            // Gold glow layer for trained muscles
            if isTrained {
                patch.path
                    .fill(AppColors.gold.opacity(0.35))
                    .blur(radius: 6)
            }

            // Main fill
            patch.path
                .fill(patch.group.accentColor.opacity(isTrained ? 0.80 : 0.50))

            // Stroke
            patch.path
                .stroke(
                    isTrained ? AppColors.gold : Color.white.opacity(0.20),
                    lineWidth: isTrained ? 1.5 : 0.8
                )

            // Label
            Text(patch.group.displayName)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                .position(patch.labelCenter)
                .allowsHitTesting(false)
        }
        .contentShape(patch.path)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onSelectGroup(patch.group)
        }
    }

    // MARK: - Activity Pills (Cardio + Stretching)

    private var activityPills: some View {
        HStack(spacing: 10) {
            activityPill(for: .cardio)
            activityPill(for: .stretching)
        }
        .padding(.horizontal, 40)
    }

    private func activityPill(for group: MuscleGroup) -> some View {
        let isTrained = trainedMuscleGroups.contains(group)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelectGroup(group)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: group.iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(isTrained ? AppColors.gold : AppColors.subtleText)

                Text(group.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(isTrained ? AppColors.gold : AppColors.primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .deepGlass(.capsule)
            .overlay {
                if isTrained {
                    Capsule()
                        .stroke(AppColors.gold.opacity(0.4), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
