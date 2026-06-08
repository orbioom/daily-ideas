import SwiftUI
import SwiftData

/// Wraps the sheet destination so we can drive a single `.sheet(item:)`.
private enum LogSheetItem: Identifiable {
    case newLog
    case editLog(SleepLog)

    var id: String {
        switch self {
        case .newLog:          return "new"
        case .editLog(let l): return l.id.uuidString
        }
    }
}

struct HistoryView: View {
    @Query(sort: \SleepLog.wakeTime, order: .reverse) private var logs: [SleepLog]
    @Environment(\.modelContext) private var context
    @AppStorage("nocturne.goalHours") private var goalHours = 8.0
    @AppStorage("nocturne.clock24")   private var clock24   = false

    @State private var sheetItem:    LogSheetItem? = nil
    @State private var logToDelete:  SleepLog?     = nil
    @State private var showDeleteConfirm             = false

    /// Groups logs by month-year string, preserving order (newest first).
    private var grouped: [(key: String, logs: [SleepLog])] {
        var order: [String] = []
        var dict:  [String: [SleepLog]] = [:]
        for log in logs {
            let key = Format.monthYear(log.nightDate)
            if dict[key] == nil {
                order.append(key)
                dict[key] = []
            }
            dict[key]?.append(log)
        }
        return order.map { k in (key: k, logs: dict[k] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if logs.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No sleep logs",
                        message: "Your logged nights will appear here grouped by month."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.key) { section in
                            Section {
                                ForEach(section.logs) { log in
                                    HistoryRowView(
                                        log: log,
                                        goalHours: goalHours,
                                        clock24: clock24
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            logToDelete = log
                                            showDeleteConfirm = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(Brand.danger)

                                        Button {
                                            Haptics.tap()
                                            sheetItem = .editLog(log)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Brand.info)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Haptics.tap()
                                        sheetItem = .editLog(log)
                                    }
                                    .accessibilityHint("Double tap to edit this sleep log")
                                }
                            } header: {
                                Text(section.key)
                                    .font(Brand.mono(12, weight: .semibold))
                                    .foregroundStyle(Brand.text3)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        sheetItem = .newLog
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add sleep log")
                }
            }
            .sheet(item: $sheetItem) { item in
                switch item {
                case .newLog:
                    LogSleepView()
                case .editLog(let log):
                    LogSleepView(existing: log)
                }
            }
            .confirmationDialog(
                "Delete this sleep log?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let log = logToDelete {
                        context.delete(log)
                        try? context.save()
                        Haptics.warning()
                    }
                    logToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    logToDelete = nil
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

// MARK: - History Row

private struct HistoryRowView: View {
    let log: SleepLog
    let goalHours: Double
    let clock24: Bool

    private var debtContrib: Double {
        SleepEngine.debtContribution(log, targetHours: goalHours)
    }

    var body: some View {
        GlassCard(padding: 14) {
            HStack(alignment: .center, spacing: 12) {
                // Date column
                VStack(spacing: 2) {
                    Text(Format.weekdayShort(log.nightDate))
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.text3)
                    Text(dayString)
                        .font(Brand.mono(20, weight: .bold))
                        .foregroundStyle(Brand.text)
                    Text(monthString)
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
                .frame(width: 38)
                .accessibilityHidden(true)

                Divider()
                    .frame(height: 44)
                    .overlay(Brand.hairline)
                    .accessibilityHidden(true)

                // Main info
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(Format.duration(log.durationHours))
                            .font(Brand.mono(18, weight: .semibold))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        StarRatingDisplay(rating: log.quality, starSize: 13)
                    }

                    HStack(spacing: 8) {
                        Label(Format.clock(log.bedTime, use24h: clock24), systemImage: "moon.fill")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                        Label(Format.clock(log.wakeTime, use24h: clock24), systemImage: "sunrise.fill")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                        Spacer()
                        debtBadge
                    }

                    if !log.tags.isEmpty {
                        TagChipsDisplay(tags: log.tags)
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let dateStr = Format.shortDate(log.nightDate)
        let dur     = Format.duration(log.durationHours)
        let qual    = Format.qualityLabel(log.quality)
        let tagsStr = log.tags.isEmpty ? "" : ", tags: \(log.tags.joined(separator: ", "))"
        return "\(dateStr), \(dur), quality \(qual)\(tagsStr)"
    }

    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: log.nightDate)
    }

    private var monthString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: log.nightDate)
    }

    private var debtBadge: some View {
        let color: Color = debtContrib <= 0 ? Brand.live : (debtContrib < 1 ? Brand.warn : Brand.danger)
        let text = debtContrib <= 0
            ? "+\(Format.hoursDecimal(-debtContrib))"
            : "-\(Format.hoursDecimal(debtContrib))"
        return Text(text)
            .font(Brand.mono(11, weight: .semibold))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}
