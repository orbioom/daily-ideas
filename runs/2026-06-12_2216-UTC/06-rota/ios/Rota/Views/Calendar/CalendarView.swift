import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var patterns: [RotationPattern]
    @Query private var overrides: [ShiftOverride]
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true

    @State private var monthAnchor = Date.now
    @State private var selectedDay: Date?

    private var activePattern: RotationPattern? {
        patterns.first(where: \.isActive) ?? patterns.first
    }

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = weekStartsMonday ? 2 : 1
        return c
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    monthHeader
                    weekdayHeader
                    monthGrid
                    legend
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: Binding(
                get: { selectedDay.map { DayBox(date: $0) } },
                set: { if $0 == nil { selectedDay = nil } }
            )) { box in
                DaySheet(date: box.date, activePattern: activePattern)
                    .presentationDetents([.medium])
            }
        }
    }

    private struct DayBox: Identifiable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack {
            Button {
                Haptics.tap()
                shift(-1)
            } label: {
                Image(systemName: "chevron.left").frame(width: 38, height: 38)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            VStack(spacing: 1) {
                Text(monthAnchor, format: .dateTime.month(.wide).year())
                    .font(.headline)
                if !calendar.isDate(monthAnchor, equalTo: .now, toGranularity: .month) {
                    Button("Back to today") {
                        Haptics.tap()
                        monthAnchor = .now
                    }
                    .font(.caption2.weight(.semibold))
                }
            }
            Spacer()
            Button {
                Haptics.tap()
                shift(1)
            } label: {
                Image(systemName: "chevron.right").frame(width: 38, height: 38)
            }
            .accessibilityLabel("Next month")
        }
    }

    private func shift(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }

    private var weekdayHeader: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let ordered = Array(symbols[(calendar.firstWeekday - 1)...] + symbols[..<(calendar.firstWeekday - 1)])
        return HStack(spacing: 4) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor),
              let dayCount = calendar.range(of: .day, in: .month, for: monthAnchor)?.count else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = ((firstWeekday - calendar.firstWeekday) + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for index in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: index, to: interval.start))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var monthGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 54)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let resolved = RotaEngine.shift(on: day, pattern: activePattern, overrides: overrides)
        let isToday = calendar.isDateInToday(day)
        return Button {
            Haptics.tap()
            selectedDay = day
        } label: {
            VStack(spacing: 3) {
                Text(day, format: .dateTime.day())
                    .font(.caption.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? RotaTheme.amber : .primary)
                if let type = resolved.shiftType, !type.isRest {
                    ShiftBadge(symbol: type.symbol, colorHex: type.colorHex, small: true)
                } else {
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if resolved.isOverride {
                    Circle()
                        .fill(RotaTheme.amber)
                        .frame(width: 4, height: 4)
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isToday ? RotaTheme.amber.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(day: day, resolved: resolved))
        .accessibilityHint("Shows details and lets you change this day")
    }

    private func cellLabel(day: Date, resolved: (shiftType: ShiftType?, isOverride: Bool, note: String)) -> String {
        let base = day.formatted(.dateTime.weekday(.wide).day().month())
        let what = (resolved.shiftType?.isRest == false ? resolved.shiftType?.name : nil) ?? "day off"
        return "\(base): \(what)\(resolved.isOverride ? ", manually changed" : "")"
    }

    private var legend: some View {
        Group {
            if let pattern = activePattern, !pattern.sortedSlots.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(pattern.name) — \(pattern.sortedSlots.count)-day cycle")
                        .font(.subheadline.weight(.semibold))
                    Text("Tap any day to swap a shift, add overtime, or mark a day off. Amber dots mark changed days.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .rotaPanel()
            } else {
                ContentUnavailableView(
                    "No Rotation Yet",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Set up shift types and a repeating cycle on the Rotation tab — the calendar fills itself in, years ahead.")
                )
                .frame(minHeight: 180)
            }
        }
    }
}

// MARK: - Day sheet

struct DaySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var overrides: [ShiftOverride]
    @Query(sort: \ShiftType.createdAt) private var shiftTypes: [ShiftType]
    @AppStorage("use24Hour") private var use24Hour = true

    let date: Date
    let activePattern: RotationPattern?

    @State private var note = ""

    private var dayKey: String { RotaDay.key(for: date) }
    private var existingOverride: ShiftOverride? {
        overrides.first { $0.dayKey == dayKey }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let resolved = RotaEngine.shift(on: date, pattern: activePattern, overrides: overrides)
                    HStack(spacing: 12) {
                        if let type = resolved.shiftType, !type.isRest {
                            ShiftBadge(symbol: type.symbol, colorHex: type.colorHex)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.name).font(.body.weight(.semibold))
                                Text(type.timeRangeString(use24Hour: use24Hour))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundStyle(RotaTheme.amber)
                            Text("Day off").font(.body.weight(.semibold))
                        }
                        Spacer()
                        if resolved.isOverride {
                            Text("Changed")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RotaTheme.amber)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("Scheduled")
                }

                Section {
                    ForEach(shiftTypes) { type in
                        Button {
                            apply(type: type)
                        } label: {
                            HStack {
                                ShiftBadge(symbol: type.symbol, colorHex: type.colorHex, small: true)
                                Text(type.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if !type.isRest {
                                    Text(type.timeRangeString(use24Hour: use24Hour))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Button {
                        apply(type: nil)
                    } label: {
                        Label("Force day off", systemImage: "moon.zzz")
                    }
                } header: {
                    Text("Change this day to")
                } footer: {
                    shiftTypes.isEmpty
                        ? Text("Create shift types on the Rotation tab first.")
                        : Text("Changes affect only this date — the rotation continues unchanged.")
                }

                if existingOverride != nil {
                    Section {
                        Button("Restore rotation for this day", role: .destructive) {
                            if let existing = existingOverride {
                                modelContext.delete(existing)
                            }
                            Haptics.tap()
                            dismiss()
                        }
                    }
                }

                Section("Note") {
                    TextField("Why the change? (swap with Dana, overtime…)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .onAppear { note = existingOverride?.note ?? "" }
                }
            }
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).day().month()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let existing = existingOverride {
                            existing.note = note
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    private func apply(type: ShiftType?) {
        Haptics.tap()
        if let existing = existingOverride {
            existing.shiftType = type
            existing.note = note
        } else {
            modelContext.insert(ShiftOverride(dayKey: dayKey, shiftType: type, note: note))
        }
        dismiss()
    }
}
