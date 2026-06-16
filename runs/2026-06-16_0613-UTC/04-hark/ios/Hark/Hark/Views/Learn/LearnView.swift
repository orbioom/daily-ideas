import SwiftUI

struct LearnView: View {
    private let articles = LearnArticle.all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Text("A few short reads on hearing — what the screening means and how to protect what you've got.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(articles) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            articleRow(article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Learn")
        }
    }

    private func articleRow(_ article: LearnArticle) -> some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 48, height: 48)
                    Image(systemName: article.icon)
                        .font(Theme.rounded(20, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(article.title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(article.summary)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ArticleDetailView: View {
    let article: LearnArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 72, height: 72)
                    Image(systemName: article.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)

                Text(article.title)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(article.summary)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(article.sections) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.heading)
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(section.body)
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                DisclaimerBanner(compact: true)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
    }
}
