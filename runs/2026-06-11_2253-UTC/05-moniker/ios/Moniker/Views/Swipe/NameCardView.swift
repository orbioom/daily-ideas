import SwiftUI

/// The big swipeable card showing one name.
struct NameCardView: View {
    let card: NameCard
    let partner: Partner
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header band tinted by gender.
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Theme.genderColor(card.gender).opacity(0.85),
                             Theme.genderColor(card.gender).opacity(0.55)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.gender.label.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
                    Text(card.name)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(20)
            }
            .frame(height: 200)

            VStack(alignment: .leading, spacing: 14) {
                detailRow(icon: "globe", title: "Origin", value: card.origin)
                detailRow(icon: "text.quote", title: "Meaning", value: card.meaning)
                Spacer(minLength: 0)
                // Style chips.
                FlowWrap(spacing: 8) {
                    ForEach(card.styles) { style in
                        Text(style.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.genderColor(card.gender).opacity(0.14), in: Capsule())
                            .foregroundStyle(Theme.genderColor(card.gender))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Theme.card(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(Theme.inkSoft(scheme).opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.12), radius: 14, y: 6)
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.inkSoft(scheme))
                .frame(width: 22)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.ink(scheme))
            }
        }
    }
}

/// Lightweight wrapping HStack for chips.
struct FlowWrap: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.width, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                      proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Celebration sheet shown when a swipe creates a match.
struct MatchCelebrationView: View {
    let card: NameCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("babyLastName") private var babyLastName = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                ForEach(0..<3) { i in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Theme.blush.opacity(0.3))
                        .offset(x: CGFloat([-70, 0, 70][i]), y: CGFloat([-10, -30, -10][i]))
                        .scaleEffect(animate ? 1 : 0.5)
                        .opacity(animate ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6).delay(Double(i) * 0.1), value: animate)
                }
                Image(systemName: "heart.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.blush)
                    .scaleEffect(animate ? 1 : 0.3)
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: animate)
            }
            .frame(height: 120)
            .accessibilityHidden(true)

            Text("It's a match!")
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink(scheme))
            Text(babyLastName.isEmpty ? card.name : "\(card.name) \(babyLastName)")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.genderColor(card.gender))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            Text("\(card.origin) — \(card.meaning)")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("You both love this one. It's on your shortlist.")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft(scheme))
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Keep swiping")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blush)
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background(scheme))
        .onAppear { animate = true }
        .presentationDetents([.large])
    }
}
