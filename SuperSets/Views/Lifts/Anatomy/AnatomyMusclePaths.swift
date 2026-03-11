// AnatomyMusclePaths.swift
// Super Sets — The Workout Tracker
//
// Muscular Bézier anatomy figure with per-patch paths and label positions.
// Each bilateral muscle produces two MusclePatch instances (left + right)
// so labels center correctly on each side.

import SwiftUI

// MARK: - MusclePatch

struct MusclePatch: Identifiable {
    let id: String
    let group: MuscleGroup
    let path: Path
    let labelCenter: CGPoint
}

// MARK: - PathSegment

enum PathSegment {
    case move(CGFloat, CGFloat)
    case line(CGFloat, CGFloat)
    case quad(to: (CGFloat, CGFloat), cp: (CGFloat, CGFloat))
    case cubic(to: (CGFloat, CGFloat), cp1: (CGFloat, CGFloat), cp2: (CGFloat, CGFloat))
    case close
}

// MARK: - AnatomyMusclePaths

struct AnatomyMusclePaths {

    // MARK: - Public API

    static func patches(for side: AnatomySide, in rect: CGRect) -> [MusclePatch] {
        let defs: [(String, MuscleGroup, [PathSegment], (CGFloat, CGFloat))]
        switch side {
        case .front, .both:
            defs = frontPatches
        case .back:
            defs = backPatches
        }

        return defs.map { id, group, segs, label in
            MusclePatch(
                id: id,
                group: group,
                path: buildPath(from: segs, in: rect),
                labelCenter: CGPoint(x: label.0 * rect.width, y: label.1 * rect.height)
            )
        }
    }

    static func bodyOutline(side: AnatomySide, in rect: CGRect) -> Path {
        switch side {
        case .front, .both:
            return buildPath(from: frontOutline, in: rect)
        case .back:
            return buildPath(from: backOutline, in: rect)
        }
    }

    static func headShape(in rect: CGRect) -> Path {
        let cx = 0.50 * rect.width
        let cy = 0.038 * rect.height
        let rx = 0.065 * rect.width
        let ry = 0.038 * rect.height
        var path = Path()
        path.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        return path
    }

    // MARK: - Build Path

    private static func buildPath(from segments: [PathSegment], in rect: CGRect) -> Path {
        var path = Path()
        for seg in segments {
            switch seg {
            case .move(let x, let y):
                path.move(to: pt(x, y, rect))
            case .line(let x, let y):
                path.addLine(to: pt(x, y, rect))
            case .quad(let to, let cp):
                path.addQuadCurve(to: pt(to.0, to.1, rect),
                                  control: pt(cp.0, cp.1, rect))
            case .cubic(let to, let cp1, let cp2):
                path.addCurve(to: pt(to.0, to.1, rect),
                              control1: pt(cp1.0, cp1.1, rect),
                              control2: pt(cp2.0, cp2.1, rect))
            case .close:
                path.closeSubpath()
            }
        }
        return path
    }

    private static func pt(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
        CGPoint(x: x * rect.width, y: y * rect.height)
    }

    // MARK: - Mirror

    private static func mirror(_ segs: [PathSegment]) -> [PathSegment] {
        segs.map { seg in
            switch seg {
            case .move(let x, let y):
                return .move(1.0 - x, y)
            case .line(let x, let y):
                return .line(1.0 - x, y)
            case .quad(let to, let cp):
                return .quad(to: (1.0 - to.0, to.1), cp: (1.0 - cp.0, cp.1))
            case .cubic(let to, let cp1, let cp2):
                return .cubic(to: (1.0 - to.0, to.1), cp1: (1.0 - cp1.0, cp1.1), cp2: (1.0 - cp2.0, cp2.1))
            case .close:
                return .close
            }
        }
    }

    // MARK: - Front Patches

