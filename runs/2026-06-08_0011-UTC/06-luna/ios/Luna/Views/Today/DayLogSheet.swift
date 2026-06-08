import SwiftUI
import SwiftData

/// Log or edit a single day. Finds an existing DayLog for the date or creates one.
struct DayLogSheet: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var logs: [DayLog]

    @State private var flow: Flow = .none
    @State private var symptoms: Set<String> = []
    @State private var mood = 0
    @State private var note = ""
    @State private var loaded = false

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

    private var existing: DayLog? {
        let d = Calendar.current.startOfDay(for: date)
        return logs.first { Calendar.current.isDate($0.date, inSameDayAs: d) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "FLOW")
                                HStack(spacing: 8) {
                                    ForEach(Flow.allCases) { f in
                                        Button { flow = f; Haptics.selection() } label: {
                                            VStack(spacing: 6) {
                                                Circle()
                                                    .fill(flow == f ? f.color : Color.clear)
                                                    .overlay(Circle().strokeBorder(f == .none ? Brand.text3 : f.color, lineWidth: 1.5))
                                                    .frame(width: 34, height: 34)
                                                Text(f.label).font(.caption2)
                                                    .foregroundStyle(flow == f ? Brand.text : Brand.text3)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(f.label)
                                        .accessibilityAddTraits(flow == f ? .isSelected : [])
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "MOOD")
                                HStack(spacing: 10) {
                                    ForEach(1...5, id: \.self) { i in
                                        Button { mood = (mood == i ? 0 : i); Haptics.selection() } label: {
                                            Image(systemName: moodSymbol(i))
                                                .font(.title2)
                                                .foregroundStyle(i == mood ? LunaColors.luteal : Brand.text3)
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Mood \(i)")
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "SYMPTOMS")
                                LazyVGrid(columns: cols, spacing: 8) {
                                    ForEach(Symptoms.all, id: \.0) { name, symbol in
                                        let sel = symptoms.contains(name)
                                        Button {
                                            if sel { symptoms.remove(name) } else { symptoms.insert(name) }
                                            Haptics.selection()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: symbol).font(.caption)
                                                Text(name).font(.subheadline).lineLimit(1)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12).padding(.vertical, 10)
                                            .background(sel ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                                                        in: RoundedRectangle(cornerRadius: 12))
                                            .foregroundStyle(sel ? .white : Brand.text)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: "NOTE")
                                TextField("Anything to remember", text: $note, axis: .vertical)
                                    .lineLimit(1...4).foregroundStyle(Brand.text)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(Format.day.string(from: date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func moodSymbol(_ i: Int) -> String {
        ["cloud.rain.fill", "cloud.fill", "cloud.sun.fill", "sun.max.fill", "sparkles"][i - 1]
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let e = existing {
            flow = e.flow; symptoms = Set(e.symptoms); mood = e.mood; note = e.note
        }
    }

    private func save() {
        let log: DayLog
        if let e = existing { log = e } else {
            log = DayLog(date: date); context.insert(log)
        }
        log.flow = flow
        log.symptoms = Array(symptoms).sorted()
        log.mood = mood
        log.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if log.isEmpty, existing != nil { context.delete(log) }
        try? context.save(); Haptics.success(); dismiss()
    }
}
