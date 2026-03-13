// SchemaVersions.swift
// Super Sets — The Workout Tracker
//
// SwiftData versioned schema definitions and migration plan.
//
// V1 — Frozen at v0.085, Mar 2026. Local SQLite, 15 models.
// V2 — CloudKit-compatible: declaration-site defaults on all
//      non-optional properties, @Attribute(.externalStorage) removed.

import SwiftData

// MARK: - Schema V1 (Frozen — local SQLite only)
// Do not modify. Exists so SwiftData can compute the V1→V2 diff.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self,
            WeightEntry.self,
            WorkoutSplit.self,
            BodyMeasurement.self,
            BodyFatEntry.self,
            SplitSchedule.self,
            WaterEntry.self,
            MedicationLog.self,
            SleepEntry.self,
            StepsEntry.self,
            CalorieEntry.self,
            GoalSetting.self
        ]
    }
}

// MARK: - Schema V2 (CloudKit-compatible)
// Same 15 models after adding declaration-site defaults
// and removing @Attribute(.externalStorage) from UserProfile.

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self,
            WeightEntry.self,
            WorkoutSplit.self,
            BodyMeasurement.self,
            BodyFatEntry.self,
            SplitSchedule.self,
            WaterEntry.self,
            MedicationLog.self,
            SleepEntry.self,
            StepsEntry.self,
            CalorieEntry.self,
            GoalSetting.self
        ]
    }
}

// MARK: - Schema V3 (Food Tracking)
// Adds FoodEntry model + new UserProfile nutrition goal columns.

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self,
            WeightEntry.self,
            WorkoutSplit.self,
            BodyMeasurement.self,
            BodyFatEntry.self,
            SplitSchedule.self,
            WaterEntry.self,
            MedicationLog.self,
            SleepEntry.self,
            StepsEntry.self,
            CalorieEntry.self,
            GoalSetting.self,
            FoodEntry.self
        ]
    }
}

// MARK: - Migration Plan

enum SuperSetsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    // Lightweight: SwiftData infers the diff automatically.
    // Changes: declaration-site defaults added, .externalStorage removed.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    // Lightweight: adds FoodEntry table + UserProfile nutrition goal columns.
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )
}
