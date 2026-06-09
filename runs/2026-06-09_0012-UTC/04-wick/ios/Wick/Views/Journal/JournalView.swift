import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \Trade.entryDate, order: .reverse) private var trades: [Trade]
    @AppStorage("wick.symbol") private var symbol = "$"
    @State private var filter: Filter = .all
    @State private var adding = false

    enum Filter: String, CaseIterable, Identifiable { case all = "All", open = "Open", closed = "Closed"; var id: String { rawValue } }

    private var filtered: [Trade] {
        switch filter {
        case .all: return trades
        case .open: return trades.filter { $0.isOpen }
        case .closed: return trades.filter { !$0.isOpen }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trades.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.bar.doc.horizontal",
                                       title: "No trades yet",
                                       message: "Tap + to log your first trade. Wick handles the math.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            summaryHeader
                            Picker("Filter", selection: $filter) {
                                ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            if filtered.isEmpty {
                                Text("No \(filter.rawValue.lowercased()) trades.")
                                    .font(.subheadline).foregroundStyle(Brand.text3).padding(.top, 12)
                            } else {
                                ForEach(filtered) { trade in
                                    NavigationLink { TradeDetailView(trade: trade) } label: {
                                        TradeRow(trade: trade, symbol: symbol)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log trade")
                }
            }
            .sheet(isPresented: $adding) { TradeEditorView(trade: nil) }
        }
    }

    private var summaryHeader: some View {
        let s = TradeStats.summary(trades)
        let openCount = trades.filter { $0.isOpen }.count
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Net realised P/L")
                Text(Money.string(s.totalPL, symbol: symbol, showsSign: true))
                    .font(Brand.mono(32, weight: .bold))
                    .foregroundStyle(s.totalPL >= 0 ? Brand.live : Brand.danger)
                HStack(spacing: 18) {
                    miniStat("Win rate", s.count > 0 ? "\(Int((s.winRate * 100).rounded()))%" : "—")
                    miniStat("Trades", "\(s.count)")
                    miniStat("Open", "\(openCount)")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
    }
}

struct TradeRow: View {
    let trade: Trade
    let symbol: String

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(trade.symbol).font(.headline).foregroundStyle(Brand.text)
                        Image(systemName: trade.direction.icon)
                            .font(.caption2).foregroundStyle(trade.direction.tint)
                            .accessibilityLabel(trade.direction.title)
                    }
                    Text("\(trade.strategy.title) · \(Format.relativeDay(trade.entryDate))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                if trade.isOpen {
                    Text("OPEN")
                        .font(Brand.mono(11, weight: .bold))
                        .foregroundStyle(Brand.warn)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Brand.warn.opacity(0.15), in: Capsule())
                } else if let pl = trade.netPL {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Money.string(pl, symbol: symbol, showsSign: true))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(pl >= 0 ? Brand.live : Brand.danger)
                        if let r = trade.rMultiple {
                            Text(Money.rMultiple(r)).font(Brand.mono(11)).foregroundStyle(Brand.text3)
                        } else if let ret = trade.returnPct {
                            Text(Money.percent(ret)).font(Brand.mono(11)).foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
