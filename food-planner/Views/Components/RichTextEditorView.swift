import SwiftUI
import UIKit

extension Notification.Name {
    static let richTextEditorDidChange = Notification.Name("richTextEditorDidChange")
}

struct RichTextEditorView: View {
    @Binding var attributedText: NSAttributedString

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RichTextFormatToolbar(attributedText: $attributedText)

            ZStack(alignment: .topLeading) {
                RichTextEditorRepresentable(attributedText: $attributedText)
                    .frame(minHeight: 160)

                if attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("addRecipe.stepsPlaceholder")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Toolbar

struct RichTextFormatToolbar: View {
    @Binding var attributedText: NSAttributedString

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                formatButton("bold", label: "addRecipe.format.bold") {
                    RichTextFormatting.toggleBold()
                }
                formatButton("underline", label: "addRecipe.format.underline") {
                    RichTextFormatting.toggleUnderline()
                }
                formatButton("textformat.size", label: "addRecipe.format.heading") {
                    RichTextFormatting.applyHeading()
                }
                formatButton("list.number", label: "addRecipe.format.numberedList") {
                    RichTextFormatting.toggleNumberedList()
                }
            }
        }
    }

    private func formatButton(
        _ systemImage: String,
        label: LocalizedStringResource,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 36, height: 36)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
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
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.attributedText = attributedText
        RichTextFormatting.activeTextView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        RichTextFormatting.activeTextView = textView
        guard !context.coordinator.isEditing else { return }
        if textView.attributedText.string != attributedText.string {
            textView.attributedText = attributedText
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
