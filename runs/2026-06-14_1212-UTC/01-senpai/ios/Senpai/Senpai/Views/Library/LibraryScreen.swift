import SwiftUI
import SwiftData

/// Library — segmented by kind, filter by status, search, sort, gradient grid.
struct LibraryScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTitles: [Title]

    @State private var kindFilter: KindFilter = .all
    @State private var statusFilter: StatusFilter = .all
    @State private var sort: LibrarySort = .recent
    @State private var search = ""
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var didApplyDefaults = false

    private var visibleTitles: [Title] {
        LibraryEngine.filteredAndSorted(allTitles,
                                        kind: kindFilter.kind,
                                        status: statusFilter.status,
                                        search: search,
                                        sort: sort)
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Library")
            .searchable(text: $search, prompt: "Search titles or authors")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) { addButton }
            }
            .navigationDestination(for: Title.self) { title in
                TitleDetailView(title: title)
            }
            .sheet(isPresented: $showAdd) {
                AddEditTitleView(mode: .add)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        .onAppear(perform: applyDefaultsOnce)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            kindPicker
            statusChips
            grid
        }
    }

    private var kindPicker: some View {
        Picker("Kind", selection: $kindFilter) {
            ForEach(KindFilter.allCases) { f in
                Text(f.rawValue).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var statusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatusFilter.allCases) { f in
                    let selected = statusFilter == f
                    Button {
                        Haptics.tap(settings.hapticsEnabled)
                        statusFilter = f
                    } label: {
                        Text(f.rawValue)
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(selected ? .white : Theme.inkSoft)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(selected ? Theme.accent : Theme.surfaceAlt)
                            )
                    }
                    .accessibilityLabel("Filter \(f.label)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var grid: some View {
        if visibleTitles.isEmpty {
            ScrollView {
                emptyState
                    .padding(.top, 40)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(visibleTitles) { title in
                        NavigationLink(value: title) {
                            TitleCard(title: title,
                                      hideScore: settings.hideScores,
                                      intensity: settings.accentIntensity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if allTitles.isEmpty {
            EmptyStateView(symbol: "books.vertical",
                           title: "Your library is empty",
                           message: "Add a title or quick-add from Browse to start tracking your anime and manga.",
                           actionTitle: "Add a title") {
                attemptAdd()
            }
        } else {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "Nothing matches",
                           message: "No titles fit these filters. Try a different kind, status, or search.")
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(LibrarySort.allCases) { s in
                    Label(s.rawValue, systemImage: s.symbol).tag(s)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    private var addButton: some View {
        Button {
            attemptAdd()
        } label: {
            Image(systemName: "plus.circle.fill")
        }
        .accessibilityLabel("Add title")
    }

    private func attemptAdd() {
        if Pro.canAddTitle(currentCount: allTitles.count, isPro: isPro) {
            showAdd = true
        } else {
            Haptics.warning(settings.hapticsEnabled)
            paywallReason = .titleLimit
        }
    }

    private func applyDefaultsOnce() {
        guard !didApplyDefaults else { return }
        didApplyDefaults = true
        kindFilter = settings.defaultKind
        sort = settings.defaultSort
    }
}
