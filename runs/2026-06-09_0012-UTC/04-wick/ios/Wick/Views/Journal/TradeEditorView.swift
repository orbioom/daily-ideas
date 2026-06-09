import SwiftUI
import SwiftData

struct TradeEditorView: View {
    var trade: Trade?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("wick.symbol") private var symbol = "$"

    @State private var symbolText = ""
    @State private var asset: AssetType = .stock
    @State private var direction: Direction = .long
    @State private var strategy: Strategy = .breakout
    @State private var entryDate = Date()
    @State private var entryText = ""
    @State private var qtyText = ""
    @State private var feesText = ""
    @State private var isClosed = false
    @State private var exitDate = Date()
    @State private var exitText = ""
    @State private var useStop = false
    @State private var stopText = ""
    @State private var useTarget = false
    @State private var targetText = ""
    @State private var discipline = 0
    @State private var notes = ""
    @State private var loaded = false

    private func num(_ s: String) -> Double? {
        let v = Double(s.replacingOccurrences(of: ",", with: ""))
        return (v ?? -1) > 0 ? v : nil
    }
    private var canSave: Bool {
        !symbolText.trimmingCharacters(in: .whitespaces).isEmpty &&
        num(entryText) != nil && num(qtyText) != nil &&
        (!isClosed || num(exitText) != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Instrument") {
                    TextField("Symbol (e.g. AAPL)", text: $symbolText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Picker("Asset", selection: $asset) {
                        ForEach(AssetType.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Direction", selection: $direction) {
                        ForEach(Direction.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Strategy", selection: $strategy) {
                        ForEach(Strategy.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("Entry") {
                    DatePicker("Date", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                    field("Entry price", text: $entryText, prefix: symbol)
                    field("Quantity", text: $qtyText, prefix: nil)
                    field("Fees", text: $feesText, prefix: symbol)
                }
                Section("Exit") {
                    Toggle("Trade is closed", isOn: $isClosed.animation())
                    if isClosed {
                        DatePicker("Exit date", selection: $exitDate, displayedComponents: [.date, .hourAndMinute])
                        field("Exit price", text: $exitText, prefix: symbol)
                    } else {
                        Text("Leave off to keep the position open. You can close it later.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Section("Risk plan (optional)") {
                    Toggle("Stop loss", isOn: $useStop.animation())
                    if useStop { field("Stop price", text: $stopText, prefix: symbol) }
                    Toggle("Target", isOn: $useTarget.animation())
                    if useTarget { field("Target price", text: $targetText, prefix: symbol) }
                }
                Section("Review") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discipline").font(.subheadline).foregroundStyle(Brand.text2)
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= discipline ? "circle.fill" : "circle")
                                    .font(.title3).foregroundStyle(i <= discipline ? strategy.tint : Brand.text3)
                                    .onTapGesture { Haptics.selection(); discipline = (discipline == i) ? 0 : i }
                            }
                        }
                        .accessibilityLabel("Discipline rating")
                        .accessibilityValue("\(discipline) of 5")
                    }
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .navigationTitle(trade == nil ? "New trade" : "Edit trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func field(_ label: String, text: Binding<String>, prefix: String?) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            if let prefix { Text(prefix).foregroundStyle(Brand.text3) }
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Brand.mono(15))
                .frame(maxWidth: 130)
        }
    }

    private func load() {
        guard let trade, !loaded else { return }
        loaded = true
        symbolText = trade.symbol; asset = trade.assetType; direction = trade.direction
        strategy = trade.strategy; entryDate = trade.entryDate
        entryText = String(trade.entryPrice); qtyText = String(trade.quantity)
        feesText = trade.fees > 0 ? String(trade.fees) : ""
        if let ex = trade.exitPrice, let exd = trade.exitDate {
            isClosed = true; exitText = String(ex); exitDate = exd
        }
        if let stop = trade.stopPrice { useStop = true; stopText = String(stop) }
        if let target = trade.targetPrice { useTarget = true; targetText = String(target) }
        discipline = trade.discipline; notes = trade.notes
    }

    private func save() {
        guard let entry = num(entryText), let qty = num(qtyText) else { return }
        let fees = Double(feesText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let exitP = isClosed ? num(exitText) : nil
        let exitD = isClosed ? exitDate : nil
        let stop = useStop ? num(stopText) : nil
        let target = useTarget ? num(targetText) : nil
        let sym = symbolText.trimmingCharacters(in: .whitespaces).uppercased()

        if let trade {
            trade.symbol = sym; trade.assetType = asset; trade.direction = direction
            trade.strategy = strategy; trade.entryDate = entryDate; trade.entryPrice = entry
            trade.quantity = qty; trade.fees = max(0, fees)
            trade.exitPrice = exitP; trade.exitDate = exitD
            trade.stopPrice = stop; trade.targetPrice = target
            trade.discipline = discipline; trade.notes = notes
        } else {
            let new = Trade(symbol: sym, assetType: asset, direction: direction, strategy: strategy,
                            entryDate: entryDate, entryPrice: entry, quantity: qty, fees: max(0, fees),
                            exitDate: exitD, exitPrice: exitP, stopPrice: stop, targetPrice: target,
                            discipline: discipline, notes: notes)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
