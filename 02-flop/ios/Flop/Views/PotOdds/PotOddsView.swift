import SwiftUI

struct PotOddsView: View {
    @State private var potSize: Double = 100
    @State private var callAmount: Double = 30
    @State private var showInfo = false

    var potOdds: Double { PokerEngine.potOddsPercentage(callAmount: callAmount, potBefore: potSize) }
    var breakEven: Double { PokerEngine.breakEvenEquity(callAmount: callAmount, potBefore: potSize) }

    var body: some View {
        ZStack {
            FlopTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    resultCard
                    inputsCard
                    equityExamplesCard
                    formulaCard
                }
                .padding(16)
            }
        }
        .navigationTitle("Pot Odds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FlopTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showInfo = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(FlopTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showInfo) { infoSheet }
    }

    var resultCard: some View {
        VStack(spacing: 14) {
            Text("Break-even Equity")
                .font(.system(size: 14))
                .foregroundStyle(FlopTheme.textSecondary)
            Text("\(breakEven, specifier: "%.1f")%")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(equityColor)
            Text("You need at least this much equity to call profitably")
                .font(.system(size: 13))
                .foregroundStyle(FlopTheme.textSecondary)
                .multilineTextAlignment(.center)
            Divider().background(FlopTheme.textSecondary.opacity(0.3))
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(potOdds, specifier: "%.1f")%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(FlopTheme.accentGold)
                    Text("Pot Odds")
                        .font(.system(size: 12))
                        .foregroundStyle(FlopTheme.textSecondary)
                }
                VStack(spacing: 4) {
                    Text(oddsString)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(FlopTheme.accent)
                    Text("Expressed as odds")
                        .font(.system(size: 12))
                        .foregroundStyle(FlopTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 18))
    }

    var oddsString: String {
        guard callAmount > 0 else { return "∞:1" }
        let ratio = (potSize) / callAmount
        return String(format: "%.1f:1", ratio)
    }

    var equityColor: Color {
        if breakEven < 25 { return FlopTheme.correctGreen }
        if breakEven < 40 { return FlopTheme.accentGold }
        return FlopTheme.wrongRed
    }

    var inputsCard: some View {
        VStack(spacing: 16) {
            Text("Adjust Values")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FlopTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pot size")
                        .font(.system(size: 14))
                        .foregroundStyle(FlopTheme.textSecondary)
                    Spacer()
                    Text("$\(Int(potSize))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FlopTheme.textPrimary)
                }
                Slider(value: $potSize, in: 10...1000, step: 5)
                    .tint(FlopTheme.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Call amount")
                        .font(.system(size: 14))
                        .foregroundStyle(FlopTheme.textSecondary)
                    Spacer()
                    Text("$\(Int(callAmount))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(FlopTheme.textPrimary)
                }
                Slider(value: $callAmount, in: 1...500, step: 1)
                    .tint(FlopTheme.accentGold)
            }
        }
        .padding(16)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 14))
    }

    var equityExamplesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Common Hand Equities")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FlopTheme.textSecondary)
            equityRow("Flush draw (9 outs)", 19, "~36% by river")
            equityRow("Open-ended straight", 17, "~32% by river")
            equityRow("Gutshot straight", 8, "~17% by river")
            equityRow("Overcards (6 outs)", 13, "~26% by river")
            equityRow("Set vs overpair", 65, "65% fav")
        }
        .padding(14)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 14))
    }

    func equityRow(_ hand: String, _ equity: Int, _ note: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hand)
                    .font(.system(size: 14))
                    .foregroundStyle(FlopTheme.textPrimary)
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(FlopTheme.textSecondary)
            }
            Spacer()
            Text("\(equity)%")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(equity >= Int(breakEven) ? FlopTheme.correctGreen : FlopTheme.wrongRed)
        }
        .padding(.vertical, 4)
    }

    var formulaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Formula")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FlopTheme.textSecondary)
            Text("Pot odds % = Call ÷ (Pot + Call) × 100")
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(FlopTheme.textPrimary)
            Text("You need equity > pot odds % to call profitably. The Rule of 4&2: multiply your outs × 4 (flop) or × 2 (turn) for a quick equity estimate.")
                .font(.system(size: 13))
                .foregroundStyle(FlopTheme.textSecondary)
        }
        .padding(14)
        .background(FlopTheme.felt, in: RoundedRectangle(cornerRadius: 14))
    }

    var infoSheet: some View {
        NavigationStack {
            ZStack {
                FlopTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pot odds tell you the minimum equity you need to make a profitable call. If your equity (chance of winning) exceeds the pot odds percentage, calling is +EV.")
                            .font(.system(size: 15))
                            .foregroundStyle(FlopTheme.textPrimary)
                        Text("Example: $100 pot, $30 to call → 30/(100+30) = 23%. If you have a flush draw (~36%), calling is profitable.")
                            .font(.system(size: 15))
                            .foregroundStyle(FlopTheme.textSecondary)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("About Pot Odds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FlopTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showInfo = false }
                        .foregroundStyle(FlopTheme.accent)
                }
            }
        }
    }
}
