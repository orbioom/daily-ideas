import SwiftUI

/// Searchable picker to add a marker to a draft panel.
struct MarkerPickerSheet: View {
    let excluded: Set<String>
    let onPick: (Biomarker) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var grouped: [(category: MarkerCategory, markers: [Biomarker])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return MarkerCategory.allCases.compactMap { cat in
            let ms = BiomarkerCatalog.markers(in: cat).filter { m in
                guard !excluded.contains(m.id) else { return false }
                guard !q.isEmpty else { return true }
                return m.name.lowercased().contains(q) || m.shortName.lowercased().contains(q)
            }
            return ms.isEmpty ? nil : (cat, ms)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if grouped.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "Nothing to add",
                        message: search.isEmpty ? "Every catalog marker is already in this panel." : "No markers match \"\(search)\"."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.category.id) { group in
                            Section(group.category.rawValue) {
                                ForEach(group.markers) { marker in
                                    Button {
                                        onPick(marker)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(marker.name)
                                                    .font(Theme.rounded(15, .semibold))
                                                    .foregroundStyle(Theme.ink)
                                                Text(marker.unit)
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.inkSoft)
                                            }
                                            Spacer()
                                            Image(systemName: "plus.circle")
                                                .foregroundStyle(Theme.accent)
                                        }
                                    }
                                    .listRowBackground(Theme.surface)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Add Marker")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
