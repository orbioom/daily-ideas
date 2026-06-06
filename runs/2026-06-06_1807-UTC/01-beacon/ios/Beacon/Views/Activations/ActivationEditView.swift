import SwiftUI
import SwiftData

struct ActivationEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("myGrid") private var myGrid = ""
    let activation: Activation?

    @State private var title = ""
    @State private var reference = ""
    @State private var kind = ActivationKind.pota
    @State private var grid = ""
    @State private var date = Date.now
    @State private var notes = ""

    private var titleValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    private var gridValid: Bool { grid.isEmpty || GridMath.normalize(grid) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Outing") {
                    TextField("Title (e.g. Acadia NP)", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(ActivationKind.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) }
                    }
                    TextField(referencePrompt, text: $reference)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().font(Brand.mono(16))
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section {
                    TextField("Grid (e.g. FN54)", text: $grid)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().font(Brand.mono(16))
                    if !gridValid {
                        Text("Invalid Maidenhead locator.").font(.caption).foregroundStyle(Brand.danger)
                    }
                } header: { Text("Your location") } footer: {
                    Text("Used as the reference point for distance and bearing to your contacts.")
                }
                Section("Notes") {
                    TextField("Conditions, gear, antenna…", text: $notes, axis: .vertical).lineLimit(2...6)
                }
                if kind.qsoTarget > 0 {
                    Section {
                        Text("\(kind.rawValue) needs \(kind.qsoTarget) valid contacts to count as an activation.")
                            .font(.footnote).foregroundStyle(Brand.text2)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(activation == nil ? "New Outing" : "Edit Outing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!titleValid || !gridValid) }
            }
            .onAppear(perform: load)
        }
    }

    private var referencePrompt: String {
        switch kind {
        case .pota: return "Park ref (e.g. US-0001)"
        case .sota: return "Summit ref (e.g. W1/HA-001)"
        case .contest: return "Contest name"
        default: return "Reference (optional)"
        }
    }

    private func load() {
        if let a = activation {
            title = a.title; reference = a.reference; kind = a.kind
            grid = a.grid; date = a.date; notes = a.notes
        } else {
            grid = myGrid
        }
    }

    private func save() {
        let g = GridMath.normalize(grid) ?? grid.uppercased()
        if let a = activation {
            a.title = title; a.reference = reference; a.kind = kind
            a.grid = g; a.date = date; a.notes = notes
        } else {
            context.insert(Activation(reference: reference, title: title, kind: kind, grid: g, date: date, notes: notes))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
