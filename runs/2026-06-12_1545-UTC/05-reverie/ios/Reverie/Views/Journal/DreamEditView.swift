import SwiftUI
import SwiftData

struct DreamEditView: View {
    let dream: Dream?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DreamSign.name) private var allSigns: [DreamSign]

    @State private var date = Date()
    @State private var title = ""
    @State private var narrative = ""
    @State private var lucidity: Lucidity = .nonLucid
    @State private var vividness = 3
    @State private var mood: DreamMood = .neutral
    @State private var isNightmare = false
    @State private var isRecurring = false
    @State private var technique: DreamTechnique = .none
    @State private var selectedSignIDs: Set<UUID> = []
    @State private var newSignName = ""
    @State private var newSignCategory: SignCategory = .theme

    private var isEditing: Bool { dream != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Night of", selection: $date, in: ...Date(), displayedComponents: .date)
                    TextField("Title (optional)", text: $title)
                    TextField("What happened in the dream?", text: $narrative, axis: .vertical)
                        .lineLimit(4...12)
                } header: {
                    Text("The dream")
                }

                Section("Awareness") {
                    Picker("Lucidity", selection: $lucidity) {
                        ForEach(Lucidity.allCases) { Text($0.label).tag($0) }
                    }
                    Stepper(value: $vividness, in: 1...5) {
                        HStack { Text("Vividness"); Spacer(); VividnessDots(level: vividness) }
                    }
                    Picker("Mood", selection: $mood) {
                        ForEach(DreamMood.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                    Toggle("Recurring dream", isOn: $isRecurring).tint(Theme.accent)
                    Toggle("Nightmare", isOn: $isNightmare).tint(Theme.accent)
                    Picker("Technique used", selection: $technique) {
                        ForEach(DreamTechnique.allCases) { Text($0.rawValue).tag($0) }
                    }
                }

                Section {
                    if allSigns.isEmpty {
                        Text("Add a sign below to start spotting patterns.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(allSigns) { sign in
                            Button {
                                toggle(sign)
                            } label: {
                                HStack {
                                    Label(sign.name, systemImage: sign.category.symbol)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    if selectedSignIDs.contains(sign.id) {
                                        Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("New sign", text: $newSignName)
                        Picker("", selection: $newSignCategory) {
                            ForEach(SignCategory.allCases) { Image(systemName: $0.symbol).tag($0) }
                        }
                        .labelsHidden()
                        Button { addSign() } label: { Image(systemName: "plus.circle.fill") }
                            .disabled(newSignName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Dream signs")
                } footer: {
                    Text("Tag the recurring people, places and themes — your cues to recognize a dream.")
                }
            }
            .navigationTitle(isEditing ? "Edit Dream" : "New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty ||
        !narrative.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func toggle(_ sign: DreamSign) {
        Haptics.tap()
        if selectedSignIDs.contains(sign.id) { selectedSignIDs.remove(sign.id) }
        else { selectedSignIDs.insert(sign.id) }
    }

    private func addSign() {
        let name = newSignName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if let existing = allSigns.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            selectedSignIDs.insert(existing.id)
        } else {
            let sign = DreamSign(name: name, category: newSignCategory)
            context.insert(sign)
            selectedSignIDs.insert(sign.id)
        }
        newSignName = ""
        Haptics.tap()
    }

    private func load() {
        guard let d = dream else { return }
        date = d.date; title = d.title; narrative = d.narrative
        lucidity = d.lucidity; vividness = d.vividness; mood = d.mood
        isNightmare = d.isNightmare; isRecurring = d.isRecurring; technique = d.technique
        selectedSignIDs = Set(d.signs.map(\.id))
    }

    private func save() {
        guard canSave else { return }
        let d = dream ?? Dream(date: date)
        d.date = date
        d.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        d.narrative = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        d.lucidity = lucidity
        d.vividness = vividness
        d.mood = mood
        d.isNightmare = isNightmare
        d.isRecurring = isRecurring
        d.technique = technique
        if dream == nil { context.insert(d) }
        d.signs = allSigns.filter { selectedSignIDs.contains($0.id) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