    private static var frontPatches: [(String, MuscleGroup, [PathSegment], (CGFloat, CGFloat))] {
        var result: [(String, MuscleGroup, [PathSegment], (CGFloat, CGFloat))] = []

        // Shoulders (bilateral)
        result.append(("shoulder_left", .shoulders, shoulderFrontLeft, (0.24, 0.155)))
        result.append(("shoulder_right", .shoulders, mirror(shoulderFrontLeft), (0.76, 0.155)))

        // Chest (bilateral)
        result.append(("chest_left", .chest, chestLeft, (0.39, 0.21)))
        result.append(("chest_right", .chest, mirror(chestLeft), (0.61, 0.21)))

        // Biceps (bilateral)
        result.append(("bicep_left", .biceps, bicepLeft, (0.20, 0.27)))
        result.append(("bicep_right", .biceps, mirror(bicepLeft), (0.80, 0.27)))

        // Triceps front (bilateral) — inner arm sliver
        result.append(("tricep_front_left", .triceps, tricepFrontLeft, (0.16, 0.27)))
        result.append(("tricep_front_right", .triceps, mirror(tricepFrontLeft), (0.84, 0.27)))

        // Abs (center)
        result.append(("abs_center", .abs, absCenter, (0.50, 0.34)))

        // Quads (bilateral)
        result.append(("quad_left", .quads, quadLeft, (0.40, 0.54)))
        result.append(("quad_right", .quads, mirror(quadLeft), (0.60, 0.54)))

        // Calves front (bilateral)
        result.append(("calf_front_left", .calves, calfFrontLeft, (0.40, 0.76)))
        result.append(("calf_front_right", .calves, mirror(calfFrontLeft), (0.60, 0.76)))

        return result
    }

    // MARK: - Back Patches

    private static var backPatches: [(String, MuscleGroup, [PathSegment], (CGFloat, CGFloat))] {
        var result: [(String, MuscleGroup, [PathSegment], (CGFloat, CGFloat))] = []

        // Neck (center)
        result.append(("neck_center", .neck, neckCenter, (0.50, 0.09)))

        // Traps (center)
        result.append(("traps_center", .traps, trapsCenter, (0.50, 0.155)))

        // Shoulders back (bilateral)
        result.append(("shoulder_back_left", .shoulders, shoulderBackLeft, (0.24, 0.155)))
        result.append(("shoulder_back_right", .shoulders, mirror(shoulderBackLeft), (0.76, 0.155)))

        // Triceps back (bilateral)
        result.append(("tricep_back_left", .triceps, tricepBackLeft, (0.20, 0.27)))
        result.append(("tricep_back_right", .triceps, mirror(tricepBackLeft), (0.80, 0.27)))

        // Lats (bilateral)
        result.append(("lat_left", .lats, latLeft, (0.37, 0.25)))
        result.append(("lat_right", .lats, mirror(latLeft), (0.63, 0.25)))

        // Lower Back (center)
        result.append(("lower_back_center", .lowerBack, lowerBackCenter, (0.50, 0.37)))

        // Glutes (center)
        result.append(("glutes_center", .glutes, glutesCenter, (0.50, 0.47)))

        // Hamstrings (bilateral)
        result.append(("hamstring_left", .legBiceps, hamstringLeft, (0.40, 0.57)))
        result.append(("hamstring_right", .legBiceps, mirror(hamstringLeft), (0.60, 0.57)))

        // Calves back (bilateral)
        result.append(("calf_back_left", .calves, calfBackLeft, (0.40, 0.76)))
        result.append(("calf_back_right", .calves, mirror(calfBackLeft), (0.60, 0.76)))

        return result
    }

    // MARK: - Shoulder Paths

    private static let shoulderFrontLeft: [PathSegment] = [
        .move(0.30, 0.13),
        .cubic(to: (0.14, 0.15), cp1: (0.24, 0.11), cp2: (0.18, 0.12)),
        .cubic(to: (0.14, 0.21), cp1: (0.12, 0.17), cp2: (0.12, 0.19)),
        .cubic(to: (0.22, 0.22), cp1: (0.15, 0.22), cp2: (0.18, 0.22)),
        .line(0.30, 0.21),
        .close
    ]

