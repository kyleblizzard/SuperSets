// MedicationView.swift
// Super Sets — The Workout Tracker
//
// Log medications, supplements, vitamins, and injections.
// Grouped by type with effectiveness rating.

import SwiftUI
import SwiftData

// MARK: - MedicationView

struct MedicationView: View {

    @Bindable var workoutManager: WorkoutManager

    @Query(sort: \MedicationLog.date, order: .reverse)
    private var allLogs: [MedicationLog]

    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newDosage = ""
    @State private var newType: MedicationType = .supplement
    @State private var newFrequency: MedicationFrequency = .daily
    @State private var newRating: Int = 0
    @State private var newNotes = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Quick log for existing meds
                if !uniqueMedNames.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Quick Log", icon: "bolt.fill")

                        ForEach(uniqueMedNames, id: \.self) { name in
                            if let latest = allLogs.first(where: { $0.name == name }) {
                                Button {
                                    quickLog(from: latest)
                                } label: {
                                    HStack {
                                        Image(systemName: latest.type.iconName)
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

                // History grouped by type
                ForEach(MedicationType.allCases) { type in
                    let typeLogs = allLogs.filter { $0.type == type }
                    if !typeLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(type.rawValue + "s", icon: type.iconName)

                            ForEach(typeLogs.prefix(10), id: \.date) { log in
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

                                    if let rating = log.effectivenessRating {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= rating ? "star.fill" : "star")
                                                    .font(.system(size: 8))
                                                    .foregroundStyle(star <= rating ? AppColors.gold : AppColors.subtleText)
                                            }
                                        }
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
                        .padding(16)
                        .glassCard()
                    }
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Medications & Supplements")
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
            addMedicationSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var addMedicationSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("Medication name", text: $newName)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(10)
                            .glassField(cornerRadius: 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dosage")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("e.g. 500mg", text: $newDosage)
                            .font(.body)
                            .foregroundStyle(AppColors.primaryText)
                            .padding(10)
                            .glassField(cornerRadius: 10)
                    }

                    Picker("Type", selection: $newType) {
                        ForEach(MedicationType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Frequency", selection: $newFrequency) {
                        ForEach(MedicationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effectiveness (optional)")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    newRating = star
                                } label: {
                                    Image(systemName: star <= newRating ? "star.fill" : "star")
                                        .font(.title3)
                                        .foregroundStyle(star <= newRating ? AppColors.gold : AppColors.subtleText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.subtleText)
                        TextField("Side effects, observations...", text: $newNotes)
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
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                        showingAddSheet = false
                    }
                    .disabled(newName.isEmpty || newDosage.isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        guard let context = workoutManager.modelContext else { return }
        let log = MedicationLog(
            name: newName,
            dosage: newDosage,
            type: newType,
            frequency: newFrequency,
            effectivenessRating: newRating > 0 ? newRating : nil,
            notes: newNotes.isEmpty ? nil : newNotes
        )
        context.insert(log)
        workoutManager.save()
        newName = ""
        newDosage = ""
        newRating = 0
        newNotes = ""
    }

    private func quickLog(from template: MedicationLog) {
        guard let context = workoutManager.modelContext else { return }
        let log = MedicationLog(
            name: template.name,
            dosage: template.dosage,
            type: template.type,
            frequency: template.frequency
        )
        context.insert(log)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var uniqueMedNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for log in allLogs {
            if !seen.contains(log.name) {
                seen.insert(log.name)
                result.append(log.name)
            }
        }
        return result
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
