import SwiftUI
import SwiftData

struct AgendaView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeBlock.start) private var allBlocks: [TimeBlock]
    @AppStorage("slate.showCompleted") private var showCompleted = true

    private let cal = Calendar.current

    private var upcoming: [TimeBlock] {
        let cutoff = cal.startOfDay(for: .now)
        return allBlocks.filter {
            $0.start >= cutoff && (showCompleted || !$0.isDone)
        }
    }

    private var grouped: [(day: Date, blocks: [TimeBlock])] {
        let dict = Dictionary(grouping: upcoming) { cal.startOfDay(for: $0.start) }
        return dict.keys.sorted().map { ($0, dict[$0]!.sorted { $0.start < $1.start }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if grouped.isEmpty {
                    EmptyStateView(icon: "list.bullet.rectangle",
                                   title: "No upcoming blocks",
                                   message: "Blocks you schedule for today and beyond appear here as a clean agenda.")
                } else {
                    List {
                        ForEach(grouped, id: \.day) { group in
                            Section {
                                ForEach(group.blocks) { block in
                                    NavigationLink(value: block.persistentModelID) {
                                        AgendaRow(block: block)
                                    }
                                }
                            } header: {
                                Text(sectionTitle(group.day))
                                    .foregroundStyle(Brand.text2)
                            }
                            .listRowBackground(Color.white.opacity(0.001))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Agenda")
            .navigationDestination(for: PersistentIdentifier.self) { id in
                if let block = allBlocks.first(where: { $0.persistentModelID == id }) {
                    BlockDetailView(block: block)
                } else {
                    EmptyStateView(icon: "questionmark", title: "Block not found",
                                   message: "This block may have been deleted.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showCompleted.toggle() }
                    } label: {
                        Image(systemName: showCompleted ? "eye" : "eye.slash")
                    }
                    .accessibilityLabel(showCompleted ? "Hide completed" : "Show completed")
                }
            }
        }
    }

    private func sectionTitle(_ day: Date) -> String {
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInTomorrow(day) { return "Tomorrow" }
        return Format.dayFull.string(from: day)
    }
}

struct AgendaRow: View {
    let block: TimeBlock

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(ScheduleEngine.clockString(minuteOfDay: block.startMinuteOfDay)
                        .replacingOccurrences(of: " ", with: "\n"))
                    .font(Brand.mono(11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Brand.text2)
            }
            .frame(width: 52)

            RoundedRectangle(cornerRadius: 3)
                .fill(block.category.color)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(block.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .strikethrough(block.isDone, color: Brand.text3)
                HStack(spacing: 8) {
                    Label(block.category.title, systemImage: block.category.icon)
                        .labelStyle(.titleAndIcon)
                    if !block.checklist.isEmpty {
                        Label("\(block.checklist.filter { $0.isDone }.count)/\(block.checklist.count)",
                              systemImage: "checklist")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Brand.text3)
            }
            Spacer()
            if block.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Brand.live)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.title), \(ScheduleEngine.clockString(minuteOfDay: block.startMinuteOfDay)), \(block.isDone ? "done" : "not done")")
    }
}
