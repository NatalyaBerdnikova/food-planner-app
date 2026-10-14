import SwiftUI
import UIKit

struct RecipeImageView: View {
    let imageData: Data?
    var cornerRadius: CGFloat = 12
    var pointSize: CGSize = CGSize(width: 320, height: 320)

    @Environment(\.displayScale) private var displayScale
    @State private var processedImage: UIImage?

    var body: some View {
        Group {
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFill()
            } else if imageData != nil {
                ZStack {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
