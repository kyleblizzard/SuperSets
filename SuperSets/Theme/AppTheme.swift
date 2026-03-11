// AppTheme.swift
// Super Sets — The Workout Tracker
//
// The visual design system for the entire app. Defines reusable styles,
// colors, and view extensions using Apple's Liquid Glass design language.
//
// v2.0 — 10x LIQUID GLASS: Aqua meets Liquid Glass.
// Every visible surface is sculpted glass floating in luminous light.
// Depth upon depth upon depth. Glass on glass on glass.
//
// MODIFIER HIERARCHY (deepest to lightest):
//   .deepGlass()   — interactive buttons: 3-layer shadows + outer glow + rim + convex + active state
//   .glassSlab()    — thick floating container cards: 4-layer shadow stack + halo + rim + convex + bottom thickness
//   .glassGem()     — small decorative elements: tight 2-layer shadow + rim + subtle convex
//   .glassField()   — text input fields: inverted depression gradient + inverted rim + shadow
//   .glassRow()     — content rows inside slabs: single shadow + rim (depth upon depth)

import SwiftUI

// MARK: - App Color Palette (Dark Only)

/// Central color definitions for consistent theming.
/// Locked to dark mode for maximum Liquid Glass impact.
enum AppColors {

    // MARK: Background Colors

    static let backgroundTop    = Color(hex: 0x060E1A)
    static let backgroundMid    = Color(hex: 0x0F2744)
    static let backgroundBottom = Color(hex: 0x1B3B5A)

    // MARK: Accent Colors (10% — Primary CTAs only)

    static let accent          = Color(hex: 0x2196F3)
    static let accentSecondary = Color(hex: 0x00BCD4)

    // MARK: Secondary Colors (30% — Section headers, decorative elements, warm accents)

    /// Warm gold for achievements, secondary accents, section headers.
    static let gold      = Color(hex: 0xFFD700)

    /// Warm amber for softer secondary indicators.
    static let warmAmber = Color(hex: 0xF0C040)

    // MARK: Semantic Colors

    /// Green for positive indicators (improved over previous workout).
    static let positive = Color(hex: 0x4CAF50)

    /// Red for destructive actions and regression indicators.
    static let danger   = Color(hex: 0xF44336)

    /// Gray for neutral/equal comparisons.
    static let neutral  = Color(hex: 0x9E9E9E)

    // MARK: Text Colors

    /// Primary text — near-white on dark backgrounds.
    static let primaryText = Color(hex: 0xE4E6EB)

    /// Secondary/subtle text for labels and hints.
    static let subtleText  = Color(hex: 0xB0B3B8)

    // MARK: Surface & Input Colors

    static let glassBorder = Color(hex: 0x1E4976).opacity(0.8)
    static let divider     = Color(hex: 0x1E4976)

    /// Background fill for text input fields.
    static let inputFill   = Color(hex: 0x1A2A3A)

    /// Border for text input fields.
    static let inputBorder = Color(hex: 0x2A4A6A)
}

// MARK: - Adaptive Background Gradient (5 Pools)

/// The full-screen gradient behind all content.
/// 6 radial pools create dramatic color shifts as glass refracts over them.
struct AppBackground: View {

