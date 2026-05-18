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
                    "empty.shopping",
                    systemImage: "cart",
                    description: Text("empty.shopping.hint")
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
        .navigationTitle("nav.shopping")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(sortedItems.isEmpty)
                .accessibilityLabel("accessibility.share")
            }
        }
        .onAppear { refreshList() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    private var shareText: String {
        let header = String(localized: "shopping.shareHeader")
        let lines = sortedItems.map { item in
            L10n.shoppingShareLine(
                purchased: item.isPurchased,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit
            )
        }
        return header + "\n\n" + lines.joined(separator: "\n")
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
                    Text(L10n.amount(quantity: item.quantity, unit: item.unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
