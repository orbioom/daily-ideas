import SwiftUI
import SwiftData

struct BlockDetailView: View {
    @Bindable var block: TimeBlock
    @Environment(\.modelContext) private var context
    @State private var showingEdit = false

    private var sortedChecklist: [ChecklistItem] {
        block.checklist.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if !block.checklist.isEmpty { checklistCard }
                if !block.notes.isEmpty { notesCard }
                doneButton
            }
            .padding()
        }
        .background(Brand.pageBackground)
        .navigationTitle("Block")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            BlockEditorView(mode: .edit(block), defaultDay: block.start)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(block.category.title, systemImage: block.category.icon)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(block.category.color.opacity(0.16),
                                in: Capsule())
                    .foregroundStyle(block.category.color)
                Spacer()
            }
            Text(block.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            HStack(spacing: 16) {
                detail(icon: "clock", text: ScheduleEngine.clockString(minuteOfDay: block.startMinuteOfDay))
                detail(icon: "hourglass", text: ScheduleEngine.durationString(block.durationMinutes))
                detail(icon: "calendar", text: Format.dayFull.string(from: block.start))
            }
        }
        .glassCard()
    }

    private func detail(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(Brand.text2)
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Checklist")
                Spacer()
                Text(Format.percent(block.checklistProgress))
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            ForEach(sortedChecklist) { item in
                Button {
                    item.isDone.toggle()
                    Haptics.tap()
                    syncDone()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isDone ? Brand.live : Brand.text3)
                        Text(item.title)
                            .foregroundStyle(Brand.text)
                            .strikethrough(item.isDone, color: Brand.text3)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityValue(item.isDone ? "Done" : "Not done")
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Notes")
            Text(block.notes)
                .font(.body)
                .foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var doneButton: some View {
        Button {
            block.isDone.toggle()
            if block.isDone { Haptics.success() } else { Haptics.tap() }
            try? context.save()
        } label: {
            Label(block.isDone ? "Completed" : "Mark complete",
                  systemImage: block.isDone ? "checkmark.circle.fill" : "circle")
        }
        .buttonStyle(InkButtonStyle())
    }

    /// If every checklist item is done, the block is done; saves the change.
    private func syncDone() {
        if !block.checklist.isEmpty {
            block.isDone = block.checklist.allSatisfy { $0.isDone }
        }
        try? context.save()
    }
}
