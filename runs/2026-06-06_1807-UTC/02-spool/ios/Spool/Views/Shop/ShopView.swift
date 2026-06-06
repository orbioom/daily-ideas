import SwiftUI
import SwiftData

/// Printers management plus a filament grams↔length calculator.
struct ShopView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Printer.name) private var printers: [Printer]
    @State private var showAddPrinter = false
    @State private var editingPrinter: Printer?

    // Calculator state
    @State private var calcMaterial = Material.pla
    @State private var calcDiameter = Diameter.mm175
    @State private var calcGrams = "100"
    @State private var calcMode = 0   // 0: grams->length, 1: length->grams
    @State private var calcMeters = "30"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    calculatorCard
                    HStack {
                        SectionHeader(title: "Printers")
                        Spacer()
                        Button { Haptics.tap(); showAddPrinter = true } label: {
                            Label("Add", systemImage: "plus.circle").font(.subheadline)
                        }
                    }
                    if printers.isEmpty {
                        Text("Add a printer to compute electricity cost per print.")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                    } else {
                        ForEach(printers) { p in
                            Button { editingPrinter = p } label: { printerRow(p) }.buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Shop")
            .sheet(isPresented: $showAddPrinter) { PrinterEditView(printer: nil) }
            .sheet(item: $editingPrinter) { PrinterEditView(printer: $0) }
        }
    }

    private var calculatorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Filament calculator")
            Picker("Direction", selection: $calcMode) {
                Text("Grams → length").tag(0)
                Text("Length → grams").tag(1)
            }
            .pickerStyle(.segmented)
            Picker("Material", selection: $calcMaterial) {
                ForEach(Material.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Diameter", selection: $calcDiameter) {
                ForEach(Diameter.allCases) { Text($0.label).tag($0) }
            }
            if calcMode == 0 {
                inputRow(label: "Grams", text: $calcGrams, unit: "g")
                resultRow(label: "Length", value: String(format: "%.1f m",
                    CostMath.lengthMeters(grams: Double(calcGrams) ?? 0, material: calcMaterial, diameter: calcDiameter)))
            } else {
                inputRow(label: "Length", text: $calcMeters, unit: "m")
                resultRow(label: "Mass", value: String(format: "%.0f g",
                    CostMath.grams(meters: Double(calcMeters) ?? 0, material: calcMaterial, diameter: calcDiameter)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private func inputRow(label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            TextField("0", text: text).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).font(Brand.mono(18)).frame(width: 100)
            Text(unit).foregroundStyle(Brand.text3)
        }
    }
    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
            Spacer()
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.magic)
        }
        .padding(.top, 4)
    }

    private func printerRow(_ p: Printer) -> some View {
        HStack {
            Image(systemName: "printer").font(.title3).foregroundStyle(Brand.text)
                .frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(p.name).font(.headline).foregroundStyle(Brand.text)
                if !p.model.isEmpty { Text(p.model).font(.subheadline).foregroundStyle(Brand.text2) }
            }
            Spacer()
            Text("\(Int(p.watts)) W").font(Brand.mono(14)).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }
}
