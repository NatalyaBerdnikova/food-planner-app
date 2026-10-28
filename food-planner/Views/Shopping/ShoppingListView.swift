import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]

    @State private var displayedWeekStart = Calendar.current.startOfWeek(for: .now)
    @State private var showShareSheet = false
    @State private var showAddItem = false

    private var displayedWeekPlan: WeekPlan? {
        let normalized = Calendar.current.startOfWeek(for: displayedWeekStart)
        return weekPlans.first { Calendar.current.isSameDay($0.weekStartDate, normalized) }
    }

    private var groupedItems: [(category: IngredientCategory, items: [ShoppingItem])] {
        guard displayedWeekPlan != nil else { return [] }

        let grouped = Dictionary(grouping: sortedItems, by: \.category)
        return IngredientCategory.shoppingListOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    private var sortedItems: [ShoppingItem] {
        guard let plan = displayedWeekPlan else { return [] }
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
        List {
            Section {
                WeekRangeSwitcher(weekStart: $displayedWeekStart)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if groupedItems.isEmpty {
                Section {
                    ContentUnavailableView(
                        "empty.shopping",
                        systemImage: "cart",
                        description: Text("empty.shopping.hint")
                    )
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } else {
                ForEach(groupedItems, id: \.category) { section in
                    Section {
                        ForEach(section.items) { item in
                            ShoppingItemRow(item: item)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if item.isManual {
                                        Button(role: .destructive) {
                                            deleteItem(item)
                                        } label: {
                                                Label("shopping.deleteItem", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    } header: {
                        Text(section.category.displayName)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .appScreenBackground()
        .navigationTitle("nav.shopping")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("shopping.addItem")

                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(groupedItems.isEmpty)
                .accessibilityLabel("accessibility.share")
            }
        }
        .task(id: displayedWeekStart) {
            syncShoppingList()
        }
        .onAppear {
            AppAnalytics.logShoppingListOpen(itemsCount: sortedItems.count)
        }
        .onChange(of: weekPlans.count) { _, _ in syncShoppingList() }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showAddItem) {
            AddIngredientSheet(autofocusSearch: true) { draft in
                addManualItem(draft)
            }
            .appFormSheetPresentation()
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
        let plan = WeekPlanService.weekPlan(
            forWeekStarting: displayedWeekStart,
            from: weekPlans,
            in: modelContext,
            setAsActive: false
        )
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }

    private func addManualItem(_ draft: DraftIngredient) {
        let plan = WeekPlanService.weekPlan(
            forWeekStarting: displayedWeekStart,
            from: weekPlans,
            in: modelContext,
            setAsActive: false
        )
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.displayName)
        .accessibilityValue(
            Text(item.isPurchased ? "accessibility.purchased" : "accessibility.notPurchased")
        )
        .accessibilityHint("accessibility.togglePurchased")
        .accessibilityAddTraits(.isButton)
    }
}

private extension IngredientCategory {
    var shoppingListOrderIndex: Int {
        Self.shoppingListOrder.firstIndex(of: self) ?? Int.max
    }
}
