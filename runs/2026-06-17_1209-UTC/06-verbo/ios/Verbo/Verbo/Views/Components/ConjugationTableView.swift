import SwiftUI

/// A clean typographic conjugation table for one verb × tense.
struct ConjugationTableView: View {
    let verb: Verb
    let tense: Tense

    private var rows: [(person: Person, form: String)] {
        let table = ConjugationEngine.fullTable(verb, tense: tense)
        return verb.language.persons.map { ($0, table[$0] ?? "—") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(tense.displayName)
                    .font(Theme.serif(17, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(tense.englishName)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .firstTextBaseline) {
                    Text(row.person.pronoun)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(width: 100, alignment: .leading)
                    Text(row.form)
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                .padding(.vertical, 7)
                .accessibilityElement(children: .combine)
                Divider().background(Theme.hairline)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }
}
