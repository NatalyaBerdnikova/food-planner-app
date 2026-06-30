import Adapty
import Foundation
import StoreKit

enum SubscriptionPlural {
    static func unit(_ unit: AdaptyPeriodUnit, count: Int) -> String {
        let word: String = {
            switch unit {
            case .day: return "day"
            case .week: return "week"
            case .month: return "month"
            case .year: return "year"
            case .unknown: return "day"
            }
        }()
        return pluralized(word: word, count: count)
    }

    static func unit(_ unit: Product.SubscriptionPeriod.Unit, count: Int) -> String {
        let word: String = {
            switch unit {
            case .day: return "day"
            case .week: return "week"
            case .month: return "month"
            case .year: return "year"
            @unknown default: return "day"
            }
        }()
        return pluralized(word: word, count: count)
    }

    private static func pluralized(word: String, count: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "ru" {
            if count % 10 == 1 && count % 100 != 11 {
                return NSLocalizedString(word, comment: "")
            } else if count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20) {
                return NSLocalizedString("\(word)2", comment: "")
            }
            return NSLocalizedString("\(word)s", comment: "")
        }

        if count == 1 {
            return NSLocalizedString(word, comment: "")
        }
        return NSLocalizedString("\(word)s", comment: "")
    }
}
