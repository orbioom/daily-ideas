import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Bindable var match: Match
    @Environment(\.modelContext) private var context
    @State private var showingAddLeg = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    statGrid
                    legsSection
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle(match.opponent.isEmpty ? "Match" : match.opponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddLeg = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add leg")
            }
        }
        .sheet(isPresented: $showingAddLeg) {
            LegEditView(nextIndex: (match.orderedLegs.last?.index ?? -1) + 1,
                        startScore: match.startScore) { leg in
                leg.match = match
                match.legs.append(leg)
                context.insert(leg)
                try? context.save()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("\(match.legsWon) – \(match.legsLost)")
                .font(Brand.mono(40, weight: .bold))
                .foregroundStyle(match.didWin ? Brand.live : Brand.text)
            Text(match.isDecided ? (match.didWin ? "Match won" : "Match lost") : "In progress")
                .font(.subheadline).foregroundStyle(Brand.text2)
            HStack(spacing: 8) {
                Chip(text: "\(match.startScore)")
                Chip(text: "Best of \(match.bestOfLegs)")
                Chip(text: Fmt.date(match.date))
            }
            if !match.notes.isEmpty {
                Text(match.notes).font(.footnote).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center).padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 20)
    }

    private var statGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: Fmt.avg(match.threeDartAverage), label: "3-dart avg", accent: Brand.text)
                StatTile(value: "\(match.highestVisit)", label: "High visit", accent: Brand.magic)
            }
            HStack(spacing: 12) {
                StatTile(value: Fmt.pct(match.checkoutPercent), label: "Checkout %", accent: Brand.live)
                StatTile(value: match.bestLegDarts.map { "\($0)" } ?? "—", label: "Best leg (darts)")
            }
        }
    }

    private var legsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Legs", trailing: "\(match.orderedLegs.count)")
            if match.orderedLegs.isEmpty {
                Text("No legs recorded. Tap + to add one.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity).glassCard(padding: 20)
            } else {
                ForEach(match.orderedLegs) { leg in
                    LegRow(leg: leg)
                        .swipeActions {
                            Button(role: .destructive) {
                                match.legs.removeAll { $0.id == leg.id }
                                context.delete(leg)
                                try? context.save()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
        }
    }
}

struct LegRow: View {
    let leg: Leg
    var body: some View {
        HStack {
            StatusDot(color: leg.didWin ? Brand.live : Brand.danger)
            VStack(alignment: .leading, spacing: 3) {
                Text("Leg \(leg.index + 1) · \(leg.didWin ? "won" : "lost")")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                Text("\(leg.dartsThrown) darts · avg \(Fmt.avg(leg.average))")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            Spacer()
            if leg.didWin && leg.checkoutDouble > 0 {
                Chip(text: leg.checkoutDouble == 25 ? "Bull" : "D\(leg.checkoutDouble)",
                     system: "checkmark", tint: Brand.live)
            }
            if leg.highestScore >= 100 {
                Chip(text: "\(leg.highestScore)", tint: Brand.magic)
            }
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Leg \(leg.index + 1), \(leg.didWin ? "won" : "lost"), \(leg.dartsThrown) darts")
    }
}
