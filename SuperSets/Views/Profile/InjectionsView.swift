// InjectionsView.swift
// Super Sets — The Workout Tracker
//
// Weekly injection tracker: testosterone, insulin, biologics.
// Shows next-due date, history log, quick-log from previous entries.

import SwiftUI
import SwiftData

// MARK: - InjectionsView

struct InjectionsView: View {

    @Bindable var workoutManager: WorkoutManager

    @Query(sort: \MedicationLog.date, order: .reverse)
    private var allLogs: [MedicationLog]

    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newDosage = ""
    @State private var newFrequency: MedicationFrequency = .weekly
    @State private var newNotes = ""

    private var injectionLogs: [MedicationLog] {
        allLogs.filter { $0.type == .injection }
    }

    private var uniqueInjectionNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for log in injectionLogs {
            if !seen.contains(log.name) {
                seen.insert(log.name)
                result.append(log.name)
            }
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Next due
                if !uniqueInjectionNames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Next Due", icon: "clock.badge.exclamationmark.fill")

                        ForEach(uniqueInjectionNames, id: \.self) { name in
                            if let latest = injectionLogs.first(where: { $0.name == name }) {
                                let nextDue = nextDueDate(for: latest)
                                HStack {
                                    Image(systemName: "syringe.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColors.gold)
                                        .frame(width: 28, height: 28)
                                        .glassGem(.circle)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(latest.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppColors.primaryText)
                                        Text(latest.dosage + " · " + latest.frequency.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(AppColors.subtleText)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(dueLabel(nextDue))
                                            .font(.caption.bold())
                                            .foregroundStyle(isDueOrOverdue(nextDue) ? AppColors.danger : AppColors.accent)
                                        Text(Formatters.shortDate.string(from: nextDue))
                                            .font(.caption2)
                                            .foregroundStyle(AppColors.subtleText)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .deepGlass(.rect(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(16)
                    .glassCard()
                }

                // Quick log
                if !uniqueInjectionNames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Quick Log", icon: "bolt.fill")

                        ForEach(uniqueInjectionNames, id: \.self) { name in
                            if let latest = injectionLogs.first(where: { $0.name == name }) {
                                Button {
                                    quickLog(from: latest)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(latest.name)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(AppColors.primaryText)
                                            Text(latest.dosage)
                                                .font(.caption2)
                                                .foregroundStyle(AppColors.subtleText)
                                        }

                                        Spacer()

                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppColors.accent)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .deepGlass(.rect(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .glassCard()
                }

                // History
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader("History", icon: "clock.fill")

                    if injectionLogs.isEmpty {
                        Text("No injections logged yet")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.subtleText)
                            .padding(.vertical, 16)
                    } else {
                        ForEach(injectionLogs.prefix(20), id: \.date) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                    Text(log.dosage)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.subtleText)
                                }

                                Spacer()

                                if let notes = log.notes, !notes.isEmpty {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppColors.subtleText)
                                }

                                Text(Formatters.shortDate.string(from: log.date))
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.subtleText)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .glassRow(cornerRadius: 10)
                        }
                    }
                }
                .padding(16)
                .glassCard()

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Injections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            addInjectionSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var addInjectionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("e.g. Testosterone Cypionate", text: $newName)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(10)
                            .glassField(cornerRadius: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dosage")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("e.g. 200mg/mL", text: $newDosage)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(10)
                            .glassField(cornerRadius: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        Picker("Frequency", selection: $newFrequency) {
                            ForEach(MedicationFrequency.allCases) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("Injection site, reactions...", text: $newNotes)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(10)
                            .glassField(cornerRadius: 10)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .appBackground()
            .navigationTitle("Log Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveInjection()
                        showingAddSheet = false
                    }
                    .disabled(newName.isEmpty || newDosage.isEmpty)
                }
            }
        }
    }

    private func saveInjection() {
        guard let context = workoutManager.modelContext else { return }
        let log = MedicationLog(
            name: newName,
            dosage: newDosage,
            type: .injection,
            frequency: newFrequency,
            notes: newNotes.isEmpty ? nil : newNotes
        )
        context.insert(log)
        workoutManager.save()
        newName = ""
        newDosage = ""
        newNotes = ""
    }

    private func quickLog(from template: MedicationLog) {
        guard let context = workoutManager.modelContext else { return }
        let log = MedicationLog(
            name: template.name,
            dosage: template.dosage,
            type: .injection,
            frequency: template.frequency
        )
        context.insert(log)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func nextDueDate(for log: MedicationLog) -> Date {
        let calendar = Calendar.current
        switch log.frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: log.date) ?? log.date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: log.date) ?? log.date
        case .asNeeded:
            return log.date
        }
    }

    private func isDueOrOverdue(_ date: Date) -> Bool {
        date <= Date()
    }

    private func dueLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: now, to: due).day ?? 0

        if days < 0 {
            return "\(abs(days))d overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "In \(days) days"
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.gold)
                .frame(width: 26, height: 26)
                .glassGem(.circle)

            Text(title)
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)
        }
    }
}
