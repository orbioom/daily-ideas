import SwiftUI
import SwiftData

struct RoundDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chains.units") private var units = "feet"
    @AppStorage("chains.showRating") private var showRating = true
    @Bindable var round: Round
    @State private var resumeScoring = false

    private var rating: Int {
        RatingEngine.rating(strokes: round.totalStrokes, ssa: round.ssa, pointsPerThrow: round.pointsPerThrow)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showRating {
                    VStack(spacing: 6) {
                        Text("ROUND RATING").font(Brand.mono(12, weight: .medium)).tracking(2)
                            .foregroundStyle(Brand.text3)
                        Text("\(rating)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.text)
                        Text(RatingEngine.tier(for: rating))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.live)
                    }
                    .frame(maxWidth: .infinity).glassCard(padding: 22)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Round rating \(rating), \(RatingEngine.tier(for: rating))")
                }

                HStack(spacing: 12) {
                    StatTile(value: "\(round.totalStrokes)", label: "Strokes")
                    StatTile(value: Fmt.relative(round.relativeToPar), label: "To par",
                             accent: round.relativeToPar <= 0 ? Brand.live : Brand.text)
                    StatTile(value: "\(round.totalPutts)", label: "Putts")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Breakdown")
                    ForEach(ScoreKind.allCases, id: \.self) { kind in
                        let n = round.tally(kind)
                        if n > 0 {
                            HStack {
                                Text(kind.rawValue).foregroundStyle(Brand.text2).font(.subheadline)
                                Spacer()
                                Text("\(n)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                            }
                            if kind != ScoreKind.allCases.last { Divider().overlay(Brand.hairline) }
                        }
                    }
                    Divider().overlay(Brand.hairline)
                    InfoRow(label: "Penalties", value: "\(round.totalPenalties)", mono: true)
                }.glassCard()

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Details")
                    InfoRow(label: "Course", value: round.courseName)
                    Divider().overlay(Brand.hairline)
                    InfoRow(label: "Date", value: round.date.formatted(date: .abbreviated, time: .omitted))
                    Divider().overlay(Brand.hairline)
                    InfoRow(label: "Weather", value: round.weather)
                }.glassCard()

                VStack(alignment: .leading, spacing: 0) {
                    SectionTitle(text: "Hole by hole").padding(.bottom, 8)
                    ForEach(round.orderedScores) { s in
                        HStack {
                            Text("\(s.holeNumber)").font(Brand.mono(14, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 26, alignment: .leading)
                            Badge(text: "Par \(s.par)")
                            Spacer()
                            Text("\(s.strokes)").font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 28)
                            Text(Fmt.relative(s.relative)).font(Brand.mono(13))
                                .foregroundStyle(s.relative <= 0 ? Brand.live : Brand.text2).frame(width: 34)
                        }
                        .padding(.vertical, 7)
                        if s.id != round.orderedScores.last?.id { Divider().overlay(Brand.hairline) }
                    }
                }.glassCard()
            }
            .padding()
        }
        .navigationTitle("Round")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { resumeScoring = true } label: { Label("Edit", systemImage: "pencil") }
                    .tint(Brand.text)
            }
        }
        .navigationDestination(isPresented: $resumeScoring) { ScorecardView(round: round) }
    }
}
