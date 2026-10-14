import SwiftUI

struct PasteImportRequest: Identifiable {
    let id = UUID()
}

struct PasteImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ImportCoordinator.self) private var importCoordinator
    @State private var pasteURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("import.paste.placeholder", text: $pasteURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("import.paste.title")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("import.paste.footer")
                        Text("import.privacy.server")
                    }
                }
            }
            .navigationTitle("import.paste.nav")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("import.paste.action") {
                        let url = pasteURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !url.isEmpty else { return }
                        dismiss()
                        importCoordinator.startImport(urlString: url)
                    }
                    .disabled(pasteURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
