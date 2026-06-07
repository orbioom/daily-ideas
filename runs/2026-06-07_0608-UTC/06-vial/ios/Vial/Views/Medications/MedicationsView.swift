import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Medication.name) private var meds: [Medication]
    @AppStorage("vial.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Medication?

    var body: some View {
        NavigationStack {
            Group {
                if meds.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "pills", title: "No medications",
                                       message: "Add a medication with its schedule and supply to start tracking.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(meds) { med in
                                NavigationLink { MedDetailView(med: med) } label: { MedRow(med: med) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = med } else { delete(med) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add medication")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { MedEditView(existing: nil) }
            .confirmationDialog("Delete this medication and its history?", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let m = pendingDelete { delete(m) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ m: Medication) { context.delete(m); try? context.save(); Haptics.warning() }
}

struct MedRow: View {
    let med: Medication
    private var refillSoon: Bool { DoseEngine.needsRefillSoon(med) }
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: med.colorHex)).frame(width: 6, height: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(med.name).font(.headline).foregroundStyle(Brand.text)
                    if !med.isActive { Badge(text: "Paused") }
                }
                Text("\(med.strength.isEmpty ? med.form : med.strength) · \(med.doseTimes.count)×/day")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(supplyText).font(Brand.mono(14, weight: .semibold))
                    .foregroundStyle(refillSoon ? Brand.warn : Brand.text2)
                if refillSoon { Badge(text: "Refill soon", color: Brand.warn) }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(med.name), \(supplyText)\(refillSoon ? ", refill soon" : "")")
    }

    private var supplyText: String {
        if med.dailyConsumption <= 0 { return "\(Int(med.quantityOnHand)) left" }
        let days = med.daysOfSupply
        if days.isInfinite { return "\(Int(med.quantityOnHand)) left" }
        return "\(Int(days.rounded(.down))) days"
    }
}
