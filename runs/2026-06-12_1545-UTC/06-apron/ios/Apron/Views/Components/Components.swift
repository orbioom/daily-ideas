import SwiftUI

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 46))
                .foregroundStyle(Theme.accent.opacity(0.9)).accessibilityHidden(true)
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent).tint(Theme.accent).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity).padding(28)
    }
}

struct MiniStat: View {
    var value: String
    var label: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint).minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine).accessibilityLabel("\(label): \(value)")
    }
}

/// A horizontal stacked bar showing the split between two values.
struct SplitBar: View {
    var a: Double
    var b: Double
    var colorA: Color
    var colorB: Color
    var body: some View {
        GeometryReader { geo in
            let total = max(a + b, 0.0001)
            HStack(spacing: 2) {
                Capsule().fill(colorA).frame(width: geo.size.width * a / total)
                Capsule().fill(colorB).frame(width: geo.size.width * b / total)
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

struct JobBadge: View {
    let job: Job
    var body: some View {
        Label(job.name, systemImage: job.role.symbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(job.tint.opacity(0.16), in: Capsule())
            .foregroundStyle(job.tint)
            .lineLimit(1)
    }
}

struct CurrencyField: View {
    let label: String
    @Binding var text: String
    var color: Color = Theme.textPrimary
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(Currency.code).font(.caption).foregroundStyle(Theme.textSecondary)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
                .foregroundStyle(color)
        }
    }
}
