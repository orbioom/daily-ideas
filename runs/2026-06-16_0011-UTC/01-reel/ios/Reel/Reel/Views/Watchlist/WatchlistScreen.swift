import SwiftUI
import SwiftData

/// Titles you want to watch. Includes a "Pick for me" reveal and quick actions.
struct WatchlistScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Title.addedDate, order: .reverse) private var allTitles: [Title]

    @State private var pick: Title?
    @State private var showPick = false
    @State private var path: [Title] = []

    private var watchlist: [Title] {
        allTitles.filter { $0.status == .watchlist }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Watchlist")
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
            .sheet(isPresented: $showPick) {
                if let pick {
                    PickRevealView(title: pick,
                                   onWatched: { markWatched(pick) },
                                   onSkip: { pickAnother() })
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if watchlist.isEmpty {
            EmptyStateView(symbol: "bookmark",
                           title: "Nothing on deck",
                           message: "Add a film or show and set its status to Watchlist. It'll wait for you right here.")
        } else {
            VStack(spacing: 0) {
                pickButton
                List {
                    ForEach(watchlist) { title in
                        Button {
                            path.append(title)
                        } label: {
                            WatchlistRow(title: title, asGradient: settings.showPostersAsGradient)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.bg)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeFromWatchlist(title)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            Button {
                                markWatched(title)
                            } label: {
                                Label("Watched", systemImage: "checkmark")
                            }
                            .tint(Theme.good)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var pickButton: some View {
        PrimaryButton(title: "Pick for me", systemImage: "sparkles") {
            pickAnother()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Actions

    private func pickAnother() {
        let list = watchlist
        guard !list.isEmpty else { return }
        // Seed by current time so each press is fresh but deterministic within a tick.
        var seed = UInt64(Date().timeIntervalSince1970 * 1000)
        seed ^= seed >> 12; seed ^= seed << 25; seed ^= seed >> 27
        let idx = Int(seed % UInt64(list.count))
        let safeIdx = min(max(idx, 0), list.count - 1)
        pick = list[safeIdx]
        showPick = true
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func markWatched(_ title: Title) {
        title.status = .watched
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        showPick = false
    }

    private func removeFromWatchlist(_ title: Title) {
        // Removing from the watchlist deletes the title entirely (it was never watched).
        context.delete(title)
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}

/// A row in the watchlist list.
struct WatchlistRow: View {
    let title: Title
    var asGradient: Bool

    var body: some View {
        HStack(spacing: 12) {
            PosterView(title: title, asGradient: asGradient, showOverlay: false, cornerRadius: 8)
                .frame(width: 50, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(title.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(title.kind.displayName) · \(String(title.year))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                if !title.genres.isEmpty {
                    Text(title.genres.prefix(3).map { $0.displayName }.joined(separator: " · "))
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(12)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

/// The reveal card shown by "Pick for me".
struct PickRevealView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: Title
    let onWatched: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            Text("Tonight, watch…")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 24)

            PosterView(title: title, asGradient: settings.showPostersAsGradient, showOverlay: false, cornerRadius: 18)
                .frame(width: 150, height: 222)
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
                .opacity(appeared || reduceMotion ? 1 : 0)

            VStack(spacing: 6) {
                Text(title.name)
                    .font(Theme.serif(22, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("\(String(title.year)) · \(title.kind.displayName) · \(title.runtimeLabel)")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Mark watched", systemImage: "checkmark.circle.fill") {
                    onWatched()
                }
                SecondaryButton(title: "Skip — pick another", systemImage: "shuffle") {
                    onSkip()
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appeared = true } }
        }
    }
}

#Preview {
    WatchlistScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
