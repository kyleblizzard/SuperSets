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
import UserNotifications

// MARK: - Notification Delegate

/// Handles actionable notification responses for the workout inactivity reminder.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var workoutManager: WorkoutManager?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.categoryIdentifier == "WORKOUT_INACTIVITY" {
            workoutManager?.handleInactivityAction(response.actionIdentifier)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - App Entry Point

@main
struct SuperSetsApp: App {

    let container: ModelContainer
    let notificationDelegate = NotificationDelegate()
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

        // Register notification category with actionable buttons
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate

        let endAction = UNNotificationAction(
            identifier: "END_WORKOUT",
            title: "End Workout",
            options: .destructive
        )
        let keepAction = UNNotificationAction(
            identifier: "KEEP_GOING",
            title: "Keep Going"
        )
        let category = UNNotificationCategory(
            identifier: "WORKOUT_INACTIVITY",
            actions: [endAction, keepAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    var body: some Scene {
        WindowGroup {
            ContentView(notificationDelegate: notificationDelegate)
                .environment(healthKitManager)
                .onAppear {
                    healthKitManager.setup(context: container.mainContext)
                    Task { await healthKitManager.requestAuthorization() }
                }
        }
        .modelContainer(container)
    }
}
