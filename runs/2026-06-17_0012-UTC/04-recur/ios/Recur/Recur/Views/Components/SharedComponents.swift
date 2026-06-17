import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Section header

struct SectionHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RecurTheme.violet)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RecurTheme.secondaryText(scheme))
            Spacer(minLength: 0)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Colored glyph badge (per-subscription)

struct SubGlyph: View {
    let colorHex: String
    let symbol: String
    var size: CGFloat = 44

    var body: some View {
        let color = Color(hex: colorHex)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(color.opacity(0.18))
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Category dot

struct CategoryDot: View {
    let colorHex: String
    var size: CGFloat = 10
    var body: some View {
        Circle()
            .fill(Color(hex: colorHex))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Trial badge

struct TrialBadge: View {
    var body: some View {
        Text("TRIAL")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(RecurTheme.amber))
            .accessibilityLabel("Free trial")
    }
}

// MARK: - Pro lock badge

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill").font(.caption2)
            Text("PRO").font(.caption2.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(RecurTheme.violet))
        .accessibilityLabel("Recur Pro feature")
    }
}

// MARK: - Count tile

struct CountTile: View {
    @Environment(\.colorScheme) private var scheme
    let value: String
    let caption: String
    let symbol: String
    var tint: Color = RecurTheme.violet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(RecurTheme.primaryText(scheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(caption)
                .font(.caption)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RecurTheme.cardSurface(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RecurTheme.hairline(scheme), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(caption)")
    }
}

// MARK: - Empty state

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
                .font(.system(size: 48))
                .foregroundStyle(RecurTheme.violet.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(RecurTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(RecurPrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Loading state

struct LoadingView: View {
    @Environment(\.colorScheme) private var scheme
    var label: String = "Loading…"
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(RecurTheme.violet)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RecurTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

// MARK: - Hide-amounts aware money text

/// Shows a money value, or a masked stand-in when privacy mode is on.
struct MoneyText: View {
    let value: Decimal
    let code: String
    var hidden: Bool
    var compact: Bool = false

    var body: some View {
        Text(displayString)
    }

    var displayString: String {
        if hidden { return MoneyFormatter.masked(code: code) }
        return compact ? MoneyFormatter.compact(value, code: code)
                       : MoneyFormatter.string(value, code: code)
    }
}

// MARK: - Share sheet (CSV export)

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
