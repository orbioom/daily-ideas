import SwiftUI
import SwiftData

struct SetlistsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Setlist.date, order: .reverse) private var setlists: [Setlist]
    @AppStorage("capo.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Setlist?

    var body: some View {
        NavigationStack {
            Group {
                if setlists.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "list.number", title: "No setlists",
                                       message: "Build an ordered set for your next gig.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(setlists) { set in
                                NavigationLink { SetlistDetailView(setlist: set) } label: { SetlistRow(setlist: set) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = set } else { delete(set) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Setlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add setlist")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { SetlistEditView(existing: nil) }
            .confirmationDialog("Delete this setlist?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let s = pendingDelete { delete(s) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ s: Setlist) { context.delete(s); try? context.save(); Haptics.warning() }
}

private struct SetlistRow: View {
    let setlist: Setlist
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(setlist.name).font(.headline).foregroundStyle(Brand.text)
                    Text("\(setlist.venue.isEmpty ? "—" : setlist.venue) · \(setlist.date.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(setlist.items.count)").font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("songs").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            if setlist.estimatedSeconds > 0 {
                Badge(text: "≈ \(formatDuration(setlist.estimatedSeconds))")
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(setlist.name), \(setlist.items.count) songs")
    }
}

func formatDuration(_ seconds: Int) -> String {
    let m = seconds / 60, s = seconds % 60
    return "\(m):" + String(format: "%02d", s)
}
