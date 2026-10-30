import SwiftUI
import UIKit

extension Notification.Name {
    static let richTextEditorDidChange = Notification.Name("richTextEditorDidChange")
}

struct RichTextEditorView: View {
    @Binding var attributedText: NSAttributedString

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RichTextEditorRepresentable(attributedText: $attributedText)
                    .frame(minHeight: 240)

                if attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("addRecipe.stepsPlaceholder")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }

            Divider()

            RichTextFormatToolbar()
        }
    }
}

// MARK: - Toolbar

struct RichTextFormatToolbar: View {
    private let items: [(icon: String, label: LocalizedStringResource, action: () -> Void)] = [
        ("bold", "addRecipe.format.bold", RichTextFormatting.toggleBold),
        ("underline", "addRecipe.format.underline", RichTextFormatting.toggleUnderline),
        ("textformat.size", "addRecipe.format.heading", RichTextFormatting.applyHeading),
        ("list.number", "addRecipe.format.numberedList", RichTextFormatting.toggleNumberedList),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider()
                        .frame(height: 22)
                }

                Button(action: item.action) {
                    Image(systemName: item.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(item.label))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - UITextView

private struct RichTextEditorRepresentable: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString

    func makeCoordinator() -> Coordinator {
        Coordinator(attributedText: $attributedText)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        textView.attributedText = RecipeStepsStorage.sanitizeListIndents(attributedText)
        RichTextFormatting.activeTextView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        RichTextFormatting.activeTextView = textView
        guard !context.coordinator.isEditing else { return }
        let sanitized = RecipeStepsStorage.sanitizeListIndents(attributedText)
        if textView.attributedText.string != sanitized.string {
            textView.attributedText = sanitized
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var attributedText: NSAttributedString
        var isEditing = false
        private var changeObserver: NSObjectProtocol?

        init(attributedText: Binding<NSAttributedString>) {
            _attributedText = attributedText
            super.init()
            changeObserver = NotificationCenter.default.addObserver(
                forName: .richTextEditorDidChange,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let textView = notification.object as? UITextView else { return }
                self?.attributedText = textView.attributedText
            }
        }

        deinit {
            if let changeObserver {
                NotificationCenter.default.removeObserver(changeObserver)
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            RichTextFormatting.activeTextView = textView
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            attributedText = textView.attributedText
        }

        func textViewDidChange(_ textView: UITextView) {
            attributedText = textView.attributedText
        }
    }
}

// MARK: - Formatting

enum RichTextFormatting {
    static weak var activeTextView: UITextView?

    static func toggleBold() {
        guard let textView = activeTextView else { return }
        let range = textView.selectedRange
        guard range.length > 0 else { return }

        textView.textStorage.beginEditing()
        textView.textStorage.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let current = (value as? UIFont) ?? .preferredFont(forTextStyle: .body)
            let traits = current.fontDescriptor.symbolicTraits
            let isBold = traits.contains(.traitBold)
            let newTraits = isBold
                ? traits.subtracting(.traitBold)
                : traits.union(.traitBold)
            if let descriptor = current.fontDescriptor.withSymbolicTraits(newTraits) {
                let font = UIFont(descriptor: descriptor, size: current.pointSize)
                textView.textStorage.addAttribute(.font, value: font, range: subrange)
            }
        }
        textView.textStorage.endEditing()
        syncFromTextView(textView)
    }

    static func toggleUnderline() {
        guard let textView = activeTextView else { return }
        let range = textView.selectedRange
        guard range.length > 0 else { return }

        textView.textStorage.beginEditing()
        textView.textStorage.enumerateAttribute(.underlineStyle, in: range) { value, subrange, _ in
            let style = (value as? Int) ?? 0
            let newStyle = style == 0 ? NSUnderlineStyle.single.rawValue : 0
            textView.textStorage.addAttribute(.underlineStyle, value: newStyle, range: subrange)
        }
        textView.textStorage.endEditing()
        syncFromTextView(textView)
    }

    static func applyHeading() {
        guard let textView = activeTextView else { return }
        let range = paragraphRange(in: textView)
        guard range.length > 0 else { return }

        let font = UIFont.preferredFont(forTextStyle: .title3)
        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
        let headingFont = UIFont(descriptor: boldDescriptor, size: font.pointSize)

        textView.textStorage.beginEditing()
        textView.textStorage.addAttribute(.font, value: headingFont, range: range)
        textView.textStorage.endEditing()
        syncFromTextView(textView)
    }

    static func toggleNumberedList() {
        guard let textView = activeTextView else { return }
        let range = paragraphRange(in: textView)
        guard range.length > 0 else { return }

        textView.textStorage.beginEditing()
        let existing = (textView.textStorage.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle)
        let mutable = (existing?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()

        if mutable.textLists.isEmpty {
            mutable.textLists = [NSTextList(markerFormat: .decimal, options: 0)]
        } else {
            mutable.textLists = []
        }

        textView.textStorage.addAttribute(.paragraphStyle, value: mutable, range: range)
        textView.textStorage.endEditing()
        syncFromTextView(textView)
    }

    private static func syncFromTextView(_ textView: UITextView) {
        NotificationCenter.default.post(name: .richTextEditorDidChange, object: textView)
    }

    private static func paragraphRange(in textView: UITextView) -> NSRange {
        let nsString = textView.textStorage.string as NSString
        let cursor = textView.selectedRange
        let location = cursor.length > 0 ? cursor.location : cursor.location
        return nsString.paragraphRange(for: NSRange(location: min(location, nsString.length), length: 0))
    }
}
