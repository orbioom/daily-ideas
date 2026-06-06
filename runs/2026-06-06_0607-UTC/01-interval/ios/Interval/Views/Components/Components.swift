import SwiftUI

// MARK: - Glass surface

/// A glass panel using `.ultraThinMaterial` with a hairline luminous edge.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Brand.cardShadow, radius: 14, x: 0, y: 8)
    }
}

// MARK: - Ink primary action

/// The single focal ink action per screen: ink gradient, white label, 12pt radius.
struct InkButton: View {
    var title: String
    var systemImage: String?
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .foregroundStyle(.white)
            .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Empty / error states

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).fontWeight(.semibold)
                }
                .padding(.top, 4)
                .tint(Brand.text)
            }
        }
        .frame(maxWidth: 340)
        .padding(28)
    }
}

// MARK: - Section header

struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(Brand.text3)
            .tracking(0.8)
    }
}

// MARK: - Kind chip

/// A small pill that names a segment kind in text + color (color is never the only signal).
struct KindChip: View {
    var kind: SegmentKind

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: kind.symbol)
                .font(.system(size: 11, weight: .semibold))
                .accessibilityHidden(true)
            Text(kind.title)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(kind.tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(kind.tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.title)
    }
}

// MARK: - Stat block

/// A labelled value used in summaries and insights.
struct StatBlock: View {
    var value: String
    var label: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Toast

struct ToastView: View {
    var message: String
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Brand.inkGradient, in: Capsule())
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Preview helper

extension View {
    /// Wraps a preview in the sample container + settings, falling back to an empty
    /// state view when an in-memory store cannot be created.
    @MainActor @ViewBuilder
    func intervalPreview() -> some View {
        if let container = SampleData.previewContainer() {
            self
                .modelContainer(container)
                .environment(SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        } else {
            Text("Preview store unavailable")
                .foregroundStyle(Brand.text2)
        }
    }
}
