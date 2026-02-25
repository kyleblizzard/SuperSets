// ContentView.swift
// Super Sets — The Workout Tracker
//
// The root view of the app. Uses iOS 26's native TabView which automatically
// gets Liquid Glass styling on the tab bar.
//
// v1.1 UPDATE: Replaced the custom glass tab bar (~120 lines) with native
// TabView. iOS 26's TabView automatically receives Liquid Glass treatment —
// real lensing, specular highlights, and proper system integration.
//
// LEARNING NOTE:
// In iOS 26, standard system components (TabView, NavigationStack toolbars,
// search bars) automatically get Liquid Glass. Building custom versions
// loses these benefits: accessibility, haptics, VoiceOver, and the actual
// lensing/refraction effects that only the system can render.
//
// The Tab() initializer (iOS 26+) replaces the old .tabItem {} approach.
// .tabBarMinimizeBehavior(.onScrollDown) collapses the tab bar when the
// user scrolls, giving more screen space for workout content.

import SwiftUI
import SwiftData

// MARK: - ContentView

struct ContentView: View {
    
    // MARK: Environment
    
    /// SwiftData's model context, injected by the App's modelContainer.
    @Environment(\.modelContext) private var modelContext
    
    // MARK: State
    
    /// The shared WorkoutManager that all child views use.
    @State private var workoutManager = WorkoutManager()
    
    /// The shared TimerManager for the rest timer.
    @State private var timerManager = TimerManager()
    
    /// Tracks first appearance for one-time setup.
    @State private var hasAppeared = false
    
    // MARK: Body
    
    var body: some View {
        TabView {
            // LEARNING NOTE:
            // Tab() is the iOS 26 way to define tabs. Each Tab gets a label,
            // an SF Symbol icon, and its content view. The tab bar automatically
            // receives Liquid Glass styling — no custom implementation needed.
            
            Tab("Workout", systemImage: "dumbbell.fill") {
                WorkoutView(workoutManager: workoutManager, timerManager: timerManager)
                    .appBackground()
            }
            
            Tab("Calendar", systemImage: "calendar") {
                CalendarView(workoutManager: workoutManager)
                    .appBackground()
            }
            
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                ProgressDashboardView(workoutManager: workoutManager)
                    .appBackground()
            }
            
            Tab("Profile", systemImage: "person.fill") {
                ProfileView(workoutManager: workoutManager)
                    .appBackground()
            }
        }
        // LEARNING NOTE:
        // .tabBarMinimizeBehavior(.onScrollDown) makes the tab bar collapse
        // into a small floating pill when the user scrolls down, giving more
        // screen real estate for workout content. Tap the pill to expand it back.
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppColors.accent)
        .preferredColorScheme(colorScheme)
        .onAppear {
            // LEARNING NOTE:
            // .onAppear runs every time the view appears, but we only want
            // to initialize WorkoutManager once. The flag prevents re-init.
            if !hasAppeared {
                workoutManager.setup(context: modelContext)
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Theme
    
    /// Returns the color scheme based on user preference.
    private var colorScheme: ColorScheme? {
        guard let theme = workoutManager.userProfile?.preferredTheme else {
            return nil
        }
        switch theme {
        case .dark:  return .dark
        case .light: return .light
        }
    }
}
