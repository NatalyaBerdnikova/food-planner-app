import SwiftUI

struct BootstrapSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            AppTheme.heroGradient.ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(y: -36)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    Text("bootstrap.title")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                        .opacity(isRevealed ? 1 : 0)
                        .offset(y: isRevealed ? 0 : 12)

                    Text("bootstrap.subtitle")
                        .font(.title3.weight(.regular))
                        .fontDesign(.rounded)
                        .foregroundStyle(.white.opacity(0.86))
                        .opacity(isRevealed ? 1 : 0)
                        .offset(y: isRevealed ? 0 : 10)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 0)

                SparklesLoader(size: 36, tint: .white.opacity(0.95))
                    .padding(.bottom, 56)
                    .opacity(isRevealed ? 1 : 0)
            }
        }
        .onAppear(perform: revealIfNeeded)
        .onChange(of: reduceMotion) { _, _ in
            revealIfNeeded()
        }
    }

    private func revealIfNeeded() {
        if reduceMotion {
            isRevealed = true
            return
        }
        isRevealed = false
        withAnimation(.spring(response: 0.72, dampingFraction: 0.86).delay(0.08)) {
            isRevealed = true
        }
    }
}

#Preview {
    BootstrapSplashView()
}
