import SwiftUI
import SwiftData

struct TradeDetailView: View {
    @Bindable var trade: Trade
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wick.symbol") private var symbol = "$"
    @State private var editing = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                plCard
                detailsCard
                if trade.stopPrice != nil || trade.targetPrice != nil {
                    riskCard
                }
                if !trade.notes.isEmpty { notesCard }
                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete trade", systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle()).tint(Brand.danger)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(trade.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(trade.isOpen ? "Close / Edit" : "Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) { TradeEditorView(trade: trade) }
        .alert("Delete this trade?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { context.delete(trade); try? context.save(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var plCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: trade.direction.icon).foregroundStyle(trade.direction.tint)
                    Text("\(trade.direction.title) · \(trade.assetType.title)")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(trade.strategy.title)
                        .font(.caption).foregroundStyle(trade.strategy.tint)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(trade.strategy.tint.opacity(0.15), in: Capsule())
                }
                if trade.isOpen {
                    Text("Position open")
                        .font(.title2.weight(.bold)).foregroundStyle(Brand.warn)
                    Text("Close it from Edit to record the result.")
                        .font(.caption).foregroundStyle(Brand.text3)
                } else if let pl = trade.netPL {
                    Text(Money.string(pl, symbol: symbol, showsSign: true))
                        .font(Brand.mono(34, weight: .bold))
                        .foregroundStyle(pl >= 0 ? Brand.live : Brand.danger)
                    HStack(spacing: 16) {
                        if let ret = trade.returnPct { badge(Money.percent(ret)) }
                        if let r = trade.rMultiple { badge(Money.rMultiple(r)) }
                        if let h = trade.holdingInterval { badge(Format.duration(h)) }
                    }
                }
            }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text).font(Brand.mono(13)).foregroundStyle(Brand.text2)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var detailsCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                row("Entry", "\(symbol)\(Money.price(trade.entryPrice))  ·  \(Format.dateTime.string(from: trade.entryDate))")
                Divider().overlay(Brand.hairline)
                if let ex = trade.exitPrice, let exd = trade.exitDate {
                    row("Exit", "\(symbol)\(Money.price(ex))  ·  \(Format.dateTime.string(from: exd))")
                    Divider().overlay(Brand.hairline)
                }
                row("Quantity", Money.price(trade.quantity))
                Divider().overlay(Brand.hairline)
                row("Fees", Money.string(trade.fees, symbol: symbol))
                if trade.discipline > 0 {
                    Divider().overlay(Brand.hairline)
                    HStack {
                        Text("Discipline").font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= trade.discipline ? "circle.fill" : "circle")
                                    .font(.caption2).foregroundStyle(i <= trade.discipline ? trade.strategy.tint : Brand.text3)
                            }
                        }
                        .accessibilityLabel("Discipline \(trade.discipline) of 5")
                    }
                }
            }
        }
    }

    private var riskCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Eyebrow(text: "Risk plan")
                if let stop = trade.stopPrice {
                    row("Stop", "\(symbol)\(Money.price(stop))")
                }
                if let target = trade.targetPrice {
                    Divider().overlay(Brand.hairline)
                    row("Target", "\(symbol)\(Money.price(target))")
                }
                if let risk = trade.riskAmount {
                    Divider().overlay(Brand.hairline)
                    row("Risk", Money.string(risk, symbol: symbol))
                }
                if let rr = trade.plannedRR {
                    Divider().overlay(Brand.hairline)
                    row("Planned R:R", String(format: "%.2f : 1", rr))
                }
            }
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Notes")
                Text(trade.notes).font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer()
            Text(value).font(Brand.mono(13)).foregroundStyle(Brand.text).multilineTextAlignment(.trailing)
        }
    }
}
