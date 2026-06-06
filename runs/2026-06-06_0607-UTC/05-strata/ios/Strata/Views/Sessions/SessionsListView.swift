import SwiftUI
import SwiftData

/// The home tab: a reverse-chronological list of sessions with a focal "Log session"
/// action and a summary header.
struct SessionsListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @Query private var climbs: [Climb]

    @State private var editingSession: Session?
    @State private var showingEditor = false

    private var summary: Analytics.Summary {
        Analytics.summary(sessions: sessions, climbs: climbs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if sessions.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No sessions yet",
                        message: "Log your first session to start building your climbing history and analytics.",
                        actionTitle: "Log a session",
                        action: { startNewSession() }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            summaryHeader
                            ForEach(sessions) { session in
                                NavigationLink(value: session) {
                                    SessionRow(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startNewSession()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log session")
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let editingSession {
                    SessionEditView(session: editingSession, isNew: true)
                }
            }
        }
    }

    private var summaryHeader: some View {
        GlassCard {
            HStack(spacing: 12) {
                StatTile(value: "\(summary.sessionCount)", caption: "Sessions")
                Divider().frame(height: 34)
                StatTile(value: "\(summary.sendCount)", caption: "Sends", tint: Brand.send)
                Divider().frame(height: 34)
                StatTile(value: "\(summary.attemptCount)", caption: "Attempts")
            }
        }
    }

    private func startNewSession() {
        let session = Session(date: .now,
                              location: defaultLocation())
        context.insert(session)
        editingSession = session
        showingEditor = true
    }

    /// Resolve the user's preferred default location from settings, if it still exists.
    private func defaultLocation() -> Location? {
        guard let id = UUID(uuidString: settings.defaultLocationID) else { return nil }
        let descriptor = FetchDescriptor<Location>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}

/// A single session row card.
struct SessionRow: View {
    @Environment(SettingsStore.self) private var settings
    var session: Session

    private var dateLabel: String {
        session.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dateLabel)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                        if let location = session.location {
                            Label(location.name, systemImage: location.kind.symbol)
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    Spacer()
                    Text(session.durationLabel)
                        .font(Brand.mono(14))
                        .foregroundStyle(Brand.text3)
                }
                HStack(spacing: 8) {
                    metric("\(session.attemptCount)", "attempts")
                    metric("\(session.sendCount)", "sends", tint: Brand.send)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dateLabel), \(session.location?.name ?? "no location"), \(session.attemptCount) attempts, \(session.sendCount) sends")
    }

    private func metric(_ value: String, _ label: String, tint: Color = Brand.text2) -> some View {
        HStack(spacing: 4) {
            Text(value).font(Brand.mono(14, weight: .semibold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(Brand.text3)
        }
    }
}

#Preview {
    SessionsListView()
        .environment(SettingsStore())
        .modelContainer(for: [Location.self, Climb.self, Session.self, Attempt.self], inMemory: true)
}
