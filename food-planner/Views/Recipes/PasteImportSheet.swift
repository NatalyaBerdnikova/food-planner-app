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
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("import.paste.fromClipboard")
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                    .background(AppTheme.nestedFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("import.paste.footer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("import.privacy.server")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

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
                    .padding(.top, 12)
                }
                .padding(AppTheme.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
        .presentationDetents([.medium])
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else { return }
        pasteURL = text
    }
}
