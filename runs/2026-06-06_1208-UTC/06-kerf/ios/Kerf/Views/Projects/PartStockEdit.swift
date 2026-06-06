import SwiftUI
import SwiftData

/// Add or edit a part.
struct PartEditView: View {
    let part: Part?
    var onCommit: (Part) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    @State private var label = ""
    @State private var lengthText = ""
    @State private var quantity = 1

    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }
    private var canSave: Bool { unit.parse(lengthText) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Part") {
                    TextField("Label (optional)", text: $label)
                    HStack {
                        Text("Length (\(unit.short))"); Spacer()
                        TextField("0", text: $lengthText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    Stepper(value: $quantity, in: 1...999) {
                        HStack { Text("Quantity"); Spacer(); Text("\(quantity)").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(part == nil ? "New Part" : "Edit Part").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if let p = part { label = p.label; lengthText = unit.string(p.lengthMm, withUnit: false); quantity = p.quantity }
            }
        }
    }

    private func save() {
        let target = part ?? Part(label: "", lengthMm: 0)
        target.label = label.trimmingCharacters(in: .whitespaces)
        target.lengthMm = unit.toMM(unit.parse(lengthText))
        target.quantity = max(1, quantity)
        onCommit(target); Haptics.success(); dismiss()
    }
}

/// Add or edit a stock board.
struct StockEditView: View {
    let stock: StockBoard?
    var onCommit: (StockBoard) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue

    @State private var label = ""
    @State private var lengthText = ""
    @State private var unlimited = true
    @State private var quantity = 1
    @State private var priceText = ""

    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }
    private var canSave: Bool { unit.parse(lengthText) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock board") {
                    TextField("Label (optional)", text: $label)
                    HStack {
                        Text("Length (\(unit.short))"); Spacer()
                        TextField("0", text: $lengthText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    Toggle("Unlimited supply", isOn: $unlimited.animation())
                    if !unlimited {
                        Stepper(value: $quantity, in: 1...999) {
                            HStack { Text("Available"); Spacer(); Text("\(quantity)").font(Brand.mono(15)).foregroundStyle(Brand.text2) }
                        }
                    }
                    HStack {
                        Text("Price each (optional)"); Spacer()
                        TextField("0", text: $priceText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(stock == nil ? "New Stock" : "Edit Stock").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if let s = stock {
                    label = s.label; lengthText = unit.string(s.lengthMm, withUnit: false)
                    unlimited = s.isUnlimited; quantity = max(1, s.quantity)
                    if s.pricePerBoard > 0 { priceText = String(s.pricePerBoard) }
                }
            }
        }
    }

    private func save() {
        let target = stock ?? StockBoard(label: "", lengthMm: 0)
        target.label = label.trimmingCharacters(in: .whitespaces)
        target.lengthMm = unit.toMM(unit.parse(lengthText))
        target.quantity = unlimited ? 0 : max(1, quantity)
        target.pricePerBoard = max(0, Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        onCommit(target); Haptics.success(); dismiss()
    }
}
