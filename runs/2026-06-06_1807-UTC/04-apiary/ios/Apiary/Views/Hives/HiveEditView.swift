import SwiftUI
import SwiftData

struct HiveEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Apiary.createdAt) private var apiaries: [Apiary]
    let hive: Hive?
    var presetApiary: Apiary? = nil

    @State private var name = ""
    @State private var kind = HiveKind.langstroth
    @State private var status = HiveStatus.active
    @State private var established = Date.now
    @State private var queenYear = Calendar.current.component(.year, from: .now)
    @State private var queenMarked = true
    @State private var notes = ""
    @State private var apiary: Apiary?

    private var valid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && apiary != nil }
    private let years: [Int] = {
        let y = Calendar.current.component(.year, from: .now)
        return Array((y - 6)...(y + 1)).reversed()
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Hive") {
                    TextField("Name (e.g. Amber)", text: $name)
                    Picker("Apiary", selection: $apiary) {
                        Text("Select…").tag(Apiary?.none)
                        ForEach(apiaries) { a in Text(a.name).tag(Apiary?.some(a)) }
                    }
                    Picker("Type", selection: $kind) {
                        ForEach(HiveKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(HiveStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    DatePicker("Established", selection: $established, displayedComponents: .date)
                }
                Section("Queen") {
                    Picker("Queen year", selection: $queenYear) {
                        ForEach(years, id: \.self) { y in
                            HStack { Text(String(y)); QueenDot(year: y, size: 12) }.tag(y)
                        }
                    }
                    HStack {
                        Text("Marking color")
                        Spacer()
                        QueenDot(year: queenYear, size: 16)
                        Text(BeeLogic.queenColorName(year: queenYear)).foregroundStyle(Brand.text2)
                    }
                    Toggle("Queen is marked", isOn: $queenMarked)
                }
                Section("Notes") {
                    TextField("Genetics, source, temperament…", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(hive == nil ? "New Hive" : "Edit Hive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let h = hive {
            name = h.name; kind = h.kind; status = h.status; established = h.establishedDate
            queenYear = h.queenYear; queenMarked = h.queenMarked; notes = h.notes; apiary = h.apiary
        } else {
            apiary = presetApiary ?? apiaries.first
        }
    }
    private func save() {
        if let h = hive {
            h.name = name; h.kind = kind; h.status = status; h.establishedDate = established
            h.queenYear = queenYear; h.queenMarked = queenMarked; h.notes = notes; h.apiary = apiary
        } else {
            let new = Hive(name: name, kind: kind, status: status, establishedDate: established,
                           queenYear: queenYear, queenMarked: queenMarked, notes: notes, apiary: apiary)
            context.insert(new)
            apiary?.hives.append(new)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
