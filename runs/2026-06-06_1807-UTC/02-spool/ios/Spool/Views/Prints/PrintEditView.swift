import SwiftUI
import SwiftData

struct PrintEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Spool.purchaseDate, order: .reverse) private var spools: [Spool]
    @Query(sort: \Printer.name) private var printers: [Printer]
    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("kwhRate") private var kwhRate = 0.15

    let job: PrintJob?

    @State private var name = ""
    @State private var date = Date.now
    @State private var grams = ""
    @State private var hours = ""
    @State private var minutes = ""
    @State private var success = true
    @State private var notes = ""
    @State private var spool: Spool?
    @State private var printer: Printer?
    /// Grams already deducted by this job (so editing re-balances the spool).
    @State private var originalGrams: Double = 0
    @State private var originalSpoolID: PersistentIdentifier?

    private var nameValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var gramsValue: Double { Double(grams) ?? 0 }
    private var gramsValid: Bool { gramsValue > 0 }
    private var durationMin: Int { (Int(hours) ?? 0) * 60 + (Int(minutes) ?? 0) }
    private var canSave: Bool { nameValid && gramsValid }

    private var estCost: Double {
        let filament = (spool?.pricePerGram ?? 0) * gramsValue
        let elec = printer.map { ($0.watts / 1000.0) * (Double(durationMin) / 60.0) * kwhRate } ?? 0
        return filament + elec
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Print") {
                    TextField("Name (e.g. Phone stand)", text: $name)
                    DatePicker("Date", selection: $date)
                    Toggle("Successful", isOn: $success)
                }
                Section("Filament") {
                    Picker("Spool", selection: $spool) {
                        Text("None").tag(Spool?.none)
                        ForEach(spools.filter { !$0.archived || $0 == spool }) { s in
                            Text(s.displayName).tag(Spool?.some(s))
                        }
                    }
                    HStack {
                        Text("Grams used")
                        Spacer()
                        TextField("0", text: $grams).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 80)
                        Text("g").foregroundStyle(Brand.text3)
                    }
                    if let s = spool, gramsValue > s.remainingG + originalGramsForSpool(s) {
                        Text("Only \(Int(s.remainingG + originalGramsForSpool(s))) g left on this spool.")
                            .font(.caption).foregroundStyle(Brand.warn)
                    }
                }
                Section("Printer & time") {
                    Picker("Printer", selection: $printer) {
                        Text("None").tag(Printer?.none)
                        ForEach(printers) { p in Text(p.name).tag(Printer?.some(p)) }
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", text: $hours).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 44)
                        Text("h").foregroundStyle(Brand.text3)
                        TextField("0", text: $minutes).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 44)
                        Text("m").foregroundStyle(Brand.text3)
                    }
                }
                Section {
                    HStack {
                        Text("Estimated cost").font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text(Money.string(estCost, symbol: currency))
                            .font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.text)
                    }
                } footer: {
                    Text("Filament cost from the spool's price-per-gram, plus electricity from the printer's wattage at your \(Money.string(kwhRate, symbol: currency))/kWh rate.")
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4) }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(job == nil ? "Log Print" : "Edit Print")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    /// If editing and the spool is unchanged, the original grams are "credited back" for headroom math.
    private func originalGramsForSpool(_ s: Spool) -> Double {
        s.persistentModelID == originalSpoolID ? originalGrams : 0
    }

    private func load() {
        guard let j = job else { return }
        name = j.name; date = j.date; grams = String(Int(j.gramsUsed))
        hours = String(j.durationMinutes / 60); minutes = String(j.durationMinutes % 60)
        success = j.success; notes = j.notes; spool = j.spool; printer = j.printer
        originalGrams = j.gramsUsed; originalSpoolID = j.spool?.persistentModelID
    }

    private func save() {
        let g = gramsValue
        // Re-credit prior deduction to the original spool, then deduct from the chosen spool.
        if let oldID = originalSpoolID, let old = spools.first(where: { $0.persistentModelID == oldID }) {
            old.remainingG = min(old.netWeightG, old.remainingG + originalGrams)
        }
        if let s = spool {
            s.remainingG = max(0, s.remainingG - g)
        }
        if let j = job {
            j.name = name; j.date = date; j.gramsUsed = g; j.durationMinutes = durationMin
            j.success = success; j.notes = notes; j.spool = spool; j.printer = printer
        } else {
            context.insert(PrintJob(name: name, date: date, gramsUsed: g, durationMinutes: durationMin,
                                    success: success, notes: notes, spool: spool, printer: printer))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
