//
//  Super_SetsApp.swift
//  Super Sets
//
//  Created by bliz on 2/20/26.
//
//  WHAT THIS FILE DOES:
//  The entry point of the app. Sets up SwiftData model container with all our models,
//  seeds the database with pre-loaded lifts on first launch, and displays the root ContentView.

import SwiftUI
import SwiftData

@main
struct Super_SetsApp: App {
    
    // MARK: - SwiftData Container Setup
    
    // LEARNING NOTE: This creates the SwiftData container that manages our database.
    // It's declared as a stored property so it persists for the app's lifetime.
    var sharedModelContainer: ModelContainer = {
        // Define all the model types we want to persist
        let schema = Schema([
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self
        ])
        
        // Configure where and how data is stored
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // false = persist to disk
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Seed the database with pre-loaded lifts on first launch
            // LEARNING NOTE: @MainActor ensures this runs on the main thread
            Task { @MainActor in
                PreloadedLifts.seedIfNeeded(modelContext: container.mainContext)
            }
            
            return container
        } catch {
            // LEARNING NOTE: fatalError stops the app. Only use for unrecoverable errors.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - App Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // LEARNING NOTE: .modelContainer makes SwiftData available throughout the view hierarchy
        .modelContainer(sharedModelContainer)
    }
}
