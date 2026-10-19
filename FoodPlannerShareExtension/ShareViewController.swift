import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStart else { return }
        didStart = true
        processSharedItems()
    }

    private func processSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completeRequest()
            return
        }

        let providers = extensionItem.attachments ?? []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    let urlString = (item as? URL)?.absoluteString ?? (item as? String)
                    DispatchQueue.main.async {
                        self?.finishWithInstagramURL(urlString)
                    }
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    DispatchQueue.main.async {
                        self?.finishWithInstagramURL(item as? String)
                    }
                }
                return
            }
        }

        completeRequest()
    }

    private func finishWithInstagramURL(_ urlString: String?) {
        guard let urlString, Self.isInstagramURL(urlString) else {
            completeRequest()
            return
        }

        ImportAppGroup.savePendingImportURL(urlString)
        openHostApp(with: urlString) { [weak self] in
            self?.completeRequest()
        }
    }

    private static func isInstagramURL(_ urlString: String) -> Bool {
        let lowered = urlString.lowercased()
        return lowered.contains("instagram.com") || lowered.contains("instagr.am")
    }

    private func openHostApp(with instagramURL: String, completion: @escaping () -> Void) {
        guard let importURL = ImportAppGroup.importDeepLink(forInstagramURL: instagramURL) else {
            completion()
            return
        }

        var responder: UIResponder? = self
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(importURL, options: [:]) { _ in
                    completion()
                }
                return
            }

            let selector = NSSelectorFromString("openURL:")
            if current.responds(to: selector) {
                _ = current.perform(selector, with: importURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: completion)
                return
            }

            responder = current.next
        }

        extensionContext?.open(importURL) { _ in
            completion()
        } ?? completion()
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
