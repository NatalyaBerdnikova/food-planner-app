import SwiftUI

enum NutritionTargetStatus {
    case below
    case onTarget
    case above

    /// Жёлтый: < 81%, зелёный: 81–105%, красный: > 105%.
    static func from(actual: Double, target: Double) -> NutritionTargetStatus? {
        guard target > 0 else { return nil }
        let ratio = actual / target
        if ratio < 0.81 { return .below }
        if ratio <= 1.05 { return .onTarget }
        return .above
    }

    /// Для микронутриентов: жёлтый < 81%, зелёный 81–200%, красный > 200%.
    static func fromMicronutrient(actual: Double, target: Double) -> NutritionTargetStatus? {
        guard target > 0 else { return nil }
        let ratio = actual / target
        if ratio < 0.81 { return .below }
        if ratio <= 2.05 { return .onTarget }
        return .above
    }

    var color: Color {
        switch self {
        case .below:
            return AppTheme.warning
        case .onTarget:
            return AppTheme.success
        case .above:
            return .red
        }
    }
}
