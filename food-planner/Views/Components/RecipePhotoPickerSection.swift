import PhotosUI
import SwiftUI

struct RecipePhotoPickerSection: View {
    @Binding var imageData: Data?
    @Binding var photoPickerItem: PhotosPickerItem?
    var height: CGFloat = 180

    var body: some View {
        Section {
            if imageData != nil {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    ZStack(alignment: .bottom) {
                        RecipeImageView(
                            imageData: imageData,
                            cornerRadius: 0,
                            pointSize: CGSize(width: 780, height: height * 2)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .clipped()

                        Label("addRecipe.replacePhoto", systemImage: "photo.on.rectangle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 14)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .accessibilityLabel("addRecipe.replacePhoto")
            } else {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("addRecipe.pickPhoto", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("addRecipe.photo")
        }
    }
}
