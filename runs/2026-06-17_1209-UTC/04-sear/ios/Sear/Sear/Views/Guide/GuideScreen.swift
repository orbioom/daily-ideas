import SwiftUI

/// Searchable doneness reference, grouped by protein.
struct GuideScreen: View {
    @Environment(AppSettings.self) private var settings
    @State private var query = ""
    @State private var selectedProtein: Protein? = nil

    private var filtered: [GuideEntry] {
        DonenessGuide.all.filter { entry in
            let matchesProtein = selectedProtein == nil || entry.protein == selectedProtein
            let q = query.trimmingCharacters(in: .whitespaces).lowercased()
            let matchesQuery = q.isEmpty
                || entry.cut.lowercased().contains(q)
                || entry.protein.label.lowercased().contains(q)
                || entry.woodPairing.lowercased().contains(q)
            return matchesProtein && matchesQuery
        }
    }

    private var grouped: [(protein: Protein, entries: [GuideEntry])] {
        Protein.allCases.compactMap { protein in
            let entries = filtered.filter { $0.protein == protein }
            return entries.isEmpty ? nil : (protein, entries)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Doneness Guide")
            .navigationDestination(for: GuideEntry.self) { entry in
                GuideDetailView(entry: entry)
            }
        }
        .searchable(text: $query, prompt: "Search cuts, proteins, woods")
    }

    @ViewBuilder
    private var content: some View {
        if grouped.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Try a different cut, protein or wood.")
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    proteinFilter
                    ForEach(grouped, id: \.protein) { group in
                        section(group.protein, group.entries)
                    }
                }
                .padding(16)
            }
        }
    }

    private var proteinFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", active: selectedProtein == nil) {
                    selectedProtein = nil
                }
                ForEach(Protein.allCases) { protein in
                    filterChip(title: protein.label, active: selectedProtein == protein) {
                        selectedProtein = (selectedProtein == protein) ? nil : protein
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(active ? .white : Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(active ? Theme.accent : Theme.surfaceAlt))
        }
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func section(_ protein: Protein, _ entries: [GuideEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(protein.label, systemImage: protein.symbol)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(protein.hue)
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                    NavigationLink(value: entry) {
                        GuideRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    if idx < entries.count - 1 {
                        Divider().background(Theme.hairline)
                    }
                }
            }
            .searCard(padding: 0)
        }
    }
}

/// One row in the guide list.
private struct GuideRow: View {
    @Environment(AppSettings.self) private var settings
    let entry: GuideEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.cut)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Pit \(settings.temp(entry.smokerTempC)) · rest \(entry.restMinutes)m · \(entry.woodPairing)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            Text(settings.temp(entry.defaultTargetC))
                .font(Theme.numeral(18, .bold))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens doneness detail")
    }
}
