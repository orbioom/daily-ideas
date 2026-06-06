import SwiftUI
import SwiftData

/// Create or edit a contact. Passing `qso == nil` creates a new one.
struct QSOEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Activation.date, order: .reverse) private var activations: [Activation]
    @AppStorage("defaultBand") private var defaultBandRaw = Band.m20.rawValue
    @AppStorage("defaultMode") private var defaultModeRaw = Mode.ssb.rawValue

    let qso: QSO?
    var presetActivation: Activation? = nil

    @State private var callsign = ""
    @State private var date = Date.now
    @State private var band = Band.m20
    @State private var mode = Mode.ssb
    @State private var freq = ""
    @State private var rstSent = ""
    @State private var rstRcvd = ""
    @State private var theirGrid = ""
    @State private var theirName = ""
    @State private var theirQTH = ""
    @State private var confirmed = false
    @State private var notes = ""
    @State private var activation: Activation?

    private var callValid: Bool {
        let t = callsign.trimmingCharacters(in: .whitespaces)
        return t.count >= 3 && t.rangeOfCharacter(from: CharacterSet.alphanumerics.union(.init(charactersIn: "/"))
            .inverted) == nil
    }
    private var gridValid: Bool { theirGrid.isEmpty || GridMath.normalize(theirGrid) != nil }
    private var freqValid: Bool { freq.isEmpty || Double(freq) != nil }
    private var canSave: Bool { callValid && gridValid && freqValid }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Callsign", text: $callsign)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(Brand.mono(17))
                    if !callsign.isEmpty && !callValid {
                        Text("Enter a valid callsign.").font(.caption).foregroundStyle(Brand.danger)
                    }
                    DatePicker("Date & time", selection: $date)
                }
                Section("Radio") {
                    Picker("Band", selection: $band) {
                        ForEach(Band.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    HStack {
                        Text("Frequency")
                        Spacer()
                        TextField("\(band.centerMHz, specifier: "%.3f")", text: $freq)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .font(Brand.mono(16)).frame(width: 120)
                        Text("MHz").foregroundStyle(Brand.text3)
                    }
                    if !freqValid {
                        Text("Frequency must be a number.").font(.caption).foregroundStyle(Brand.danger)
                    }
                    HStack {
                        labeledField("RST sent", text: $rstSent, placeholder: mode.defaultReport)
                        labeledField("RST rcvd", text: $rstRcvd, placeholder: mode.defaultReport)
                    }
                }
                Section("Their details") {
                    TextField("Grid (e.g. FN31)", text: $theirGrid)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled().font(Brand.mono(16))
                    if !gridValid {
                        Text("Invalid Maidenhead locator.").font(.caption).foregroundStyle(Brand.danger)
                    }
                    TextField("Name", text: $theirName)
                    TextField("QTH (location)", text: $theirQTH)
                }
                Section("Outing") {
                    Picker("Group", selection: $activation) {
                        Text("None").tag(Activation?.none)
                        ForEach(activations) { a in Text(a.title).tag(Activation?.some(a)) }
                    }
                }
                Section("Log") {
                    Toggle("Confirmed (QSL)", isOn: $confirmed)
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(qso == nil ? "New Contact" : "Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
            .onChange(of: mode) { _, m in
                if rstSent.isEmpty { rstSent = m.defaultReport }
                if rstRcvd.isEmpty { rstRcvd = m.defaultReport }
            }
        }
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Brand.text3)
            TextField(placeholder, text: text).font(Brand.mono(16))
        }
    }

    private func load() {
        if let qso {
            callsign = qso.callsign; date = qso.dateTime; band = qso.band; mode = qso.mode
            freq = String(format: "%.3f", qso.freqMHz)
            rstSent = qso.rstSent; rstRcvd = qso.rstRcvd
            theirGrid = qso.theirGrid; theirName = qso.theirName; theirQTH = qso.theirQTH
            confirmed = qso.confirmed; notes = qso.notes; activation = qso.activation
        } else {
            band = Band(rawValue: defaultBandRaw) ?? .m20
            mode = Mode(rawValue: defaultModeRaw) ?? .ssb
            rstSent = mode.defaultReport; rstRcvd = mode.defaultReport
            activation = presetActivation
        }
    }

    private func save() {
        let f = Double(freq) ?? band.centerMHz
        let grid = GridMath.normalize(theirGrid) ?? theirGrid.uppercased()
        if let qso {
            qso.callsign = callsign.uppercased(); qso.dateTime = date
            qso.band = band; qso.mode = mode; qso.freqMHz = f
            qso.rstSent = rstSent.isEmpty ? mode.defaultReport : rstSent
            qso.rstRcvd = rstRcvd.isEmpty ? mode.defaultReport : rstRcvd
            qso.theirGrid = grid; qso.theirName = theirName; qso.theirQTH = theirQTH
            qso.confirmed = confirmed; qso.notes = notes; qso.activation = activation
        } else {
            let new = QSO(callsign: callsign, dateTime: date, band: band, mode: mode, freqMHz: f,
                          rstSent: rstSent, rstRcvd: rstRcvd, theirGrid: grid,
                          theirName: theirName, theirQTH: theirQTH, confirmed: confirmed,
                          notes: notes, activation: activation)
            context.insert(new)
            activation?.qsos.append(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
