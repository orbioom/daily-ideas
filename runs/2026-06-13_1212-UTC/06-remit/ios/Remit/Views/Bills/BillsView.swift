import SwiftUI
import SwiftData

/// Full CRUD list of all bills with search and sort, an add button gated by the
/// free-tier cap, and a delete-with-confirm.
struct BillsView: View {
    @Environment(\.modelContext) private var context
    @Environment(ProStore.self) private var pro
    @Query(sort: \Bill.dueDate) private var bills: [Bill]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("defaultRecurrence") private var defaultRecurrenceRaw = Recurrence.monthly.rawValue
    @AppStorage("defaultDueSoonDays") private var defaultDueSoonDays = 3

    @State private var query = ""
    @State private var sort: SortOption = .dueDate
    @State private var editing: Bill?
    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var pendingDelete: Bill?

    enum SortOption: String, CaseIterable, Identifiable {
        case dueDate = "Due date"
        case name = "Name"
        case amount = "Amount"
        var id: String { rawValue }
    }

    private var filtered: [Bill] {
        let base = query.isEmpty ? bills : bills.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
        switch sort {
        case .dueDate: return base.sorted { $0.dueDate < $1.dueDate }
        case .name:    return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .amount:  return base.sorted { $0.amount > $1.amount }
        }
    }

    private var atCap: Bool { !pro.isPro && bills.count >= Limits.freeBillCap }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if bills.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle.portrait.fill",
                                   title: "Add your first bill",
                                   message: "Rent, electricity, a streaming subscription, a loan — add anything you pay on a schedule and Remit tracks it for you.",
                                   actionTitle: "Add a bill") { startAdd() }
                } else {
                    list
                }
            }
            .navigationTitle("Bills")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort bills")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startAdd() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add bill")
                }
            }
            .searchable(text: $query, prompt: "Search bills")
            .sheet(isPresented: $showAdd) {
                BillFormView(bill: nil,
                             defaultRecurrence: Recurrence(rawValue: defaultRecurrenceRaw) ?? .monthly,
                             defaultDueSoonDays: defaultDueSoonDays,
                             currencyCode: currencyCode)
            }
            .sheet(item: $editing) { bill in
                BillFormView(bill: bill,
                             defaultRecurrence: bill.recurrence,
                             defaultDueSoonDays: bill.dueSoonDays,
                             currencyCode: currencyCode)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Delete bill?", isPresented: .init(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } })) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This removes \(pendingDelete?.name ?? "the bill") and its upcoming due dates. Its past payments stay in your history.")
            }
        }
    }

    private var list: some View {
        List {
            if atCap {
                Section {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                            Text("Free plan holds \(Limits.freeBillCap) bills. Unlock Pro for unlimited.")
                                .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                        }
                    }
                    .listRowBackground(Theme.accentSoft)
                }
            }
            Section {
                ForEach(filtered) { bill in
                    Button { editing = bill } label: {
                        BillRow(bill: bill, currencyCode: currencyCode)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.surface)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { pendingDelete = bill } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } footer: {
                Text(pro.isPro ? "\(bills.count) bills · Pro" : "\(bills.count) of \(Limits.freeBillCap) free bills")
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func startAdd() {
        if atCap { showPaywall = true; Haptics.warning() }
        else { showAdd = true }
    }

    private func confirmDelete() {
        guard let bill = pendingDelete else { return }
        // Detach payments so history survives (cascade would remove them).
        for p in bill.payments { p.bill = nil }
        context.delete(bill)
        try? context.save()
        pendingDelete = nil
        Haptics.success()
    }
}
