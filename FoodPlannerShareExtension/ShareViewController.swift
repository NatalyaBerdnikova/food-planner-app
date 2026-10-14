import Social
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completeRequest()
            return
        }

        let providers = extensionItem.attachments ?? []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    let urlString = (item as? URL)?.absoluteString
                        ?? (item as? String)
                    self?.handleInstagramURL(urlString)
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    self?.handleInstagramURL(item as? String)
                }
                return
            }
        }

        completeRequest()
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private func handleInstagramURL(_ urlString: String?) {
        guard let urlString,
              urlString.contains("instagram.com") else {
            completeRequest()
            return
        }

        ImportAppGroup.savePendingImportURL(urlString)

        if let importURL = URL(string: "\(ImportAppGroup.importURLScheme)://import") {
            extensionContext?.open(importURL, completionHandler: nil)
        }

        completeRequest()
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
