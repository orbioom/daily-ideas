import SwiftUI
import SwiftData

/// Generate a CO₂ or O₂ table from a max breath-hold, with a live schedule
/// preview that updates as you change the inputs.
struct TableEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var suggestedMax: Int = 180

    @State private var name = ""
    @State private var type: TableType = .co2
    @State private var maxHold = 180
    @State private var rounds = 8

    private var preview: [ApneaRound] { TableEngine.schedule(type: type, maxHold: maxHold, rounds: rounds) }
    private var total: Int { TableEngine.totalSeconds(preview) }
    private var resolvedName: String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? (type == .co2 ? "CO₂ Tolerance" : "O₂ Builder") : t
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Table")
                        TextField("Name (optional)", text: $name).textFieldStyle(.roundedBorder)
                        Picker("Type", selection: $type) {
                            ForEach(TableType.allCases) { Text("\($0.rawValue) table").tag($0) }
                        }.pickerStyle(.segmented)
                        Text(type.subtitle).font(.caption).foregroundStyle(Brand.text2)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "Your numbers")
                        HStack {
                            Text("Max breath-hold").foregroundStyle(Brand.text)
                            Spacer()
                            Text(TableEngine.clock(maxHold)).font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.text)
                        }
                        Slider(value: Binding(get: { Double(maxHold) },
                                              set: { maxHold = Int($0) }), in: 30...360, step: 5)
                            .tint(Brand.live)
                        Divider().overlay(Brand.hairline)
                        Stepper("\(rounds) rounds", value: $rounds, in: 2...12)
                            .foregroundStyle(Brand.text)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionTitle(text: "Preview")
                            Spacer()
                            Text("~\(TableEngine.clock(total))").font(Brand.mono(13, weight: .medium))
                                .foregroundStyle(Brand.text2)
                        }
                        ForEach(preview) { r in
                            HStack {
                                Text("Round \(r.index)").font(.subheadline).foregroundStyle(Brand.text2)
                                Spacer()
                                Label(TableEngine.clock(r.holdSeconds), systemImage: "lungs.fill")
                                    .font(Brand.mono(13)).foregroundStyle(Brand.text)
                                if r.restSeconds > 0 {
                                    Label(TableEngine.clock(r.restSeconds), systemImage: "wind")
                                        .font(Brand.mono(13)).foregroundStyle(Brand.text3)
                                }
                            }
                            if r.id != preview.last?.id { Divider().overlay(Brand.hairline) }
                        }
                    }.glassCard()
                }
                .padding()
            }
            .navigationTitle("New table")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Brand.text2) }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.tint(Brand.text) }
            }
            .onAppear { maxHold = min(360, max(30, suggestedMax)) }
        }
    }

    private func save() {
        let table = ApneaTable(name: resolvedName, type: type, maxHoldSeconds: maxHold, rounds: rounds)
        context.insert(table)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
