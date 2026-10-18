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
    var onHero: Bool = false
    private let content: Content

    init(onHero: Bool = false, @ViewBuilder content: () -> Content) {
        self.onHero = onHero
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .padding()
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var fill: Color {
        if onHero {
            return Color.white.opacity(0.16)
        }
        return Color.secondary.opacity(colorScheme == .light ? 0.1 : 0.2)
    }
}
