import SwiftUI

struct SubscriptionLoader: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
            SparklesLoader()
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
