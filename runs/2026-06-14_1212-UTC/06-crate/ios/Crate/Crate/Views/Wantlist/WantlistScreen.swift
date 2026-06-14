import SwiftUI
import SwiftData

/// Wantlist — wishlist records with a "mark as acquired" action.
struct WantlistScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Record.artist) private var allRecords: [Record]

    @State private var showAdd = false
    @State private var acquiring: Record?

    private var wantlist: [Record] {
        allRecords.filter { $0.status == .wishlist }
            .sorted { $0.artist.localizedCaseInsensitiveCompare($1.artist) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Wantlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add to wantlist")
                }
            }
            .navigationDestination(for: Record.self) { rec in
                RecordDetailView(record: rec)
            }
            .sheet(isPresented: $showAdd) {
                RecordEditorView(record: nil, initialStatus: .wishlist)
            }
            .sheet(item: $acquiring) { rec in
                AcquireSheet(record: rec)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if wantlist.isEmpty {
            EmptyStateView(symbol: "bookmark",
                           title: "Nothing on the hunt",
                           message: "Add records you're chasing. When one lands in your hands, mark it acquired and it moves to your collection.",
                           actionTitle: "Add a want") { showAdd = true }
        } else {
            List {
                ForEach(wantlist) { rec in
                    NavigationLink(value: rec) {
                        row(rec)
                    }
                    .listRowBackground(Theme.surface)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { acquiring = rec } label: {
                            Label("Acquired", systemImage: "checkmark.seal.fill")
                        }
                        .tint(Theme.good)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(rec) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
        }
    }

    private func row(_ rec: Record) -> some View {
        HStack(spacing: 12) {
            CoverArtView(title: rec.title, artist: rec.artist, hue: rec.coverHue, showDisc: false)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(rec.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(rec.artist)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Pill(text: rec.format.display, tint: Theme.accent)
                    if rec.estValue > 0 && !settings.hideValues {
                        Text("~\(settings.formatMoney(rec.estValue))")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            Spacer()
            Button { acquiring = rec } label: {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.good)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(rec.title) as acquired")
        }
        .padding(.vertical, 4)
    }

    private func delete(_ rec: Record) {
        context.delete(rec)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
