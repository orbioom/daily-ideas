import SwiftUI
import SwiftData

struct TechniqueLibraryView: View {
    @Query(sort: \Technique.name) private var techniques: [Technique]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedCategory: TechniqueCategory? = nil
    @State private var showingAddTechnique = false

    private var favorites: [Technique] {
        techniques.filter { $0.isFavorite && matchesFilters($0) }
    }

    private var filteredTechniques: [Technique] {
        techniques.filter { !$0.isFavorite && matchesFilters($0) }
    }

    private func matchesFilters(_ technique: Technique) -> Bool {
        let matchesCategory = selectedCategory == nil || technique.category == selectedCategory?.rawValue
        let matchesSearch = searchText.isEmpty || technique.name.localizedCaseInsensitiveContains(searchText)
        return matchesCategory && matchesSearch
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DojoTheme.subtleText)
                        TextField("Search techniques...", text: $searchText)
                            .foregroundColor(.white)
                            .tint(DojoTheme.crimson)
                    }
                    .padding(12)
                    .background(DojoTheme.cardBg)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryFilterChip(
                                label: "All",
                                icon: "square.grid.2x2",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }

                            ForEach(TechniqueCategory.allCases, id: \.self) { cat in
                                CategoryFilterChip(
                                    label: cat.rawValue,
                                    icon: cat.icon,
                                    isSelected: selectedCategory == cat
                                ) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }

                    // Technique list
                    ScrollView {
                        LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {

                            // Favorites section
                            if !favorites.isEmpty {
                                Section {
                                    ForEach(favorites) { technique in
                                        NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                                            TechniqueCardView(technique: technique)
                                        }
                                        .padding(.horizontal)
                                    }
                                } header: {
                                    HStack {
                                        Label("Favorites", systemImage: "star.fill")
                                            .font(.subheadline.bold())
                                            .foregroundColor(DojoTheme.gold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background(DojoTheme.darkBg)
                                }
                            }

                            // All techniques
                            Section {
                                ForEach(filteredTechniques) { technique in
                                    NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                                        TechniqueCardView(technique: technique)
                                    }
                                    .padding(.horizontal)
                                }
                            } header: {
                                if !favorites.isEmpty {
                                    HStack {
                                        Text("All Techniques")
                                            .font(.subheadline.bold())
                                            .foregroundColor(DojoTheme.subtleText)
                                        Spacer()
                                        Text("\(filteredTechniques.count)")
                                            .font(.caption)
                                            .foregroundColor(DojoTheme.subtleText)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background(DojoTheme.darkBg)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddTechnique = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(DojoTheme.crimson)
                                .clipShape(Circle())
                                .shadow(color: DojoTheme.crimson.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Techniques")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .sheet(isPresented: $showingAddTechnique) {
                AddTechniqueView()
            }
        }
        .tint(DojoTheme.crimson)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : DojoTheme.subtleText)
            .background(isSelected ? DojoTheme.crimson : DojoTheme.cardBg)
            .cornerRadius(20)
        }
    }
}

// MARK: - Technique Card

struct TechniqueCardView: View {
    let technique: Technique

    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DojoTheme.crimson.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: technique.techniqueCategory.icon)
                    .font(.system(size: 18))
                    .foregroundColor(DojoTheme.crimson)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(technique.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(technique.category)
                    .font(.caption)
                    .foregroundColor(DojoTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if technique.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(DojoTheme.gold)
                }
                if technique.drillCount > 0 {
                    Text("\(technique.drillCount) drills")
                        .font(.caption2)
                        .foregroundColor(DojoTheme.subtleText)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(DojoTheme.subtleText)
        }
        .padding(14)
        .cardStyle()
    }
}

// MARK: - Add Technique Sheet

struct AddTechniqueView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedCategory: TechniqueCategory = .submissions
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DojoTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FormSection(title: "Name") {
                            TextField("Technique name", text: $name)
                                .padding(14)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                        }

                        FormSection(title: "Category") {
                            VStack(spacing: 0) {
                                ForEach(TechniqueCategory.allCases, id: \.self) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        HStack {
                                            Image(systemName: cat.icon)
                                                .foregroundColor(DojoTheme.crimson)
                                                .frame(width: 24)
                                            Text(cat.rawValue)
                                                .foregroundColor(.white)
                                            Spacer()
                                            if selectedCategory == cat {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(DojoTheme.crimson)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    if cat != TechniqueCategory.allCases.last {
                                        Divider()
                                            .background(DojoTheme.elevatedBg)
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                        }

                        FormSection(title: "Notes") {
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(12)
                                .foregroundColor(.white)
                                .tint(DojoTheme.crimson)
                                .scrollContentBackground(.hidden)
                        }

                        Button("Add Technique") {
                            guard !name.isEmpty else { return }
                            let technique = Technique(
                                name: name,
                                category: selectedCategory.rawValue,
                                notes: notes
                            )
                            modelContext.insert(technique)
                            dismiss()
                        }
                        .buttonStyle(CrimsonButtonStyle())
                        .padding(.horizontal)
                        .disabled(name.isEmpty)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add Technique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DojoTheme.darkBg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DojoTheme.crimson)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TechniqueLibraryView()
        .modelContainer(for: [Technique.self], inMemory: true)
}
