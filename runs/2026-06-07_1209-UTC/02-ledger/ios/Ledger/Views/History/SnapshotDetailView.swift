import SwiftUI

struct SnapshotDetailView: View {
    @AppStorage("ledger.currency") private var currency = "USD"
    let snapshot: Snapshot

    private var allocation: [(AssetClass, Double)] {
        snapshot.allocation().sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    private var assetsTotal: Double { snapshot.totalAssets }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("NET WORTH").font(Brand.mono(11, weight: .medium)).tracking(2).foregroundStyle(Brand.text3)
                    Text(Money.string(snapshot.netWorth, code: currency))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(snapshot.netWorth >= 0 ? Brand.text : Brand.danger)
                        .minimumScaleFactor(0.5).lineLimit(1)
                    Text(snapshot.date.formatted(date: .complete, time: .omitted))
                        .font(.caption).foregroundStyle(Brand.text2)
                }.frame(maxWidth: .infinity).glassCard(padding: 20)

                HStack(spacing: 12) {
                    StatTile(value: Money.compact(snapshot.totalAssets, code: currency), label: "Assets", accent: Brand.live)
                    StatTile(value: Money.compact(snapshot.totalLiabilities, code: currency), label: "Debts", accent: Brand.danger)
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Allocation at this date")
                    ForEach(allocation, id: \.0) { cls, value in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(cls.rawValue, systemImage: cls.symbol)
                                    .font(.subheadline).foregroundStyle(Brand.text2)
                                Spacer()
                                Text(Money.compact(value, code: currency))
                                    .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                            }
                            MeterBar(fraction: assetsTotal > 0 ? value / assetsTotal : 0, color: cls.tint)
                        }
                    }
                }.glassCard()

                VStack(alignment: .leading, spacing: 0) {
                    SectionTitle(text: "Accounts").padding(.bottom, 8)
                    ForEach(snapshot.entries.sorted { $0.value > $1.value }) { e in
                        HStack {
                            Text(e.accountName).font(.subheadline).foregroundStyle(Brand.text2)
                            Spacer()
                            Text((e.isLiability ? "-" : "") + Money.compact(e.value, code: currency))
                                .font(Brand.mono(13, weight: .medium))
                                .foregroundStyle(e.isLiability ? Brand.danger : Brand.text)
                        }
                        .padding(.vertical, 6)
                        if e.id != snapshot.entries.sorted(by: { $0.value > $1.value }).last?.id {
                            Divider().overlay(Brand.hairline)
                        }
                    }
                }.glassCard()
            }
            .padding()
        }
        .navigationTitle("Snapshot")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }
}
