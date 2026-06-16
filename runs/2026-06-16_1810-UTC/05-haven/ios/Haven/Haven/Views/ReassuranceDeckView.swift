import SwiftUI
import SwiftData

/// A calming, swipeable deck of reassurance cards.
struct ReassuranceDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \ReassuranceCard.text) private var cards: [ReassuranceCard]
    @State private var index = 0

    var body: some View {
        ZStack {
            HavenBackground()
            VStack(spacing: 0) {
                header
                if cards.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "quote.bubble",
                        title: "No cards yet",
                        message: "Reassurance cards will appear here. You can add your own from the Toolbox."
                    )
                    Spacer()
                } else {
                    Spacer()
                    deck
                    Spacer()
                    controls
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
            .accessibilityLabel("Close reassurance")
            Spacer()
            if !cards.isEmpty {
                Text("\(safeIndex + 1) of \(cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
        }
        .padding(.top, 14)
    }

    private var safeIndex: Int { min(max(index, 0), max(cards.count - 1, 0)) }

    private var deck: some View {
        TabView(selection: $index) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { pair in
                cardView(pair.element.text)
                    .tag(pair.offset)
                    .padding(.horizontal, 4)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 340)
        .animation(reduceMotion ? nil : .easeInOut, value: index)
    }

    private func cardView(_ text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "quote.opening")
                .font(.title)
                .foregroundStyle(HavenTheme.accent.opacity(0.6))
                .accessibilityHidden(true)
            Text(text)
                .font(.title2.weight(.medium))
                .foregroundStyle(HavenTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenTheme.card(scheme))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerLarge, style: .continuous))
        .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.06), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                step(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(HavenTheme.accentDeep)
                    .frame(width: 56, height: 52)
                    .background(HavenTheme.subtleFill(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            }
            .accessibilityLabel("Previous card")

            Button {
                step(1)
            } label: {
                Text("Next reminder")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(HavenTheme.sosGradient)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
            }
            .accessibilityLabel("Next card")
        }
    }

    private func step(_ delta: Int) {
        guard !cards.isEmpty else { return }
        let next = (safeIndex + delta + cards.count) % cards.count
        if reduceMotion { index = next }
        else { withAnimation(.easeInOut) { index = next } }
    }
}
