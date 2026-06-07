import SwiftUI
import SwiftData

/// The full ride log, grouped by week (newest first), with add / edit / delete.
struct RidesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]

    @State private var showAdd = false
    @State private var searchText = ""

    private var filtered: [Ride] {
        guard !searchText.isEmpty else { return rides }
        let q = searchText.lowercased()
        return rides.filter {
            $0.name.lowercased().contains(q) ||
            $0.type.label.lowercased().contains(q) ||
            $0.notes.lowercased().contains(q)
        }
    }

    private var groups: [WeekGroup] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { ride in
            LoadEngine.startOfWeek(for: ride.date, calendar: weekCalendar(cal))
        }
        return dict.keys.sorted(by: >).map { start in
            let items = (dict[start] ?? []).sorted { $0.date > $1.date }
            let total = items.reduce(0) { $0 + $1.tss }
            return WeekGroup(id: start, weekStart: start, rides: items, totalTSS: total)
        }
    }

    private func weekCalendar(_ base: Calendar) -> Calendar {
        var c = base; c.firstWeekday = 2; return c
    }

    var body: some View {
        NavigationStack {
            Group {
                if rides.isEmpty {
                    ScrollView { emptyState }
                } else if filtered.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No matches",
                                       message: "No rides match “\(searchText)”. Try a different name or type.")
                            .padding(.top, 40)
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Rides")
            .background(Brand.pageBackground)
            .searchable(text: $searchText, prompt: "Search rides")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a ride")
                }
            }
            .sheet(isPresented: $showAdd) {
                RideEditView(ride: nil)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.rides) { ride in
                        ZStack {
                            NavigationLink(value: ride.id) { EmptyView() }.opacity(0)
                            RideRow(ride: ride)
                        }
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(ride)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                } header: {
                    HStack {
                        Text(Format.relativeWeek(group.weekStart))
                            .font(Brand.mono(11, weight: .medium))
                            .foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(Format.int(group.totalTSS)) TSS")
                            .font(Brand.mono(11, weight: .medium))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: UUID.self) { id in
            if let ride = rides.first(where: { $0.id == id }) {
                RideEditView(ride: ride)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(icon: "list.bullet.rectangle",
                           title: "Your ride log is empty",
                           message: "Add rides to build your training history. Power-based or manual TSS — both count.")
            Button { Haptics.tap(); showAdd = true } label: {
                Label("Add a ride", systemImage: "plus.circle.fill")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 60)
    }

    private func delete(_ ride: Ride) {
        Haptics.warning()
        withAnimation(Brand.ease()) { context.delete(ride) }
        try? context.save()
    }
}

private struct WeekGroup: Identifiable {
    let id: Date
    let weekStart: Date
    let rides: [Ride]
    let totalTSS: Double
}
