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

// MARK: - App Color Palette (Adaptive)

/// Central color definitions for consistent theming.
/// All colors automatically adapt to light/dark mode.
enum AppColors {

    // MARK: Background Colors

    static var backgroundTop: Color {
        Color(light: 0xF5F7FA, dark: 0x060E1A)
    }

    static var backgroundMid: Color {
        Color(light: 0xE0E5EC, dark: 0x0F2744)
    }

    static var backgroundBottom: Color {
        Color(light: 0xC8D0DC, dark: 0x1B3B5A)
    }

    // MARK: Accent Colors (10% — Primary CTAs only)

    static var accent: Color {
        Color(light: 0x1565C0, dark: 0x2196F3)
    }

    static var accentSecondary: Color {
        Color(light: 0x0097A7, dark: 0x00BCD4)
    }

    // MARK: Secondary Colors (30% — Section headers, decorative elements, warm accents)

    /// Warm gold for achievements, secondary accents, section headers.
    static var gold: Color {
        Color(light: 0xC49000, dark: 0xFFD700)
    }

    /// Warm amber for softer secondary indicators.
    static var warmAmber: Color {
        Color(light: 0xB87A1A, dark: 0xF0C040)
    }

    // MARK: Semantic Colors

    /// Green for positive indicators (improved over previous workout).
    static var positive: Color {
        Color(light: 0x2E7D32, dark: 0x4CAF50)
    }

    /// Red for destructive actions and regression indicators.
    static var danger: Color {
        Color(light: 0xC62828, dark: 0xF44336)
    }

    /// Gray for neutral/equal comparisons.
    static var neutral: Color {
        Color(light: 0x757575, dark: 0x9E9E9E)
    }

    // MARK: Text Colors

    /// Primary text — near-black in light, near-white in dark.
    static var primaryText: Color {
        Color(light: 0x1C1E21, dark: 0xE4E6EB)
    }

    /// Secondary/subtle text for labels and hints.
    static var subtleText: Color {
        Color(light: 0x4E4F50, dark: 0xB0B3B8)
    }

    // MARK: Surface & Input Colors

    static var glassBorder: Color {
        Color(light: 0xBFC1C5, dark: 0x1E4976).opacity(0.8)
    }

    static var divider: Color {
        Color(light: 0xDADDE1, dark: 0x1E4976)
    }

    /// Background fill for text input fields.
    /// Light: subtle gray · Dark: subtle white
    static var inputFill: Color {
        Color(light: 0xE4E6EB, dark: 0x1A2A3A)
    }

    /// Border for text input fields.
    static var inputBorder: Color {
        Color(light: 0xCED0D4, dark: 0x2A4A6A)
    }
}

// MARK: - Adaptive Background Gradient (5 Pools)

/// The full-screen gradient behind all content.
/// 5 radial pools create dramatic color shifts as glass refracts over them.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. Base linear gradient
            LinearGradient(
                colors: [
                    AppColors.backgroundTop,
                    AppColors.backgroundMid,
                    AppColors.backgroundBottom
                ],
                startPoint: colorScheme == .light ? .top : .topLeading,
                endPoint: colorScheme == .light ? .bottom : .bottomTrailing
            )

            // 2. Upper-right radial pool — teal/sky (intensified)
            RadialGradient(
                colors: [
                    Color(light: 0xB3D4F0, dark: 0x1A5276)
                        .opacity(colorScheme == .dark ? 0.40 : 0.45),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.15),
                startRadius: 0,
                endRadius: 336
            )

            // 3. Lower-left radial pool — purple/lavender (intensified)
            RadialGradient(
                colors: [
                    Color(light: 0xE0C3F0, dark: 0x2C1654)
                        .opacity(0.33),
                    Color.clear
                ],
                center: UnitPoint(x: 0.15, y: 0.75),
                startRadius: 0,
                endRadius: 300
            )

            // 4. Center-bottom radial pool — emerald/sage (intensified)
            RadialGradient(
                colors: [
                    Color(light: 0xC5E8D5, dark: 0x0B3D2E)
                        .opacity(0.26),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.55),
                startRadius: 0,
                endRadius: 264
            )

            // 5. NEW: Amber/gold pool — warm accent
            RadialGradient(
                colors: [
                    Color(light: 0xF0D9A0, dark: 0x5A4010)
                        .opacity(colorScheme == .dark ? 0.25 : 0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7, y: 0.60),
                startRadius: 0,
                endRadius: 260
            )

            // 6. NEW: Rose/pink pool — soft warmth
            RadialGradient(
                colors: [
                    Color(light: 0xF0C0D0, dark: 0x4A1830)
                        .opacity(colorScheme == .dark ? 0.20 : 0.18),
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
    @Environment(\.colorScheme) private var colorScheme

    private var shadowBase: Double { colorScheme == .dark ? 0.35 : 0.25 }

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
    @Environment(\.colorScheme) private var colorScheme

    private var shadowBase: Double { colorScheme == .dark ? 0.30 : 0.20 }

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
        let haloColor = Color.white.opacity(colorScheme == .dark ? 0.08 : 0.15)
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
    @Environment(\.colorScheme) private var colorScheme

    private var shadowBase: Double { colorScheme == .dark ? 0.30 : 0.20 }

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
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            // Single subtle shadow
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.20 : 0.12), radius: 2, y: 1)
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
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            // Single shadow for subtle lift
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.22 : 0.14), radius: 3, y: 1.5)
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

/// Creates adaptive colors that switch between light and dark mode.
extension Color {
    init(light: UInt, dark: UInt) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:  return UIColor(hex: light)
            case .dark:   return UIColor(hex: dark)
            case .unspecified:
                return UIColor(hex: dark)
            @unknown default: return UIColor(hex: dark)
            }
        })
    }
}

/// UIColor from hex integer.
extension UIColor {
    convenience init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            alpha: opacity
        )
    }
}

// MARK: - Custom Animations

/// Shared animation constants for consistent motion.
enum AppAnimation {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
}
