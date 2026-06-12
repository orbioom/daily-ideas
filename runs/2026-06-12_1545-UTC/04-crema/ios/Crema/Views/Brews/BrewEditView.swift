import SwiftUI
import SwiftData

struct BrewEditView: View {
    let brew: Brew?
    let preselectedBean: Bean?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Bean.createdAt, order: .reverse) private var beans: [Bean]

    @State private var beanID: UUID?
    @State private var method: BrewMethod = .espresso
    @State private var date = Date()
    @State private var dose = "18"
    @State private var output = "36"
    @State private var time = "28"
    @State private var temp = "93"
    @State private var grind = ""
    @State private var ratingHalf = 0
    @State private var taste: Taste?
    @State private var notes = ""

    private var isEditing: Bool { brew != nil }
    private var selectableBeans: [Bean] { beans.filter { !$0.isArchived || $0.id == beanID } }
    private var canSave: Bool { parse(dose) > 0 && parse(output) > 0 }

    private var liveRatio: String {
        let d = parse(dose), o = parse(output)
        return d > 0 ? String(format: "1:%.1f", o / d) : "—"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Coffee") {
                    Picker("Bean", selection: $beanID) {
                        Text("None").tag(UUID?.none)
                        ForEach(selectableBeans) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                    Picker("Method", selection: $method) {
                        ForEach(BrewMethod.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section {
                    field("Dose", text: $dose, unit: "g")
                    field(method.isEspresso ? "Yield" : "Water", text: $output, unit: "g")
                    HStack {
                        Text("Ratio").foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(liveRatio).font(.headline).foregroundStyle(Theme.accent)
                    }
                    field("Time", text: $time, unit: "s")
                    field("Water temp", text: $temp, unit: "°C")
                    HStack {
                        Text("Grind setting")
                        Spacer()
                        TextField("e.g. 4.5", text: $grind).multilineTextAlignment(.trailing).frame(maxWidth: 120)
                    }
                } header: {
                    Text("Recipe")
                }
                Section("How did it taste?") {
                    Picker("Taste", selection: $taste) {
                        Text("Not rated").tag(Taste?.none)
                        ForEach(Taste.allCases) { Text($0.rawValue).tag(Taste?.some($0)) }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Rating")
                        Spacer()
                        StarRating(ratingHalf: $ratingHalf, size: 22)
                    }
                }
                Section("Notes") {
                    TextField("Anything to remember…", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Brew" : "Log Brew")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func field(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(maxWidth: 90)
            Text(unit).font(.caption).foregroundStyle(Theme.textSecondary)
        }
    }

    private func load() {
        if let b = brew {
            beanID = b.bean?.id
            method = b.method; date = b.date
            dose = trimmed(b.doseGrams); output = trimmed(b.outputGrams)
            time = trimmed(b.timeSeconds); temp = trimmed(b.waterTempC)
            grind = b.grindSetting; ratingHalf = b.ratingHalf; taste = b.taste; notes = b.notes
        } else {
            beanID = preselectedBean?.id ?? beans.first { !$0.isArchived }?.id
            if let def = BrewMethod(rawValue: UserDefaults.standard.string(forKey: "defaultMethodRaw") ?? "") {
                method = def
            }
            // Default output to a sensible ratio for the method.
            output = trimmed(18 * method.defaultRatio)
        }
    }

    private func trimmed(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(format: "%.1f", d)
    }
    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }

    private func save() {
        let newDose = parse(dose)
        guard newDose > 0, parse(output) > 0 else { return }
        let targetBean = beans.first { $0.id == beanID }

        let b = brew ?? Brew()
        // Maintain each bean's grams-used tally.
        if let old = brew {
            old.bean?.gramsUsed = max(0, (old.bean?.gramsUsed ?? 0) - old.doseGrams)
        }
        b.method = method
        b.date = date
        b.doseGrams = newDose
        b.outputGrams = parse(output)
        b.timeSeconds = parse(time)
        b.waterTempC = parse(temp)
        b.grindSetting = grind.trimmingCharacters(in: .whitespaces)
        b.ratingHalf = ratingHalf
        b.taste = taste
        b.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if brew == nil { context.insert(b) }
        b.bean = targetBean
        if let targetBean {
            if !(targetBean.brews.contains { $0.id == b.id }) { targetBean.brews.append(b) }
            targetBean.gramsUsed += newDose
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
