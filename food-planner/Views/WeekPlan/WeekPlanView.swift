import SwiftUI
import SwiftData

struct WeekPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeekPlan.weekStartDate, order: .reverse) private var weekPlans: [WeekPlan]
    @Query(filter: #Predicate<AppSettings> { $0.singletonKey == "main" })
    private var settingsList: [AppSettings]

    @State private var displayedWeekStart = Calendar.current.startOfWeek(for: .now)
    @State private var selectedDay: Date?
    @State private var addMealPresentation: AddMealPresentation?

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

    var body: some View {
        content
            .navigationTitle("nav.weekPlan")
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
            }
    }

    @ViewBuilder
    private var content: some View {
        if let weekPlan = displayedWeekPlan {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: AppTheme.sectionSpacing) {
                        weekSwitcher

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
                }
                .appScreenBackground()
                .onAppear {
                    scrollToCurrentDay(using: proxy)
                }
                .onChange(of: displayedWeekStart) { _, _ in
                    scrollToCurrentDay(using: proxy)
                }
            }
        } else {
            ProgressView()
        }
    }

    private func scrollToCurrentDay(using proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        guard let todayPlan = displayedWeekPlan?.dayPlans.first(where: { calendar.isDateInToday($0.date) }) else {
            return
        }
        let dayID = calendar.startOfDay(for: todayPlan.date)
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(dayID, anchor: .top)
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

    private var weekSwitcher: some View {
        HStack {
            Button {
                shiftWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }

            Spacer()

            Text(weekRangeTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                shiftWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 4)
        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    private var weekRangeTitle: String {
        guard let weekPlan = displayedWeekPlan else { return "" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekPlan.weekStartDate)
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: start) else {
            return start.formatted(.dateTime.day().month(.abbreviated))
        }
        let startText = start.formatted(.dateTime.day().month(.abbreviated))
        let endText = endDate.formatted(.dateTime.day().month(.abbreviated))
        return "\(startText) - \(endText)"
    }

    private func shiftWeek(by offset: Int) {
        guard let newStart = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: displayedWeekStart) else {
            return
        }
        displayedWeekStart = Calendar.current.startOfWeek(for: newStart)
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