    var body: some View {
        ZStack {
            // 1. Base linear gradient
            LinearGradient(
                colors: [
                    AppColors.backgroundTop,
                    AppColors.backgroundMid,
                    AppColors.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 2. Upper-right radial pool — teal/sky
            RadialGradient(
                colors: [
                    Color(hex: 0x1A5276).opacity(0.40),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.15),
                startRadius: 0,
                endRadius: 336
            )

            // 3. Lower-left radial pool — purple/lavender
            RadialGradient(
                colors: [
                    Color(hex: 0x2C1654).opacity(0.33),
                    Color.clear
                ],
                center: UnitPoint(x: 0.15, y: 0.75),
                startRadius: 0,
                endRadius: 300
            )

            // 4. Center-bottom radial pool — emerald/sage
            RadialGradient(
                colors: [
                    Color(hex: 0x0B3D2E).opacity(0.26),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.55),
                startRadius: 0,
                endRadius: 264
            )

            // 5. Amber/gold pool — warm accent
            RadialGradient(
                colors: [
                    Color(hex: 0x5A4010).opacity(0.25),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.60),
                startRadius: 0,
                endRadius: 260
            )

            // 6. Rose/pink pool — soft warmth
            RadialGradient(
                colors: [
                    Color(hex: 0x4A1830).opacity(0.20),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3, y: 0.30),
                startRadius: 0,
                endRadius: 220
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shape Types

/// Shape types shared across glass modifiers.
enum DeepGlassShape {
    case circle
    case capsule
    case rect(cornerRadius: CGFloat)
}

// MARK: - Deep Glass Effect (Interactive Buttons)

/// Full glass depth stack for interactive controls:
/// base Liquid Glass, 3-layer shadows (intensified), outer glow overlay,
/// rim highlight (1pt), inner convex highlight (more pronounced), active glow.
struct DeepGlassModifier: ViewModifier {
    let shape: DeepGlassShape
    var isActive: Bool = false

    private let shadowBase: Double = 0.35

    func body(content: Content) -> some View {
        content
            // 1. Base Liquid Glass
            .modifier(GlassShapeModifier(shape: shape, interactive: true))
            // 2. Contact shadow — tight, close (intensified)
            .shadow(color: .black.opacity(shadowBase), radius: 3, y: 2)
            // 3. Lift shadow — medium spread (intensified)
            .shadow(color: .black.opacity(shadowBase * 0.6), radius: 10, y: 5)
            // 4. Ambient shadow — wide soft halo (intensified)
            .shadow(color: .black.opacity(shadowBase * 0.3), radius: 20, y: 8)
            // 5. Outer glow — light bleeding around glass edge
            .overlay { outerGlow }
            // 6. Rim highlight (1.0pt)
            .overlay { rimHighlight }
            // 7. Inner convex highlight (more pronounced)
            .overlay { innerConvexHighlight }
            // 8. Active state — glow + scale
            .shadow(
                color: isActive ? AppColors.accent.opacity(0.6) : .clear,
                radius: isActive ? 20 : 0
            )
            .shadow(
                color: isActive ? Color.white.opacity(0.25) : .clear,
                radius: isActive ? 8 : 0
            )
            .scaleEffect(isActive ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }

    /// 1.5pt AngularGradient stroke on an outset path — simulates light bleeding around edge.
    @ViewBuilder
    private var outerGlow: some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: .white.opacity(0.25), location: 0.0),
                .init(color: .white.opacity(0.12), location: 0.15),
                .init(color: .clear, location: 0.3),
                .init(color: .clear, location: 0.55),
                .init(color: .white.opacity(0.10), location: 0.7),
                .init(color: .white.opacity(0.20), location: 0.85),
                .init(color: .white.opacity(0.25), location: 1.0)
            ],
            center: .center
        )
        switch shape {
        case .circle:
            Circle().inset(by: -0.75).stroke(gradient, lineWidth: 1.5)
        case .capsule:
            Capsule().inset(by: -0.75).stroke(gradient, lineWidth: 1.5)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).inset(by: -0.75).stroke(gradient, lineWidth: 1.5)
        }
    }

    /// 1.0pt AngularGradient stroke simulating directional light on the glass edge.
    @ViewBuilder
    private var rimHighlight: some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: .white.opacity(0.45), location: 0.0),
                .init(color: .white.opacity(0.25), location: 0.12),
                .init(color: .clear, location: 0.25),
                .init(color: .clear, location: 0.5),
                .init(color: .white.opacity(0.15), location: 0.62),
                .init(color: .white.opacity(0.35), location: 0.75),
                .init(color: .clear, location: 0.88),
                .init(color: .white.opacity(0.45), location: 1.0)
            ],
            center: .center
        )
        switch shape {
        case .circle:
            Circle().stroke(gradient, lineWidth: 1.0)
        case .capsule:
            Capsule().stroke(gradient, lineWidth: 1.0)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).stroke(gradient, lineWidth: 1.0)
        }
    }

    /// LinearGradient overlay faking a curved glass surface catching overhead light.
    @ViewBuilder
    private var innerConvexHighlight: some View {
        let gradient = LinearGradient(
            colors: [
                Color.white.opacity(0.18),
                Color.white.opacity(0.06),
                Color.clear,
                Color.black.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        switch shape {
        case .circle:
            Circle().fill(gradient).allowsHitTesting(false)
        case .capsule:
            Capsule().fill(gradient).allowsHitTesting(false)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).fill(gradient).allowsHitTesting(false)
        }
    }
}

// MARK: - Glass Slab (Thick Floating Container Cards)

/// Non-interactive glass base + 4-layer shadow stack + outer white halo +
/// 1pt AngularGradient rim + inner convex gradient + inner bottom shadow
/// simulating glass thickness.
struct GlassSlabModifier: ViewModifier {
    let shape: DeepGlassShape

    private let shadowBase: Double = 0.30

