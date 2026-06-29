import SwiftUI

struct SubscriptionLoader: View {
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(2)
            }
        }
    }
}

struct SubscriptionHContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .padding()
        .background(Color.secondary.opacity(colorScheme == .light ? 0.1 : 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
