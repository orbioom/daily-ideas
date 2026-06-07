import SwiftUI
import SwiftData

/// The Instruments tab: a list of saved instruments with their total neck
/// tension, plus full create / edit / delete.
struct InstrumentsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Instrument.createdAt, order: .reverse) private var instruments: [Instrument]
    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue

    @State private var newInstrument: Instrument?
    @State private var pendingDelete: Instrument?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Instruments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addInstrument()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add instrument")
                }
            }
            .navigationDestination(for: Instrument.self) { instrument in
                InstrumentDetailView(instrument: instrument)
            }
            .sheet(item: $newInstrument) { instrument in
                InstrumentEditSheet(instrument: instrument, isNew: true) {
                    context.delete(instrument)
                }
            }
            .confirmationDialog("Delete this instrument?",
                                isPresented: deleteBinding,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This removes the instrument and all of its strings.")
            }
        }
    }

    @ViewBuilder private var content: some View {
        if instruments.isEmpty {
            EmptyStateView(icon: "guitars",
                           title: "No instruments yet",
                           message: "Add a guitar or bass to start computing string tension.")
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(instruments) { instrument in
                        NavigationLink(value: instrument) {
                            InstrumentRow(instrument: instrument, unit: unit)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                pendingDelete = instrument
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } })
    }

    private func addInstrument() {
        Haptics.tap()
        let instrument = Instrument(name: "New Instrument", type: .electricGuitar)
        // Start with a standard E set so the new instrument isn't empty.
        StringSets.apply(set: StringSets.sets[1], to: instrument)
        StringSets.apply(tuning: StringSets.tunings[0], to: instrument)
        context.insert(instrument)
        newInstrument = instrument
    }

    private func confirmDelete() {
        guard let target = pendingDelete else { return }
        Haptics.warning()
        context.delete(target)
        pendingDelete = nil
    }
}

/// One row in the instruments list.
private struct InstrumentRow: View {
    let instrument: Instrument
    let unit: WeightUnit

    var body: some View {
        let summary = TensionEngine.summary(for: instrument)
        HStack(spacing: 14) {
            Image(systemName: instrument.type.symbol)
                .font(.title2)
                .foregroundStyle(Brand.text2)
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(instrument.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    Text(instrument.type.label)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                    Text(String(format: "%.2f\"", instrument.scaleLengthIn))
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(unit.format(fromLb: summary.totalLb, decimals: 1))
                    .font(Brand.mono(15, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("total")
                    .font(Brand.mono(9))
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(instrument.name), \(instrument.type.label), total tension \(unit.format(fromLb: summary.totalLb))")
    }
}
