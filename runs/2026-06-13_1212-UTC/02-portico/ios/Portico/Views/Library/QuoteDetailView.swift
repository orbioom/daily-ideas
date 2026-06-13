import SwiftUI
import SwiftData

struct QuoteDetailView: View {
    let quote: StoicQuote
    @Environment(\.modelContext) private var context
    @Query private var saved: [SavedQuote]

    private var isSaved: Bool { saved.contains { $0.quoteID == quote.id } }

    private var shareText: String {
        "\u{201C}\(quote.text)\u{201D}\n— \(quote.author), \(quote.source)"
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Pill(text: quote.theme.rawValue)
                        Spacer()
                    }

                    Text("\u{201C}\(quote.text)\u{201D}")
                        .font(Theme.serif(30, .bold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.author)
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.accent)
                        Text(quote.source)
                            .font(Theme.rounded(15, .regular))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    HStack(spacing: 12) {
                        Button {
                            Haptics.tap(); toggleSave()
                        } label: {
                            Label(isSaved ? "Saved" : "Save",
                                  systemImage: isSaved ? "bookmark.fill" : "bookmark")
                                .font(Theme.rounded(16, .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isSaved ? Theme.accent.opacity(0.16) : Theme.surfaceAlt,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)

                        ShareLink(item: shareText) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(quote.author)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleSave() {
        if let existing = saved.first(where: { $0.quoteID == quote.id }) {
            context.delete(existing)
        } else {
            context.insert(SavedQuote(quoteID: quote.id))
        }
        try? context.save()
    }
}

struct VirtueDetailView: View {
    let virtue: Virtue

    /// Quotes from the library most aligned with this virtue's spirit.
    private var related: [StoicQuote] {
        let theme: QuoteTheme
        switch virtue {
        case .wisdom:     theme = .virtue
        case .justice:    theme = .virtue
        case .courage:    theme = .adversity
        case .temperance:  theme = .desire
        }
        return QuoteLibrary.all.filter { $0.theme == theme }.prefix(4).map { $0 }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        Image(systemName: virtue.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(virtue.tint)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(virtue.rawValue)
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(virtue.greek)
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Text(virtue.definition)
                        .font(Theme.rounded(17, .regular))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if !related.isEmpty {
                        Text("In their words")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.inkSoft)
                        ForEach(related) { q in
                            NavigationLink(value: q) {
                                Card {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("\u{201C}\(q.text)\u{201D}")
                                            .font(Theme.serif(16, .regular))
                                            .foregroundStyle(Theme.ink)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("— \(q.author)")
                                            .font(Theme.rounded(13, .semibold))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(virtue.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
