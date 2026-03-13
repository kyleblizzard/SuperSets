// FoodTrackingView.swift
// Super Sets — The Workout Tracker
//
// Daily food and macro tracking with progress rings,
// quick-log for previously eaten foods, and preset food database.

import SwiftUI
import SwiftData

// MARK: - FoodTrackingView

struct FoodTrackingView: View {

    @Bindable var workoutManager: WorkoutManager
    @State private var showingAddSheet = false

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var allEntries: [FoodEntry]

    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDateInToday($0.date) }
    }

    private var todayCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }

    private var todayProtein: Double {
        todayEntries.reduce(0) { $0 + $1.protein }
    }

    private var todayCarbs: Double {
        todayEntries.reduce(0) { $0 + $1.carbs }
    }

    private var todayFat: Double {
        todayEntries.reduce(0) { $0 + $1.fat }
    }

    private var profile: UserProfile? {
        workoutManager.userProfile
    }

    private var calorieGoal: Int {
        profile?.effectiveCalorieGoal ?? 2200
    }

    private var proteinGoal: Double {
        profile?.effectiveProteinGoal ?? 165
    }

    private var carbsGoal: Double {
        profile?.effectiveCarbsGoal ?? 220
    }

    private var fatGoal: Double {
        profile?.effectiveFatGoal ?? 73
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ringsSection
                quickLogSection
                todayLogSection
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Food Tracking")
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
            AddFoodSheet(workoutManager: workoutManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Rings Section

    private var ringsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Today's Nutrition", icon: "fork.knife")

            // Calorie ring
            ZStack {
                Circle()
                    .stroke(AppColors.subtleText.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: calorieProgress)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: calorieProgress)

                VStack(spacing: 4) {
                    Text("\(todayCalories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                    Text("/ \(calorieGoal) cal")
                        .font(.caption)
                        .foregroundStyle(AppColors.subtleText)
                }
            }
            .frame(width: 160, height: 160)

            // Macro mini-rings
            HStack(spacing: 20) {
                macroRing(
                    label: "Protein",
                    current: todayProtein,
                    goal: proteinGoal,
                    color: AppColors.positive
                )
                macroRing(
                    label: "Carbs",
                    current: todayCarbs,
                    goal: carbsGoal,
                    color: Color(hex: 0x42A5F5)
                )
                macroRing(
                    label: "Fat",
                    current: todayFat,
                    goal: fatGoal,
                    color: AppColors.warmAmber
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard()
    }

    private var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(Double(todayCalories) / Double(calorieGoal), 1.0)
    }

    private func macroRing(label: String, current: Double, goal: Double, color: Color) -> some View {
        let progress = goal > 0 ? min(current / goal, 1.0) : 0

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(AppColors.subtleText.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)

                Text("\(Int(current))g")
                    .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
            }
            .frame(width: 60, height: 60)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.subtleText)
        }
    }

    // MARK: - Quick Log Section

    @ViewBuilder
    private var quickLogSection: some View {
        let uniqueFoods = uniqueFoodNames
        if !uniqueFoods.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Quick Log", icon: "bolt.fill")

                ForEach(uniqueFoods, id: \.self) { name in
                    if let latest = allEntries.first(where: { $0.name == name }) {
                        Button {
                            quickLog(from: latest)
                        } label: {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.gold)
                                    .frame(width: 28, height: 28)
                                    .glassGem(.circle)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(latest.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                    Text(latest.macroSummary)
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
    }

    // MARK: - Today's Log Section

    @ViewBuilder
    private var todayLogSection: some View {
        if !todayEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Today's Log", icon: "list.bullet")

                ForEach(todayEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                            Text(entry.macroSummary)
                                .font(.caption2)
                                .foregroundStyle(AppColors.subtleText)
                        }

                        Spacer()

                        Text(entry.formattedTime)
                            .font(.caption2)
                            .foregroundStyle(AppColors.subtleText)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .glassRow(cornerRadius: 10)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
            .glassCard()
        }
    }

    // MARK: - Helpers

    private var uniqueFoodNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in allEntries {
            if !seen.contains(entry.name) {
                seen.insert(entry.name)
                result.append(entry.name)
            }
        }
        return result
    }

    private func quickLog(from template: FoodEntry) {
        guard let context = workoutManager.modelContext else { return }
        let entry = FoodEntry(
            name: template.name,
            calories: template.calories,
            protein: template.protein,
            carbs: template.carbs,
            fat: template.fat,
            servingSize: template.servingSize,
            servingUnit: template.servingUnit
        )
        context.insert(entry)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func deleteEntry(_ entry: FoodEntry) {
        guard let context = workoutManager.modelContext else { return }
        context.delete(entry)
        workoutManager.save()
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

// MARK: - AddFoodSheet

struct AddFoodSheet: View {

    @Bindable var workoutManager: WorkoutManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showCustomForm = false

    // Custom entry fields
    @State private var customName = ""
    @State private var customCalories = ""
    @State private var customProtein = ""
    @State private var customCarbs = ""
    @State private var customFat = ""
    @State private var customServingSize = "1"
    @State private var customServingUnit: ServingUnit = .serving

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.subtleText)
                        TextField("Search foods...", text: $searchText)
                            .foregroundStyle(AppColors.primaryText)
                    }
                    .padding(10)
                    .glassField(cornerRadius: 10)

                    // Custom entry button
                    Button {
                        showCustomForm.toggle()
                    } label: {
                        HStack {
                            Image(systemName: showCustomForm ? "chevron.down" : "square.and.pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.accent)
                            Text("Custom Entry")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .deepGlass(.rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if showCustomForm {
                        customFormSection
                    }

                    // Preset foods
                    if !showCustomForm {
                        presetFoodsSection
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .appBackground()
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Custom Form

    private var customFormSection: some View {
        VStack(spacing: 12) {
            formField("Name", text: $customName, placeholder: "Food name")

            HStack(spacing: 12) {
                formField("Serving", text: $customServingSize, placeholder: "1", keyboard: .decimalPad)
                    .frame(maxWidth: 80)

                Picker("Unit", selection: $customServingUnit) {
                    ForEach(ServingUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            formField("Calories", text: $customCalories, placeholder: "0", keyboard: .numberPad)

            HStack(spacing: 12) {
                formField("Protein (g)", text: $customProtein, placeholder: "0", keyboard: .decimalPad)
                formField("Carbs (g)", text: $customCarbs, placeholder: "0", keyboard: .decimalPad)
                formField("Fat (g)", text: $customFat, placeholder: "0", keyboard: .decimalPad)
            }

            Button {
                saveCustomEntry()
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(saveDisabled ? AppColors.subtleText : AppColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .deepGlass(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(saveDisabled)
        }
        .padding(16)
        .glassCard()
    }

    private var saveDisabled: Bool {
        customName.isEmpty || (Int(customCalories) ?? 0) <= 0
    }

    private func formField(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(AppColors.subtleText)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .padding(10)
                .glassField(cornerRadius: 10)
        }
    }

    // MARK: - Preset Foods

    private var presetFoodsSection: some View {
        let filtered = searchText.isEmpty
            ? PreloadedFoods.byCategory
            : filteredBySearch

        return ForEach(filtered, id: \.category) { group in
            VStack(alignment: .leading, spacing: 8) {
                Text(group.category.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.top, 4)

                ForEach(group.foods) { food in
                    Button {
                        addPreset(food)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                Text("\(food.calories) cal · \(Int(food.protein))P · \(Int(food.carbs))C · \(Int(food.fat))F")
                                    .font(.caption2)
                                    .foregroundStyle(AppColors.subtleText)
                            }

                            Spacer()

                            Text("\(food.servingSize, specifier: "%g") \(food.servingUnit.rawValue)")
                                .font(.caption2)
                                .foregroundStyle(AppColors.subtleText)

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColors.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassRow(cornerRadius: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredBySearch: [(category: FoodCategory, foods: [FoodTemplate])] {
        let results = PreloadedFoods.search(searchText)
        return FoodCategory.allCases.compactMap { category in
            let foods = results.filter { $0.category == category }
            return foods.isEmpty ? nil : (category: category, foods: foods)
        }
    }

    // MARK: - Actions

    private func addPreset(_ food: FoodTemplate) {
        guard let context = workoutManager.modelContext else { return }
        let entry = FoodEntry(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit
        )
        context.insert(entry)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }

    private func saveCustomEntry() {
        guard let context = workoutManager.modelContext else { return }
        let entry = FoodEntry(
            name: customName,
            calories: Int(customCalories) ?? 0,
            protein: Double(customProtein) ?? 0,
            carbs: Double(customCarbs) ?? 0,
            fat: Double(customFat) ?? 0,
            servingSize: Double(customServingSize) ?? 1,
            servingUnit: customServingUnit
        )
        context.insert(entry)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
