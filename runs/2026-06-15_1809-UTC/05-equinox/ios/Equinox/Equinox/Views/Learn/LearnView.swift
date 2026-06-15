import SwiftUI

struct LearnView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings

    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    ForEach(LearnCategory.allCases) { category in
                        categorySection(category)
                    }
                    disclaimer
                }
                .padding(16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var introCard: some View {
        HStack(spacing: 14) {
            BotanicalSprig(size: 30, color: .white)
            VStack(alignment: .leading, spacing: 4) {
                Text("Understanding the change")
                    .font(Theme.serif(20, .semibold))
                    .foregroundStyle(.white)
                Text("Clear, evidence-based reading — at your own pace.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.heroGradient))
    }

    private func categorySection(_ category: LearnCategory) -> some View {
        let articles = LearnLibrary.articles(in: category)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.symbol)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(category.blurb)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer()
            }
            ForEach(articles) { article in
                articleRow(article)
            }
        }
        .padding(18)
        .cardSurface()
    }

    @ViewBuilder
    private func articleRow(_ article: Article) -> some View {
        let locked = article.isPro && !isPro
        Group {
            if locked {
                Button { paywallReason = .learnArticle } label: { rowLabel(article, locked: true) }
                    .buttonStyle(PressableScale())
            } else {
                NavigationLink(value: article) { rowLabel(article, locked: false) }
                    .buttonStyle(PressableScale())
            }
        }
    }

    private func rowLabel(_ article: Article, locked: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(article.title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(article.summary)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(article.readMinutes) min read")
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer(minLength: 8)
            if locked {
                ProLockChip()
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .combine)
        .accessibilityHint(locked ? "Pro article, double tap to unlock" : "Double tap to read")
    }

    private var disclaimer: some View {
        Text("Educational information only — general, not personalised medical advice. Always talk to your clinician about your own care.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
}