    private static let shoulderBackLeft: [PathSegment] = [
        .move(0.30, 0.13),
        .cubic(to: (0.14, 0.15), cp1: (0.24, 0.11), cp2: (0.18, 0.12)),
        .cubic(to: (0.14, 0.21), cp1: (0.12, 0.17), cp2: (0.12, 0.19)),
        .cubic(to: (0.22, 0.22), cp1: (0.15, 0.22), cp2: (0.18, 0.22)),
        .line(0.30, 0.21),
        .close
    ]

    // MARK: - Chest Path

    private static let chestLeft: [PathSegment] = [
        .move(0.30, 0.17),
        .cubic(to: (0.49, 0.18), cp1: (0.35, 0.15), cp2: (0.43, 0.16)),
        .line(0.49, 0.26),
        .cubic(to: (0.36, 0.28), cp1: (0.48, 0.27), cp2: (0.42, 0.28)),
        .cubic(to: (0.30, 0.24), cp1: (0.32, 0.27), cp2: (0.30, 0.26)),
        .close
    ]

    // MARK: - Bicep Path

    private static let bicepLeft: [PathSegment] = [
        .move(0.22, 0.21),
        .cubic(to: (0.15, 0.22), cp1: (0.20, 0.20), cp2: (0.17, 0.20)),
        .cubic(to: (0.14, 0.30), cp1: (0.13, 0.24), cp2: (0.13, 0.27)),
        .cubic(to: (0.17, 0.34), cp1: (0.14, 0.32), cp2: (0.15, 0.34)),
        .cubic(to: (0.24, 0.34), cp1: (0.19, 0.35), cp2: (0.22, 0.35)),
        .cubic(to: (0.26, 0.26), cp1: (0.26, 0.31), cp2: (0.26, 0.28)),
        .cubic(to: (0.22, 0.21), cp1: (0.25, 0.23), cp2: (0.24, 0.21)),
        .close
    ]

    // MARK: - Tricep Front Path (inner arm sliver)

    private static let tricepFrontLeft: [PathSegment] = [
        .move(0.14, 0.22),
        .cubic(to: (0.11, 0.26), cp1: (0.12, 0.23), cp2: (0.11, 0.24)),
        .cubic(to: (0.11, 0.32), cp1: (0.10, 0.28), cp2: (0.10, 0.30)),
        .cubic(to: (0.15, 0.34), cp1: (0.12, 0.34), cp2: (0.13, 0.35)),
        .cubic(to: (0.14, 0.30), cp1: (0.14, 0.32), cp2: (0.13, 0.31)),
        .cubic(to: (0.14, 0.22), cp1: (0.13, 0.27), cp2: (0.13, 0.24)),
        .close
    ]

    // MARK: - Tricep Back Path

    private static let tricepBackLeft: [PathSegment] = [
        .move(0.22, 0.21),
        .cubic(to: (0.14, 0.22), cp1: (0.19, 0.20), cp2: (0.16, 0.20)),
        .cubic(to: (0.12, 0.28), cp1: (0.12, 0.23), cp2: (0.11, 0.25)),
        .cubic(to: (0.14, 0.34), cp1: (0.12, 0.31), cp2: (0.13, 0.33)),
        .cubic(to: (0.20, 0.35), cp1: (0.16, 0.35), cp2: (0.18, 0.36)),
        .cubic(to: (0.25, 0.28), cp1: (0.23, 0.33), cp2: (0.25, 0.31)),
        .cubic(to: (0.22, 0.21), cp1: (0.25, 0.25), cp2: (0.24, 0.22)),
        .close
    ]

    // MARK: - Abs Path

    private static let absCenter: [PathSegment] = [
        .move(0.36, 0.26),
        .cubic(to: (0.50, 0.25), cp1: (0.40, 0.25), cp2: (0.45, 0.25)),
        .cubic(to: (0.64, 0.26), cp1: (0.55, 0.25), cp2: (0.60, 0.25)),
        .cubic(to: (0.64, 0.42), cp1: (0.65, 0.32), cp2: (0.65, 0.38)),
        .cubic(to: (0.50, 0.44), cp1: (0.60, 0.43), cp2: (0.55, 0.44)),
        .cubic(to: (0.36, 0.42), cp1: (0.45, 0.44), cp2: (0.40, 0.43)),
        .cubic(to: (0.36, 0.26), cp1: (0.35, 0.38), cp2: (0.35, 0.32)),
        .close
    ]

