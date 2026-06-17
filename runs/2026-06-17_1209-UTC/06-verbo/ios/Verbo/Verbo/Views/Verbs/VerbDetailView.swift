import SwiftUI
import SwiftData

/// Full conjugation reference for a single verb across enabled tenses.
struct VerbDetailView: View {
    let verb: Verb

    @AppStorage(Prefs.isPro) private var isPro = false
    @Query private var allStats: [ItemStat]
    @State private var paywallReason: PaywallReason?

    /// Show all tenses for the language; lock advanced ones if not Pro.
    private var tenses: [Tense] { verb.language.tenses }

    private func mastery(for tense: Tense) -> Double? {
        let key = ItemStat.makeID(language: verb.language.rawValue,
                                  verb: verb.infinitive,
                                  tense: tense.rawValue)
        return allStats.first { $0.id == key }?.mastery
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ForEach(tenses) { tense in
                        if tense.requiresPro && !isPro {
                            lockedTense(tense)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                if let m = mastery(for: tense) {
                                    HStack {
                                        Text("Your mastery")
                                            .font(Theme.rounded(12))
                                            .foregroundStyle(Theme.inkSoft)
                                        Spacer()
                                        Text("\(Int((m * 100).rounded()))%")
                                            .font(Theme.rounded(12, .semibold))
                                            .foregroundStyle(Theme.ink)
                                    }
                                    MasteryBar(mastery: m)
                                }
                                ConjugationTableView(verb: verb, tense: tense)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(verb.infinitive)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(verb.meaning)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                Pill(text: verb.language.displayName, systemImage: nil, tint: Theme.accent)
                Pill(text: "\(verb.group.displayName) verb", tint: Theme.inkSoft)
                if verb.isIrregular {
                    Pill(text: "irregular", systemImage: "bolt.fill", tint: Theme.bad)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func lockedTense(_ tense: Tense) -> some View {
        Button { paywallReason = .advancedTense } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tense.displayName)
                        .font(Theme.serif(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(tense.englishName)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.accent)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surfaceAlt))
        }
    }
}
