import SwiftUI
import SwiftData
import Combine

struct PlannerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeBlock.start) private var allBlocks: [TimeBlock]

    @AppStorage("slate.dayStartHour") private var dayStartHour = 6
    @AppStorage("slate.dayEndHour") private var dayEndHour = 23

    @State private var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @State private var editing: TimeBlock?
    @State private var showingNew = false
    @State private var showingSettings = false
    @State private var now = Date()

    private let cal = Calendar.current

    private var dayBlocks: [TimeBlock] {
        allBlocks.filter { cal.isDate($0.start, inSameDayAs: selectedDay) }
    }

    private var isToday: Bool { cal.isDateInToday(selectedDay) }

    private var summary: ScheduleEngine.DaySummary {
        ScheduleEngine.summary(dayBlocks,
                               dayStart: dayStartHour * 60,
                               dayEnd: dayEndHour * 60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    DateStrip(selectedDay: $selectedDay)
                    summaryBar
                    Divider().overlay(Brand.hairline)
                    content
                }
            }
            .navigationTitle("Slate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add block")
                }
            }
            .sheet(item: $editing) { block in
                BlockEditorView(mode: .edit(block), defaultDay: selectedDay)
            }
            .sheet(isPresented: $showingNew) {
                BlockEditorView(mode: .create, defaultDay: selectedDay)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            now = Date()
        }
    }

    @ViewBuilder private var summaryBar: some View {
        HStack(spacing: 0) {
            stat(value: ScheduleEngine.durationString(summary.scheduledMinutes), label: "Scheduled")
            divider
            stat(value: Format.percent(summary.completion), label: "Done")
            divider
            stat(value: ScheduleEngine.durationString(summary.freeMinutes), label: "Free")
            divider
            stat(value: "\(summary.conflicts)", label: "Conflicts",
                 tint: summary.conflicts > 0 ? Brand.warn : nil)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }

    private var divider: some View {
        Rectangle().fill(Brand.hairline).frame(width: 1, height: 28)
    }

    private func stat(value: String, label: String, tint: Color? = nil) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(tint ?? Brand.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    @ViewBuilder private var content: some View {
        if dayBlocks.isEmpty {
            ScrollView {
                VStack(spacing: 20) {
                    EmptyStateView(icon: "calendar.badge.plus",
                                   title: "Nothing scheduled",
                                   message: isToday ? "Add a block, or drop in a routine from the Routines tab."
                                                    : "This day is open. Tap + to plan something.")
                        .padding(.top, 40)
                    Button {
                        showingNew = true
                    } label: {
                        Label("Add a block", systemImage: "plus")
                    }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 32)
                }
            }
        } else {
            ScrollView {
                TimelineCanvas(blocks: dayBlocks,
                               dayStartHour: dayStartHour,
                               dayEndHour: max(dayStartHour + 1, dayEndHour),
                               isToday: isToday,
                               now: now,
                               onTap: { editing = $0 },
                               onToggle: toggle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
        }
    }

    private func toggle(_ block: TimeBlock) {
        block.isDone.toggle()
        if block.isDone { Haptics.success() } else { Haptics.tap() }
        try? context.save()
    }
}

/// A 7-day horizontal strip centered on the selected day.
private struct DateStrip: View {
    @Binding var selectedDay: Date
    private let cal = Calendar.current

    private var days: [Date] {
        let start = cal.date(byAdding: .day, value: -3, to: cal.startOfDay(for: selectedDay)) ?? selectedDay
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                let selected = cal.isDate(day, inSameDayAs: selectedDay)
                Button {
                    withAnimation(Brand.ease(0.25)) { selectedDay = day }
                    Haptics.selection()
                } label: {
                    VStack(spacing: 3) {
                        Text(Format.weekdayShort.string(from: day))
                            .font(.caption2.weight(.medium))
                        Text(Format.dayOfMonth.string(from: day))
                            .font(.callout.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selected ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(selected ? Color.white :
                                        (cal.isDateInToday(day) ? Color(hex: 0x5E63A6) : Brand.text2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(cal.isDateInToday(day) && !selected ? Color(hex: 0x5E63A6).opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Format.dayFull.string(from: day))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}
