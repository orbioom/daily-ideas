import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ForEach(article.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.heading)
                            .font(Theme.serif(19, .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, para in
                            Text(para)
                                .font(Theme.rounded(16))
                                .foregroundStyle(Theme.inkSoft)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                clinicianNote
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(article.category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: article.category.symbol)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("\(article.readMinutes) min read")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(article.title)
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(article.summary)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)
                .padding(.top, 4)
        }
    }

    private var clinicianNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "stethoscope")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("This is general information, not advice for your specific situation. Bring questions — and your Equinox summary — to your clinician.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.accentSoft))
        .accessibilityElement(children: .combine)
    }
}
