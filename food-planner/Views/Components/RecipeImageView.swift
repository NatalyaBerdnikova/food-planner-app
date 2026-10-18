import SwiftUI
import UIKit

struct RecipeImageView: View {
    let imageData: Data?
    var cornerRadius: CGFloat = 12
    var pointSize: CGSize = CGSize(width: 320, height: 320)

    @Environment(\.displayScale) private var displayScale
    @State private var processedImage: UIImage?

    var body: some View {
        Color(.secondarySystemBackground)
            .overlay {
                if let processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFill()
                } else if imageData != nil {
                    ProgressView()
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .task(id: imageData) {
                guard let imageData else {
                    processedImage = nil
                    return
                }
                let scale = displayScale
                let size = pointSize
                processedImage = await ImageProcessor.shared.downsample(
                    data: imageData,
                    pointSize: size,
                    scale: scale
                )
            }
    }
}
