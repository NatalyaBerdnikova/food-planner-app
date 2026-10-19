import Foundation

enum MacroDisplaySettings {
    static let showFractionsKey = "showMacroFractions"
    static let showFractionsDefault = false

    static func format(_ value: Double, showFractions: Bool) -> String {
        if showFractions {
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", value)
                : String(format: "%.1f", value)
        }
        return String(format: "%.0f", value.rounded())
    }
}
