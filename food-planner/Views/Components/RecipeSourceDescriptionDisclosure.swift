import SwiftUI

struct RecipeSourceDescriptionDisclosure: View {
    let text: String
    @State private var isExpanded = false
    @State private var isChevronExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 12 : 0) {
            Button(action: toggle) {
                Label {
                    Text("recipe.sourceDescription")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isChevronExpanded ? 90 : 0))
                        .frame(width: 22, height: 22)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.2),
                            value: isChevronExpanded
                        )
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("recipe.sourceDescription")
            .accessibilityValue(Text(isExpanded ? "accessibility.expanded" : "accessibility.collapsed"))
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func toggle() {
        let next = !isExpanded

        var layoutTransaction = Transaction()
        layoutTransaction.disablesAnimations = true
        withTransaction(layoutTransaction) {
            isExpanded = next
        }

        isChevronExpanded = next
    }
}
