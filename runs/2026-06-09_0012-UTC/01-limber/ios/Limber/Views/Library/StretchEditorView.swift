import SwiftUI
import SwiftData

struct StretchEditorView: View {
    /// nil → create a new custom stretch; non-nil → edit it.
    var stretch: Stretch?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var detail = ""
    @State private var area: BodyArea = .fullBody
    @State private var seconds = 30
    @State private var bothSides = false
    @State private var difficulty = 1
    @State private var loaded = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stretch") {
                    TextField("Name", text: $name)
                    TextField("How to do it", text: $detail, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Target") {
                    Picker("Body area", selection: $area) {
                        ForEach(BodyArea.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("Defaults") {
                    Stepper(value: $seconds, in: 5...300, step: 5) {
                        Text("Hold \(seconds) seconds").font(Brand.mono(14))
                    }
                    Toggle("Both sides", isOn: $bothSides)
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Gentle").tag(1); Text("Moderate").tag(2); Text("Deep").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(stretch == nil ? "New stretch" : "Edit stretch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let stretch, !loaded else { return }
        loaded = true
        name = stretch.name
        detail = stretch.detail
        area = stretch.area
        seconds = stretch.defaultSeconds
        bothSides = stretch.bothSides
        difficulty = stretch.difficultyRaw
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let stretch {
            stretch.name = trimmed
            stretch.detail = detail
            stretch.area = area
            stretch.defaultSeconds = max(5, min(seconds, 600))
            stretch.bothSides = bothSides
            stretch.difficultyRaw = difficulty
        } else {
            let new = Stretch(name: trimmed, area: area,
                              detail: detail.isEmpty ? "A gentle \(area.title.lowercased()) stretch." : detail,
                              defaultSeconds: seconds, bothSides: bothSides,
                              difficulty: difficulty, isCustom: true)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