    // MARK: - Quad Path

    private static let quadLeft: [PathSegment] = [
        .move(0.32, 0.44),
        .cubic(to: (0.49, 0.43), cp1: (0.37, 0.42), cp2: (0.43, 0.42)),
        .cubic(to: (0.49, 0.55), cp1: (0.49, 0.47), cp2: (0.49, 0.51)),
        .cubic(to: (0.46, 0.66), cp1: (0.49, 0.59), cp2: (0.48, 0.63)),
        .cubic(to: (0.38, 0.66), cp1: (0.44, 0.67), cp2: (0.41, 0.67)),
        .cubic(to: (0.31, 0.58), cp1: (0.35, 0.65), cp2: (0.32, 0.62)),
        .cubic(to: (0.32, 0.44), cp1: (0.30, 0.54), cp2: (0.30, 0.48)),
        .close
    ]

    // MARK: - Calf Front Path

    private static let calfFrontLeft: [PathSegment] = [
        .move(0.35, 0.68),
        .cubic(to: (0.46, 0.68), cp1: (0.38, 0.67), cp2: (0.43, 0.67)),
        .cubic(to: (0.46, 0.76), cp1: (0.47, 0.71), cp2: (0.47, 0.74)),
        .cubic(to: (0.43, 0.85), cp1: (0.46, 0.80), cp2: (0.45, 0.83)),
        .cubic(to: (0.38, 0.85), cp1: (0.41, 0.86), cp2: (0.39, 0.86)),
        .cubic(to: (0.34, 0.78), cp1: (0.36, 0.84), cp2: (0.35, 0.81)),
        .cubic(to: (0.35, 0.68), cp1: (0.33, 0.74), cp2: (0.34, 0.71)),
        .close
    ]

    // MARK: - Neck Path

    private static let neckCenter: [PathSegment] = [
        .move(0.43, 0.065),
        .cubic(to: (0.57, 0.065), cp1: (0.46, 0.06), cp2: (0.54, 0.06)),
        .cubic(to: (0.58, 0.11), cp1: (0.58, 0.08), cp2: (0.58, 0.10)),
        .cubic(to: (0.42, 0.11), cp1: (0.54, 0.12), cp2: (0.46, 0.12)),
        .cubic(to: (0.43, 0.065), cp1: (0.42, 0.10), cp2: (0.42, 0.08)),
        .close
    ]

    // MARK: - Traps Path

    private static let trapsCenter: [PathSegment] = [
        .move(0.30, 0.13),
        .cubic(to: (0.42, 0.11), cp1: (0.34, 0.12), cp2: (0.38, 0.11)),
        .cubic(to: (0.50, 0.12), cp1: (0.45, 0.11), cp2: (0.48, 0.11)),
        .cubic(to: (0.58, 0.11), cp1: (0.52, 0.11), cp2: (0.55, 0.11)),
        .cubic(to: (0.70, 0.13), cp1: (0.62, 0.11), cp2: (0.66, 0.12)),
        .cubic(to: (0.64, 0.20), cp1: (0.68, 0.16), cp2: (0.66, 0.18)),
        .cubic(to: (0.50, 0.22), cp1: (0.60, 0.21), cp2: (0.55, 0.22)),
        .cubic(to: (0.36, 0.20), cp1: (0.45, 0.22), cp2: (0.40, 0.21)),
        .cubic(to: (0.30, 0.13), cp1: (0.34, 0.18), cp2: (0.32, 0.16)),
        .close
    ]

    // MARK: - Lat Path

