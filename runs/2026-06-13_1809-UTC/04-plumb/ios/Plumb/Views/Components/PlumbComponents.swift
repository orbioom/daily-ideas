import SwiftUI

/// A signed change badge — green up, red down.
struct DeltaBadge: View {
    let amount: Double
    var percent: Double? = nil
    var currency: String = "USD"
    var body: some View {
        let positive = amount >= 0
        let color = amount == 0 ? Theme.inkSoft : (positive ? Theme.good : Theme.bad)
        HStack(spacing: 4) {
            Image(systemName: amount == 0 ? "minus" : (positive ? "arrow.up.right" : "arrow.down.right"))
                .font(.system(size: 11, weight: .bold))
            Text(Money.compact(abs(amount), code: currency))
                .font(Theme.rounded(13, .bold))
            if let percent {
                Text("(\(percent >= 0 ? "+" : "")\(String(format: "%.1f", percent))%)")
                    .font(Theme.rounded(12, .semibold))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityLabel("\(positive ? "Up" : "Down") \(Money.format(abs(amount), code: currency))")
    }
}

struct AccountRow: View {
    let account: Account
    let currency: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(account.isAsset ? Theme.accentSoft : Theme.bad.opacity(0.16))
                    .frame(width: 42, height: 42)
                Image(systemName: account.type.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(account.isAsset ? Theme.accent : Theme.bad)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink).lineLimit(1)
                Text(account.institution.isEmpty ? account.type.label : account.institution)
                    .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft).lineLimit(1)
            }
            Spacer()
            Text((account.isAsset ? "" : "−") + Money.format(account.balance, code: currency))
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(account.isAsset ? Theme.ink : Theme.bad)
        }
        .padding(.vertical, 4)
        .opacity(account.includeInNetWorth ? 1 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(account.name), \(account.isAsset ? "asset" : "liability"), \(Money.format(account.balance, code: currency))")
    }
}

/// Small inline legend dot + label + value used beside donut charts.
struct LegendRow: View {
    let color: Color
    let label: String
    let value: String
    let pct: String
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 11, height: 11)
            Text(label).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
            Text(pct).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft).frame(width: 46, alignment: .trailing)
        }
    }
}
