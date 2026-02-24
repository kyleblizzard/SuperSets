//
//  LiquidGlassStyle.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  Provides reusable view modifiers for the liquid glass design language.
//  Includes frosted glass panels, shadows, gradients, and spring animations
//  that create the modern, immersive UI throughout the app.

import SwiftUI

// MARK: - Liquid Glass Panel Modifier

/// Applies the liquid glass visual style to any view
// LEARNING NOTE: ViewModifier is a protocol that lets us create reusable
// view transformations. This is more powerful than just functions.
struct LiquidGlassPanelModifier: ViewModifier {
    
    /// Optional accent color for the glass tint
    var accentColor: Color?
    
    func body(content: Content) -> some View {
        content
            .background {
                // LEARNING NOTE: ZStack layers views on top of each other
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle white gradient overlay for extra gloss
                    if let accent = accentColor {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(0.3),
                                        accent.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

// MARK: - View Extension

extension View {
    /// Applies liquid glass panel styling
    /// - Parameter accentColor: Optional tint color for the glass
    /// - Returns: Modified view with glass effect
    func liquidGlassPanel(accentColor: Color? = nil) -> some View {
        modifier(LiquidGlassPanelModifier(accentColor: accentColor))
    }
}

// MARK: - Spring Animation

extension Animation {
    /// The standard spring animation used throughout the app
    // LEARNING NOTE: static let creates a reusable constant we can access anywhere
    static let liquidGlass = Animation.spring(
        response: 0.35,
        dampingFraction: 0.7
    )
}

// MARK: - Background Gradient

/// The app's signature deep navy/purple gradient background
struct LiquidGlassBackground: View {
    var body: some View {
        // LEARNING NOTE: LinearGradient creates a smooth color transition
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),  // Deep navy
                Color(red: 0.15, green: 0.1, blue: 0.25), // Navy-purple
                Color(red: 0.2, green: 0.1, blue: 0.3)    // Purple
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Glass Button Style

/// Button style for lift circle buttons and other glass buttons
struct GlassButtonStyle: ButtonStyle {
    
    var accentColor: Color?
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    
                    if let accent = accentColor {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(isSelected ? 0.6 : 0.3),
                                        accent.opacity(isSelected ? 0.3 : 0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    if isSelected {
                        Circle()
                            .stroke(accentColor ?? .white, lineWidth: 2)
                    }
                }
            }
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            // LEARNING NOTE: scaleEffect creates a press-down animation
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.liquidGlass, value: configuration.isPressed)
    }
}

// MARK: - Primary Action Button Style

/// Button style for primary actions (Log Set, Start Workout, etc.)
struct PrimaryActionButtonStyle: ButtonStyle {
    
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.gradient)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.liquidGlass, value: configuration.isPressed)
    }
}

// MARK: - Monospaced Number Style

extension View {
    /// Formats numbers with monospaced digits (for timer display)
    func monospacedDigit() -> some View {
        self.font(.system(.body, design: .monospaced))
    }
}
