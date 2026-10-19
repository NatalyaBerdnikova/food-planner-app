import SwiftUI

struct BlinkingLockIcon: View {
    var size: CGFloat = 44
    var tint: Color = AppTheme.accent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBright = true

    var body: some View {
        Image(systemName: "lock.open.fill")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(tint)
            .opacity(reduceMotion ? 1 : (isBright ? 1 : 0.62))
            .scaleEffect(reduceMotion ? 1 : (isBright ? 1.03 : 0.94))
            .accessibilityHidden(true)
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
        withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
            isBright = false
        }
    }
}
