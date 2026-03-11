// WorkoutManager+Scheduling.swift
// Super Sets — The Workout Tracker
//
// Extension: Split schedule CRUD, pattern generation, reminder scheduling.

import Foundation
import SwiftData
import UserNotifications

// MARK: - WorkoutManager + Scheduling

extension WorkoutManager {

    // MARK: Split Schedule CRUD

    /// Fetch all split schedules.
    func allSplitSchedules() -> [SplitSchedule] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<SplitSchedule>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Fetch the active split schedule, if any.
    func activeSplitSchedule() -> SplitSchedule? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<SplitSchedule>(
            predicate: #Predicate<SplitSchedule> { $0.isActive == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    /// Create a new split schedule.
    func createSplitSchedule(name: String, pattern: [SplitDay], reminderEnabled: Bool = false, reminderTime: String = "08:00") {
        guard let context = modelContext else { return }

        // Deactivate existing active schedules
        let existing = allSplitSchedules().filter { $0.isActive }
        for schedule in existing {
            schedule.isActive = false
        }

        let schedule = SplitSchedule(
            name: name,
            pattern: pattern,
            isActive: true,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )
        context.insert(schedule)

        if reminderEnabled {
            scheduleReminders(for: schedule)
        }

        save()
    }

    /// Delete a split schedule.
    func deleteSplitSchedule(_ schedule: SplitSchedule) {
        guard let context = modelContext else { return }
        cancelReminders(for: schedule)
        context.delete(schedule)
        save()
    }

    /// Toggle a schedule's active state.
    func toggleSplitScheduleActive(_ schedule: SplitSchedule) {
        if schedule.isActive {
            schedule.isActive = false
            cancelReminders(for: schedule)
        } else {
            // Deactivate all others
            for s in allSplitSchedules() {
                s.isActive = false
                cancelReminders(for: s)
            }
            schedule.isActive = true
            if schedule.reminderEnabled {
                scheduleReminders(for: schedule)
            }
        }
        save()
    }

    // MARK: Reminders

    /// Schedule local notifications for the next 14 days.
    func scheduleReminders(for schedule: SplitSchedule) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let calendar = Calendar.current

            for dayOffset in 0..<14 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()),
                      let splitDay = schedule.splitDay(for: date),
                      splitDay != .rest else { continue }

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = schedule.reminderHour
                dateComponents.minute = schedule.reminderMinute

                let content = UNMutableNotificationContent()
                content.title = "Time to Train!"
                content.body = "Today's split: \(splitDay.rawValue)"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let id = "split-\(schedule.name)-\(dayOffset)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

                center.add(request)
            }
        }
    }

    /// Cancel pending reminders for a schedule.
    func cancelReminders(for schedule: SplitSchedule) {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<14).map { "split-\(schedule.name)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
