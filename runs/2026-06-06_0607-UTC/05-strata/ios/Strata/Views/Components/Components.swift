import SwiftUI

// MARK: - Glass surface

/// A Liquid Glass panel using `.ultraThinMaterial` with a hairline luminous edge.
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
                if let systemImage { Image(systemName: systemImage) }
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

// MARK: - Empty state

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
        .frame(maxWidth: 320)
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

// MARK: - Grade pill

/// A monospaced grade label. Conveys discipline family with text — never color alone.
struct GradePill: View {
    var label: String
    var tint: Color = Brand.text

    var body: some View {
        Text(label)
            .font(Brand.mono(15, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Brand.glassStroke.opacity(0.22), in: Capsule())
            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Outcome badge

/// An outcome chip carrying both an icon and its text label so meaning never
/// depends on color alone (accessibility).
struct OutcomeBadge: View {
    var outcome: Outcome
    var compact: Bool = false

    private var tint: Color {
        switch outcome {
        case .flash, .onsight: return Brand.send
        case .redpoint, .repeat: return Brand.send
        case .fall: return Brand.fall
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: outcome.symbol)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
            Text(compact ? outcome.shortTitle : outcome.title)
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(outcome.title)
    }
}

// MARK: - Hold color dot

/// A small colored dot for a gym problem's hold color, with a VoiceOver label.
struct HoldColorDot: View {
    var index: Int
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(Brand.holdColor(index))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.6), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

// MARK: - Stat tile

/// A compact metric tile: big monospaced value + caption.
struct StatTile: View {
    var value: String
    var caption: String
    var tint: Color = Brand.text

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption): \(value)")
    }
}

// MARK: - Toast feedback

/// A restrained bottom confirmation toast.
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

// MARK: - Segmented chip selector

/// A horizontal selectable chip row used for disciplines, outcomes, systems.
struct ChipPicker<T: Hashable>: View {
    var options: [T]
    var title: (T) -> String
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let selected = option == selection
                    Button {
                        selection = option
                    } label: {
                        Text(title(option))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(selected ? .white : Brand.text2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selected
                                    ? AnyShapeStyle(Brand.inkGradient)
                                    : AnyShapeStyle(Brand.glassStroke.opacity(0.25)),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(Brand.glassStroke.opacity(0.5),
                                                       lineWidth: selected ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
