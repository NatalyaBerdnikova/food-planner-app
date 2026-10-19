import SwiftUI

struct SparklesLoader: View {
    var size: CGFloat = 44
    var tint: Color = AppTheme.accent
    var accessibilityLabel: LocalizedStringKey = "common.loading"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBright = true

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(tint)
            .opacity(reduceMotion ? 1 : (isBright ? 1 : 0.2))
            .scaleEffect(reduceMotion ? 1 : (isBright ? 1.08 : 0.82))
            .accessibilityLabel(Text(accessibilityLabel))
            .onAppear(perform: startBlinkIfNeeded)
            .onChange(of: reduceMotion) { _, _ in
                startBlinkIfNeeded()
            }
    }

    private func startBlinkIfNeeded() {
        guard !reduceMotion else {
            isBright = true
            return
        }
        isBright = true
        withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
            isBright = false
        }
    }
}
