import SwiftUI

/// Detailed explanation of one tense: usage, ending tables, worked examples.
struct TenseDetailView: View {
    let tense: Tense

    private var info: TenseInfo { TenseInfo.info(for: tense) }

    private var personLabels: [String] {
        tense.language.persons.map { $0.pronoun }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    usageCard
                    endingsCard
                    examplesSection
                }
                .padding(20)
            }
        }
        .navigationTitle(tense.displayName)
        .navigationBarTitleDisplayMode(.large)
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("When to use it", systemImage: "lightbulb")
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            Text(info.usage)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var endingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Regular endings", systemImage: "textformat.abc")
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            ForEach(Array(info.endings.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(row.group.displayName) verbs")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.accent)
                    ForEach(Array(zip(personLabels, row.values).enumerated()), id: \.offset) { _, pair in
                        HStack {
                            Text(pair.0)
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.inkSoft)
                                .frame(width: 100, alignment: .leading)
                            Text(pair.1)
                                .font(Theme.rounded(14, .medium))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Worked examples", systemImage: "checkmark.seal")
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            ForEach(info.exampleVerbs, id: \.self) { inf in
                if let verb = VerbCatalog.verb(infinitive: inf, language: tense.language) {
                    ConjugationTableView(verb: verb, tense: tense)
                }
            }
        }
    }
}
