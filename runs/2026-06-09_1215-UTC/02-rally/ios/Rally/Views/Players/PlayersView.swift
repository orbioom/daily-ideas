import SwiftUI
import SwiftData

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]
    @Query private var matches: [Match]

    @State private var showEditor = false

    private var completed: [Match] { matches.filter { $0.isComplete } }
    private var me: Player? { players.first { $0.isMe } }
    private var others: [Player] { players.filter { !$0.isMe }.sorted { $0.rating > $1.rating } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let me {
                        NavigationLink(value: me) {
                            PlayerRow(player: me, record: StatsEngine.record(for: me, in: completed))
                        }
                        .buttonStyle(.plain)
                    }
                    if others.isEmpty && me == nil {
                        EmptyStateView(icon: "person.2",
                                       title: "No players yet",
                                       message: "Add the people you play against and with.")
                            .glassCard()
                    } else if !others.isEmpty {
                        HStack {
                            Eyebrow(text: "Opponents & partners")
                            Spacer()
                        }
                        .padding(.top, 4)
                        LazyVStack(spacing: 12) {
                            ForEach(others) { p in
                                NavigationLink(value: p) {
                                    PlayerRow(player: p, record: StatsEngine.record(for: p, in: completed))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Players")
            .navigationDestination(for: Player.self) { PlayerDetailView(player: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(); showEditor = true
                    } label: {
                        Label("Add player", systemImage: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                PlayerEditorView()
            }
        }
    }
}

struct PlayerRow: View {
    let player: Player
    let record: StatsEngine.Record

    var body: some View {
        HStack(spacing: 12) {
            PlayerAvatar(initials: player.initials, isMe: player.isMe, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.name).font(.headline).foregroundStyle(Brand.text)
                    if player.isMe {
                        Text("YOU")
                            .font(Brand.mono(10, weight: .bold)).tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Brand.magic))
                    }
                }
                Text(record.total == 0 ? "No matches yet" : "\(record.line) · \(record.winRatePercent)% win")
                    .font(.caption).foregroundStyle(Brand.text2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.rating(player.rating))
                    .font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
                Text("rating").font(.caption2).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name)\(player.isMe ? ", you" : ""), rating \(Format.rating(player.rating)), record \(record.line)")
    }
}
