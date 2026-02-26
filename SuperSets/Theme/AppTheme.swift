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
        Color(light: 0xF0F2F5, dark: 0x0A1929)
    }
    
    static var backgroundMid: Color {
        Color(light: 0xE8EAED, dark: 0x132F4C)
    }
    
    static var backgroundBottom: Color {
        Color(light: 0xD8DADF, dark: 0x1A3A52)
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
        LinearGradient(
            colors: [
                AppColors.backgroundTop,
                AppColors.backgroundMid,
                AppColors.backgroundBottom
            ],
            startPoint: colorScheme == .light ? .top : .topLeading,
            endPoint: colorScheme == .light ? .bottom : .bottomTrailing
        )
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
