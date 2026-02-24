//
//  ContentView.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  The root view of the app. Contains a custom liquid glass tab bar at the bottom
//  and switches between three main views: Workout, Calendar, and Profile.

import SwiftUI
import SwiftData

struct ContentView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    // LEARNING NOTE: @State creates mutable state that SwiftUI watches for changes
    @State private var selectedTab: AppTab = .workout
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LiquidGlassBackground()
            
            // Main content based on selected tab
            Group {
                switch selectedTab {
                case .workout:
                    WorkoutView()
                case .calendar:
                    CalendarView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom glass tab bar at the bottom
            VStack {
                Spacer()
                GlassTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - App Tab Enum

/// The three main tabs in the app
enum AppTab: String, CaseIterable {
    case workout
    case calendar
    case profile
    
    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .calendar: return "Calendar"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .workout: return "dumbbell.fill"
        case .calendar: return "calendar"
        case .profile: return "person.circle.fill"
        }
    }
}

// MARK: - Glass Tab Bar

/// Custom liquid glass tab bar
struct GlassTabBar: View {
    
    // LEARNING NOTE: @Binding creates a two-way connection to the parent's @State
    @Binding var selectedTab: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.liquidGlass) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.title2)
                        
                        Text(tab.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .liquidGlassPanel()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ], inMemory: true)
}
