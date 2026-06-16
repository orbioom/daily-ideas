import SwiftUI

/// Warm app background applied behind screen content.
struct GalleyBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        GalleyTheme.appBackground(scheme)
            .ignoresSafeArea()
    }
}

/// A calm, friendly empty state with an SF Symbol, title and message.
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(GalleyTheme.terracotta)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(GalleyTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(GalleyPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Small uppercased section label.
struct SectionLabel: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(GalleyTheme.secondaryText(scheme))
            .accessibilityAddTraits(.isHeader)
    }
}

/// A labeled value row used in reference tables.
struct EquivalenceRow: View {
    @Environment(\.colorScheme) private var scheme
    let left: String
    let right: String
    var body: some View {
        HStack {
            Text(left)
                .foregroundStyle(GalleyTheme.primaryText(scheme))
            Spacer(minLength: 12)
            Text(right)
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(left) equals \(right)")
    }
}

/// A reusable "Pro" badge.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(GalleyTheme.sageDeep))
            .accessibilityLabel("Pro feature")
    }
}
