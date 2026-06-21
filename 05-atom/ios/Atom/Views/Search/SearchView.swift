import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var selectedCategory: ElementCategory? = nil
    @State private var sortOrder: SortOrder = .atomicNumber
    var colorBlindMode: Bool = false
    var kelvin: Bool = false
    var showMass: Bool = true

    enum SortOrder: String, CaseIterable {
        case atomicNumber = "Number"
        case name = "Name"
        case mass = "Mass"

        var icon: String {
            switch self {
            case .atomicNumber: return "number"
            case .name: return "textformat.abc"
            case .mass: return "scalemass"
            }
        }
    }

    private var filtered: [Element] {
        var results = Element.all
        if !query.isEmpty {
            let q = query.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(q) ||
                $0.symbol.lowercased().contains(q) ||
                "\($0.atomicNumber)".contains(q)
            }
        }
        if let cat = selectedCategory {
            results = results.filter { $0.category == cat }
        }
        switch sortOrder {
        case .atomicNumber: return results.sorted { $0.id < $1.id }
        case .name:         return results.sorted { $0.name < $1.name }
        case .mass:         return results.sorted { $0.atomicMass < $1.atomicMass }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AtomTheme.textSecondary)
                    TextField("Search elements...", text: $query)
                        .foregroundStyle(AtomTheme.textPrimary)
                        .tint(AtomTheme.accent)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AtomTheme.textSecondary)
                        }
                    }
                }
                .padding(10)
                .background(AtomTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Filter row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ElementCategory.allCases) { cat in
                            FilterChip(
                                label: cat.rawValue,
                                isSelected: selectedCategory == cat,
                                color: cat.displayColor(colorBlind: colorBlindMode)
                            ) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Sort controls
                HStack {
                    Text("\(filtered.count) elements")
                        .font(.caption)
                        .foregroundStyle(AtomTheme.textSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Sort:")
                            .font(.caption)
                            .foregroundStyle(AtomTheme.textSecondary)
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: order.icon)
                                    Text(order.rawValue)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(sortOrder == order ? AtomTheme.accent : AtomTheme.cardBackground)
                                .clipShape(Capsule())
                                .foregroundStyle(sortOrder == order ? .white : AtomTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                Divider()
                    .background(AtomTheme.cellBorder)

                // Results list
                if filtered.isEmpty {
                    emptyState
                } else {
                    List(filtered) { element in
                        NavigationLink {
                            ElementDetailView(
                                element: element,
                                colorBlindMode: colorBlindMode,
                                kelvin: kelvin
                            )
                        } label: {
                            ElementListRow(
                                element: element,
                                colorBlindMode: colorBlindMode,
                                showMass: showMass
                            )
                        }
                        .listRowBackground(AtomTheme.cardBackground)
                        .listRowSeparatorTint(AtomTheme.cellBorder)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AtomTheme.background)
            .navigationTitle("Search")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AtomTheme.textTertiary)
            Text("No elements found")
                .font(.headline)
                .foregroundStyle(AtomTheme.textSecondary)
            Text("Try a different name, symbol, or number")
                .font(.subheadline)
                .foregroundStyle(AtomTheme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct ElementListRow: View {
    let element: Element
    var colorBlindMode: Bool = false
    var showMass: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            // Symbol badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.category.displayColor(colorBlind: colorBlindMode).opacity(0.80))
                    .frame(width: 44, height: 44)
                VStack(spacing: 0) {
                    Text(element.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(element.name)
                        .font(.headline)
                        .foregroundStyle(AtomTheme.textPrimary)
                    Spacer()
                    if showMass {
                        Text(String(format: "%.3f u", element.atomicMass))
                            .font(.caption)
                            .foregroundStyle(AtomTheme.textTertiary)
                    }
                }
                HStack(spacing: 8) {
                    Text("Z = \(element.atomicNumber)")
                        .font(.caption)
                        .foregroundStyle(AtomTheme.textSecondary)
                    Text("·")
                        .foregroundStyle(AtomTheme.textTertiary)
                    Text(element.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(element.category.displayColor(colorBlind: colorBlindMode))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let label: String
    var isSelected: Bool
    var color: Color = AtomTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : AtomTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color : AtomTheme.cardBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? color : AtomTheme.cellBorder, lineWidth: 1)
                )
        }
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
