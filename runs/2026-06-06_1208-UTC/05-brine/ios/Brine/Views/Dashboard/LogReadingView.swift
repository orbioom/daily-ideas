import SwiftUI
import SwiftData

/// Log one or more parameter readings in a single test session.
struct LogReadingView: View {
    let tank: Tank
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("tempFahrenheit") private var tempF = false
    @AppStorage("salinitySG") private var salSG = false

    @State private var date = Date()
    @State private var entries: [String: String] = [:]   // parameter.rawValue -> text

    private var units: Units { Units(tempFahrenheit: tempF, salinitySG: salSG) }
    private var hasAny: Bool { entries.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }

    var body: some View {
        NavigationStack {
            Form {
                Section { DatePicker("Date", selection: $date) }
                Section {
                    ForEach(WaterParameter.allCases) { p in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.name).font(.subheadline).foregroundStyle(Brand.text)
                                Text("ideal \(Fmt.idealString(p, units)) \(Fmt.unit(p, units))")
                                    .font(.caption2).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            TextField("—", text: binding(for: p))
                                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                                .frame(width: 80).font(Brand.mono(16))
                            statusDot(for: p)
                        }
                    }
                } header: {
                    Text("Readings")
                } footer: {
                    Text("Enter only what you tested. Values are in your display units (\(Fmt.unit(.temperature, units)), \(Fmt.unit(.salinity, units))).")
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Log Test").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!hasAny).fontWeight(.semibold)
                }
            }
        }
    }

    private func binding(for p: WaterParameter) -> Binding<String> {
        Binding(get: { entries[p.rawValue] ?? "" }, set: { entries[p.rawValue] = $0 })
    }

    @ViewBuilder private func statusDot(for p: WaterParameter) -> some View {
        if let display = Double((entries[p.rawValue] ?? "").replacingOccurrences(of: ",", with: ".")) {
            let canonical = Fmt.toCanonical(p, display, units)
            Circle().fill(p.status(for: canonical).tint).frame(width: 9, height: 9)
                .accessibilityHidden(true)
        } else {
            Circle().fill(Brand.text3.opacity(0.3)).frame(width: 9, height: 9).accessibilityHidden(true)
        }
    }

    private func save() {
        for p in WaterParameter.allCases {
            let raw = (entries[p.rawValue] ?? "").replacingOccurrences(of: ",", with: ".")
            guard !raw.isEmpty, let display = Double(raw) else { continue }
            let canonical = Fmt.toCanonical(p, display, units)
            let r = Reading(parameter: p, value: canonical, date: date)
            r.tank = tank
            tank.readings.append(r)
            context.insert(r)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
