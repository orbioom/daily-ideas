import SwiftUI
import SwiftData

/// The cellar: a searchable, filterable, sortable list of bottles.
struct CellarListView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var allBottles: [Bottle]

    @State private var search = ""
    @State private var categoryFilter: TastingCategory?
    @State private var sortOrder: SettingsStore.SortOrder = .recentlyAdded
    @State private var showingAdd = false
    @State private var didSetSort = false

    private var visible: [Bottle] {
        let f = CellarModel.filtered(allBottles, search: search, category: categoryFilter)
        return CellarModel.sorted(f, by: sortOrder)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Cellar")
            .navigationDestination(for: Bottle.self) { bottle in
                BottleDetailView(bottle: bottle)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { sortMenu }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a bottle")
                }
            }
            .searchable(text: $search, prompt: "Search name, maker, origin")
            .sheet(isPresented: $showingAdd) {
                BottleEditView(bottle: nil)
            }
        }
        .onAppear {
            guard !didSetSort else { return }
            sortOrder = settings.defaultSort
            didSetSort = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if allBottles.isEmpty {
            EmptyStateView(
                icon: "archivebox",
                title: "Your cellar is empty",
                message: "Add the first bottle, bag or tin worth remembering — then record how it tasted.",
                actionTitle: "Add a bottle",
                action: { showingAdd = true }
            )
        } else {
            VStack(spacing: 0) {
                categoryStrip
                if visible.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Nothing matches",
                        message: "No bottle fits this search and filter. Clear them to see everything again.",
                        actionTitle: "Clear filters",
                        action: clearFilters
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(visible) { bottle in
                            NavigationLink(value: bottle) {
                                BottleRow(bottle: bottle)
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(bottle)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", active: categoryFilter == nil) { categoryFilter = nil }
                ForEach(TastingCategory.allCases) { cat in
                    filterChip(title: cat.title, active: categoryFilter == cat) {
                        categoryFilter = (categoryFilter == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .accessibilityLabel("Filter by category")
    }

    private func filterChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(active ? .white : Brand.text2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    active ? AnyShapeStyle(Brand.inkGradient)
                           : AnyShapeStyle(.ultraThinMaterial),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5),
                                                lineWidth: active ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sortOrder) {
                ForEach(SettingsStore.SortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .accessibilityLabel("Sort order")
        }
    }

    private func clearFilters() {
        search = ""
        categoryFilter = nil
    }

    private func delete(_ bottle: Bottle) {
        Haptics.warning(enabled: settings.hapticsEnabled)
        withAnimation(Brand.ease()) { context.delete(bottle) }
    }
}
