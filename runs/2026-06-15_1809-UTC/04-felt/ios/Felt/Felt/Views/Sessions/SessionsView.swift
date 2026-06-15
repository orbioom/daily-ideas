import SwiftUI
import SwiftData

struct SessionsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    @State private var searchText = ""
    @State private var formatFilter: SessionFormat?
    @State private var gameFilter: GameType?
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var pendingDelete: Session?

    private var sym: String { settings.currencySymbol }
    private var hide: Bool { settings.hideAmounts }

    private var filtered: [Session] {
        sessions.filter { s in
            if let formatFilter, s.format != formatFilter { return false }
            if let gameFilter, s.gameType != gameFilter { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let hay = "\(s.location) \(s.stakes) \(s.gameType.rawValue) \(s.tag) \(s.notes)".lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Add session")
                }
            }
            .searchable(text: $searchText, prompt: "Search location, game, tag")
            .sheet(isPresented: $showAdd) { AddEditSessionView(session: nil) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .confirmationDialog("Delete this session?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This permanently removes the session from your history.")
            }
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            filterBar
            if !isPro { capBanner }
            if filtered.isEmpty {
                EmptyStateView(symbol: "magnifyingglass",
                               title: "No matches",
                               message: "No sessions match your search or filters. Try clearing them.")
                    .padding(.top, 20)
                Spacer()
            } else {
                List {
                    ForEach(filtered) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRow(session: session, symbol: sym, hide: hide)
                        }
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDelete = session
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isOn: formatFilter == nil && gameFilter == nil) {
                    formatFilter = nil; gameFilter = nil
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
                ForEach(SessionFormat.allCases) { f in
                    FilterChip(title: f.rawValue, isOn: formatFilter == f) {
                        formatFilter = formatFilter == f ? nil : f
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }
                }
                ForEach(GameType.allCases) { g in
                    FilterChip(title: g.rawValue, isOn: gameFilter == g) {
                        gameFilter = gameFilter == g ? nil : g
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var capBanner: some View {
        let remaining = Pro.sessionsRemaining(isPro: isPro, currentCount: sessions.count) ?? 0
        return HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Theme.gold)
            Text(remaining > 0
                 ? "Free plan: \(remaining) of \(Pro.freeSessionLimit) sessions left."
                 : "Free limit reached. Unlock Pro for unlimited sessions.")
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Button("Unlock") { paywallReason = .sessionLimit }
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.goldSoft)
    }

    private var emptyState: some View {
        EmptyStateView(symbol: "list.bullet.rectangle.portrait",
                       title: "No sessions yet",
                       message: "Add your cash games and tournaments to build your history and unlock your stats.",
                       actionTitle: "Add a session") {
            attemptAdd()
        }
    }

    private func attemptAdd() {
        Haptics.tap(enabled: settings.hapticsEnabled)
        if Pro.canAddSession(isPro: isPro, currentCount: sessions.count) {
            showAdd = true
        } else {
            paywallReason = .sessionLimit
        }
    }

    private func confirmDelete() {
        guard let target = pendingDelete else { return }
        modelContext.delete(target)
        try? modelContext.save()
        pendingDelete = nil
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

/// A toggle chip used in the filter bar.
struct FilterChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(isOn ? .white : Theme.inkSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isOn ? Theme.accent : Theme.surfaceAlt)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}