    private static let latLeft: [PathSegment] = [
        .move(0.30, 0.18),
        .cubic(to: (0.46, 0.20), cp1: (0.36, 0.17), cp2: (0.42, 0.18)),
        .cubic(to: (0.46, 0.34), cp1: (0.47, 0.24), cp2: (0.47, 0.30)),
        .cubic(to: (0.38, 0.38), cp1: (0.45, 0.36), cp2: (0.42, 0.37)),
        .cubic(to: (0.30, 0.32), cp1: (0.35, 0.37), cp2: (0.32, 0.35)),
        .cubic(to: (0.28, 0.24), cp1: (0.28, 0.29), cp2: (0.28, 0.26)),
        .cubic(to: (0.30, 0.18), cp1: (0.28, 0.21), cp2: (0.29, 0.19)),
        .close
    ]

    // MARK: - Lower Back Path

    private static let lowerBackCenter: [PathSegment] = [
        .move(0.36, 0.32),
        .cubic(to: (0.50, 0.31), cp1: (0.40, 0.31), cp2: (0.45, 0.31)),
        .cubic(to: (0.64, 0.32), cp1: (0.55, 0.31), cp2: (0.60, 0.31)),
        .cubic(to: (0.64, 0.42), cp1: (0.65, 0.36), cp2: (0.65, 0.40)),
        .cubic(to: (0.50, 0.43), cp1: (0.60, 0.43), cp2: (0.55, 0.43)),
        .cubic(to: (0.36, 0.42), cp1: (0.45, 0.43), cp2: (0.40, 0.43)),
        .cubic(to: (0.36, 0.32), cp1: (0.35, 0.40), cp2: (0.35, 0.36)),
        .close
    ]

    // MARK: - Glutes Path

    private static let glutesCenter: [PathSegment] = [
        .move(0.30, 0.42),
        .cubic(to: (0.50, 0.43), cp1: (0.36, 0.41), cp2: (0.43, 0.42)),
        .cubic(to: (0.70, 0.42), cp1: (0.57, 0.42), cp2: (0.64, 0.41)),
        .cubic(to: (0.68, 0.52), cp1: (0.72, 0.46), cp2: (0.71, 0.50)),
        .cubic(to: (0.50, 0.53), cp1: (0.63, 0.53), cp2: (0.56, 0.54)),
        .cubic(to: (0.32, 0.52), cp1: (0.44, 0.54), cp2: (0.37, 0.53)),
        .cubic(to: (0.30, 0.42), cp1: (0.29, 0.50), cp2: (0.28, 0.46)),
        .close
    ]

    // MARK: - Hamstring Path

    private static let hamstringLeft: [PathSegment] = [
        .move(0.32, 0.50),
        .cubic(to: (0.49, 0.51), cp1: (0.37, 0.49), cp2: (0.43, 0.50)),
        .cubic(to: (0.49, 0.60), cp1: (0.49, 0.54), cp2: (0.49, 0.57)),
        .cubic(to: (0.46, 0.66), cp1: (0.49, 0.63), cp2: (0.48, 0.65)),
        .cubic(to: (0.38, 0.66), cp1: (0.44, 0.67), cp2: (0.41, 0.67)),
        .cubic(to: (0.31, 0.58), cp1: (0.35, 0.65), cp2: (0.33, 0.62)),
        .cubic(to: (0.32, 0.50), cp1: (0.30, 0.55), cp2: (0.30, 0.52)),
        .close
    ]

    // MARK: - Calf Back Path

    private static let calfBackLeft: [PathSegment] = [
        .move(0.34, 0.68),
        .cubic(to: (0.46, 0.68), cp1: (0.37, 0.67), cp2: (0.42, 0.67)),
        .cubic(to: (0.47, 0.76), cp1: (0.47, 0.71), cp2: (0.48, 0.74)),
        .cubic(to: (0.44, 0.85), cp1: (0.47, 0.80), cp2: (0.46, 0.83)),
        .cubic(to: (0.38, 0.85), cp1: (0.42, 0.86), cp2: (0.40, 0.86)),
        .cubic(to: (0.34, 0.78), cp1: (0.36, 0.84), cp2: (0.34, 0.82)),
        .cubic(to: (0.34, 0.68), cp1: (0.33, 0.74), cp2: (0.33, 0.71)),
        .close
    ]

