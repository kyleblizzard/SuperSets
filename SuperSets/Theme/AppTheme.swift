// AppTheme.swift
// Super Sets — The Workout Tracker
//
// The visual design system for the entire app. Defines reusable styles,
// colors, and view extensions using Apple's Liquid Glass design language.
//
// v1.1 UPDATE: Migrated from .ultraThinMaterial to real .glassEffect() API.
// Added adaptive inputFill/inputBorder colors for light mode support.
//
// LEARNING NOTE:
// Liquid Glass is Apple's iOS 26 material that uses real-time lensing
// (bending light, not just blurring), specular highlights responding to
// device motion, and adaptive shadows. The key API is .glassEffect() —
// NOT .ultraThinMaterial or .regularMaterial (those are the old blur-based system).
//
// IMPORTANT DESIGN RULE: Glass is ONLY for the navigation/control layer
// (buttons, toolbars, input panels). NEVER apply glass to content
// (lists, tables, text blocks). Content should sit on the background directly.

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
    
    // MARK: Accent Colors
    
    static var accent: Color {
        Color(light: 0x1565C0, dark: 0x2196F3)
    }
    
    static var accentSecondary: Color {
        Color(light: 0x0097A7, dark: 0x00BCD4)
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

// MARK: - Adaptive Background Gradient

/// The full-screen gradient behind all content.
/// Liquid Glass refracts whatever is behind it, so this gradient
/// subtly shows through glass elements — that's intentional.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. Base linear gradient — higher contrast between stops
            LinearGradient(
                colors: [
                    AppColors.backgroundTop,
                    AppColors.backgroundMid,
                    AppColors.backgroundBottom
                ],
                startPoint: colorScheme == .light ? .top : .topLeading,
                endPoint: colorScheme == .light ? .bottom : .bottomTrailing
            )

            // 2. Upper-right radial pool — teal/sky
            RadialGradient(
                colors: [
                    Color(light: 0xB3D4F0, dark: 0x1A5276)
                        .opacity(colorScheme == .dark ? 0.30 : 0.35),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.15),
                startRadius: 0,
                endRadius: 280
            )

            // 3. Lower-left radial pool — purple/lavender
            RadialGradient(
                colors: [
                    Color(light: 0xE0C3F0, dark: 0x2C1654)
                        .opacity(0.25),
                    Color.clear
                ],
                center: UnitPoint(x: 0.15, y: 0.75),
                startRadius: 0,
                endRadius: 250
            )

            // 4. Center-bottom radial pool — emerald/sage
            RadialGradient(
                colors: [
                    Color(light: 0xC5E8D5, dark: 0x0B3D2E)
                        .opacity(0.20),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.55),
                startRadius: 0,
                endRadius: 220
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply the app's gradient background.
    func appBackground() -> some View {
        self.background { AppBackground() }
    }
    
    /// Apply a Liquid Glass card effect with rounded corners.
    ///
    /// LEARNING NOTE:
    /// This is the REAL iOS 26 .glassEffect() API. Unlike the old
    /// .ultraThinMaterial (which just blurs), .glassEffect() creates
    /// true optical refraction — bending light, specular highlights
    /// from device motion, and automatic light/dark adaptation.
    ///
    /// .regular = standard glass for most UI (toolbars, cards, controls)
    /// .clear = higher transparency for small controls over media
    /// .identity = no effect (for conditional toggling)
    func glassCard() -> some View {
        self.glassEffect(.regular, in: .rect(cornerRadius: 16))
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
///
/// LEARNING NOTE:
/// Spring animations feel more natural than linear/easeInOut because
/// they mimic physics. `response` = speed (lower = faster),
/// `dampingFraction` = bounce (lower = bouncier, 1.0 = no bounce).
enum AppAnimation {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

// MARK: - Deep Glass Effect

/// Shape types for the deep glass modifier.
enum DeepGlassShape {
    case circle
    case capsule
    case rect(cornerRadius: CGFloat)
}

/// A ViewModifier that wraps any view with the full glass depth stack:
/// base Liquid Glass, 3-layer shadows, rim highlight, inner convex highlight,
/// and an active glow state.
struct DeepGlassModifier: ViewModifier {
    let shape: DeepGlassShape
    var isActive: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    // Shadow opacity adapts to color scheme (slightly stronger in dark)
    private var shadowBase: Double { colorScheme == .dark ? 0.35 : 0.25 }

    func body(content: Content) -> some View {
        content
            // 1. Base Liquid Glass
            .modifier(GlassShapeModifier(shape: shape))
            // 2. Contact shadow — tight, close
            .shadow(color: .black.opacity(shadowBase), radius: 2, y: 1)
            // 3. Lift shadow — medium spread
            .shadow(color: .black.opacity(shadowBase * 0.6), radius: 8, y: 4)
            // 4. Ambient shadow — wide soft halo
            .shadow(color: .black.opacity(shadowBase * 0.3), radius: 16, y: 6)
            // 5. Rim highlight + 6. Inner convex highlight
            .overlay { rimHighlight }
            .overlay { innerConvexHighlight }
            // 7. Active state — glow + scale
            .shadow(
                color: isActive ? AppColors.accent.opacity(0.5) : .clear,
                radius: isActive ? 16 : 0
            )
            .scaleEffect(isActive ? 1.06 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }

    /// 0.75pt AngularGradient stroke simulating directional light on the glass edge.
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
            Circle().stroke(gradient, lineWidth: 0.75)
        case .capsule:
            Capsule().stroke(gradient, lineWidth: 0.75)
        case .rect(let cr):
            RoundedRectangle(cornerRadius: cr).stroke(gradient, lineWidth: 0.75)
        }
    }

    /// LinearGradient overlay faking a curved glass surface catching overhead light.
    @ViewBuilder
    private var innerConvexHighlight: some View {
        let gradient = LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.04),
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
}

/// Helper modifier that applies .glassEffect with the correct shape.
private struct GlassShapeModifier: ViewModifier {
    let shape: DeepGlassShape

    func body(content: Content) -> some View {
        switch shape {
        case .circle:
            content.glassEffect(.regular.interactive(), in: .circle)
        case .capsule:
            content.glassEffect(.regular.interactive(), in: .capsule)
        case .rect(let cr):
            content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cr))
        }
    }
}

extension View {
    /// Apply the full deep glass treatment: Liquid Glass + 3-layer shadows +
    /// rim highlight + inner convex highlight + optional active glow.
    func deepGlass(_ shape: DeepGlassShape, isActive: Bool = false) -> some View {
        self.modifier(DeepGlassModifier(shape: shape, isActive: isActive))
    }
}
