import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]

    @State private var filter: TripPurpose? = nil
    @State private var editorTrip: Trip? = nil
    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var toast: String?
    @State private var deleteError: String?

    private var filtered: [Trip] {
        guard let filter else { return trips }
        return trips.filter { $0.purpose == filter }
    }

    /// Trips grouped by month, newest first.
    private var grouped: [(key: Date, value: [Trip])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filtered) { trip -> Date in
            let comps = cal.dateComponents([.year, .month], from: trip.date)
            return cal.date(from: comps) ?? trip.date
        }
        return groups.sorted { $0.key > $1.key }
    }

    private var atFreeCap: Bool { !isPro && trips.count >= Pro.freeTripCap }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if trips.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { addButton }
                ToolbarItem(placement: .topBarLeading) { filterMenu }
            }
            .sheet(isPresented: $showEditor) {
                TripEditorView(trip: editorTrip) {
                    toast = editorTrip == nil ? "Trip saved" : "Trip updated"
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .alert("Couldn't delete trip", isPresented: .constant(deleteError != nil)) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    private var addButton: some View {
        Button {
            if atFreeCap {
                showPaywall = true
                Haptics.warning(settings.hapticsEnabled)
            } else {
                editorTrip = nil
                showEditor = true
                Haptics.impact(settings.hapticsEnabled)
            }
        } label: {
            Image(systemName: atFreeCap ? "lock.fill" : "plus")
                .font(.system(size: 16, weight: .bold))
        }
        .accessibilityLabel(atFreeCap ? "Log trip — Pro required" : "Log trip")
    }

    private var filterMenu: some View {
        Menu {
            Button {
                filter = nil
            } label: {
                if filter == nil { Label("All purposes", systemImage: "checkmark") }
                else { Text("All purposes") }
            }
            ForEach(TripPurpose.allCases) { p in
                Button {
                    filter = p
                    Haptics.selection(settings.hapticsEnabled)
                } label: {
                    if filter == p { Label(p.rawValue, systemImage: "checkmark") }
                    else { Label(p.rawValue, systemImage: p.symbol) }
                }
            }
        } label: {
            Image(systemName: filter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 16, weight: .semibold))
        }
        .accessibilityLabel("Filter by purpose")
    }

    private var list: some View {
        List {
            if atFreeCap {
                Section {
                    ProLockBanner(message: "You've reached the free \(Pro.freeTripCap)-trip cap. Unlock unlimited logging.") {
                        showPaywall = true
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(Color.clear)
                }
            }
            if filtered.isEmpty {
                Section {
                    Text("No \(filter?.rawValue.lowercased() ?? "") trips match this filter.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .listRowBackground(Theme.surface)
                }
            }
            ForEach(grouped, id: \.key) { group in
                Section {
                    ForEach(group.value) { trip in
                        Button {
                            editorTrip = trip
                            showEditor = true
                        } label: {
                            TripRow(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(trip) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(DateFormatting.monthYear.string(from: group.key))
                        Spacer()
                        Text(settings.distance(group.value.reduce(0) { $0 + $1.effectiveMiles }))
                            .font(Theme.mono(12, .semibold))
                    }
                    .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func delete(_ trip: Trip) {
        Haptics.impact(settings.hapticsEnabled, style: .medium)
        context.delete(trip)
        do {
            try context.save()
            toast = "Trip deleted"
        } catch {
            deleteError = "Please try again."
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "car.fill",
            title: "No trips yet",
            message: "Log a drive and Furlong converts the miles into a deduction using the right IRS rate.",
            actionTitle: "Log a trip") {
                editorTrip = nil
                showEditor = true
                Haptics.impact(settings.hapticsEnabled)
            }
    }
}
