import Foundation
import UIKit

enum RecipeStepsStorage {
    static func rtfData(from attributed: NSAttributedString) -> Data? {
        guard attributed.length > 0 else { return nil }
        return try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    static func attributedString(from data: Data) -> NSAttributedString? {
        try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
    }

    static func plainStepLines(from attributed: NSAttributedString) -> [String] {
        attributed.string
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func attributedString(fromPlainSteps steps: [String]) -> NSAttributedString {
        let body = steps.joined(separator: "\n")
        return NSAttributedString(
            string: body,
            attributes: defaultBodyAttributes()
        )
    }

    static func defaultBodyAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ]
    }
}
