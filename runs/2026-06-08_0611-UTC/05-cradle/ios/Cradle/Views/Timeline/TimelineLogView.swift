import SwiftUI
import SwiftData

struct TimelineLogView: View {
    @AppStorage("cradle.activeBaby") private var activeBabyID = ""
    @AppStorage("cradle.unit") private var unitRaw = "ml"
    @AppStorage("cradle.clock24") private var use24h = false

    @Environment(\.modelContext) private var context
    @Query(sort: \Baby.order) private var babies: [Baby]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var editingEvent: CareEvent? = nil
    @State private var showAddSheet = false
    @State private var eventToDelete: CareEvent? = nil

    private var useOz: Bool { unitRaw == "oz" }

    private var activeBaby: Baby? {
        babies.first(where: { $0.id.uuidString == activeBabyID }) ?? babies.first
    }

    private var dayEvents: [CareEvent] {
        guard let baby = activeBaby else { return [] }
        let cal = Calendar.current
        return baby.events
            .filter { cal.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime > $1.startTime }
    }

    private var summary: CradleEngine.DaySummary {
        CradleEngine.daySummary(events: activeBaby?.events ?? [], day: selectedDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 0) {
                    // Date selector
                    datePicker
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Day summary header
                    daySummaryHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Events list
                    if dayEvents.isEmpty {
                        EmptyStateView(
                            icon: "list.bullet.rectangle",
                            title: "No events logged",
                            message: "Use the quick log on Home, or tap + to add an event."
                        )
                        .padding(.top, 40)
                    } else {
                        List {
                            ForEach(dayEvents) { event in
                                EventRow(event: event, useOz: useOz, use24h: use24h)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Haptics.tap()
                                        editingEvent = event
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteEvent(event)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .accessibilityHint("Double-tap to edit, swipe left to delete")
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Brand.text)
                    }
                    .accessibilityLabel("Add event")
                }
            }
            .sheet(item: $editingEvent) { event in
                AddEventSheet(existingEvent: event, baby: event.baby)
            }
            .sheet(isPresented: $showAddSheet) {
                AddEventSheet(defaultKind: .feed, baby: activeBaby)
            }
        }
    }

    // MARK: - Date Picker Row

    @ViewBuilder
    private var datePicker: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.selection()
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text2)
            }
            .accessibilityLabel("Previous day")

            Spacer()

            DatePicker(
                "Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .foregroundStyle(Brand.text)
            .accessibilityLabel("Selected date")

            Spacer()

            Button {
                Haptics.selection()
                let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                if next <= Date() {
                    selectedDate = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(selectedDate) ? Brand.text3 : Brand.text2
                    )
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .accessibilityLabel("Next day")
        }
    }

    // MARK: - Day Summary Header

    @ViewBuilder
    private var daySummaryHeader: some View {
        GlassCard(padding: 12) {
            HStack(spacing: 0) {
                miniStat(value: "\(summary.feeds)", label: "Feeds", color: EventKind.feed.color)
                Divider().frame(height: 28).padding(.horizontal, 6)
                miniStat(value: Format.duration(summary.totalSleep), label: "Sleep", color: EventKind.sleep.color)
                Divider().frame(height: 28).padding(.horizontal, 6)
                miniStat(value: "\(summary.wetDiapers + summary.dirtyDiapers)", label: "Diapers", color: EventKind.diaper.color)
                Divider().frame(height: 28).padding(.horizontal, 6)
                miniStat(value: "\(summary.naps)", label: "Naps", color: Brand.magic)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Summary: \(summary.feeds) feeds, \(Format.duration(summary.totalSleep)) sleep, \(summary.naps) naps, \(summary.wetDiapers + summary.dirtyDiapers) diapers")
    }

    @ViewBuilder
    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Brand.mono(14, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Delete

    private func deleteEvent(_ event: CareEvent) {
        Haptics.warning()
        if let baby = event.baby, let idx = baby.events.firstIndex(where: { $0.id == event.id }) {
            baby.events.remove(at: idx)
        }
        context.delete(event)
    }
}
