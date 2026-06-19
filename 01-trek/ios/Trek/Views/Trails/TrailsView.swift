import SwiftUI
import SwiftData

struct TrailsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trail.name) private var allTrails: [Trail]
    @State private var vm = HikeViewModel()
    @State private var showAddSheet = false
    @State private var trailToEdit: Trail? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(Color(.systemGroupedBackground))

                if vm.filteredTrails(allTrails).isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(vm.filteredTrails(allTrails)) { trail in
                            NavigationLink(destination: TrailDetailView(trail: trail)) {
                                TrailRow(trail: trail)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(trail)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    trailToEdit = trail
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    trail.isFavorite.toggle()
                                } label: {
                                    Label(
                                        trail.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: trail.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trails")
            .searchable(text: $vm.searchText, prompt: "Search trails")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Add trail")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $vm.sortOrder) {
                            ForEach(HikeViewModel.TrailSortOrder.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityLabel("Sort trails")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTrailView()
            }
            .sheet(item: $trailToEdit) { trail in
                AddTrailView(trailToEdit: trail)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    label: "Favorites",
                    icon: "star.fill",
                    isSelected: vm.showFavoritesOnly
                ) {
                    vm.showFavoritesOnly.toggle()
                }

                ForEach(TrailDifficulty.allCases, id: \.self) { diff in
                    FilterChip(
                        label: diff.rawValue,
                        icon: diff.icon,
                        isSelected: vm.selectedDifficulty == diff
                    ) {
                        vm.selectedDifficulty = vm.selectedDifficulty == diff ? nil : diff
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 6)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundStyle(TrekTheme.forestGreen)
                .accessibilityHidden(true)
            Text("No Trails Yet")
                .font(.title3.bold())
            Text("Add the trails you hike to build your personal trail library.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Add Your First Trail") {
                showAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? TrekTheme.forestGreen : Color(.secondarySystemGroupedBackground),
                        in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct TrailRow: View {
    let trail: Trail

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(TrekTheme.difficultyColor(trail.difficulty).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: trail.difficulty.icon)
                    .foregroundStyle(TrekTheme.difficultyColor(trail.difficulty))
                    .font(.system(size: 18))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(trail.name)
                        .font(.subheadline.weight(.semibold))
                    if trail.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(TrekTheme.sunGold)
                            .accessibilityHidden(true)
                    }
                }
                if !trail.location.isEmpty {
                    Text(trail.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: trail.difficulty)
                    if trail.sessionCount > 0 {
                        Text("\(trail.sessionCount) hike\(trail.sessionCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(trail.name)\(trail.location.isEmpty ? "" : ", \(trail.location)"), \(trail.difficulty.rawValue), \(trail.sessionCount) hikes"
        )
    }
}