    func body(content: Content) -> some View {
        content
            // 1. Base Liquid Glass (non-interactive)
            .modifier(GlassShapeModifier(shape: shape, interactive: false))
            // 2. Contact shadow
            .shadow(color: .black.opacity(shadowBase), radius: 3, y: 2)
            // 3. Lift shadow
            .shadow(color: .black.opacity(shadowBase * 0.7), radius: 12, y: 6)
            // 4. Spread shadow
            .shadow(color: .black.opacity(shadowBase * 0.4), radius: 24, y: 10)
            // 5. Atmosphere shadow
            .shadow(color: .black.opacity(shadowBase * 0.2), radius: 40, y: 14)
            // 6. Outer white halo
            .overlay { outerHalo }
            // 7. Rim highlight (1pt AngularGradient)
            .overlay { rimHighlight }
            // 8. Inner convex gradient
            .overlay { innerConvexHighlight }
            // 9. Inner bottom shadow (glass thickness)
            .overlay { innerBottomShadow }
    }

    @ViewBuilder
    private var outerHalo: some View {
        let haloColor = Color.white.opacity(0.08)
        switch shape {
        case .circle:
            Circle().inset(by: -1.5).stroke(haloColor, lineWidth: 3).blur(radius: 2)
        case .capsule:
            Capsule().inset(by: -1.5).stroke(haloColor, lineWidth: 3).blur(radius: 2)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).inset(by: -1.5).stroke(haloColor, lineWidth: 3).blur(radius: 2)
        }
    }

    @ViewBuilder
    private var rimHighlight: some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: .white.opacity(0.35), location: 0.0),
                .init(color: .white.opacity(0.18), location: 0.15),
                .init(color: .clear, location: 0.3),
                .init(color: .clear, location: 0.55),
                .init(color: .white.opacity(0.12), location: 0.7),
                .init(color: .white.opacity(0.28), location: 0.85),
                .init(color: .white.opacity(0.35), location: 1.0)
            ],
            center: .center
        )
        switch shape {
        case .circle:
            Circle().stroke(gradient, lineWidth: 1.0)
        case .capsule:
            Capsule().stroke(gradient, lineWidth: 1.0)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).stroke(gradient, lineWidth: 1.0)
        }
    }

    @ViewBuilder
    private var innerConvexHighlight: some View {
        let gradient = LinearGradient(
            colors: [
                Color.white.opacity(0.14),
                Color.white.opacity(0.04),
                Color.clear,
                Color.black.opacity(0.03)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        switch shape {
        case .circle:
            Circle().fill(gradient).allowsHitTesting(false)
        case .capsule:
            Capsule().fill(gradient).allowsHitTesting(false)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).fill(gradient).allowsHitTesting(false)
        }
    }

    /// Dark gradient at bottom 20% simulating glass thickness.
    @ViewBuilder
    private var innerBottomShadow: some View {
        let gradient = LinearGradient(
            colors: [
                Color.clear,
                Color.clear,
                Color.clear,
                Color.clear,
                Color.black.opacity(0.06),
                Color.black.opacity(0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        switch shape {
        case .circle:
            Circle().fill(gradient).allowsHitTesting(false)
        case .capsule:
            Capsule().fill(gradient).allowsHitTesting(false)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).fill(gradient).allowsHitTesting(false)
        }
    }
}

// MARK: - Glass Gem (Small Decorative Elements)

/// Non-interactive glass base + tight 2-layer shadow + 0.5pt rim + subtle convex.
struct GlassGemModifier: ViewModifier {
    let shape: DeepGlassShape

    private let shadowBase: Double = 0.30

    func body(content: Content) -> some View {
        content
            .modifier(GlassShapeModifier(shape: shape, interactive: false))
            // Tight 2-layer shadow
            .shadow(color: .black.opacity(shadowBase), radius: 2, y: 1)
            .shadow(color: .black.opacity(shadowBase * 0.5), radius: 4, y: 2)
            // 0.5pt rim highlight
            .overlay { rimHighlight }
            // Subtle convex
            .overlay { innerConvexHighlight }
    }

    @ViewBuilder
    private var rimHighlight: some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: .white.opacity(0.30), location: 0.0),
                .init(color: .white.opacity(0.15), location: 0.15),
                .init(color: .clear, location: 0.35),
                .init(color: .clear, location: 0.6),
                .init(color: .white.opacity(0.10), location: 0.75),
                .init(color: .white.opacity(0.25), location: 0.9),
                .init(color: .white.opacity(0.30), location: 1.0)
            ],
            center: .center
        )
        switch shape {
        case .circle:
            Circle().stroke(gradient, lineWidth: 0.5)
        case .capsule:
            Capsule().stroke(gradient, lineWidth: 0.5)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).stroke(gradient, lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var innerConvexHighlight: some View {
        let gradient = LinearGradient(
            colors: [
                Color.white.opacity(0.10),
                Color.white.opacity(0.03),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        switch shape {
        case .circle:
            Circle().fill(gradient).allowsHitTesting(false)
        case .capsule:
            Capsule().fill(gradient).allowsHitTesting(false)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).fill(gradient).allowsHitTesting(false)
        }
    }
}

// MARK: - Glass Field (Text Input Fields)

/// Glass base + inverted gradient (dark top -> light bottom = inset depression) +
/// inverted rim stroke + single shadow. Replaces plain inputFill/inputBorder.
struct GlassFieldModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            // Single subtle shadow
            .shadow(color: .black.opacity(0.20), radius: 2, y: 1)
            // Inverted depression gradient (dark top, light bottom)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.04),
                                Color.clear,
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
            // Inverted rim stroke (darker at top, lighter at bottom)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.clear,
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            }
    }
}

