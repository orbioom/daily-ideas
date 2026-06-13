import SwiftUI

/// A circular progress ring with a centered label.
struct RingView: View {
    var progress: Double           // 0…1
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var tint: Color = Theme.accent
    var center: AnyView? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let center { center }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// A linear progress bar used in debt rows.
struct ProgressBar: View {
    var value: Double              // 0…1
    var tint: Color = Theme.accent
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule().fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

/// A single debt row with name, balance, APR and a progress bar.
struct DebtRow: View {
    let debt: Debt
    let currency: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: debt.kind.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(debt.name)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer()
                    Text(Money.format(debt.balance, code: currency))
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                }
                ProgressBar(value: debt.progress)
                HStack {
                    Text("\(debt.apr, specifier: "%.2f")% APR")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("min \(Money.format(debt.minimumPayment, code: currency))")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(debt.name), balance \(Money.format(debt.balance, code: currency)), \(Int(debt.progress * 100)) percent paid off")
    }
}

/// A labelled key/value row.
struct KVRow: View {
    let key: String
    let value: String
    var valueColor: Color = Theme.ink
    var body: some View {
        HStack {
            Text(key).font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(15, .bold)).foregroundStyle(valueColor)
        }
    }
}
