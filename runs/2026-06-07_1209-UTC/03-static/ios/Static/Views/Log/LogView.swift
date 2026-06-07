import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ApneaSession.date, order: .reverse) private var sessions: [ApneaSession]
    @AppStorage("static.confirmDeletes") private var confirmDeletes = true
    @State private var pendingDelete: ApneaSession?

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: "No sessions yet",
                                       message: "Finish a training session and it lands here with your rounds and longest hold.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sessions) { s in
                                sessionRow(s)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = s } else { delete(s) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Log")
            .background(Brand.pageBackground)
            .confirmationDialog("Delete this session?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let s = pendingDelete { delete(s) } }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func sessionRow(_ s: ApneaSession) -> some View {
        HStack(spacing: 14) {
            Image(systemName: s.type.symbol).font(.title3).foregroundStyle(Brand.text).frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(s.tableName).font(.headline).foregroundStyle(Brand.text)
                    if s.completed { Badge(text: "Complete", color: Brand.live) }
                }
                Text(s.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(Brand.text3)
                HStack(spacing: 8) {
                    Badge(text: "\(s.roundsCompleted)/\(s.roundsPlanned) rounds")
                    Badge(text: "max " + TableEngine.clock(s.longestHoldSeconds))
                }
                if !s.notes.isEmpty {
                    Text(s.notes).font(.caption).foregroundStyle(Brand.text2).lineLimit(2)
                }
            }
            Spacer()
        }
        .glassCard()
    }

    private func delete(_ s: ApneaSession) {
        context.delete(s); try? context.save(); Haptics.warning(); pendingDelete = nil
    }
}
