import SwiftUI
import SwiftData

/// The logbook: every round, newest first, with a way to add and remove.
struct RoundsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query private var courses: [Course]
    @AppStorage("links.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Round?

    var body: some View {
        NavigationStack {
            Group {
                if rounds.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No rounds yet",
                            message: courses.isEmpty
                                ? "Add a course first, then log your first round."
                                : "Tap the + button to log your first round.")
                        .glassCard()
                        .padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(rounds) { round in
                                NavigationLink {
                                    RoundDetailView(round: round)
                                } label: {
                                    RoundRow(round: round)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        if confirmDeletes { pendingDelete = round }
                                        else { context.delete(round); try? context.save(); Haptics.warning() }
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rounds")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(); showingEditor = true
                    } label: { Image(systemName: "plus") }
                    .disabled(courses.isEmpty)
                    .accessibilityLabel("Log round")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) {
                RoundEditView(existing: nil)
            }
            .confirmationDialog("Delete this round?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let r = pendingDelete { context.delete(r); try? context.save(); Haptics.warning() }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }
}

private struct RoundRow: View {
    let round: Round
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(round.courseName).font(.headline).foregroundStyle(Brand.text)
                    Text("\(round.teeName) · \(round.date, format: .dateTime.month(.abbreviated).day().year())")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(round.isComplete ? "\(round.totalScore)" : "\(round.totalScore)·\(round.enteredHoleCount)h")
                        .font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                    Text(toParText(round.toPar))
                        .font(Brand.mono(12, weight: .medium))
                        .foregroundStyle(round.toPar <= 0 ? Brand.live : Brand.text2)
                }
            }
            HStack(spacing: 8) {
                if round.holeCount == 9 { Badge(text: "9 holes") }
                if !round.isComplete { Badge(text: "In progress", color: Brand.warn) }
                if round.fairwayOpportunities > 0 {
                    Badge(text: "FIR \(round.fairwaysHitCount)/\(round.fairwayOpportunities)")
                }
                if round.isComplete {
                    Badge(text: "GIR \(round.girCount)/\(round.holeCount)")
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(round.courseName), \(round.date.formatted(date: .abbreviated, time: .omitted)), score \(round.totalScore), \(toParText(round.toPar))")
    }
}

func toParText(_ p: Int) -> String {
    if p == 0 { return "E" }
    return p > 0 ? "+\(p)" : "\(p)"
}
