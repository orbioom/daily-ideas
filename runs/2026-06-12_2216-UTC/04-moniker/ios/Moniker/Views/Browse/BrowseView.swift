import SwiftUI
import SwiftData

struct BrowseView: View {
    @Query private var decisions: [Decision]

    @State private var search = ""
    @State private var genderFilter: NameGender?
    @State private var styleFilter: NameStyle?
    @State private var originFilter: String?

    private var filtered: [NameEntry] {
        var pool = NameCatalog.all
        if let genderFilter {
            pool = pool.filter { $0.gender == genderFilter }
        }
        if let styleFilter {
            pool = pool.filter { $0.styles.contains(styleFilter) }
        }
        if let originFilter {
            pool = pool.filter { $0.origin == originFilter }
        }
        let needle = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !needle.isEmpty {
            pool = pool.filter {
                $0.name.lowercased().contains(needle) || $0.meaning.lowercased().contains(needle)
            }
        }
        return pool.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No Names Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search or loosen the filters.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(filtered) { entry in
                                NavigationLink {
                                    NameDetailView(entry: entry)
                                } label: {
                                    row(entry)
                                }
                            }
                        } footer: {
                            Text("\(filtered.count) of \(NameCatalog.all.count) names · every one with origin and meaning")
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .searchable(text: $search, prompt: "Name or meaning")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Gender", selection: $genderFilter) {
                Text("Any gender").tag(NameGender?.none)
                ForEach(NameGender.allCases) { g in
                    Text(g.displayName).tag(NameGender?.some(g))
                }
            }
            Picker("Style", selection: $styleFilter) {
                Text("Any style").tag(NameStyle?.none)
                ForEach(NameStyle.allCases) { s in
                    Text(s.displayName).tag(NameStyle?.some(s))
                }
            }
            Picker("Origin", selection: $originFilter) {
                Text("Any origin").tag(String?.none)
                ForEach(NameCatalog.origins, id: \.self) { origin in
                    Text(origin).tag(String?.some(origin))
                }
            }
            if genderFilter != nil || styleFilter != nil || originFilter != nil {
                Button("Clear Filters", role: .destructive) {
                    genderFilter = nil
                    styleFilter = nil
                    originFilter = nil
                }
            }
        } label: {
            Image(systemName: (genderFilter != nil || styleFilter != nil || originFilter != nil)
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter names")
    }

    private func row(_ entry: NameEntry) -> some View {
        let likedA = MatchEngine.likedIDs(for: .a, in: decisions).contains(entry.id)
        let likedB = MatchEngine.likedIDs(for: .b, in: decisions).contains(entry.id)
        return HStack(spacing: 12) {
            Circle()
                .fill(MonikerTheme.genderColor(entry.gender))
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body.weight(.medium))
                    .fontDesign(.serif)
                Text("\(entry.origin) · “\(entry.meaning)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if likedA && likedB {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(MonikerTheme.roseDeep)
                    .accessibilityLabel("Matched")
            } else if likedA || likedB {
                Image(systemName: "heart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Loved by one of you")
            }
        }
        .accessibilityElement(children: .combine)
    }
}
