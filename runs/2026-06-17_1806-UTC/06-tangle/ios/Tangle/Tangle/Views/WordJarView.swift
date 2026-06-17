import SwiftUI
import SwiftData

/// The Word Jar: every bonus word the player has discovered, with stats and
/// search. Pro shows short definitions.
struct WordJarView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \FoundBonusWord.foundAt, order: .reverse) private var words: [FoundBonusWord]

    @State private var search = ""
    @State private var showPaywall = false

    private var filtered: [FoundBonusWord] {
        let q = search.trimmingCharacters(in: .whitespaces).uppercased()
        guard !q.isEmpty else { return words }
        return words.filter { $0.word.contains(q) }
    }

    private var longest: String? {
        words.max(by: { $0.word.count < $1.word.count })?.word
    }

    private var mostFound: FoundBonusWord? {
        words.max(by: { $0.timesFound < $1.timesFound })
    }

    var body: some View {
        NavigationStack {
            Group {
                if words.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            systemImage: "sparkles",
                            title: "Your jar is empty",
                            message: "Spell valid words that aren't part of the crossword and they'll be collected here as bonus words.",
                            actionTitle: nil,
                            action: nil
                        )
                        .padding(.top, 60)
                    }
                    .background(Theme.bg.ignoresSafeArea())
                } else {
                    listContent
                }
            }
            .navigationTitle("Word Jar")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                statsCard
                if filtered.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "No matches",
                        message: "No bonus words contain “\(search.uppercased())”."
                    )
                    .padding(.top, 20)
                } else {
                    ForEach(filtered) { word in
                        wordRow(word)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Theme.bg.ignoresSafeArea())
        .searchable(text: $search, prompt: "Search bonus words")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.characters)
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            stat(value: "\(words.count)", label: "Collected")
            divider
            stat(value: longest ?? "—", label: "Longest")
            divider
            stat(value: mostFound.map { "\($0.timesFound)×" } ?? "—", label: "Most found")
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        )
        .padding(.top, 8)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(18, .heavy))
                .foregroundStyle(Theme.accentDeep)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(width: 1, height: 34)
    }

    private func wordRow(_ word: FoundBonusWord) -> some View {
        HStack(spacing: 12) {
            Text(word.word)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            if word.timesFound > 1 {
                Text("×\(word.timesFound)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.accentDeep)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accentSoft))
            }
            Spacer()
            if isPro {
                Text(BonusDefinitions.short(for: word.word))
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Button { showPaywall = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Definition, requires Pro")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous).fill(Theme.surface).overlay(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.word), found \(word.timesFound) time\(word.timesFound == 1 ? "" : "s")")
    }
}
