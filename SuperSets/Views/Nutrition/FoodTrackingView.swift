// FoodTrackingView.swift
// Super Sets — The Workout Tracker
//
// Daily food and macro tracking with net calories view,
// horizontal macro bars, quick-log, saved meals, and preset database.

import SwiftUI
import SwiftData

// MARK: - FoodTrackingView

struct FoodTrackingView: View {

    @Bindable var workoutManager: WorkoutManager
    @Environment(HealthKitManager.self) private var healthKitManager: HealthKitManager?
    @State private var showingAddSheet = false

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var allEntries: [FoodEntry]

    @Query(sort: \SavedMeal.date, order: .reverse)
    private var savedMeals: [SavedMeal]

    // MARK: Computed — Today's Intake

    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return allEntries.filter { calendar.isDateInToday($0.date) }
    }

    private var consumed: Int {
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

    // MARK: Computed — Calories Burned

    private var profile: UserProfile? {
        workoutManager.userProfile
    }

    private var burned: Int {
        guard let profile else { return 0 }
        return bmrSoFar(profile: profile)
             + stepCalories(profile: profile)
             + workoutManager.todayWorkoutCalories()
    }

    private var net: Int { consumed - burned }

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

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                netCaloriesSection
                macrosSection
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

    // MARK: - Net Calories Section

    private var netCaloriesSection: some View {
        VStack(spacing: 14) {
            sectionHeader("Net Calories", icon: "fork.knife")

            // Main net number
            VStack(spacing: 4) {
                Text("\(net)")
                    .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(netColor)

                Text(netLabel)
                    .font(.caption.bold())
                    .foregroundStyle(netColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .deepGlass(.rect(cornerRadius: 16))

            // Consumed vs Burned
            HStack(spacing: 12) {
                calorieTile(
                    icon: "arrow.up.circle.fill",
                    label: "Consumed",
                    value: consumed,
                    color: AppColors.warmAmber
                )
                calorieTile(
                    icon: "arrow.down.circle.fill",
                    label: "Burned",
                    value: burned,
                    color: AppColors.accent
                )
                calorieTile(
                    icon: "target",
                    label: "Goal",
                    value: calorieGoal,
                    color: AppColors.accentSecondary
                )
            }
        }
        .padding(16)
        .glassCard()
    }

    private var netColor: Color {
        guard let profile else { return AppColors.primaryText }
        switch profile.weightGoal {
        case .lose:     return net < 0 ? AppColors.positive : AppColors.danger
        case .maintain: return abs(net) < 200 ? AppColors.positive : AppColors.warmAmber
        case .gain:     return net > 0 ? AppColors.positive : AppColors.danger
        }
    }

    private var netLabel: String {
        if net > 0 { return "surplus" }
        if net < 0 { return "deficit" }
        return "balanced"
    }

    private func calorieTile(icon: String, label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(AppColors.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .deepGlass(.rect(cornerRadius: 12))
    }

    // MARK: - Macros Section (Horizontal Bars)

    private var macrosSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Macros", icon: "chart.bar.fill")

            macroBar(label: "Protein", current: todayProtein, goal: proteinGoal, color: AppColors.positive)
            macroBar(label: "Carbs", current: todayCarbs, goal: carbsGoal, color: Color(hex: 0x42A5F5))
            macroBar(label: "Fat", current: todayFat, goal: fatGoal, color: AppColors.warmAmber)
        }
        .padding(16)
        .glassCard()
    }

    private func macroBar(label: String, current: Double, goal: Double, color: Color) -> some View {
        let progress = goal > 0 ? min(current / goal, 1.0) : 0

        return VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
                Spacer()
                Text("\(Int(current))g / \(Int(goal))g")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.subtleText.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(color)
                        .frame(width: max(0, geo.size.width * progress), height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Quick Log Section

    @ViewBuilder
    private var quickLogSection: some View {
        let uniqueFoods = uniqueFoodNames
        let hasMeals = !savedMeals.isEmpty
        let hasItems = !uniqueFoods.isEmpty || hasMeals

        if hasItems {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Quick Log", icon: "bolt.fill")

                // Saved meals first
                ForEach(savedMeals) { meal in
                    Button {
                        logSavedMeal(meal)
                    } label: {
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.gold)
                                .frame(width: 28, height: 28)
                                .glassGem(.circle)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.primaryText)
                                Text("\(meal.items.count) items · \(meal.macroSummary)")
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
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSavedMeal(meal)
                        } label: {
                            Label("Delete Meal", systemImage: "trash")
                        }
                    }
                }

                // Individual foods
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

    // MARK: - Calorie Burn Helpers

    private func bmrSoFar(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())
        let fractionOfDay = (Double(hour) + Double(minute) / 60.0) / 24.0
        return Int(Double(profile.restingMetabolicRate) * fractionOfDay)
    }

    private func stepCalories(profile: UserProfile) -> Int {
        let steps = healthKitManager?.todaySteps ?? 0
        let calPerStep = 0.04 * (profile.bodyWeightKg / 70.0)
        return Int(Double(steps) * calPerStep)
    }

    // MARK: - Data Helpers

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

    private func logSavedMeal(_ meal: SavedMeal) {
        guard let context = workoutManager.modelContext else { return }
        for item in meal.items {
            let entry = FoodEntry(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                servingSize: item.servingSize,
                servingUnit: item.servingUnit
            )
            context.insert(entry)
        }
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func deleteSavedMeal(_ meal: SavedMeal) {
        guard let context = workoutManager.modelContext else { return }
        context.delete(meal)
        workoutManager.save()
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

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var allEntries: [FoodEntry]

    enum SheetMode { case addFood, createMeal }
    @State private var mode: SheetMode = .addFood
    @State private var searchText = ""
    @State private var showCustomForm = false

    // Custom entry fields
    @State private var customName = ""
    @State private var customCalories: Int = 0
    @State private var customProtein: Int = 0
    @State private var customCarbs: Int = 0
    @State private var customFat: Int = 0
    @State private var customServingSize: Double = 1.0
    @State private var customServingUnit: ServingUnit = .serving

    // Create meal fields
    @State private var mealName = ""
    @State private var mealItems: [SavedMealItem] = []
    @State private var mealSearchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode picker
                Picker("", selection: $mode) {
                    Text("Add Food").tag(SheetMode.addFood)
                    Text("Create Meal").tag(SheetMode.createMeal)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 16) {
                        if mode == .addFood {
                            addFoodContent
                        } else {
                            createMealContent
                        }
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
            }
            .appBackground()
            .navigationTitle(mode == .addFood ? "Add Food" : "Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if mode == .createMeal {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveMeal() }
                            .disabled(mealName.isEmpty || mealItems.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Add Food Content

    @ViewBuilder
    private var addFoodContent: some View {
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

        if !showCustomForm {
            presetFoodsSection
        }
    }

    // MARK: - Create Meal Content

    @ViewBuilder
    private var createMealContent: some View {
        // Meal name
        formField("Meal Name", text: $mealName, placeholder: "e.g. My Breakfast")

        // Current items in meal
        if !mealItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Items (\(mealItems.count))")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)

                ForEach(mealItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColors.primaryText)
                            Text("\(item.calories) cal · \(Int(item.protein))P · \(Int(item.carbs))C · \(Int(item.fat))F")
                                .font(.caption2)
                                .foregroundStyle(AppColors.subtleText)
                        }
                        Spacer()
                        Button {
                            mealItems.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(AppColors.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .glassRow(cornerRadius: 10)
                }

                // Totals
                HStack {
                    Text("Total")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.subtleText)
                    Spacer()
                    let totalCal = mealItems.reduce(0) { $0 + $1.calories }
                    let totalP = mealItems.reduce(0.0) { $0 + $1.protein }
                    let totalC = mealItems.reduce(0.0) { $0 + $1.carbs }
                    let totalF = mealItems.reduce(0.0) { $0 + $1.fat }
                    Text("\(totalCal) cal · \(Int(totalP))P · \(Int(totalC))C · \(Int(totalF))F")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(AppColors.accent)
                }
                .padding(.top, 4)
            }
            .padding(12)
            .glassCard()
        }

        // Search to add items
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.subtleText)
            TextField("Search foods to add...", text: $mealSearchText)
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(10)
        .glassField(cornerRadius: 10)

        // Previously logged foods
        let recentFoods = uniqueFoodItems
        if !recentFoods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Foods")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)

                ForEach(filteredRecentFoods(recentFoods), id: \.name) { entry in
                    Button {
                        mealItems.append(SavedMealItem(from: entry))
                    } label: {
                        foodRow(name: entry.name, detail: entry.macroSummary, trailing: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        // Presets for meal building
        mealPresetsList
    }

    private var mealPresetsList: some View {
        let filtered = mealSearchText.isEmpty
            ? PreloadedFoods.byCategory
            : filteredPresets(mealSearchText)

        return ForEach(Array(filtered.indices), id: \.self) { i in
            let group = filtered[i]
            VStack(alignment: .leading, spacing: 8) {
                Text(group.category.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.top, 4)

                ForEach(group.foods) { food in
                    Button {
                        mealItems.append(SavedMealItem(from: food))
                    } label: {
                        foodRow(
                            name: food.name,
                            detail: "\(food.calories) cal · \(Int(food.protein))P · \(Int(food.carbs))C · \(Int(food.fat))F",
                            trailing: servingLabel(food)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Shared Components

    private func foodRow(name: String, detail: String, trailing: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppColors.primaryText)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText)
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption2)
                    .foregroundStyle(AppColors.subtleText)
            }
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassRow(cornerRadius: 10)
    }

    // MARK: - Custom Form

    private var customFormSection: some View {
        VStack(spacing: 12) {
            formField("Name", text: $customName, placeholder: "Food name")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Serving")
                        .font(.caption.bold())
                        .foregroundStyle(AppColors.subtleText)
                    Picker("Serving", selection: $customServingSize) {
                        ForEach(Array(stride(from: 0.5, through: 20.0, by: 0.5)), id: \.self) { val in
                            Text(val.truncatingRemainder(dividingBy: 1) == 0
                                 ? String(format: "%.0f", val)
                                 : String(format: "%.1f", val))
                                .tag(val)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .glassField(cornerRadius: 10)
                }
                .frame(maxWidth: 100)

                Picker("Unit", selection: $customServingUnit) {
                    ForEach(ServingUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Calories wheel picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Calories")
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
                Picker("Calories", selection: $customCalories) {
                    ForEach(Array(stride(from: 0, through: 2000, by: 5)), id: \.self) { val in
                        Text("\(val)").tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .glassField(cornerRadius: 10)
            }

            // Macro wheel pickers
            HStack(spacing: 8) {
                macroWheelPicker("Protein", value: $customProtein, color: AppColors.positive)
                macroWheelPicker("Carbs", value: $customCarbs, color: Color(hex: 0x42A5F5))
                macroWheelPicker("Fat", value: $customFat, color: AppColors.warmAmber)
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

    private func macroWheelPicker(_ label: String, value: Binding<Int>, color: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Picker(label, selection: value) {
                ForEach(0...300, id: \.self) { val in
                    Text("\(val)g").tag(val)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 80)
            .glassField(cornerRadius: 8)
        }
    }

    private var saveDisabled: Bool {
        customName.isEmpty || customCalories <= 0
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
            : filteredPresets(searchText)

        return ForEach(Array(filtered.indices), id: \.self) { i in
            let group = filtered[i]
            VStack(alignment: .leading, spacing: 8) {
                Text(group.category.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(AppColors.subtleText)
                    .padding(.top, 4)

                ForEach(group.foods) { food in
                    Button {
                        addPreset(food)
                    } label: {
                        foodRow(
                            name: food.name,
                            detail: "\(food.calories) cal · \(Int(food.protein))P · \(Int(food.carbs))C · \(Int(food.fat))F",
                            trailing: servingLabel(food)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func servingLabel(_ food: FoodTemplate) -> String {
        let size = food.servingSize.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", food.servingSize)
            : String(format: "%.1f", food.servingSize)
        return "\(size) \(food.servingUnit.rawValue)"
    }

    private func filteredPresets(_ query: String) -> [(category: FoodCategory, foods: [FoodTemplate])] {
        let results = PreloadedFoods.search(query)
        return FoodCategory.allCases.compactMap { category in
            let foods = results.filter { $0.category == category }
            return foods.isEmpty ? nil : (category: category, foods: foods)
        }
    }

    // MARK: - Helpers

    private var uniqueFoodItems: [FoodEntry] {
        var seen = Set<String>()
        var result: [FoodEntry] = []
        for entry in allEntries {
            if !seen.contains(entry.name) {
                seen.insert(entry.name)
                result.append(entry)
            }
        }
        return result
    }

    private func filteredRecentFoods(_ foods: [FoodEntry]) -> [FoodEntry] {
        guard !mealSearchText.isEmpty else { return foods }
        let lowered = mealSearchText.lowercased()
        return foods.filter { $0.name.lowercased().contains(lowered) }
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
            calories: customCalories,
            protein: Double(customProtein),
            carbs: Double(customCarbs),
            fat: Double(customFat),
            servingSize: customServingSize,
            servingUnit: customServingUnit
        )
        context.insert(entry)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }

    private func saveMeal() {
        guard let context = workoutManager.modelContext else { return }
        let meal = SavedMeal(name: mealName, items: mealItems)
        context.insert(meal)
        workoutManager.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
