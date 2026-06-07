import SwiftUI
import SwiftData

/// A read-only scorecard with totals, a nine-by-nine grid, and a stats summary.
struct RoundDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var round: Round
    @State private var showingEditor = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                scorecard(title: "Front nine", range: 0..<min(9, round.holeCount))
                if round.holeCount > 9 {
                    scorecard(title: "Back nine", range: 9..<round.holeCount)
                }
                statsCard
                if !round.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Notes")
                        Text(round.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    .glassCard()
                }
            }
            .padding()
        }
        .navigationTitle(round.courseName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { Haptics.tap(); showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            RoundEditView(existing: round)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("\(round.totalScore)")
                .font(Brand.mono(48, weight: .bold)).foregroundStyle(Brand.text)
            Text(toParText(round.toPar))
                .font(.headline)
                .foregroundStyle(round.toPar <= 0 ? Brand.live : Brand.text2)
            Text("\(round.teeName) · CR \(String(format: "%.1f", round.courseRating)) / Slope \(round.slopeRating)")
                .font(.caption).foregroundStyle(Brand.text3)
            Text(round.date, format: .dateTime.weekday(.wide).month().day().year())
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassCard()
    }

    private func scorecard(title: String, range: Range<Int>) -> some View {
        let outPar = range.map { round.holePars[$0] }.reduce(0, +)
        let outScore = range.map { round.holeScores[$0] }.filter { $0 > 0 }.reduce(0, +)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: title)
            // header row
            gridRow(label: "Hole", cells: range.map { "\($0 + 1)" }, total: "Σ", bold: true)
            gridRow(label: "Par", cells: range.map { "\(round.holePars[$0])" }, total: "\(outPar)")
            HStack(spacing: 0) {
                cell("Score", width: 52, align: .leading, color: Brand.text2)
                ForEach(range, id: \.self) { i in
                    let s = round.holeScores[i]
                    cell(s > 0 ? "\(s)" : "–", width: nil,
                         color: ScoreColor.color(gross: s, par: round.holePars[i]),
                         bold: true)
                }
                cell("\(outScore)", width: 36, bold: true)
            }
        }
        .glassCard(padding: 12)
    }

    private func gridRow(label: String, cells: [String], total: String, bold: Bool = false) -> some View {
        HStack(spacing: 0) {
            cell(label, width: 52, align: .leading, color: Brand.text2)
            ForEach(Array(cells.enumerated()), id: \.offset) { _, c in
                cell(c, width: nil, color: bold ? Brand.text : Brand.text2, bold: bold)
            }
            cell(total, width: 36, color: Brand.text2, bold: true)
        }
    }

    private func cell(_ text: String, width: CGFloat?, align: Alignment = .center,
                      color: Color = Brand.text, bold: Bool = false) -> some View {
        Text(text)
            .font(Brand.mono(13, weight: bold ? .semibold : .regular))
            .foregroundStyle(color)
            .frame(width: width, alignment: align)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(height: 26)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Round stats")
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(value: round.totalPutts > 0 ? "\(round.totalPutts)" : "—", label: "Putts")
                StatTile(value: round.fairwayOpportunities > 0 ? "\(round.fairwaysHitCount)/\(round.fairwayOpportunities)" : "—", label: "Fairways")
                StatTile(value: "\(round.girCount)/\(round.holeCount)", label: "Greens")
            }
        }
        .glassCard()
    }
}
