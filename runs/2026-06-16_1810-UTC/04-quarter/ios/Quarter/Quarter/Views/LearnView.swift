import SwiftUI

/// Plain-English explainers and the disclaimer.
struct LearnView: View {
    private let articles: [LearnArticle] = LearnArticle.all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.m) {
                    ForEach(articles) { article in
                        NavigationLink {
                            LearnDetailView(article: article)
                        } label: {
                            articleRow(article)
                        }
                        .buttonStyle(.plain)
                    }
                    disclaimerCard
                }
                .padding(Theme.Spacing.m)
            }
            .background(Theme.background)
            .navigationTitle("Learn")
        }
    }

    private func articleRow(_ article: LearnArticle) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: article.icon)
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                Text(article.summary)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.tertiaryText)
                .accessibilityHidden(true)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the explainer")
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Label("Disclaimer", systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(Theme.warning)
            Text("Quarter is an educational estimator. It uses published 2024 and 2025 federal figures and a flat state rate you enter. It is not tax advice and not a substitute for a qualified professional or official IRS guidance. Always confirm before you file or pay.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .accessibilityElement(children: .combine)
    }
}

struct LearnDetailView: View {
    let article: LearnArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                ForEach(Array(article.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        if !section.heading.isEmpty {
                            Text(section.heading)
                                .font(.title3.weight(.bold))
                                .accessibilityAddTraits(.isHeader)
                        }
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(Theme.primaryText)
                    }
                }
                Text("Educational only — not tax advice.")
                    .font(.caption)
                    .foregroundStyle(Theme.tertiaryText)
                    .padding(.top, Theme.Spacing.m)
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.background)
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LearnArticle: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let summary: String
    let sections: [Section]

    struct Section {
        let heading: String
        let body: String
    }

    static let all: [LearnArticle] = [
        LearnArticle(
            icon: "person.fill",
            title: "What is self-employment tax?",
            summary: "The Social Security and Medicare you pay as your own employer.",
            sections: [
                Section(heading: "The basics", body: "When you work for an employer, they pay half of your Social Security and Medicare taxes and withhold the other half from your paycheck. When you're self-employed, you're both the employer and the employee — so you pay both halves. That combined amount is the self-employment (SE) tax."),
                Section(heading: "The rates", body: "SE tax is 12.4% for Social Security (up to an annual wage base) plus 2.9% for Medicare, for a combined 15.3%. It applies to about 92.35% of your net business profit, not your gross revenue."),
                Section(heading: "A small break", body: "You get to deduct half of your SE tax when calculating your income tax, which lowers your taxable income.")
            ]
        ),
        LearnArticle(
            icon: "calendar.badge.clock",
            title: "Why quarterly estimated payments?",
            summary: "The IRS expects tax as you earn — not just in April.",
            sections: [
                Section(heading: "Pay as you go", body: "Employees have tax withheld from every paycheck. Self-employed people don't, so the IRS asks you to send estimated payments four times a year. This keeps you from owing a large lump sum — and a penalty — at filing time."),
                Section(heading: "The four due dates", body: "For a given tax year, payments are generally due around April 15, June 15, and September 15 of that year, and January 15 of the following year. If a date lands on a weekend or holiday, it rolls to the next business day."),
                Section(heading: "How much", body: "A common approach is to divide your expected annual tax (minus any withholding) into four equal payments.")
            ]
        ),
        LearnArticle(
            icon: "shield.lefthalf.filled",
            title: "Safe harbor explained",
            summary: "Pay enough up front and you avoid an underpayment penalty.",
            sections: [
                Section(heading: "What it protects you from", body: "If you underpay during the year, the IRS can charge an underpayment penalty. 'Safe harbor' rules tell you how much to pay to avoid that penalty even if your final bill ends up higher."),
                Section(heading: "The thresholds", body: "Generally you're safe if you pay the smaller of: 90% of this year's total tax, or 100% of last year's total tax. If your prior-year adjusted gross income was over $150,000, that second number rises to 110%."),
                Section(heading: "Why it helps", body: "Safe harbor lets you base payments on last year's known numbers, which is handy when this year's income is hard to predict.")
            ]
        ),
        LearnArticle(
            icon: "doc.text.magnifyingglass",
            title: "Common deductions",
            summary: "Ordinary business costs that lower your taxable profit.",
            sections: [
                Section(heading: "Why deductions matter", body: "You owe tax on your net profit — revenue minus legitimate business expenses. Tracking expenses carefully directly reduces both your income tax and your SE tax."),
                Section(heading: "Frequently overlooked", body: "Home-office costs, a portion of phone and internet, software subscriptions, professional fees, business insurance, mileage or vehicle costs, supplies, advertising, and continuing education are commonly deductible for freelancers."),
                Section(heading: "Keep records", body: "Save receipts and log expenses as you go. The Ledger tab is built for exactly this — and its totals flow into your estimate.")
            ]
        )
    ]
}
