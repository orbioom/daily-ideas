import SwiftUI
import SwiftData

/// Live, hole-by-hole scoring. Increment strokes/putts/penalties, step between
/// holes, and finish to lock the round and reveal its rating.
struct ScorecardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("chains.units") private var units = "feet"
    @Bindable var round: Round
    @State private var index = 0
    @State private var showCard = false

    private var holes: [HoleScore] { round.orderedScores }
    private var current: HoleScore? { holes.indices.contains(index) ? holes[index] : nil }

    var body: some View {
        Group {
            if holes.isEmpty {
                EmptyStateView(icon: "exclamationmark.triangle",
                               title: "No holes to score",
                               message: "This round has no holes. Close it and check the course layout.")
            } else {
                content
            }
        }
        .navigationTitle(round.courseName.isEmpty ? "Round" : round.courseName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { try? context.save(); dismiss() }.tint(Brand.text2)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCard.toggle() } label: { Image(systemName: "tablecells") }
                    .tint(Brand.text)
            }
        }
        .sheet(isPresented: $showCard) { ScorecardGrid(round: round) }
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    runningHeader
                    if let score = current { holeCard(score) }
                }
                .padding()
            }
            footer
        }
    }

    private var runningHeader: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(round.totalStrokes)", label: "Strokes")
            StatTile(value: Fmt.relative(round.relativeToPar), label: "To par",
                     accent: round.relativeToPar <= 0 ? Brand.live : Brand.text)
            StatTile(value: "\(index + 1)/\(holes.count)", label: "Hole")
        }
    }

    private func holeCard(_ score: HoleScore) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("HOLE \(score.holeNumber)")
                    .font(Brand.mono(13, weight: .medium)).tracking(2).foregroundStyle(Brand.text3)
                HStack(spacing: 10) {
                    Badge(text: "Par \(score.par)")
                    if holeDistance(score) > 0 {
                        Badge(text: Fmt.distance(feet: holeDistance(score), units: units))
                    }
                }
            }

            // Big strokes value with category
            VStack(spacing: 6) {
                Text("\(score.strokes)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : Brand.ease(0.25), value: score.strokes)
                Text(ScoreKind.classify(strokes: score.strokes, par: score.par).rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(score.relative <= 0 ? Brand.live : Brand.text2)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hole \(score.holeNumber), \(score.strokes) strokes, \(ScoreKind.classify(strokes: score.strokes, par: score.par).rawValue)")

            stepperRow(label: "Strokes", value: bindingStrokes(score), min: 1, accent: Brand.text)
            stepperRow(label: "Putts", value: bindingPutts(score), min: 0, accent: Brand.info)
            stepperRow(label: "Penalties", value: bindingPenalties(score), min: 0, accent: Brand.danger)
        }
        .glassCard(padding: 20)
    }

    private func stepperRow(label: String, value: Binding<Int>, min: Int, accent: Color) -> some View {
        HStack {
            Text(label).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
            Spacer()
            HStack(spacing: 18) {
                Button {
                    if value.wrappedValue > min { value.wrappedValue -= 1; Haptics.tap() }
                } label: { Image(systemName: "minus.circle.fill").font(.title) }
                    .tint(Brand.text3)
                    .disabled(value.wrappedValue <= min)
                    .accessibilityLabel("Decrease \(label)")
                Text("\(value.wrappedValue)")
                    .font(Brand.mono(22, weight: .semibold)).foregroundStyle(accent)
                    .frame(minWidth: 34)
                    .accessibilityLabel("\(label) \(value.wrappedValue)")
                Button {
                    value.wrappedValue += 1; Haptics.tap()
                } label: { Image(systemName: "plus.circle.fill").font(.title) }
                    .tint(accent)
                    .accessibilityLabel("Increase \(label)")
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(reduceMotion ? nil : Brand.ease(0.25)) { index = max(0, index - 1) }
            } label: { Label("Prev", systemImage: "chevron.left").frame(maxWidth: .infinity) }
                .buttonStyle(GlassButtonStyle())
                .disabled(index == 0)

            if index >= holes.count - 1 {
                Button { finish() } label: {
                    Label("Finish", systemImage: "checkmark").frame(maxWidth: .infinity)
                }.buttonStyle(InkButtonStyle())
            } else {
                Button {
                    withAnimation(reduceMotion ? nil : Brand.ease(0.25)) { index = min(holes.count - 1, index + 1) }
                } label: { Label("Next", systemImage: "chevron.right").frame(maxWidth: .infinity) }
                    .buttonStyle(InkButtonStyle())
            }
        }
        .padding(.horizontal).padding(.bottom, 8)
    }

    private func finish() {
        round.isComplete = true
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func holeDistance(_ score: HoleScore) -> Int { score.distanceFeet }

    private func bindingStrokes(_ s: HoleScore) -> Binding<Int> {
        Binding(get: { s.strokes }, set: { s.strokes = max(1, $0) })
    }
    private func bindingPutts(_ s: HoleScore) -> Binding<Int> {
        Binding(get: { s.putts }, set: { s.putts = max(0, $0) })
    }
    private func bindingPenalties(_ s: HoleScore) -> Binding<Int> {
        Binding(get: { s.penalties }, set: { s.penalties = max(0, $0) })
    }
}

/// A compact full-card grid of every hole's score.
private struct ScorecardGrid: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var round: Round
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(round.orderedScores) { s in
                        HStack {
                            Text("Hole \(s.holeNumber)").foregroundStyle(Brand.text2).font(.subheadline)
                            Spacer()
                            Badge(text: "Par \(s.par)")
                            Text("\(s.strokes)")
                                .font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
                                .frame(width: 30)
                            Text(Fmt.relative(s.relative))
                                .font(Brand.mono(13))
                                .foregroundStyle(s.relative <= 0 ? Brand.live : Brand.text2)
                                .frame(width: 34)
                        }
                        .padding(.vertical, 4)
                        Divider().overlay(Brand.hairline)
                    }
                    HStack {
                        Text("Total").font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(round.totalStrokes)").font(Brand.mono(18, weight: .bold)).foregroundStyle(Brand.text)
                        Text(Fmt.relative(round.relativeToPar))
                            .font(Brand.mono(14)).foregroundStyle(round.relativeToPar <= 0 ? Brand.live : Brand.text2)
                            .frame(width: 34)
                    }
                }
                .padding()
            }
            .navigationTitle("Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.tint(Brand.text) } }
        }
    }
}
