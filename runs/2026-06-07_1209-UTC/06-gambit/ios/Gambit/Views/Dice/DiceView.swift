import SwiftUI
import SwiftData

struct DiceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \DiceLog.createdAt, order: .reverse) private var history: [DiceLog]

    @State private var expression = ""
    @State private var lastResult: RollResult?
    @State private var error: String?
    @State private var modifier = 0
    @State private var pulse = false

    private let quickDice = [4, 6, 8, 10, 12, 20, 100]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    resultCard
                    quickCard
                    d20Card
                    customCard
                    if !history.isEmpty { historyCard }
                }
                .padding()
            }
            .navigationTitle("Dice")
            .background(Brand.pageBackground)
        }
    }

    private var resultCard: some View {
        VStack(spacing: 6) {
            if let r = lastResult {
                Text("\(r.total)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                    .scaleEffect(pulse && !reduceMotion ? 1.06 : 1)
                Text(r.breakdown).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            } else if let e = error {
                Text("—").font(.system(size: 56, weight: .bold, design: .rounded)).foregroundStyle(Brand.text3)
                Text(e).font(.subheadline).foregroundStyle(Brand.danger)
            } else {
                Text("Roll").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(Brand.text3)
                Text("Tap a die or enter an expression").font(.subheadline).foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity).glassCard(padding: 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(lastResult.map { "Rolled \($0.total). \($0.breakdown)" } ?? "No roll yet")
    }

    private var quickCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Quick dice")
            let columns = [GridItem(.adaptive(minimum: 72), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(quickDice, id: \.self) { sides in
                    Button { rollExpr("1d\(sides)", label: "d\(sides)") } label: {
                        Text("d\(sides)").font(Brand.mono(18, weight: .bold))
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                            .foregroundStyle(Brand.text)
                    }
                }
            }
        }.glassCard()
    }

    private var d20Card: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "d20 check")
            HStack {
                Text("Modifier").foregroundStyle(Brand.text2).font(.subheadline)
                Spacer()
                Stepper("\(modifier >= 0 ? "+" : "")\(modifier)", value: $modifier, in: -20...20)
                    .fixedSize().foregroundStyle(Brand.text)
            }
            HStack(spacing: 10) {
                Button { rollD20(adv: false, dis: false) } label: {
                    Text("Normal").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
                Button { rollD20(adv: true, dis: false) } label: {
                    Text("Adv").frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
                Button { rollD20(adv: false, dis: true) } label: {
                    Text("Dis").frame(maxWidth: .infinity)
                }.buttonStyle(GlassButtonStyle())
            }
        }.glassCard()
    }

    private var customCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Custom expression")
            HStack {
                TextField("e.g. 2d6+3", text: $expression)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { rollCustom() }
                Button { rollCustom() } label: {
                    Image(systemName: "die.face.6").font(.title3)
                }.tint(Brand.text)
                    .disabled(expression.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Combine terms with + and −, e.g. 1d20+5 or 2d8+1d6−2.")
                .font(.caption).foregroundStyle(Brand.text3)
        }.glassCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "History")
                Spacer()
                Button("Clear") { clearHistory() }.font(.caption).tint(Brand.text2)
            }
            ForEach(history.prefix(20)) { log in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.label.isEmpty ? log.expression : "\(log.label) · \(log.expression)")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Text(log.breakdown).font(Brand.mono(11)).foregroundStyle(Brand.text3).lineLimit(1)
                    }
                    Spacer()
                    Text("\(log.total)").font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.live)
                }
                .padding(.vertical, 5)
                if log.id != history.prefix(20).last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    // MARK: - Actions

    private func rollExpr(_ expr: String, label: String) {
        guard let r = Dice.roll(expr) else { error = "Couldn't roll \(expr)"; lastResult = nil; return }
        present(r, label: label)
    }

    private func rollCustom() {
        let expr = expression.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }
        guard let r = Dice.roll(expr) else {
            error = "“\(expr)” isn't a valid expression"; lastResult = nil; Haptics.warning(); return
        }
        present(r, label: "")
    }

    private func rollD20(adv: Bool, dis: Bool) {
        let r = Dice.d20(advantage: adv, disadvantage: dis, modifier: modifier)
        present(r, label: adv ? "Advantage" : (dis ? "Disadvantage" : "d20"))
    }

    private func present(_ r: RollResult, label: String) {
        error = nil
        lastResult = r
        context.insert(DiceLog(expression: r.expression, total: r.total, breakdown: r.breakdown, label: label))
        try? context.save()
        Haptics.success()
        withAnimation(reduceMotion ? nil : Brand.ease(0.2)) { pulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(reduceMotion ? nil : Brand.ease(0.2)) { pulse = false }
        }
    }

    private func clearHistory() {
        for log in history { context.delete(log) }
        try? context.save()
        Haptics.warning()
    }
}
