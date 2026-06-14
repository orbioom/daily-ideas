import SwiftUI
import SwiftData

struct ItineraryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Bindable var trip: Trip

    @State private var selectedDayID: UUID?
    @State private var editingItem: ItineraryItem?
    @State private var showingAdd = false
    @State private var editMode: EditMode = .inactive

    private var days: [TripDay] { TripService.orderedDays(trip) }

    private var selectedDay: TripDay? {
        if let id = selectedDayID, let match = days.first(where: { $0.id == id }) { return match }
        return days.first
    }

    private var sortedItems: [ItineraryItem] {
        guard let day = selectedDay else { return [] }
        return ItineraryEngine.sortedItems(day.items)
    }

    var body: some View {
        VStack(spacing: 0) {
            if days.isEmpty {
                EmptyStateView(symbol: "calendar.badge.exclamationmark",
                               title: "No days yet",
                               message: "Set the trip's start and end dates to build a day-by-day plan.")
            } else {
                daySelector
                Divider().overlay(Theme.separator)
                timeline
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let day = selectedDay, day.items.count > 1 {
                    Button(editMode.isEditing ? "Done" : "Reorder") {
                        Haptics.tap()
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                    .accessibilityHint("Reorders untimed plans")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .disabled(selectedDay == nil)
                    .accessibilityLabel("Add plan")
            }
        }
        .sheet(isPresented: $showingAdd) {
            if let day = selectedDay {
                ItineraryItemEditor(day: day, item: nil, trip: trip)
            }
        }
        .sheet(item: $editingItem) { item in
            if let host = item.day ?? selectedDay ?? days.first {
                ItineraryItemEditor(day: host, item: item, trip: trip)
            }
        }
        .onAppear {
            if selectedDayID == nil {
                // Default to "today" if on trip, else first day.
                let today = ItineraryEngine.startOfDay(Date())
                selectedDayID = days.first(where: { ItineraryEngine.startOfDay($0.date) == today })?.id ?? days.first?.id
            }
        }
        .onChange(of: selectedDayID) { _, _ in
            editMode = .inactive
        }
    }

    // MARK: Day selector

    private var daySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { idx, day in
                        dayChip(day: day, index: idx)
                            .id(day.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                if let id = selectedDay?.id {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private func dayChip(day: TripDay, index: Int) -> some View {
        let isSelected = day.id == selectedDay?.id
        let f = DateFormatter(); f.dateFormat = "EEE"
        let g = DateFormatter(); g.dateFormat = "d"
        return Button {
            Haptics.select()
            selectedDayID = day.id
        } label: {
            VStack(spacing: 2) {
                Text("Day \(index + 1)")
                    .font(Theme.font(.caption2, weight: .bold))
                Text(f.string(from: day.date))
                    .font(Theme.font(.caption2))
                Text(g.string(from: day.date))
                    .font(Theme.font(.headline, weight: .bold))
            }
            .frame(width: 56, height: 64)
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(isSelected ? Theme.accent : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Day \(index + 1), \(day.date.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: Timeline

    private var timeline: some View {
        Group {
            if let day = selectedDay {
                if day.items.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            dayTitleField(day)
                            EmptyStateView(symbol: "moon.stars",
                                           title: "Nothing planned",
                                           message: "Add your first plan for this day — a flight, a meal, a sight to see.",
                                           actionTitle: "Add a plan",
                                           action: { showingAdd = true })
                        }
                        .padding(.top, 8)
                    }
                } else {
                    List {
                        Section {
                            dayTitleField(day)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        Section {
                            ForEach(sortedItems) { item in
                                TimelineRow(item: item, use24h: settings.timeFormat.use24h, currencySymbol: settings.currencySymbol)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingItem = item }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { delete(item) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button { toggleBooked(item) } label: {
                                            Label(item.booked ? "Unbook" : "Booked",
                                                  systemImage: item.booked ? "bookmark.slash" : "bookmark.fill")
                                        }
                                        .tint(Theme.accent)
                                    }
                            }
                            .onMove { moveUntimed(day: day, from: $0, to: $1) }
                        } footer: {
                            dayCostFooter(day)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, $editMode)
                }
            }
        }
    }

    private func dayTitleField(_ day: TripDay) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "flag")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            TextField("Day label (e.g. Arrival)", text: Binding(
                get: { day.title },
                set: { day.title = $0 }
            ))
            .font(Theme.font(.headline))
            .foregroundStyle(Theme.textPrimary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityLabel("Day label")
    }

    private func dayCostFooter(_ day: TripDay) -> some View {
        let cost = ItineraryEngine.dayCost(day)
        return Group {
            if cost > 0 {
                HStack {
                    Spacer()
                    Text("Day cost: \(BudgetEngine.currencyString(cost, symbol: settings.currencySymbol))")
                        .font(Theme.font(.caption, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 6)
            }
        }
    }

    // MARK: Mutations

    private func delete(_ item: ItineraryItem) {
        Haptics.tap()
        context.delete(item)
    }

    private func toggleBooked(_ item: ItineraryItem) {
        Haptics.select()
        item.booked.toggle()
    }

    /// Reorder applies to untimed items (drag handles only meaningful for them);
    /// we re-base sortOrder across the whole sorted list to keep things stable.
    private func moveUntimed(day: TripDay, from source: IndexSet, to destination: Int) {
        var ordered = sortedItems
        ordered.move(fromOffsets: source, toOffset: destination)
        for (idx, item) in ordered.enumerated() {
            item.sortOrder = idx
        }
        Haptics.tap()
    }
}
