import SwiftUI

/// A friendly empty-state block.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A labelled pill / badge.
struct InfoPill: View {
    let symbol: String
    let text: String
    var tint: Color = Theme.textSecondary

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
            Text(text).font(Theme.rounded(11, .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(tint.opacity(0.14)))
    }
}

/// Section card wrapper.
struct CardSection<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                .fill(Theme.surface)
        )
    }
}

/// A star/number rating row used in forms.
struct StarRatingView: View {
    @Binding var rating: Int        // 0...10
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(rating)/10")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(rating) },
                set: { rating = Int($0.rounded()) }
            ), in: 0...10, step: 1)
            .tint(Theme.accent)
            .accessibilityLabel("Rating")
            .accessibilityValue("\(rating) out of 10")
        }
    }
}
