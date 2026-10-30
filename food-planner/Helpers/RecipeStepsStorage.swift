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
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return nil
        }
        return sanitizeListIndents(attributed)
    }

    static func sanitizeListIndents(_ attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        let fullRange = NSRange(location: 0, length: mutable.length)
        guard fullRange.length > 0 else { return attributed }

        mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            guard let style = value as? NSParagraphStyle, !style.textLists.isEmpty else { return }
            let cleaned = style.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            cleaned.textLists = style.textLists
            cleaned.paragraphSpacing = max(style.paragraphSpacing, 6)
            cleaned.headIndent = 28
            cleaned.firstLineHeadIndent = 0
            cleaned.defaultTabInterval = 28
            cleaned.tabStops = [
                NSTextTab(textAlignment: .left, location: 28, options: [:])
            ]
            mutable.addAttribute(.paragraphStyle, value: cleaned, range: range)
        }
        return mutable
    }

    static func plainStepLines(from attributed: NSAttributedString) -> [String] {
        attributed.string
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func attributedString(fromPlainSteps steps: [String]) -> NSAttributedString {
        attributedRecipeDocument(intro: nil, steps: steps)
    }

    /// Builds text compatible with `RichTextEditorView` (optional intro + decimal `NSTextList`).
    static func attributedRecipeDocument(intro: String?, steps: [String]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let trimmedIntro = intro?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedIntro, !trimmedIntro.isEmpty {
            result.append(NSAttributedString(string: trimmedIntro, attributes: introAttributes()))
            if !steps.isEmpty {
                result.append(NSAttributedString(string: "\n", attributes: defaultBodyAttributes()))
            }
        }

        let listStyle = NSMutableParagraphStyle()
        listStyle.textLists = [NSTextList(markerFormat: .decimal, options: 0)]
        listStyle.paragraphSpacing = 6
        listStyle.headIndent = 28
        listStyle.firstLineHeadIndent = 0
        listStyle.defaultTabInterval = 28
        listStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: 28, options: [:])
        ]

        var bodyAttributes = defaultBodyAttributes()
        bodyAttributes[.paragraphStyle] = listStyle

        for step in steps {
            let line = step.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let prefix = result.length > 0 ? "\n" : ""
            result.append(NSAttributedString(string: "\(prefix)\(line)", attributes: bodyAttributes))
        }

        if result.length == 0 {
            return NSAttributedString(string: "", attributes: defaultBodyAttributes())
        }
        return result
    }

    static func defaultBodyAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ]
    }

    static func introAttributes() -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        return [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: style,
        ]
    }

    static func headingAttributes() -> [NSAttributedString.Key: Any] {
        let font = UIFont.preferredFont(forTextStyle: .title3)
        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
        let headingFont = UIFont(descriptor: boldDescriptor, size: font.pointSize)
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 8
        return [
            .font: headingFont,
            .foregroundColor: UIColor.label,
            .paragraphStyle: style,
        ]
    }
}
