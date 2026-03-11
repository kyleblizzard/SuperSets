// SuperSetsApp.swift
// Super Sets — The Workout Tracker
//
// The entry point of the application. This is the first code that runs
// when the user opens the app.
//
// LEARNING NOTE:
// @main tells Swift "this is where the app starts." There can only be ONE
// @main attribute in the entire project.
//
// The App protocol requires a `body` property that returns a Scene.
// WindowGroup is the standard scene for iOS apps — it creates a single
// window that fills the screen.
//
// .modelContainer(for:) sets up the SwiftData database and makes it
// available to every view in the app via @Environment(\.modelContext).
// We list ALL our @Model types here so SwiftData creates tables for each.

import SwiftUI
import SwiftData

// MARK: - App Entry Point

@main
struct SuperSetsApp: App {

    let container: ModelContainer
    @State private var healthKitManager = HealthKitManager()

    init() {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration()
        do {
            container = try ModelContainer(
                for: schema,
                migrationPlan: SuperSetsMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitManager)
                .onAppear {
                    healthKitManager.setup(context: container.mainContext)
                    Task { await healthKitManager.requestAuthorization() }
                }
                .onOpenURL { url in
                    // Deep link from Live Activity — just opens the app to the workout screen.
                    // The app is already showing the workout view by default.
                }
        }
        .modelContainer(container)
    }
}
