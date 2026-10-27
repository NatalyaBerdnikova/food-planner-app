import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(WeekPlanGenerationCoordinator.self) private var weekPlanGeneration
    @Environment(WeekPlanTransferCoordinator.self) private var weekPlanTransfer
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var displayedWeekStart = Calendar.current.startOfWeek(for: .now)
    @State private var selectedDay: Date?
    @State private var scrollPosition = ScrollPosition(idType: Date.self)
    @State private var addMealPresentation: AddMealPresentation?
    @State private var isImportingFile = false
    @State private var showClearConfirmation = false

    private var displayedWeekPlan: WeekPlan? {
        let normalized = Calendar.current.startOfWeek(for: displayedWeekStart)
        return weekPlans.first { Calendar.current.isSameDay($0.weekStartDate, normalized) }
    }

    private var targetNutrition: DailyNutrition? {
        settingsList.first?.targetNutrition
    }

    private var micronutrientFocus: [MicronutrientKind] {
        settingsList.first?.profileMicronutrientFocus ?? []
    }

    private var canClearDisplayedPlan: Bool {
        guard let plan = displayedWeekPlan else { return false }
        let hasMeals = plan.dayPlans.contains { !$0.meals.isEmpty }
        return hasMeals || !plan.shoppingItems.isEmpty
    }

    var body: some View {
        @Bindable var weekPlanGeneration = weekPlanGeneration
        content
            .navigationTitle("nav.weekPlan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        weekPlanGeneration.presentCompose()
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .accessibilityLabel("weekPlan.generate.title")

                    Menu {
                        Button {
                            shareDisplayedWeek()
                        } label: {
                            Label("weekPlan.share", systemImage: "square.and.arrow.up")
                        }
                        .disabled(displayedWeekPlan == nil)

                        Button {
                            isImportingFile = true
                        } label: {
                            Label("weekPlan.import", systemImage: "square.and.arrow.down")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("weekPlan.clear", systemImage: "trash")
                        }
                        .disabled(!canClearDisplayedPlan)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("weekPlan.actions")
                }
            }
            .task(id: displayedWeekStart) {
                ensureDisplayedWeekPlan()
            }
            .onChange(of: weekPlans.count) { _, _ in
                updateSelectedDayIfNeeded()
            }
            .sheet(item: $addMealPresentation) { item in
                AddMealSheet(dayPlan: item.dayPlan, preferredMealType: item.mealType) {
                    syncShoppingList()
                }
                .appFormSheetPresentation()
            }
            .sheet(item: $weekPlanGeneration.composePresentation) { _ in
                GenerateWeekPlanSheet()
            }
            .alert("weekPlan.clear.title", isPresented: $showClearConfirmation) {
                Button("common.cancel", role: .cancel) {}
                Button("weekPlan.clear.confirm", role: .destructive) {
                    clearDisplayedPlan()
                }
            } message: {
                Text("weekPlan.clear.message")
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [FoodPlanUTType.utType, .json, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    weekPlanTransfer.importFromFile(
                        url: url,
                        targetWeekStart: displayedWeekStart
                    )
                case .failure(let error):
                    weekPlanTransfer.errorMessage = error.localizedDescription
                    weekPlanTransfer.showsError = true
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if let weekPlan = displayedWeekPlan {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    WeekRangeSwitcher(weekStart: $displayedWeekStart)

                    WeekDayCarousel(
                        dayPlans: sortedDayPlans(weekPlan),
                        targetNutrition: targetNutrition,
                        micronutrientFocus: micronutrientFocus,
                        selectedDay: $selectedDay,
                        onTapEmptyMeal: presentAddMeal
                    )
                }
                .padding(.horizontal, AppTheme.contentPadding)
                .padding(.bottom, AppTheme.contentPadding)
                .appWideReadableWidth()
            }
            .scrollPosition($scrollPosition)
            .appScreenBackground()
            .onAppear {
                scrollToCurrentDayIfNeeded()
            }
            .onChange(of: displayedWeekStart) { _, _ in
                scrollToCurrentDayIfNeeded()
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appScreenBackground()
        }
    }

    private func shareDisplayedWeek() {
        guard let weekPlan = displayedWeekPlan else { return }
        weekPlanTransfer.beginExport(weekPlan: weekPlan, targets: targetNutrition)
    }

    private func clearDisplayedPlan() {
        guard let weekPlan = displayedWeekPlan else { return }
        WeekPlanService.clearPlan(weekPlan, in: modelContext)
    }

    private func scrollToCurrentDayIfNeeded() {
        let calendar = Calendar.current
        guard let todayPlan = displayedWeekPlan?.dayPlans.first(where: { calendar.isDateInToday($0.date) }) else {
            return
        }
        let dayID = calendar.startOfDay(for: todayPlan.date)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            if reduceMotion {
                scrollPosition.scrollTo(id: dayID, anchor: .top)
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    scrollPosition.scrollTo(id: dayID, anchor: .top)
                }
            }
        }
    }

    private func sortedDayPlans(_ weekPlan: WeekPlan) -> [DayPlan] {
        weekPlan.dayPlans.sorted { $0.date < $1.date }
    }

    private func presentAddMeal(_ dayPlan: DayPlan, mealType: MealType) {
        addMealPresentation = AddMealPresentation(dayPlan: dayPlan, mealType: mealType)
    }

    private func syncShoppingList() {
        guard let plan = displayedWeekPlan else { return }
        WeekPlanService.syncShoppingItems(for: plan, in: modelContext)
    }

    private func ensureDisplayedWeekPlan() {
        let plan = WeekPlanService.weekPlan(
            forWeekStarting: displayedWeekStart,
            from: weekPlans,
            in: modelContext
        )
        AppSettingsService.setActiveWeekPlan(plan, in: modelContext)
        updateSelectedDay(for: plan)
    }

    private func updateSelectedDayIfNeeded() {
        guard let plan = displayedWeekPlan else { return }
        updateSelectedDay(for: plan)
    }

    private func updateSelectedDay(for plan: WeekPlan) {
        let calendar = Calendar.current
        if let today = plan.dayPlans.first(where: { calendar.isDateInToday($0.date) })?.date {
            selectedDay = today
        } else {
            selectedDay = sortedDayPlans(plan).first?.date ?? calendar.startOfDay(for: plan.weekStartDate)
        }
    }
}
