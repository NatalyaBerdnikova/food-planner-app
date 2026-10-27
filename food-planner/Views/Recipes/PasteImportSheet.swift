import SwiftUI
import UIKit

struct PasteImportRequest: Identifiable {
    let id = UUID()
}

struct PasteImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ImportCoordinator.self) private var importCoordinator
    @State private var pasteURL = ""

    private var trimmedURL: String {
        pasteURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    urlSection

                    hintsCard

                    openSavedButton
                }
                .padding(AppTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("import.paste.nav")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("import.paste.action") {
                        guard !trimmedURL.isEmpty else { return }
                        dismiss()
                        importCoordinator.startImport(urlString: trimmedURL)
                    }
                    .disabled(trimmedURL.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .appFormSheetPresentation()
    }

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("import.paste.title")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                TextField("import.paste.placeholder", text: $pasteURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button {
                    pasteFromClipboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: AppTheme.minTapTarget, height: AppTheme.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("import.paste.fromClipboard")
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(
                AppTheme.elevated,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
    }

    private var hintsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            hintRow(
                systemImage: "text.bubble.fill",
                textKey: "import.paste.footer"
            )

            Divider()
                .padding(.leading, 36)

            hintRow(
                systemImage: "lock.shield.fill",
                textKey: "import.privacy.server"
            )

            Divider()
                .padding(.leading, 36)

            hintRow(
                systemImage: "square.and.arrow.up",
                textKey: "import.paste.shareHint"
            )
        }
        .background(
            AppTheme.nestedFill,
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
    }

    private var openSavedButton: some View {
        Button {
            InstagramAppLauncher.openSaved()
        } label: {
            HStack(spacing: 8) {
                Image("InstagramLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("import.hero.openSaved")

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
            }
            .font(.body.weight(.medium))
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppTheme.controlMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func hintRow(systemImage: String, textKey: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            Text(textKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else { return }
        pasteURL = text
    }
}
