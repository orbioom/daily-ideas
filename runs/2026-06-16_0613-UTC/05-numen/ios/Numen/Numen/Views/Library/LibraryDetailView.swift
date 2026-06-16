import SwiftUI

struct LibraryDetailView: View {
    let meaning: NumberMeaning
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero
                    Text(meaning.essence)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keywords").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
                        FlowTags(items: meaning.keywords)
                    }

                    listBlock(title: "Strengths", symbol: "checkmark.seal.fill", tint: Theme.good, items: meaning.strengths)
                    listBlock(title: "Challenges", symbol: "exclamationmark.circle.fill", tint: Theme.warn, items: meaning.challenges)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Across the chart").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.accent)
                        ForEach([NumberPosition.lifePath, .expression, .soulUrge, .personality], id: \.self) { pos in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: pos.symbol).font(.caption).foregroundStyle(Theme.accent)
                                    .frame(width: 18)
                                    .accessibilityHidden(true)
                                Text(meaning.framing(for: pos))
                                    .font(.footnote).foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.cornerM))
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Number \(meaning.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            NumberGlyph(value: meaning.number, size: 80, isMaster: meaning.number > 9)
            Text(meaning.title)
                .font(Theme.serif(.title))
                .foregroundStyle(Theme.ink)
            if meaning.number > 9 {
                TagPill(text: "Master Number", tint: Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Number \(meaning.number), \(meaning.title)")
    }

    private func listBlock(title: String, symbol: String, tint: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(tint)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(tint).frame(width: 5, height: 5).padding(.top, 7)
                        .accessibilityHidden(true)
                    Text(item).font(.callout).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
    }
}
