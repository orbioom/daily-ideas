import SwiftUI

private struct MonthRow: Identifiable {
    let id: Int          // day of month
    let date: Date
    let isToday: Bool
    let times: [Prayer: String]
}

struct MonthView: View {
    @AppStorage("cityID") private var cityID = Gazetteer.defaultCityID
    @AppStorage("method") private var methodRaw = CalculationMethod.mwl.rawValue
    @AppStorage("hanafiAsr") private var hanafiAsr = false
    @AppStorage("use24Hour") private var use24Hour = false

    @State private var monthAnchor = Date.now
    @State private var rows: [MonthRow] = []
    @State private var isLoading = true

    private var settings: PrayerSettings {
        PrayerSettings(
            city: Gazetteer.city(id: cityID) ?? Gazetteer.cities[0],
            method: CalculationMethod(rawValue: methodRaw) ?? .mwl,
            hanafiAsr: hanafiAsr,
            use24Hour: use24Hour
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Computing the month…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    monthTable
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Monthly Times")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        shiftMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Previous month")
                    Button {
                        shiftMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("Next month")
                }
            }
            .task(id: taskKey) { await rebuild() }
        }
    }

    private var taskKey: String {
        "\(cityID)|\(methodRaw)|\(hanafiAsr)|\(use24Hour)|\(monthAnchor.timeIntervalSince1970)"
    }

    private func shiftMonth(_ delta: Int) {
        Haptics.tap()
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }

    @MainActor
    private func rebuild() async {
        isLoading = true
        let settings = self.settings
        let anchor = monthAnchor
        // Trivial math, but built off-main to keep month flips instant.
        let built: [MonthRow] = await Task.detached(priority: .userInitiated) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = settings.city.timeZone
            let formatter = settings.timeFormatter()
            guard let interval = calendar.dateInterval(of: .month, for: anchor),
                  let dayCount = calendar.range(of: .day, in: .month, for: anchor)?.count else {
                return []
            }
            var rows: [MonthRow] = []
            for dayIndex in 0..<dayCount {
                guard let day = calendar.date(byAdding: .day, value: dayIndex, to: interval.start) else { continue }
                let times = settings.times(on: day)
                var strings: [Prayer: String] = [:]
                for prayer in Prayer.allCases {
                    if let t = times.time(for: prayer) {
                        strings[prayer] = formatter.string(from: t)
                    } else {
                        strings[prayer] = "—"
                    }
                }
                rows.append(MonthRow(
                    id: dayIndex + 1,
                    date: day,
                    isToday: calendar.isDate(day, inSameDayAs: .now),
                    times: strings
                ))
            }
            return rows
        }.value
        rows = built
        isLoading = false
    }

    private var monthTable: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(monthAnchor, format: .dateTime.month(.wide).year())
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .frame(maxWidth: .infinity)

                if rows.isEmpty {
                    ContentUnavailableView(
                        "Couldn't Build This Month",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Try another month, or re-select your city in Settings.")
                    )
                } else {
                    VStack(spacing: 0) {
                        headerRow
                        ForEach(rows) { row in
                            dataRow(row)
                            if row.id != rows.count {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("\(settings.city.displayName) · \(settings.method.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("Day")
                .frame(width: 44, alignment: .leading)
            ForEach(Prayer.allCases) { prayer in
                Text(prayer.displayName.prefix(prayer == .sunrise ? 4 : 7))
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
    }

    private func dataRow(_ row: MonthRow) -> some View {
        HStack(spacing: 0) {
            Text("\(row.id)")
                .font(.caption.weight(row.isToday ? .bold : .regular).monospacedDigit())
                .foregroundStyle(row.isToday ? MihrabTheme.gold : .primary)
                .frame(width: 44, alignment: .leading)
            ForEach(Prayer.allCases) { prayer in
                Text(row.times[prayer] ?? "—")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(row.isToday ? MihrabTheme.gold : .primary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(row.isToday ? MihrabTheme.gold.opacity(0.10) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel(row))
    }

    private func rowAccessibilityLabel(_ row: MonthRow) -> String {
        let parts = Prayer.allCases.map { "\($0.displayName) \(row.times[$0] ?? "unknown")" }
        return "Day \(row.id): " + parts.joined(separator: ", ")
    }
}