    // MARK: - Muscular Body Outline (Front)

    private static let frontOutline: [PathSegment] = [
        // Head top
        .move(0.44, 0.01),
        .cubic(to: (0.56, 0.01), cp1: (0.44, -0.01), cp2: (0.56, -0.01)),
        // Head right side
        .cubic(to: (0.58, 0.065), cp1: (0.59, 0.02), cp2: (0.59, 0.04)),
        // Jaw right
        .cubic(to: (0.55, 0.09), cp1: (0.58, 0.08), cp2: (0.57, 0.09)),
        // Neck right
        .cubic(to: (0.58, 0.11), cp1: (0.56, 0.10), cp2: (0.57, 0.10)),
        // Right trap slope
        .cubic(to: (0.70, 0.13), cp1: (0.62, 0.11), cp2: (0.66, 0.12)),
        // Right shoulder cap
        .cubic(to: (0.86, 0.155), cp1: (0.76, 0.12), cp2: (0.83, 0.12)),
        .cubic(to: (0.86, 0.21), cp1: (0.89, 0.17), cp2: (0.89, 0.19)),
        // Right upper arm outer
        .cubic(to: (0.84, 0.28), cp1: (0.86, 0.23), cp2: (0.86, 0.26)),
        .cubic(to: (0.80, 0.35), cp1: (0.83, 0.31), cp2: (0.82, 0.33)),
        // Right forearm
        .cubic(to: (0.78, 0.42), cp1: (0.79, 0.37), cp2: (0.78, 0.40)),
        .cubic(to: (0.74, 0.46), cp1: (0.77, 0.44), cp2: (0.76, 0.46)),
        // Right hand
        .cubic(to: (0.72, 0.44), cp1: (0.73, 0.46), cp2: (0.72, 0.45)),
        // Right inner arm
        .cubic(to: (0.70, 0.36), cp1: (0.72, 0.42), cp2: (0.72, 0.39)),
        .cubic(to: (0.68, 0.28), cp1: (0.69, 0.33), cp2: (0.69, 0.30)),
        // Right torso
        .cubic(to: (0.66, 0.36), cp1: (0.67, 0.30), cp2: (0.66, 0.33)),
        .cubic(to: (0.64, 0.42), cp1: (0.66, 0.38), cp2: (0.65, 0.40)),
        // Right hip
        .cubic(to: (0.68, 0.46), cp1: (0.65, 0.44), cp2: (0.67, 0.45)),
        // Right outer thigh
        .cubic(to: (0.66, 0.56), cp1: (0.69, 0.49), cp2: (0.68, 0.53)),
        .cubic(to: (0.60, 0.66), cp1: (0.64, 0.60), cp2: (0.62, 0.64)),
        // Right knee
        .cubic(to: (0.58, 0.70), cp1: (0.59, 0.68), cp2: (0.58, 0.69)),
        // Right outer calf
        .cubic(to: (0.58, 0.78), cp1: (0.59, 0.72), cp2: (0.59, 0.76)),
        .cubic(to: (0.56, 0.85), cp1: (0.58, 0.81), cp2: (0.57, 0.83)),
        // Right ankle + foot
        .cubic(to: (0.56, 0.92), cp1: (0.55, 0.88), cp2: (0.55, 0.90)),
        .cubic(to: (0.58, 0.97), cp1: (0.57, 0.94), cp2: (0.58, 0.96)),
        .line(0.58, 1.0),
        .line(0.52, 1.0),
        // Right inner ankle
        .cubic(to: (0.52, 0.92), cp1: (0.52, 0.98), cp2: (0.52, 0.95)),
        .cubic(to: (0.52, 0.85), cp1: (0.52, 0.90), cp2: (0.52, 0.87)),
        // Right inner calf + thigh
        .cubic(to: (0.51, 0.70), cp1: (0.52, 0.80), cp2: (0.52, 0.74)),
        .cubic(to: (0.50, 0.50), cp1: (0.51, 0.64), cp2: (0.51, 0.56)),
        // Left inner thigh + calf
        .cubic(to: (0.49, 0.70), cp1: (0.49, 0.56), cp2: (0.49, 0.64)),
        .cubic(to: (0.48, 0.85), cp1: (0.48, 0.74), cp2: (0.48, 0.80)),
        // Left inner ankle
        .cubic(to: (0.48, 0.92), cp1: (0.48, 0.87), cp2: (0.48, 0.90)),
        .cubic(to: (0.48, 1.0), cp1: (0.48, 0.95), cp2: (0.48, 0.98)),
        .line(0.42, 1.0),
        // Left ankle + foot
        .cubic(to: (0.42, 0.97), cp1: (0.42, 0.99), cp2: (0.42, 0.98)),
        .cubic(to: (0.44, 0.92), cp1: (0.42, 0.96), cp2: (0.43, 0.94)),
        .cubic(to: (0.44, 0.85), cp1: (0.45, 0.90), cp2: (0.45, 0.88)),
        // Left outer calf
        .cubic(to: (0.42, 0.78), cp1: (0.43, 0.83), cp2: (0.42, 0.81)),
        .cubic(to: (0.42, 0.70), cp1: (0.41, 0.76), cp2: (0.41, 0.72)),
        // Left knee
        .cubic(to: (0.40, 0.66), cp1: (0.42, 0.69), cp2: (0.41, 0.68)),
        // Left outer thigh
        .cubic(to: (0.34, 0.56), cp1: (0.38, 0.64), cp2: (0.36, 0.60)),
        .cubic(to: (0.32, 0.46), cp1: (0.32, 0.53), cp2: (0.31, 0.49)),
        // Left hip
        .cubic(to: (0.36, 0.42), cp1: (0.33, 0.45), cp2: (0.35, 0.44)),
        // Left torso
        .cubic(to: (0.34, 0.36), cp1: (0.35, 0.40), cp2: (0.34, 0.38)),
        .cubic(to: (0.32, 0.28), cp1: (0.34, 0.33), cp2: (0.33, 0.30)),
        // Left inner arm
        .cubic(to: (0.30, 0.36), cp1: (0.31, 0.30), cp2: (0.31, 0.33)),
        .cubic(to: (0.28, 0.44), cp1: (0.28, 0.39), cp2: (0.28, 0.42)),
        // Left hand
        .cubic(to: (0.26, 0.46), cp1: (0.28, 0.45), cp2: (0.27, 0.46)),
        .cubic(to: (0.22, 0.42), cp1: (0.24, 0.46), cp2: (0.23, 0.44)),
        // Left forearm
        .cubic(to: (0.20, 0.35), cp1: (0.22, 0.40), cp2: (0.21, 0.37)),
        .cubic(to: (0.16, 0.28), cp1: (0.18, 0.33), cp2: (0.17, 0.31)),
        // Left upper arm outer
        .cubic(to: (0.14, 0.21), cp1: (0.14, 0.26), cp2: (0.14, 0.23)),
        // Left shoulder cap
        .cubic(to: (0.14, 0.155), cp1: (0.11, 0.19), cp2: (0.11, 0.17)),
        .cubic(to: (0.30, 0.13), cp1: (0.17, 0.12), cp2: (0.24, 0.12)),
        // Left trap slope
        .cubic(to: (0.42, 0.11), cp1: (0.34, 0.12), cp2: (0.38, 0.11)),
        // Neck left
        .cubic(to: (0.45, 0.09), cp1: (0.43, 0.10), cp2: (0.44, 0.10)),
        // Jaw left
        .cubic(to: (0.42, 0.065), cp1: (0.43, 0.09), cp2: (0.42, 0.08)),
        // Head left side
        .cubic(to: (0.44, 0.01), cp1: (0.41, 0.04), cp2: (0.41, 0.02)),
        .close
    ]

    // MARK: - Muscular Body Outline (Back)

    private static let backOutline: [PathSegment] = frontOutline
}
