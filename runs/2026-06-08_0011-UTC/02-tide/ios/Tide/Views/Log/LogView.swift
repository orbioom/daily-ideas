import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]

    @State private var showingNew = false
    @State private var editing: MoodEntry?

    private var grouped: [(Date, [MoodEntry])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: entries) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        Button {
                            showingNew = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").font(.title2)
                                Text("How are you right now?").font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(InkButtonStyle())

                        if entries.isEmpty {
                            EmptyStateView(icon: "cloud.sun.fill",
                                           title: "Your first check-in",
                                           message: "Tap above to log how you feel. It takes ten seconds.")
                            Button("Load sample journal") {
                                SampleData.load(into: context); Haptics.success()
                            }
                            .buttonStyle(GlassButtonStyle())
                        } else {
                            ForEach(grouped, id: \.0) { day, dayEntries in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(dayHeader(day))
                                        .font(Brand.mono(12, weight: .medium))
                                        .tracking(1.0)
                                        .foregroundStyle(Brand.text3)
                                        .padding(.horizontal, 4)
                                    ForEach(dayEntries) { entry in
                                        Button { editing = entry } label: { EntryRow(entry: entry) }
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tide")
            .sheet(isPresented: $showingNew) { EntryEditView(entry: nil) }
            .sheet(item: $editing) { EntryEditView(entry: $0) }
        }
    }

    private func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "TODAY" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }
        return Format.dayTime.string(from: date).components(separatedBy: " · ").first?.uppercased() ?? ""
    }
}

struct EntryRow: View {
    let entry: MoodEntry
    @Environment(\.modelContext) private var context

    var body: some View {
        GlassCard(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(Mood.color(entry.mood)).frame(width: 44, height: 44)
                    Image(systemName: Mood.symbol(entry.mood))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(Mood.label(entry.mood))
                            .font(.headline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Format.time.string(from: entry.date))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.subheadline).foregroundStyle(Brand.text2)
                            .lineLimit(3)
                    }
                    if !entry.activities.isEmpty {
                        WrapChips(items: entry.activities.sorted { $0.order < $1.order }) { a in
                            HStack(spacing: 4) {
                                Image(systemName: a.symbol).font(.caption2)
                                Text(a.name).font(.caption2)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(Brand.text2)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Mood.label(entry.mood)) at \(Format.time.string(from: entry.date)). \(entry.note)")
        .contextMenu {
            Button(role: .destructive) {
                context.delete(entry); try? context.save(); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
