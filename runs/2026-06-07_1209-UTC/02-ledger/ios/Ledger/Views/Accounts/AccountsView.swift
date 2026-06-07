import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @AppStorage("ledger.currency") private var currency = "USD"
    @AppStorage("ledger.compactNumbers") private var compact = true
    @AppStorage("ledger.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var editing: Account?
    @State private var pendingDelete: Account?
    @State private var snapshotBanner = false

    private var active: [Account] { accounts.filter { !$0.archived } }
    private var assets: [Account] { active.filter { $0.type == .asset } }
    private var liabilities: [Account] { active.filter { $0.type == .liability } }
    private var netWorth: Double { AllocationEngine.netWorth(accounts) }

    private func fmt(_ v: Double) -> String {
        compact ? Money.compact(v, code: currency) : Money.string(v, code: currency)
    }

    var body: some View {
        NavigationStack {
            Group {
                if active.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "wallet.pass",
                                       title: "No accounts yet",
                                       message: "Add your accounts and debts to see your net worth. Everything stays on your device.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("Add an account", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            netWorthCard
                            if !assets.isEmpty { group("Assets", assets, total: AllocationEngine.totalAssets(accounts), positive: true) }
                            if !liabilities.isEmpty { group("Liabilities", liabilities, total: AllocationEngine.totalLiabilities(accounts), positive: false) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Net Worth")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { AccountEditView(account: nil) }
            .sheet(item: $editing) { acc in AccountEditView(account: acc) }
            .confirmationDialog("Delete this account?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let a = pendingDelete { delete(a) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
            .overlay(alignment: .bottom) {
                if snapshotBanner {
                    Text("Snapshot saved")
                        .font(.subheadline.weight(.medium)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Brand.inkGradient, in: Capsule())
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var netWorthCard: some View {
        VStack(spacing: 10) {
            Text("NET WORTH").font(Brand.mono(12, weight: .medium)).tracking(2).foregroundStyle(Brand.text3)
            Text(Money.string(netWorth, code: currency))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(netWorth >= 0 ? Brand.text : Brand.danger)
                .minimumScaleFactor(0.5).lineLimit(1)
            HStack(spacing: 18) {
                labelled("Assets", AllocationEngine.totalAssets(accounts), Brand.live)
                labelled("Debts", AllocationEngine.totalLiabilities(accounts), Brand.danger)
            }
            Button { takeSnapshot() } label: {
                Label("Take snapshot", systemImage: "camera.aperture").frame(maxWidth: .infinity)
            }.buttonStyle(InkButtonStyle()).padding(.top, 4)
        }
        .frame(maxWidth: .infinity).glassCard(padding: 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net worth \(Money.string(netWorth, code: currency))")
    }

    private func labelled(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(fmt(value)).font(Brand.mono(16, weight: .semibold)).foregroundStyle(color)
            Text(label.uppercased()).font(Brand.mono(9)).foregroundStyle(Brand.text3)
        }
    }

    private func group(_ title: String, _ list: [Account], total: Double, positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionTitle(text: title)
                Spacer()
                Text(fmt(total)).font(Brand.mono(14, weight: .semibold))
                    .foregroundStyle(positive ? Brand.live : Brand.danger)
            }.padding(.bottom, 6)
            ForEach(list) { acc in
                Button { editing = acc } label: { accountRow(acc) }.buttonStyle(.plain)
                    .contextMenu {
                        Button { editing = acc } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) {
                            if confirmDeletes { pendingDelete = acc } else { delete(acc) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                if acc.id != list.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private func accountRow(_ acc: Account) -> some View {
        HStack(spacing: 12) {
            Image(systemName: acc.assetClass.symbol)
                .foregroundStyle(acc.assetClass.tint).frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(acc.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Text(acc.institution.isEmpty ? acc.assetClass.rawValue : "\(acc.institution) · \(acc.assetClass.rawValue)")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(fmt(acc.balance)).font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.text)
        }
        .padding(.vertical, 8)
    }

    private func takeSnapshot() {
        let snap = Snapshot(date: Date())
        for a in active {
            snap.entries.append(SnapshotEntry(accountName: a.name, classRaw: a.classRaw,
                                              isLiability: a.type == .liability, value: a.balance))
        }
        context.insert(snap)
        try? context.save()
        Haptics.success()
        withAnimation(Brand.ease()) { snapshotBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(Brand.ease()) { snapshotBanner = false }
        }
    }

    private func delete(_ acc: Account) {
        context.delete(acc); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}
