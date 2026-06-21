import SwiftUI
import SwiftData

struct IndexView: View {
    @Query private var allEntries: [BulletEntry]
    @Query(sort: \Collection.sortOrder) private var collections: [Collection]
    @Query private var settingsArr: [RectoSettings]
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedDate: Date? = nil
    @State private var showDaySheet: Bool = false

    private var fontStyle: String { settingsArr.first?.fontStyle ?? "sans" }
    private let calendar = Calendar.current

    private var currentMonthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    // All days in the displayed month
    private var daysInMonth: [Date?] {
        let start = currentMonthStart
        let range = calendar.range(of: .day, in: .month, for: start)!
        let firstWeekday = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                days.append(date)
            }
        }
        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    // Dates that have daily log entries
    private var datesWithEntries: Set<String> {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return Set(
            allEntries
                .filter { $0.collectionId == nil }
                .map { f.string(from: $0.date) }
        )
    }

    private func hasEntries(on date: Date) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return datesWithEntries.contains(f.string(from: date))
    }

    private func entryCount(on date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allEntries.filter {
            $0.collectionId == nil && $0.date >= start && $0.date < end
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Month navigation
                        monthNavigationHeader

                        // Day-of-week labels
                        weekdayLabels

                        // Calendar grid
                        calendarGrid
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)

                        Divider()
                            .overlay(RectoTheme.ruleLineColor)
                            .padding(.vertical, 16)

                        // Collections section
                        collectionsSection
                    }
                }
            }
            .navigationTitle("Index")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDaySheet) {
                if let date = selectedDate {
                    DayDetailSheet(date: date, entries: entriesForDate(date))
                }
            }
        }
    }

    // MARK: - Month Navigation
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RectoTheme.inkPrimary)
                    .padding(8)
            }

            Spacer()

            Text(monthTitle)
                .font(.system(size: 20, weight: .semibold, design: fontStyle == "serif" ? .serif : .default))
                .foregroundStyle(RectoTheme.inkPrimary)
                .onTapGesture {
                    displayedMonth = Calendar.current.startOfDay(for: .now)
                }

            Spacer()

            Button {
                navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RectoTheme.inkPrimary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Weekday Labels
    private var weekdayLabels: some View {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { sym in
                Text(sym)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(RectoTheme.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                if let date = day {
                    DayCell(
                        date: date,
                        hasEntries: hasEntries(on: date),
                        entryCount: entryCount(on: date),
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    )
                    .onTapGesture {
                        selectedDate = date
                        showDaySheet = true
                    }
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Collections Section
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collections")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RectoTheme.inkSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            if collections.isEmpty {
                HStack {
                    Spacer()
                    Text("No collections yet")
                        .font(.system(size: 14))
                        .foregroundStyle(RectoTheme.inkSecondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(collections) { col in
                        NavigationLink(destination: CollectionDetailView(collection: col)) {
                            IndexCollectionRow(
                                collection: col,
                                entryCount: allEntries.filter { $0.collectionId == col.id }.count
                            )
                        }
                        .buttonStyle(.plain)

                        if col.id != collections.last?.id {
                            Divider()
                                .padding(.leading, 60)
                                .overlay(RectoTheme.ruleLineColor.opacity(0.6))
                        }
                    }
                }
                .background(Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 32)
    }

    private func navigateMonth(by offset: Int) {
        if let newDate = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    private func entriesForDate(_ date: Date) -> [BulletEntry] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return allEntries
            .filter { $0.collectionId == nil && $0.date >= start && $0.date < end }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Day Cell
private struct DayCell: View {
    let date: Date
    let hasEntries: Bool
    let entryCount: Int
    let isToday: Bool
    let isSelected: Bool

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(RectoTheme.taskColor.opacity(0.15))
            }

            if isToday {
                Circle()
                    .stroke(RectoTheme.taskColor, lineWidth: 1.5)
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 15, weight: hasEntries ? .bold : .regular))
                    .foregroundStyle(
                        isToday ? RectoTheme.taskColor : RectoTheme.inkPrimary
                    )

                if hasEntries {
                    Circle()
                        .fill(RectoTheme.taskColor.opacity(0.7))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
    }
}

// MARK: - Index Collection Row
private struct IndexCollectionRow: View {
    let collection: Collection
    let entryCount: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: collection.colorHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: collection.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: collection.colorHex))
            }

            Text(collection.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RectoTheme.inkPrimary)

            Spacer()

            Text("\(entryCount)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(RectoTheme.inkSecondary)
                .frame(minWidth: 24, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RectoTheme.inkSecondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Day Detail Sheet
private struct DayDetailSheet: View {
    let date: Date
    let entries: [BulletEntry]
    @Environment(\.dismiss) private var dismiss

    private var dateTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RectoTheme.paperBackground.ignoresSafeArea()

                if entries.isEmpty {
                    EmptyStateView(
                        icon: "book.pages",
                        title: "No Entries",
                        subtitle: "Nothing was logged on this day."
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.bulletSymbol)
                                    .font(.system(size: 20, weight: .semibold, design: .serif))
                                    .foregroundStyle(RectoTheme.bulletColor(for: entry.bulletTypeEnum))
                                    .frame(width: 24)

                                Text(entry.text)
                                    .font(.system(size: 15))
                                    .foregroundStyle(RectoTheme.inkPrimary)
                                    .strikethrough(
                                        entry.statusEnum == .complete || entry.statusEnum == .irrelevant
                                    )
                            }
                            .listRowBackground(Color.white.opacity(0.5))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(RectoTheme.inkPrimary)
                }
            }
        }
    }
}
