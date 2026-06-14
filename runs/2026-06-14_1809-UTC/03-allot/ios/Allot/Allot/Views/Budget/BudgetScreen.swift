import SwiftUI
import SwiftData

/// The hero screen: month switcher, Ready-to-Assign header, and collapsible
/// category groups with Assigned / Activity / Available per row.
struct BudgetScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Account.dateAdded) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var transactions: [Transaction]

    @State private var monthKey = BudgetEngine.currentMonthKey
    @State private var collapsedGroups: Set<String> = []
    @State private var assignTarget: Category?
    @State private var showAddCategory = false
    @State private var paywall: PaywallReason?

    private var readyToAssign: Double {
        BudgetEngine.readyToAssign(monthKey: monthKey, accounts: accounts, categories: categories, txns: transactions)
    }

    /// Groups that contain at least one category, in their canonical order.
    private var groupsInUse: [CategoryGroup] {
        let present = Set(categories.map { $0.group })
        return CategoryGroup.allCases.filter { present.contains($0) }.sorted { $0.sortRank < $1.sortRank }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if categories.isEmpty {
                    EmptyStateView(symbol: "tray",
                                   title: "No categories yet",
                                   message: "Add a few categories, then give every dollar a job.",
                                   actionTitle: "Add category") { addCategoryTapped() }
                } else {
                    content
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addCategoryTapped() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add category")
                }
            }
            .sheet(item: $assignTarget) { cat in
                AssignSheet(category: cat, monthKey: monthKey)
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet()
            }
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: []) {
                MonthSwitcher(monthKey: $monthKey, hapticsEnabled: settings.hapticsEnabled)
                ReadyToAssignHeader(amount: readyToAssign, settings: settings)

                ForEach(groupsInUse, id: \.self) { group in
                    groupSection(group)
                }
            }
            .padding(16)
        }
    }

    private func groupSection(_ group: CategoryGroup) -> some View {
        let cats = categories
            .filter { $0.group == group }
            .sorted { $0.sortOrder < $1.sortOrder }
        let collapsed = collapsedGroups.contains(group.rawValue)
        let groupAssigned = cats.reduce(0.0) { $0 + BudgetEngine.allocated($1, monthKey: monthKey) }

        return VStack(spacing: 0) {
            Button {
                toggle(group)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: group.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    Text(group.label)
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(settings.money(groupAssigned))
                        .font(Theme.money(14, .medium))
                        .monospacedDigit()
                        .foregroundStyle(Theme.inkSoft)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.inkFaint)
                        .rotationEffect(.degrees(collapsed ? -90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.label) group")
            .accessibilityHint(collapsed ? "Collapsed. Double tap to expand." : "Expanded. Double tap to collapse.")

            if !collapsed {
                ForEach(cats) { cat in
                    Divider().overlay(Theme.hairline)
                    CategoryRow(category: cat,
                                monthKey: monthKey,
                                transactions: transactions,
                                settings: settings) {
                        assignTarget = cat
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }

    private func toggle(_ group: CategoryGroup) {
        Haptics.tap(settings.hapticsEnabled)
        withAnimation(.easeInOut(duration: 0.2)) {
            if collapsedGroups.contains(group.rawValue) {
                collapsedGroups.remove(group.rawValue)
            } else {
                collapsedGroups.insert(group.rawValue)
            }
        }
    }

    private func addCategoryTapped() {
        if Pro.canAddCategory(currentCount: categories.count, isPro: isPro) {
            showAddCategory = true
        } else {
            paywall = .categoryLimit
        }
    }
}