// MARK: - Glass Row (Content Rows Inside Slabs)

/// Glass base + single shadow + 0.5pt rim. Creates depth-upon-depth
/// when sitting inside a slab container.
struct GlassRowModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            // Single shadow for subtle lift
            .shadow(color: .black.opacity(0.22), radius: 3, y: 1.5)
            // 0.5pt rim highlight
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: .white.opacity(0.22), location: 0.0),
                                .init(color: .white.opacity(0.10), location: 0.2),
                                .init(color: .clear, location: 0.4),
                                .init(color: .clear, location: 0.65),
                                .init(color: .white.opacity(0.08), location: 0.8),
                                .init(color: .white.opacity(0.18), location: 1.0)
                            ],
                            center: .center
                        ),
                        lineWidth: 0.5
                    )
            }
    }
}

// MARK: - Glass Shape Helper

/// Helper modifier that applies .glassEffect with the correct shape.
private struct GlassShapeModifier: ViewModifier {
    let shape: DeepGlassShape
    var interactive: Bool = true

    func body(content: Content) -> some View {
        switch shape {
        case .circle:
            if interactive {
                content.glassEffect(.regular.interactive(), in: .circle)
            } else {
                content.glassEffect(.regular, in: .circle)
            }
        case .capsule:
            if interactive {
                content.glassEffect(.regular.interactive(), in: .capsule)
            } else {
                content.glassEffect(.regular, in: .capsule)
            }
        case .rect(let cr):
            if interactive {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cr))
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cr))
            }
        }
    }
}

// MARK: - View Extensions

extension View {

    /// Apply the app's gradient background.
    func appBackground() -> some View {
        self.background { AppBackground() }
    }

    /// Apply a Liquid Glass card effect — now upgraded to full GlassSlab treatment.
    /// All 22+ existing .glassCard() sites get 4-layer shadows, halo, rim, and convex
    /// with zero view-file changes.
    func glassCard() -> some View {
        self.modifier(GlassSlabModifier(shape: .rect(cornerRadius: 16)))
    }

    /// Apply the full deep glass treatment: Liquid Glass + 3-layer shadows +
    /// outer glow + rim highlight + inner convex highlight + optional active glow.
    func deepGlass(_ shape: DeepGlassShape, isActive: Bool = false) -> some View {
        self.modifier(DeepGlassModifier(shape: shape, isActive: isActive))
    }

    /// Thick floating container card with 4-layer shadow stack, halo, rim, convex,
    /// and inner bottom thickness shadow.
    func glassSlab(_ shape: DeepGlassShape) -> some View {
        self.modifier(GlassSlabModifier(shape: shape))
    }

    /// Small decorative glass element with tight 2-layer shadow, rim, and subtle convex.
    func glassGem(_ shape: DeepGlassShape) -> some View {
        self.modifier(GlassGemModifier(shape: shape))
    }

    /// Text input field with inverted depression gradient, inverted rim, and shadow.
    func glassField(cornerRadius: CGFloat = 8) -> some View {
        self.modifier(GlassFieldModifier(cornerRadius: cornerRadius))
    }

    /// Content row floating inside a slab — single shadow + rim for depth-upon-depth.
    func glassRow(cornerRadius: CGFloat = 10) -> some View {
        self.modifier(GlassRowModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Color Extensions

/// Color from hex integer (e.g. 0x2196F3).
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Custom Animations

/// Shared animation constants for consistent motion.
enum AppAnimation {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Wraps `withAnimation`, skipping the animation when Reduce Motion is enabled.
    @MainActor
    static func perform(_ animation: Animation, _ body: () -> Void) {
        if UIAccessibility.isReduceMotionEnabled {
            body()
        } else {
            withAnimation(animation, body)
        }
    }
}
