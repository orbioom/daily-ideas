import SwiftUI
import SwiftData

struct RoundsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query private var courses: [DiscCourse]
    @AppStorage("chains.showRating") private var showRating = true
    @AppStorage("chains.confirmDeletes") private var confirmDeletes = true
    @State private var showNew = false
    @State private var pendingDelete: Round?

    var body: some View {
        NavigationStack {
            Group {
                if rounds.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "flag.checkered",
                                       title: "No rounds yet",
                                       message: courses.isEmpty
                                            ? "Add a course first, then start a round and keep score hole by hole."
                                            : "Start a round and tap through the scorecard. Your rating estimate appears the moment you finish.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label(courses.isEmpty ? "Get started" : "Start a round", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(rounds) { round in
                                NavigationLink {
                                    if round.isComplete { RoundDetailView(round: round) }
                                    else { ScorecardView(round: round) }
                                } label: { RoundRow(round: round, showRating: showRating) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = round } else { delete(round) }
                                        } label: { Label("Delete round", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rounds")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                        .tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) { NewRoundFlow() }
            .confirmationDialog("Delete this round?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let r = pendingDelete { delete(r) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ round: Round) {
        context.delete(round); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}

private struct RoundRow: View {
    let round: Round
    let showRating: Bool
    private var rating: Int {
        RatingEngine.rating(strokes: round.totalStrokes, ssa: round.ssa, pointsPerThrow: round.pointsPerThrow)
    }
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(round.courseName.isEmpty ? "Round" : round.courseName)
                        .font(.headline).foregroundStyle(Brand.text)
                    if !round.isComplete { Badge(text: "In progress", color: Brand.warn) }
                }
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline).foregroundStyle(Brand.text2)
                HStack(spacing: 8) {
                    Badge(text: "\(round.totalStrokes) strokes")
                    Badge(text: Fmt.relative(round.relativeToPar),
                          color: round.relativeToPar <= 0 ? Brand.live : Brand.text2)
                }
            }
            Spacer()
            if showRating && round.isComplete {
                VStack(spacing: 2) {
                    Text("\(rating)").font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("rating").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
    }
}
