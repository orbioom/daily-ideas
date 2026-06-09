import SwiftUI

/// The "Draw" tab entry point — just the spread picker, wrapped for the tab.
struct DrawView: View {
    var body: some View {
        SpreadPickerView()
    }
}

/// Pick a spread and (optionally) set a question before drawing.
struct SpreadPickerView: View {
    @State private var selected: Spread?
    @State private var question = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose a spread to begin. Each lays out the cards a little differently.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Your question (optional)")
                        TextField("What would you like guidance on?", text: $question, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                            .accessibilityLabel("Your question")
                    }
                }

                SectionTitle(text: "Spreads")
                ForEach(SpreadCatalog.all) { spread in
                    Button {
                        Haptics.selection()
                        selected = spread
                    } label: {
                        SpreadRow(spread: spread)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Draw")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selected) { spread in
            DrawRevealView(spread: spread, question: question)
        }
    }
}

private struct SpreadRow: View {
    let spread: Spread
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: spread.symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Brand.magic)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(spread.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(spread.cardCount) card\(spread.cardCount == 1 ? "" : "s")")
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
                Text(spread.blurb)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.leading)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(spread.name), \(spread.cardCount) cards")
        .accessibilityHint(spread.blurb)
    }
}
