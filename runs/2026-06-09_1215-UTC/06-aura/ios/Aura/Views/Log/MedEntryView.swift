import SwiftUI

/// A sheet to add one medication dose to an attack. Name comes from the catalog
/// (prefilling dose & acute/preventive) or is typed as a custom entry.
struct MedEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let catalog: [Medication]
    let onAdd: (DraftMed) -> Void

    @State private var useCatalog = true
    @State private var selectedName = ""
    @State private var customName = ""
    @State private var doseMg = 0.0
    @State private var minutesAfterOnset = 30
    @State private var relief: Relief = .some
    @State private var isAcute = true

    private var resolvedName: String {
        useCatalog ? selectedName : customName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool { !resolvedName.isEmpty && doseMg >= 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication") {
                    if !catalog.isEmpty {
                        Picker("Source", selection: $useCatalog) {
                            Text("From catalog").tag(true)
                            Text("Custom").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                    if useCatalog && !catalog.isEmpty {
                        Picker("Medication", selection: $selectedName) {
                            ForEach(catalog) { med in
                                Text("\(med.name) · \(med.type.label)").tag(med.name)
                            }
                        }
                        .onChange(of: selectedName) { _, new in
                            if let med = catalog.first(where: { $0.name == new }) {
                                doseMg = med.defaultDoseMg
                                isAcute = med.type == .acute
                            }
                        }
                    } else {
                        TextField("Name", text: $customName)
                        Toggle("Acute (abortive)", isOn: $isAcute)
                    }
                }

                Section("Dose & timing") {
                    HStack {
                        Text("Dose")
                        Spacer()
                        TextField("mg", value: $doseMg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text("mg").foregroundStyle(Brand.text3)
                    }
                    Stepper("Minutes after onset: \(minutesAfterOnset)",
                            value: $minutesAfterOnset, in: 0...720, step: 5)
                }

                Section("Relief") {
                    Picker("Relief", selection: $relief) {
                        ForEach(Relief.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(DraftMed(name: resolvedName,
                                       doseMg: max(0, doseMg),
                                       minutesAfterOnset: max(0, minutesAfterOnset),
                                       relief: relief,
                                       isAcute: isAcute))
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if useCatalog, selectedName.isEmpty, let first = catalog.first {
                    selectedName = first.name
                    doseMg = first.defaultDoseMg
                    isAcute = first.type == .acute
                }
            }
        }
    }
}
