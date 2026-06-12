import SwiftUI

struct StarRating: View {
    @Binding var ratingHalf: Int
    var interactive: Bool = true
    var size: CGFloat = 22
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                let full = ratingHalf >= star * 2
                let half = !full && ratingHalf == star * 2 - 1
                Image(systemName: full ? "star.fill" : (half ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: size))
                    .foregroundStyle(full || half ? Theme.crema : Theme.track)
                    .contentShape(Rectangle())
                    .onTapGesture { loc in
                        guard interactive else { return }
                        Haptics.tap()
                        ratingHalf = loc.x < size / 2 ? star * 2 - 1 : star * 2
                    }
            }
            if interactive && ratingHalf > 0 {
                Button { Haptics.tap(); ratingHalf = 0 } label: {
                    Image(systemName: "xmark.circle").font(.footnote)
                }
                .foregroundStyle(Theme.textSecondary)
                .accessibilityLabel("Clear rating")
            }
        }
        .accessibilityElement(children: interactive ? .contain : .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(ratingHalf == 0 ? "Unrated" : String(format: "%.1f of 5", Double(ratingHalf) / 2))
    }
}

struct FreshnessBadge: View {
    let state: FreshnessState
    var days: Int?
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(state.color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(state.color)
        }
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(state.color.opacity(0.14), in: Capsule())
        .accessibilityLabel("Freshness: \(label)")
    }
    private var label: String {
        if let days, state != .unknown { return "\(state.rawValue) · \(days)d" }
        return state.rawValue
    }
}

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

struct MethodPill: View {
    let method: BrewMethod
    var body: some View {
        Label(method.rawValue, systemImage: method.symbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Theme.accent.opacity(0.15), in: Capsule())
            .foregroundStyle(Theme.accent)
    }
}

struct MiniStat: View {
    var value: String
    var label: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(tint).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine).accessibilityLabel("\(label): \(value)")
    }
}

struct TipRow: View {
    let tip: DialInTip
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.symbol).font(.title3).foregroundStyle(tip.color).frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(tip.detail).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
