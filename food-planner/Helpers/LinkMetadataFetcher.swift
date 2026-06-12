import Foundation
import LinkPresentation
import UIKit

enum LinkMetadataFetcher {
    static func thumbnailData(for url: URL) async -> Data? {
        await withCheckedContinuation { continuation in
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, _ in
                guard let imageProvider = metadata?.imageProvider else {
                    continuation.resume(returning: nil)
                    return
                }

                imageProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let image = object as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.85) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
