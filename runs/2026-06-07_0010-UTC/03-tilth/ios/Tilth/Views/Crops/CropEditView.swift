import SwiftUI
import SwiftData

struct CropEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var crop: Crop?

    @State private var name = ""
    @State private var category: CropCategory = .leafy
    @State private var method: SowMethod = .directSow
    @State private var daysToMaturity = 50
    @State private var startIndoorWeeks = 6
    @State private var transplantWeeks = 1
    @State private var directSowWeeks = 0
    @State private var successionDays = 0
    @State private var tolerance: FrostTolerance = .tender
    @State private var spacing = 6
    @State private var notes = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Identity") {
                        TextField("Name", text: $name)
                        Picker("Category", selection: $category) {
                            ForEach(CropCategory.allCases) { c in Text(c.label).tag(c) }
                        }
                        Picker("Frost tolerance", selection: $tolerance) {
                            ForEach(FrostTolerance.allCases) { t in Text(t.label).tag(t) }
                        }
                    }.listRowBackground(Color.clear)

                    Section("Timing") {
                        Picker("Method", selection: $method) {
                            ForEach(SowMethod.allCases) { m in Text(m.label).tag(m) }
                        }
                        Stepper("Days to maturity: \(daysToMaturity)", value: $daysToMaturity, in: 14...200, step: 1)
                        if method == .transplant {
                            Stepper("Start indoors: \(startIndoorWeeks) wk before",
                                    value: $startIndoorWeeks, in: 0...16)
                            Stepper("Transplant: \(weekLabel(transplantWeeks))",
                                    value: $transplantWeeks, in: -6...8)
                        } else {
                            Stepper("Sow: \(weekLabel(directSowWeeks))",
                                    value: $directSowWeeks, in: -8...8)
                        }
                        Stepper(successionDays == 0 ? "No succession" : "Succession: every \(successionDays)d",
                                value: $successionDays, in: 0...60, step: 7)
                    }.listRowBackground(Color.clear)

                    Section("Spacing") {
                        Stepper("\(spacing)\" between plants", value: $spacing, in: 1...48)
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(crop == nil ? "New crop" : "Edit crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func weekLabel(_ w: Int) -> String {
        if w == 0 { return "at last frost" }
        return w < 0 ? "\(-w) wk before" : "\(w) wk after"
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let c = crop else { return }
        name = c.name; category = c.category; method = c.method
        daysToMaturity = c.daysToMaturity; startIndoorWeeks = c.startIndoorWeeksBefore
        transplantWeeks = c.transplantWeeksAfterFrost; directSowWeeks = c.directSowWeeksAfterFrost
        successionDays = c.successionIntervalDays; tolerance = c.tolerance
        spacing = c.spacingInches; notes = c.notes
    }

    private func save() {
        if let c = crop {
            c.name = name; c.categoryRaw = category.rawValue; c.methodRaw = method.rawValue
            c.daysToMaturity = daysToMaturity; c.startIndoorWeeksBefore = startIndoorWeeks
            c.transplantWeeksAfterFrost = transplantWeeks; c.directSowWeeksAfterFrost = directSowWeeks
            c.successionIntervalDays = successionDays; c.toleranceRaw = tolerance.rawValue
            c.spacingInches = spacing; c.notes = notes
        } else {
            let c = Crop(name: name, category: category, method: method,
                         daysToMaturity: daysToMaturity, startIndoorWeeksBefore: startIndoorWeeks,
                         transplantWeeksAfterFrost: transplantWeeks,
                         directSowWeeksAfterFrost: directSowWeeks,
                         successionIntervalDays: successionDays, tolerance: tolerance,
                         spacingInches: spacing, notes: notes)
            context.insert(c)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
