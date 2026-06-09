import SwiftUI
import SwiftData

struct PrayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Prayer.createdAt, order: .reverse) private var prayers: [Prayer]
    @AppStorage("vesper.showArchived") private var showArchived = false

    @State private var search = ""
    @State private var statusFilter: PrayerStatus? = nil
    @State private var categoryFilter: PrayerCategory? = nil
    @State private var showNew = false

    private var visible: [Prayer] {
        prayers.filter { p in
            if !showArchived && p.status == .archived && statusFilter != .archived { return false }
            if let s = statusFilter, p.status != s { return false }
            if let c = categoryFilter, p.category != c { return false }
            let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !q.isEmpty {
                let hay = (p.title + " " + p.body + " " + p.personName).lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    /// Pinned first, then by most recent activity.
    private var ordered: [Prayer] {
        visible.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return a.lastActivity > b.lastActivity
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if prayers.isEmpty {
                        EmptyStateView(icon: "hands.sparkles",
                                       title: "No prayers yet",
                                       message: "Start your first prayer. Vesper will keep it close and help you notice when it's answered.")
                    } else if ordered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "Nothing matches",
                                       message: "Try clearing your search or filters.")
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Prayers")
            .searchable(text: $search, prompt: "Search prayers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(); showNew = true
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New prayer")
                }
            }
            .safeAreaInset(edge: .top) {
                if !prayers.isEmpty {
                    filterBar
                }
            }
            .sheet(isPresented: $showNew) { PrayerEditorView() }
            .navigationDestination(for: Prayer.self) { prayer in
                PrayerDetailView(prayer: prayer)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectChip(text: "All", isSelected: statusFilter == nil && categoryFilter == nil) {
                    Haptics.selection()
                    withAnimation(Brand.ease(0.25)) { statusFilter = nil; categoryFilter = nil }
                }
                ForEach(PrayerStatus.allCases) { s in
                    SelectChip(text: s.label, isSelected: statusFilter == s, systemImage: s.symbol) {
                        Haptics.selection()
                        withAnimation(Brand.ease(0.25)) { statusFilter = (statusFilter == s ? nil : s) }
                    }
                }
                Divider().frame(height: 22)
                ForEach(PrayerCategory.allCases) { c in
                    SelectChip(text: c.label, isSelected: categoryFilter == c, systemImage: c.symbol) {
                        Haptics.selection()
                        withAnimation(Brand.ease(0.25)) { categoryFilter = (categoryFilter == c ? nil : c) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var list: some View {
        List {
            ForEach(ordered) { prayer in
                NavigationLink(value: prayer) {
                    PrayerRow(prayer: prayer)
                }
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        context.delete(prayer)
                        try? context.save()
                        Haptics.warning()
                    } label: { Label("Delete", systemImage: "trash") }

                    Button {
                        withAnimation(Brand.ease()) { prayer.isPinned.toggle() }
                        try? context.save()
                        Haptics.tap()
                    } label: {
                        Label(prayer.isPinned ? "Unpin" : "Pin", systemImage: prayer.isPinned ? "pin.slash" : "pin")
                    }
                    .tint(Brand.warn)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.plain)
    }
}
