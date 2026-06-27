import SwiftUI
import SwiftData

struct TechniqueLibraryView: View {
    @Query(sort: \Technique.name) private var techniques: [Technique]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var filterCategory: TechniqueCategory? = nil
    @State private var searchText = ""
    @State private var selected: Technique? = nil

    private var filtered: [Technique] {
        techniques.filter { t in
            (filterCategory == nil || t.category == filterCategory) &&
            (searchText.isEmpty || t.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var grouped: [(TechniqueCategory, [Technique])] {
        let cats = filterCategory != nil ? [filterCategory!] : TechniqueCategory.allCases
        return cats.compactMap { cat in
            let items = filtered.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if techniques.isEmpty {
                    emptyState
                } else {
                    List {
                        filterBar
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init())
                        ForEach(grouped, id: \.0) { cat, items in
                            Section(header: Label(cat.rawValue, systemImage: cat.icon)) {
                                ForEach(items) { t in
                                    TechniqueRowView(technique: t)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selected = t }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                t.isFavorite.toggle()
                                                try? context.save()
                                            } label: {
                                                Label(t.isFavorite ? "Unfavorite" : "Favorite",
                                                      systemImage: t.isFavorite ? "heart.slash" : "heart.fill")
                                            }
                                            .tint(.pink)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            if t.isCustom {
                                                Button(role: .destructive) {
                                                    context.delete(t)
                                                } label: { Label("Delete", systemImage: "trash") }
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search techniques")
                }
            }
            .navigationTitle("Techniques")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddTechniqueView() }
            .sheet(item: $selected) { t in
                TechniqueDetailView(technique: t)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton("All", selected: filterCategory == nil) { filterCategory = nil }
                ForEach(TechniqueCategory.allCases, id: \.self) { cat in
                    chipButton(cat.rawValue, selected: filterCategory == cat) {
                        filterCategory = filterCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
        }
    }

    private func chipButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No techniques yet")
                .font(.title3.bold())
            Text("Techniques are seeded on first launch")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct TechniqueRowView: View {
    let technique: Technique

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: technique.isFavorite ? "heart.fill" : technique.category.icon)
                .font(.title3)
                .foregroundStyle(technique.isFavorite ? .pink : .red)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(technique.name).font(.subheadline.bold())
                Text("\(technique.mastery.label) · \(technique.practiceCount) reps")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            MasteryBadge(level: technique.mastery)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(technique.name), \(technique.mastery.label)")
    }
}

struct MasteryBadge: View {
    let level: MasteryLevel
    var body: some View {
        Text(level.label)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
    private var badgeColor: Color {
        switch level {
        case .learning: return .gray
        case .developing: return .blue
        case .competent: return .green
        case .proficient: return .orange
        case .mastered: return .yellow
        }
    }
}
