import SwiftUI
import SwiftData
import Charts

struct BankrollView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query(sort: \BankrollTransaction.date, order: .reverse) private var transactions: [BankrollTransaction]

    @State private var showAdd = false
    @State private var editing: BankrollTransaction?
    @State private var pendingDelete: BankrollTransaction?
    @State private var paywallReason: PaywallReason?
    @State private var buyInCushion = 20

    private var sym: String { settings.currencySymbol }
    private var hide: Bool { settings.hideAmounts }
    private var engine: StatsEngine { StatsEngine(sessions: sessions, transactions: transactions) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if !isPro {
                    lockedState
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Bankroll")
            .toolbar {
                if isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.tap(enabled: settings.hapticsEnabled)
                            showAdd = true
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                        }
                        .accessibilityLabel("Add transaction")
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddEditTransactionView(transaction: nil) }
            .sheet(item: $editing) { AddEditTransactionView(transaction: $0) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .confirmationDialog("Delete this transaction?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                balanceCard
                timelineCard
                guidanceCard
                transactionsCard
                Color.clear.frame(height: 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Balance hero

    private var balanceCard: some View {
        VStack(spacing: 14) {
            Text("Current bankroll")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(.white.opacity(0.85))
            Text(hide ? "\(sym)••••" : Money.string(engine.currentBankroll, symbol: sym))
                .font(Theme.mono(38, .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            HStack(spacing: 0) {
                heroSub("Deposited", engine.netDeposits)
                Divider().frame(height: 28).overlay(Color.white.opacity(0.25))
                heroSub("From play", engine.totalProfit)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current bankroll \(hide ? "hidden" : Money.string(engine.currentBankroll, symbol: sym))")
    }

    private func heroSub(_ label: String, _ value: Decimal) -> some View {
        VStack(spacing: 2) {
            Text(hide ? "\(sym)••" : Money.string(value, symbol: sym, signed: true))
                .font(Theme.mono(15, .semibold)).foregroundStyle(.white)
            Text(label).font(Theme.rounded(12)).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bankroll over time", systemImage: "chart.xyaxis.line")
            let points = engine.bankrollTimeline
            if points.count < 2 {
                Text("Add deposits and log sessions to see your bankroll grow over time.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 110)
            } else {
                Chart(points) { p in
                    LineMark(x: .value("Date", p.date), y: .value("Bankroll", dbl(p.value)))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", p.date), y: .value("Bankroll", dbl(p.value)))
                        .foregroundStyle(Theme.accent.opacity(0.15))
                        .interpolationMethod(.monotone)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text(hide ? "•" : Money.string(Decimal(d), symbol: sym))
                                    .font(Theme.mono(10))
                            }
                        }
                    }
                }
                .frame(height: 170)
                .accessibilityLabel("Bankroll over time chart")
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Guidance

    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Bankroll guidance", systemImage: "shield.lefthalf.filled")

            if let roi = engine.tournamentROI {
                HStack {
                    Text("Tournament ROI").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(Money.percent(roi, fractionDigits: 1))
                        .font(Theme.mono(15, .semibold))
                        .foregroundStyle(roi >= 0 ? Theme.good : Theme.bad)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cushion").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(buyInCushion) buy-ins").font(Theme.mono(14, .semibold)).foregroundStyle(Theme.ink)
                }
                Slider(value: Binding(get: { Double(buyInCushion) },
                                      set: { buyInCushion = Int($0) }),
                       in: 5...60, step: 5)
                    .tint(Theme.accent)
                    .accessibilityLabel("Buy-in cushion")
                    .accessibilityValue("\(buyInCushion) buy-ins")
            }

            if let recommended = engine.recommendedBankroll(buyIns: buyInCushion),
               let unit = engine.typicalBuyIn {
                HStack {
                    Text("Suggested minimum").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(hide ? "\(sym)••" : Money.string(recommended, symbol: sym))
                        .font(Theme.mono(15, .bold)).foregroundStyle(Theme.accent)
                }
                Text("Based on \(buyInCushion) × your largest buy-in (\(hide ? "\(sym)••" : Money.string(unit, symbol: sym))). For your reference only — not financial advice.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Log a session with a buy-in to see suggested bankroll cushion for your stakes.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Transactions list

    private var transactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Transactions", systemImage: "arrow.left.arrow.right")
            if transactions.isEmpty {
                Text("No deposits or withdrawals yet. Tap + to add one.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 70)
            } else {
                ForEach(transactions) { t in
                    transactionRow(t)
                    if t.id != transactions.last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func transactionRow(_ t: BankrollTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: t.kind.symbol)
                .font(.system(size: 20))
                .foregroundStyle(t.kind == .deposit ? Theme.good : Theme.bad)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(t.note.isEmpty ? t.kind.rawValue : t.note)
                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink).lineLimit(1)
                Text(Self.dateFormatter.string(from: t.date))
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            MoneyText(value: t.signedAmount, symbol: sym, size: 15, signed: true, hidden: hide)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap(enabled: settings.hapticsEnabled)
            editing = t
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { pendingDelete = t } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(t.kind.rawValue) \(t.note), \(hide ? "hidden" : Money.string(t.signedAmount, symbol: sym, signed: true))")
        .accessibilityHint("Double tap to edit")
    }

    // MARK: - Locked (free) state

    private var lockedState: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "banknote.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("The Bankroll module")
                    .font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                Text("Track deposits and withdrawals, watch your bankroll grow over time, and see ROI plus calm, for-your-reference guidance on cushion for your stakes.")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                ProLockChip()
                PrimaryButton(title: "Unlock Felt Pro", systemImage: "lock.open.fill") {
                    Haptics.tap(enabled: settings.hapticsEnabled)
                    paywallReason = .bankroll
                }
                .frame(maxWidth: 300)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
        }
    }

    private func confirmDelete() {
        guard let target = pendingDelete else { return }
        modelContext.delete(target)
        try? modelContext.save()
        pendingDelete = nil
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func dbl(_ d: Decimal) -> Double {
        let v = NSDecimalNumber(decimal: d).doubleValue
        return v.isFinite ? v : 0
    }
}
