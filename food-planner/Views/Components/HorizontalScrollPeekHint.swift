import SwiftUI

struct HorizontalScrollPeekHint<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didPlayHint = false
    @State private var peekOffset: CGFloat = 0

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content
                .offset(x: peekOffset)
        }
        .onAppear {
            playHintIfNeeded()
        }
    }

    private func playHintIfNeeded() {
        guard !didPlayHint, !reduceMotion else { return }
        didPlayHint = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeInOut(duration: 0.4)) {
                peekOffset = -32
            }
            try? await Task.sleep(for: .milliseconds(480))
            withAnimation(.easeInOut(duration: 0.45)) {
                peekOffset = 0
            }
        }
    }
}
