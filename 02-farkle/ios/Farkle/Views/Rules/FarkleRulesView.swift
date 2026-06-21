import SwiftUI

struct FarkleRulesView: View {
    private let scoring: [(String, String)] = [
        ("Single 1", "100 pts"),
        ("Single 5", "50 pts"),
        ("Three 1s", "1,000 pts"),
        ("Three 2s", "200 pts"),
        ("Three 3s", "300 pts"),
        ("Three 4s", "400 pts"),
        ("Three 5s", "500 pts"),
        ("Three 6s", "600 pts"),
        ("Four of a kind", "2× Three-of-kind"),
        ("Five of a kind", "3× Three-of-kind"),
        ("Six of a kind", "4× Three-of-kind"),
        ("Straight (1–6)", "1,500 pts"),
        ("Three pairs", "1,500 pts"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ruleSection("🎯 Objective",
                        "Be the first player to reach the target score (default 10,000 points) at the end of a round.")

                    ruleSection("🎲 On Your Turn",
                        "1. Roll all 6 dice.\n2. Set aside at least one scoring die.\n3. Choose to BANK (add turn score to total) or ROLL remaining dice.\n4. If you roll with no scoring combination — FARKLE! — lose all turn points.")

                    ruleSection("🔥 Hot Dice",
                        "If all 6 dice score, you get Hot Dice — roll all 6 again and keep adding to your turn total!")

                    scoringTable
                }
                .padding()
            }
            .navigationTitle("Rules & Scoring")
        }
    }

    private func ruleSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scoringTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 Scoring Chart")
                .font(.headline)
            ForEach(scoring, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(.callout)
                    Spacer()
                    Text(row.1)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.vertical, 2)
                Divider()
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
