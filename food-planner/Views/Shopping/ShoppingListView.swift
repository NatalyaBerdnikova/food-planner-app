import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var currentWeekPlan: WeekPlan?
    @State private var showShareSheet = false

    private var sortedItems: [ShoppingItem] {
        guard let plan = currentWeekPlan else { return [] }
        return plan.shoppingItems.sorted { lhs, rhs in
            if lhs.isPurchased != rhs.isPurchased {
                return !lhs.isPurchased
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        Group {
            if sortedItems.isEmpty {
                ContentUnavailableView(
                    "Список пуст",
                    systemImage: "cart",
                    description: Text("Добавьте приёмы пищи в план на неделю — ингредиенты появятся здесь")
                )
            } else {
                List {
                    ForEach(sortedItems) { item in
                        ShoppingItemRow(item: item)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Список покупок")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(sortedItems.isEmpty)
                .accessibilityLabel("Поделиться")
            }
        }
        .onAppear { refreshList() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    private var shareText: String {
        let lines = sortedItems.map { item in
            let mark = item.isPurchased ? "✓ " : "○ "
            let qty = item.quantity.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", item.quantity)
                : String(format: "%.1f", item.quantity)
            return "\(mark)\(item.name) — \(qty) \(item.unit.displayName)"
        }
        return "Список покупок\n\n" + lines.joined(separator: "\n")
    }

    private func refreshList() {
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
        currentWeekPlan = plan
    }
}

struct ShoppingItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Button {
            item.isPurchased.toggle()
        } label: {
            HStack {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .strikethrough(item.isPurchased)
                        .foregroundStyle(item.isPurchased ? .secondary : .primary)
                    Text(formattedQuantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private var formattedQuantity: String {
        let qty = item.quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", item.quantity)
            : String(format: "%.1f", item.quantity)
        return "\(qty) \(item.unit.displayName)"
    }
}
