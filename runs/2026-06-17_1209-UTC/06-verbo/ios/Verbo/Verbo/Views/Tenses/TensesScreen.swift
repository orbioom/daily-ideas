import SwiftUI

/// Learn tab: explanations of each tense + regular ending tables + examples.
struct TensesScreen: View {
    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.frenchEnabled) private var frenchEnabled = false

    @State private var language: Language = .spanish
    @State private var paywallReason: PaywallReason?

    private var availableLanguages: [Language] {
        Language.allCases.filter { $0 == .spanish || (frenchEnabled && isPro) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        if availableLanguages.count > 1 {
                            Picker("Language", selection: $language) {
                                ForEach(availableLanguages) { Text("\($0.flag) \($0.displayName)").tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                        ForEach(language.tenses) { tense in
                            if tense.requiresPro && !isPro {
                                lockedCard(tense)
                            } else {
                                NavigationLink(value: tense) {
                                    tenseCard(tense)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Learn")
            .navigationDestination(for: Tense.self) { TenseDetailView(tense: $0) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private func tenseCard(_ tense: Tense) -> some View {
        let info = TenseInfo.info(for: tense)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tense.displayName)
                        .font(Theme.serif(20, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(tense.englishName)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(info.usage)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func lockedCard(_ tense: Tense) -> some View {
        Button { paywallReason = .advancedTense } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tense.displayName)
                        .font(Theme.serif(20, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Part of Verbo Pro")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surfaceAlt))
        }
    }
}
