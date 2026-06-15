import SwiftUI

struct TraitDetailView: View {
    let trait: Trait

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                explanationCard
                polesCard
                itemsCard
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(trait.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.heroGradient).frame(width: 64, height: 64)
                Image(systemName: trait.symbolName)
                    .font(.system(size: 28, weight: .light)).foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(trait.rawValue).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.ink)
                Text("Big Five trait").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
    }

    private var explanationCard: some View {
        Text(trait.summary)
            .font(Theme.rounded(16))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .cardSurface()
    }

    private var polesCard: some View {
        HStack(spacing: 12) {
            poleColumn(title: "Lower", word: trait.lowPole, symbol: "arrow.down.circle.fill")
            poleColumn(title: "Higher", word: trait.highPole, symbol: "arrow.up.circle.fill")
        }
    }

    private func poleColumn(title: String, word: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 22)).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkFaint)
            Text(word).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "How we measure it", systemImage: "checklist")
            Text("This trait is scored from these 8 IPIP items (✓ keyed positive, ↺ reverse-scored):")
                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ItemBank.items.filter { $0.trait == trait }) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.keyedPositive ? "checkmark.circle" : "arrow.uturn.backward.circle")
                        .foregroundStyle(item.keyedPositive ? Theme.good : Theme.warn)
                        .font(.system(size: 14)).padding(.top, 2)
                        .accessibilityLabel(item.keyedPositive ? "Positively keyed" : "Reverse scored")
                    Text("\u{201C}\(item.text)\u{201D}")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }
}
