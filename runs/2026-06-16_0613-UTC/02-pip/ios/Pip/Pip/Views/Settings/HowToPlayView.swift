import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    basicsCard
                    scoringSection(title: "Upper section", categories: ScoreCategory.upperCategories)
                    scoringSection(title: "Lower section", categories: ScoreCategory.lowerCategories)
                    bonusCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The goal")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text("Fill all 13 scoring categories with the highest total you can. Each turn you roll five dice up to three times, holding the dice you like between rolls. Then choose one open category to score.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            step("1", "Roll", "Tap Roll to throw all five dice.")
            step("2", "Hold & re-roll", "Tap dice to keep them, then roll again — up to three rolls total.")
            step("3", "Score", "Tap an open category. The preview shows what you'd score. That category then locks.")
            step("4", "Repeat", "After 13 rounds the highest grand total wins.")
        }
        .padding(16)
        .card()
    }

    private func step(_ n: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func scoringSection(title: String, categories: [ScoreCategory]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 8)
            ForEach(Array(categories.enumerated()), id: \.element.id) { idx, cat in
                if idx > 0 { Divider().background(Theme.hairline) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.title).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                    Text(cat.ruleText).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .card()
    }

    private var bonusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Bonuses", systemImage: "star.fill")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.gold)
            Text("Upper bonus: score 63+ across Ones–Sixes for a +35 bonus.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("Yahtzee bonus: every Yahtzee after your first scored 50 earns +100. If the matching number box is taken, you may place it as a Full House, Straight or other open box (the Joker rule).")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
