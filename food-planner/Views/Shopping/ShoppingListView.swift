import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var showShareSheet = false
    @State private var showAddItem = false

    private var currentWeekPlan: WeekPlan {
        WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
    }

    private var groupedItems: [(category: IngredientCategory, items: [ShoppingItem])] {
        let grouped = Dictionary(grouping: sortedItems, by: \.category)
        return IngredientCategory.shoppingListOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var sortedItems: [ShoppingItem] {
        currentWeekPlan.shoppingItems.sorted { lhs, rhs in
            if lhs.isPurchased != rhs.isPurchased {
                return !lhs.isPurchased
            }
            if lhs.category.shoppingListOrderIndex != rhs.category.shoppingListOrderIndex {
                return lhs.category.shoppingListOrderIndex < rhs.category.shoppingListOrderIndex
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    var body: some View {
        Group {
            if groupedItems.isEmpty {
                ContentUnavailableView(
                    "empty.shopping",
                    systemImage: "cart",
                    description: Text("empty.shopping.hint")
                )
            } else {
                List {
                    ForEach(groupedItems, id: \.category) { section in
                        Section {
                            ForEach(section.items) { item in
                                ShoppingItemRow(item: item)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if item.isManual {
                                            Button(role: .destructive) {
                                                deleteItem(item)
                                            } label: {
                                                Label("favorites.remove.confirm", systemImage: "trash")
                                            }
                                        }
                                    }
                            }
                        } header: {
                            Text(section.category.displayName)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("nav.shopping")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("shopping.addItem")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(groupedItems.isEmpty)
                .accessibilityLabel("accessibility.share")
            }
        }
        .onAppear { syncShoppingList() }
        .onChange(of: weekPlans.count) { _, _ in syncShoppingList() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showAddItem) {
            AddIngredientSheet { draft in
                addManualItem(draft)
            }
        }
    }

    private var shareText: String {
        let header = String(localized: "shopping.shareHeader")
        let sections = groupedItems.map { section in
            let title = String(localized: section.category.displayName)
            let lines = section.items.map { item in
                L10n.shoppingShareLine(
                    purchased: item.isPurchased,
                    name: item.displayName,
                    quantity: item.quantity,
                    unit: item.unit
                )
            }
            return ([title] + lines).joined(separator: "\n")
        }
        return header + "\n\n" + sections.joined(separator: "\n\n")
    }

    private func syncShoppingList() {
        WeekPlanService.syncShoppingItems(for: currentWeekPlan, in: modelContext)
    }

    private func addManualItem(_ draft: DraftIngredient) {
        WeekPlanService.addManualShoppingItem(
            product: draft.product,
            quantity: draft.quantity,
            unit: draft.unit,
            to: currentWeekPlan,
            in: modelContext
        )
    }

    private func deleteItem(_ item: ShoppingItem) {
        modelContext.delete(item)
        LocalPersistence.save(modelContext)
    }
}

struct ShoppingItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Button {
            item.isPurchased.toggle()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.displayName)
                            .strikethrough(item.isPurchased)
                            .foregroundStyle(item.isPurchased ? .secondary : .primary)
                        if item.isManual {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 0.06, green: 0.33, blue: 0.45))
                                .accessibilityLabel("shopping.manualItem")
                        }
                    }
                    Text(L10n.amount(quantity: item.quantity, unit: item.unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension IngredientCategory {
    var shoppingListOrderIndex: Int {
        Self.shoppingListOrder.firstIndex(of: self) ?? Int.max
    }
}
