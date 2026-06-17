import SwiftUI
import SwiftData

enum SubFilter: String, CaseIterable, Identifiable {
    case all, active, trials, cancelled
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .trials: return "Trials"
        case .cancelled: return "Cancelled"
        }
    }
}

enum SubSort: String, CaseIterable, Identifiable {
    case nextRenewal, costHigh, name
    var id: String { rawValue }
    var label: String {
        switch self {
        case .nextRenewal: return "Next renewal"
        case .costHigh: return "Cost (high to low)"
        case .name: return "Name"
        }
    }
}

struct SubscriptionsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.createdAt, order: .reverse) private var subscriptions: [Subscription]

    @AppStorage(PrefKey.currencyCode) private var currencyCode: String = PrefDefault.currencyCode
    @AppStorage(PrefKey.hideAmounts) private var hideAmounts: Bool = false

    @State private var filter: SubFilter = .all
    @State private var sort: SubSort = .nextRenewal
    @State private var search: String = ""
    @State private var showAddSheet = false
    @State private var pendingDelete: Subscription?

    private let renewal = RenewalEngine()

    private var filtered: [Subscription] {
        var list = subscriptions
        switch filter {
        case .all:        break
        case .active:     list = list.filter { $0.isActive && !$0.isTrial }
        case .trials:     list = list.filter { $0.isActive && $0.isTrial }
        case .cancelled:  list = list.filter { !$0.isActive }
        }
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !term.isEmpty {
            list = list.filter {
                $0.name.lowercased().contains(term) ||
                $0.category.label.lowercased().contains(term)
            }
        }
        return sortList(list)
    }

    private func sortList(_ list: [Subscription]) -> [Subscription] {
        switch sort {
        case .name:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .costHigh:
            return list.sorted { $0.monthlyEquivalent > $1.monthlyEquivalent }
        case .nextRenewal:
            // Active first, then by soonest renewal; cancelled sink to bottom.
            return list.sorted { a, b in
                if a.isActive != b.isActive { return a.isActive && !b.isActive }
                let da = renewal.nextRenewal(firstBillingDate: a.firstBillingDate, cycle: a.cycle)
                let db = renewal.nextRenewal(firstBillingDate: b.firstBillingDate, cycle: b.cycle)
                return da < db
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RecurTheme.appBackground(scheme).ignoresSafeArea()
                if subscriptions.isEmpty {
                    ScrollView {
                        EmptyStateView(symbol: "square.stack.3d.up.slash",
                                       title: "No subscriptions",
                                       message: "Track your first recurring payment to get started.",
                                       actionTitle: "Add subscription") { showAddSheet = true }
                            .padding(.top, 60)
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar { toolbarContent }
            .searchable(text: $search, prompt: "Search subscriptions")
            .sheet(isPresented: $showAddSheet) {
                SubscriptionEditorView(mode: .create)
            }
            .navigationDestination(for: UUID.self) { id in
                if let sub = subscriptions.first(where: { $0.id == id }) {
                    SubscriptionDetailView(subscription: sub)
                } else {
                    EmptyStateView(symbol: "questionmark.folder", title: "Not found",
                                   message: "This subscription is no longer available.")
                }
            }
            .alert("Delete subscription?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This permanently removes \(pendingDelete?.name ?? "this subscription") and its price history.")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(SubSort.allCases) { Text($0.label).tag($0) }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort subscriptions")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAddSheet = true } label: { Image(systemName: "plus") }
                .accessibilityLabel("Add subscription")
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            filterBar
            if filtered.isEmpty {
                ScrollView {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "No subscriptions match this filter or search.")
                        .padding(.top, 40)
                }
            } else {
                List {
                    ForEach(filtered) { sub in
                        ZStack {
                            NavigationLink(value: sub.id) { EmptyView() }.opacity(0)
                            SubscriptionRow(subscription: sub, currencyCode: currencyCode, hideAmounts: hideAmounts)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { pendingDelete = sub } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            if sub.isActive {
                                Button { cancelSub(sub) } label: {
                                    Label("Cancel", systemImage: "pause.circle")
                                }.tint(RecurTheme.amber)
                            } else {
                                Button { reactivate(sub) } label: {
                                    Label("Reactivate", systemImage: "arrow.clockwise")
                                }.tint(RecurTheme.teal)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SubFilter.allCases) { f in
                    Button {
                        Haptics.selection()
                        filter = f
                    } label: {
                        Text(f.label).recurChip(selected: filter == f)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == f ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private func cancelSub(_ sub: Subscription) {
        sub.isActive = false
        sub.cancelledDate = Date()
        try? modelContext.save()
        Haptics.warning()
    }

    private func reactivate(_ sub: Subscription) {
        sub.isActive = true
        sub.cancelledDate = nil
        try? modelContext.save()
        Haptics.success()
    }

    private func confirmDelete() {
        guard let sub = pendingDelete else { return }
        modelContext.delete(sub)
        try? modelContext.save()
        pendingDelete = nil
        Haptics.warning()
    }
}

// MARK: - Row

struct SubscriptionRow: View {
    @Environment(\.colorScheme) private var scheme
    let subscription: Subscription
    let currencyCode: String
    let hideAmounts: Bool

    private let renewal = RenewalEngine()

    private var daysUntil: Int {
        renewal.daysUntilRenewal(firstBillingDate: subscription.firstBillingDate, cycle: subscription.cycle)
    }

    var body: some View {
        HStack(spacing: 12) {
            SubGlyph(colorHex: subscription.colorHex, symbol: subscription.iconName)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(subscription.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(RecurTheme.primaryText(scheme))
                        .lineLimit(1)
                    if subscription.isTrial { TrialBadge() }
                }
                HStack(spacing: 6) {
                    CategoryDot(colorHex: subscription.colorHex)
                    Text(subscription.category.label)
                        .font(.caption)
                        .foregroundStyle(RecurTheme.secondaryText(scheme))
                    Text("·").foregroundStyle(RecurTheme.secondaryText(scheme))
                    Text(subStatusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                MoneyText(value: subscription.monthlyEquivalent, code: currencyCode, hidden: hideAmounts)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                Text("/ mo")
                    .font(.caption2)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RecurTheme.cardSurface(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RecurTheme.hairline(scheme), lineWidth: 1)
        )
        .opacity(subscription.isActive ? 1 : 0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens details")
    }

    private var subStatusText: String {
        if !subscription.isActive { return "Cancelled" }
        if subscription.isTrial, let end = subscription.trialEndDate {
            let d = renewal.days(from: Date(), to: end)
            return "Trial ends \(DateText.relativeDays(d))"
        }
        return "Renews \(DateText.relativeDays(daysUntil))"
    }

    private var statusColor: Color {
        if !subscription.isActive { return RecurTheme.coral }
        if subscription.isTrial { return RecurTheme.amber }
        return RecurTheme.secondaryText(scheme)
    }

    private var accessibilityText: String {
        let money = hideAmounts ? "amount hidden" : MoneyFormatter.string(subscription.monthlyEquivalent, code: currencyCode) + " per month"
        return "\(subscription.name), \(subscription.category.label), \(money), \(subStatusText)"
    }
}
