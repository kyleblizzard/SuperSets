// SchemaVersions.swift
// Super Sets — The Workout Tracker
//
// SwiftData versioned schema definitions and migration plan.
// V1 freezes the initial schema so future changes can migrate cleanly.

import SwiftData

// MARK: - Schema V1 (Initial)
// Frozen: v0.065, Feb 2026
// Models: LiftDefinition, Workout, WorkoutSet, UserProfile, WeightEntry

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            LiftDefinition.self,
            Workout.self,
            WorkoutSet.self,
            UserProfile.self,
            WeightEntry.self,
            WorkoutSplit.self
        ]
    }
}

// MARK: - Migration Plan

enum SuperSetsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations needed yet — V1 is the initial schema.
        // Future versions add stages here, e.g.:
        // migrateV1toV2
        []
    }
}
