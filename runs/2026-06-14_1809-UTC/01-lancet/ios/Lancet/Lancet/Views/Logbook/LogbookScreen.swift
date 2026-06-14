import SwiftUI
import SwiftData

/// The classic logbook: rows = recent days, columns = meal slots, color-coded cells.
struct LogbookScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var editingReading: Reading?

    private let dayCount = 14
    private let columns = MealSlot.gridColumns

    /// Recent N days (most recent first), each as a start-of-day anchor.
    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<dayCount).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    /// readings keyed by (startOfDay) then by slot.
    private func readings(on day: Date, slot: MealSlot) -> [Reading] {
        let cal = Calendar.current
        return readings.filter {
            cal.isDate($0.date, inSameDayAs: day) && $0.resolvedSlot == slot
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if readings.isEmpty {
                    EmptyStateView(symbol: "square.grid.3x3",
                                   title: "Your logbook is empty",
                                   message: "Log readings and they'll fill this grid — one row per day, one column per meal.")
                } else {
                    ScrollView([.vertical]) {
                        VStack(spacing: 0) {
                            headerRow
                            ForEach(days, id: \.self) { day in
                                dayRow(day)
                                Divider().overlay(Theme.hairline)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    legendButton
                }
            }
            .sheet(item: $editingReading) { r in
                AddReadingSheet(editing: r)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 6) {
            Text("")
                .frame(width: 52, alignment: .leading)
            ForEach(columns) { slot in
                VStack(spacing: 2) {
                    Image(systemName: slot.symbol)
                        .font(.system(size: 12))
                        .accessibilityHidden(true)
                    Text(slot.shortLabel)
                        .font(Theme.rounded(11, .semibold))
                }
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(slot.label)
            }
        }
        .padding(.vertical, 8)
    }

    private func dayRow(_ day: Date) -> some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.ink)
                Text(day.formatted(.dateTime.day().month(.abbreviated)))
                    .font(Theme.rounded(10))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(width: 52, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(day.formatted(date: .complete, time: .omitted))

            ForEach(columns) { slot in
                cell(day: day, slot: slot)
            }
        }
        .padding(.vertical, 8)
    }

    private func cell(day: Date, slot: MealSlot) -> some View {
        let cellReadings = readings(on: day, slot: slot)
        return VStack(spacing: 4) {
            if cellReadings.isEmpty {
                Text("·")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .accessibilityHidden(true)
            } else {
                ForEach(cellReadings) { r in
                    Button { editingReading = r } label: {
                        GlucoseChip(mgdl: r.valueMgdl)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var legendButton: some View {
        Menu {
            Section("Legend") {
                ForEach(GlucoseBand.allCases) { band in
                    Label(band.rawValue, systemImage: band.symbol)
                }
            }
            Text("Range: \(settings.formatRange())")
        } label: {
            Image(systemName: "info.circle")
                .accessibilityLabel("Color legend")
        }
    }
}
