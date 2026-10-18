import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var showShareSheet = false
    @State private var showAddItem = false

    private var currentWeekPlan: WeekPlan? {
        WeekPlanService.findCurrentWeekPlan(in: weekPlans)
    }

    private var groupedItems: [(category: IngredientCategory, items: [ShoppingItem])] {
        guard currentWeekPlan != nil else { return [] }

        let grouped = Dictionary(grouping: sortedItems, by: \.category)
        return IngredientCategory.shoppingListOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var sortedItems: [ShoppingItem] {
        guard let plan = currentWeekPlan else { return [] }
        return plan.shoppingItems.sorted { lhs, rhs in
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
            AddIngredientSheet(autofocusSearch: true) { draft in
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
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }

    private func addManualItem(_ draft: DraftIngredient) {
        let plan = WeekPlanService.currentWeekPlan(from: weekPlans, in: modelContext)
        WeekPlanService.addManualShoppingItem(
            product: draft.product,
            quantity: draft.quantity,
            unit: draft.unit,
            to: plan,
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
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .strikethrough(item.isPurchased)
                        .foregroundStyle(item.isPurchased ? .secondary : .primary)

                    HStack(spacing: 4) {
                        if item.isManual {
                            Image(systemName: "square.and.pencil")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                                .accessibilityLabel("shopping.manualItem")
                        }
                        Text(L10n.amount(quantity: item.quantity, unit: item.unit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
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
