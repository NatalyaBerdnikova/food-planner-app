import Foundation
import Observation

enum AppTab: String, Hashable, CaseIterable {
    case today
    case plan
    case shopping
    case recipes
}

@MainActor
@Observable
final class AppNavigation {
    var selectedTab: AppTab = .today
    var pendingPlanWeekSource: String?

    func open(_ tab: AppTab) {
        selectedTab = tab
    }

    func consumePlanWeekSource(default defaultSource: String = "home") -> String {
        let source = pendingPlanWeekSource ?? defaultSource
        pendingPlanWeekSource = nil
        return source
    }

    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "foodplanner" else { return false }

        let host = url.host?.lowercased()
        let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if host == "tab" {
            switch path {
            case "plan":
                pendingPlanWeekSource = "push"
                open(.plan)
                return true
            case "shopping":
                open(.shopping)
                return true
            case "today", "":
                open(.today)
                return true
            case "recipes":
                open(.recipes)
                return true
            default:
                return false
            }
        }

        switch host {
        case "plan":
            pendingPlanWeekSource = "push"
            open(.plan)
            return true
        case "shopping":
            open(.shopping)
            return true
        default:
            return false
        }
    }
}
