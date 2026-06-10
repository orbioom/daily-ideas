import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Affirmation.createdAt, order: .reverse) private var affirmations: [Affirmation]

    @State private var search = ""
    @State private var themeFilter: AffirmationTheme? = nil
    @State private var favoritesOnly = false
    @State private var editing: Affirmation? = nil
    @State private var showingAdd = false

    private var filtered: [Affirmation] {
        affirmations.filter { a in
            (themeFilter == nil || a.theme == themeFilter!) &&
            (!favoritesOnly || a.isFavorite) &&
            (search.isEmpty || a.text.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    filterBar
                    if filtered.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "magnifyingglass",
                                       title: search.isEmpty && !favoritesOnly ? "Nothing here yet" : "No matches",
                                       message: favoritesOnly
                                            ? "Tap the heart on any affirmation to save it here."
                                            : "Try another theme, or add your own affirmation.")
                        Spacer()
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $search, prompt: "Search affirmations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add affirmation")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AffirmationEditor(existing: nil)
            }
            .sheet(item: $editing) { a in
                AffirmationEditor(existing: a)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "Favorites", icon: "heart.fill", selected: favoritesOnly) {
                    Haptics.selection(); favoritesOnly.toggle()
                }
                Chip(title: "All", icon: "square.stack", selected: themeFilter == nil && !favoritesOnly) {
                    Haptics.selection(); themeFilter = nil; favoritesOnly = false
                }
                ForEach(AffirmationTheme.allCases) { t in
                    Chip(title: t.title, icon: t.icon, selected: themeFilter == t) {
                        Haptics.selection()
                        themeFilter = (themeFilter == t) ? nil : t
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var list: some View {
        List {
            ForEach(filtered) { a in
                Button {
                    if a.isCustom { editing = a }
                } label: {
                    row(a)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing) {
                    if a.isCustom {
                        Button(role: .destructive) {
                            Haptics.warning()
                            context.delete(a); try? context.save()
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    Button {
                        a.isFavorite.toggle(); try? context.save(); Haptics.selection()
                    } label: {
                        Label(a.isFavorite ? "Unsave" : "Save", systemImage: "heart")
                    }
                    .tint(Brand.danger)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ a: Affirmation) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(a.theme.tint)
                .frame(width: 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(a.text)
                    .font(.body)
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Image(systemName: a.theme.icon).font(.caption2)
                    Text(a.theme.title).font(.caption)
                    if a.isCustom {
                        Text("• Yours").font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                .foregroundStyle(a.theme.tint)
            }
            Spacer()
            if a.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(Brand.danger).font(.footnote)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .glassCard(padding: 0)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(a.text). Theme \(a.theme.title).\(a.isFavorite ? " Favorited." : "")")
        .accessibilityHint(a.isCustom ? "Double tap to edit" : "")
    }
}

struct Chip: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption2)
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? .white : Brand.text2)
            .background {
                if selected {
                    Capsule().fill(Brand.inkGradient)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
