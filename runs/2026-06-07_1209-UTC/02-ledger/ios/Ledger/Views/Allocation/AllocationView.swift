import SwiftUI
import SwiftData
import Charts

struct AllocationView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query private var targets: [Target]
    @AppStorage("ledger.currency") private var currency = "USD"
    @State private var showTargets = false

    private var rows: [AllocationRow] { AllocationEngine.rows(accounts: accounts, targets: targets) }
    private var totalAssets: Double { AllocationEngine.totalAssets(accounts) }
    private var maxDrift: Double { AllocationEngine.maxDrift(rows) }
    private var targetTotal: Double { AllocationEngine.targetTotal(targets) }

    var body: some View {
        NavigationStack {
            Group {
                if totalAssets <= 0 {
                    ScrollView {
                        EmptyStateView(icon: "chart.pie",
                                       title: "No assets to allocate",
                                       message: "Add some asset accounts and your allocation across cash, stocks, bonds and more will appear here.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            pieCard
                            balanceCard
                            if targets.isEmpty { setTargetsPrompt } else { rebalanceCard }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Allocation")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showTargets = true } label: { Image(systemName: "target") }.tint(Brand.text)
                }
            }
            .sheet(isPresented: $showTargets) { TargetsEditView() }
        }
    }

    private var pieCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Current allocation")
            Chart(rows) { row in
                SectorMark(angle: .value("Value", row.currentValue),
                           innerRadius: .ratio(0.58), angularInset: 1.5)
                    .cornerRadius(4)
                    .foregroundStyle(row.assetClass.tint)
            }
            .frame(height: 200)
            .accessibilityLabel("Allocation pie chart")

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    HStack(spacing: 10) {
                        Circle().fill(row.assetClass.tint).frame(width: 9, height: 9)
                        Text(row.assetClass.rawValue).font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text(Money.percent(row.currentPercent)).font(Brand.mono(12, weight: .medium))
                            .foregroundStyle(Brand.text)
                        Text(Money.compact(row.currentValue, code: currency))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3).frame(width: 64, alignment: .trailing)
                    }
                }
            }
        }.glassCard()
    }

    private var balanceCard: some View {
        HStack(spacing: 12) {
            StatTile(value: Money.compact(totalAssets, code: currency), label: "Investable")
            StatTile(value: String(format: "%.0f%%", targetTotal), label: "Targets set",
                     accent: abs(targetTotal - 100) < 0.5 ? Brand.live : Brand.warn)
            StatTile(value: String(format: "%.1f", maxDrift), label: "Max drift pts",
                     accent: maxDrift > 5 ? Brand.warn : Brand.live)
        }
    }

    private var setTargetsPrompt: some View {
        VStack(spacing: 12) {
            Text("Set target weights to see your drift and the exact moves to rebalance.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            Button { showTargets = true } label: {
                Label("Set targets", systemImage: "target").frame(maxWidth: .infinity)
            }.buttonStyle(InkButtonStyle())
        }.glassCard()
    }

    private var rebalanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Target vs actual")
                Spacer()
                if abs(targetTotal - 100) >= 0.5 {
                    Text("Targets = \(String(format: "%.0f", targetTotal))%")
                        .font(Brand.mono(11, weight: .medium)).foregroundStyle(Brand.warn)
                }
            }
            ForEach(rows) { row in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label(row.assetClass.rawValue, systemImage: row.assetClass.symbol)
                            .font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(Money.percent(row.currentPercent)) / \(String(format: "%.0f%%", row.targetPercent))")
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                    targetBar(row)
                    if abs(row.rebalanceAmount) >= 1 {
                        Text(row.rebalanceAmount > 0
                             ? "Add \(Money.string(row.rebalanceAmount, code: currency))"
                             : "Trim \(Money.string(-row.rebalanceAmount, code: currency))")
                            .font(.caption)
                            .foregroundStyle(row.rebalanceAmount > 0 ? Brand.live : Brand.danger)
                    } else {
                        Text("On target").font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                if row.id != rows.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    /// A bar showing current fill with a target tick.
    private func targetBar(_ row: AllocationRow) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.hairline).frame(height: 8)
                Capsule().fill(row.assetClass.tint)
                    .frame(width: max(0, min(1, row.currentPercent / 100)) * w, height: 8)
                Rectangle().fill(Brand.text)
                    .frame(width: 2, height: 14)
                    .offset(x: max(0, min(1, row.targetPercent / 100)) * w - 1)
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}
