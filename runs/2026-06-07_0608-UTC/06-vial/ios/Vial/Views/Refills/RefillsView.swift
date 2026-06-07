import SwiftUI
import SwiftData

struct RefillsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Refill.date, order: .reverse) private var refills: [Refill]
    @Query(sort: \Medication.name) private var meds: [Medication]
    @AppStorage("vial.confirmDeletes") private var confirmDeletes = true
    @State private var refillMed: Medication?
    @State private var pendingDelete: Refill?

    private var upcoming: [Medication] {
        meds.filter { $0.isActive && $0.dailyConsumption > 0 && !$0.daysOfSupply.isInfinite }
            .sorted { $0.daysOfSupply < $1.daysOfSupply }
    }
    private var totalCost: Double { refills.map { $0.cost }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            Group {
                if meds.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "shippingbox", title: "No medications",
                                       message: "Add a medication first to track refills.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            upcomingCard
                            historyCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Refills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu { ForEach(meds) { m in Button(m.name) { refillMed = m } } }
                    label: { Image(systemName: "plus") }
                    .disabled(meds.isEmpty).accessibilityLabel("Log refill")
                }
            }
            .background(Brand.pageBackground)
            .sheet(item: $refillMed) { m in RefillEditView(med: m) }
            .confirmationDialog("Delete this refill? Supply will be reduced.", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let r = pendingDelete { delete(r) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var upcomingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Upcoming")
            if upcoming.isEmpty {
                Text("No active medications with a tracked supply.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(upcoming) { m in
                    HStack {
                        RoundedRectangle(cornerRadius: 3).fill(Color(hex: m.colorHex)).frame(width: 6, height: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            if let by = DoseEngine.refillByDate(for: m) {
                                Text("Order by \(by.formatted(.dateTime.month(.abbreviated).day()))")
                                    .font(.caption).foregroundStyle(DoseEngine.needsRefillSoon(m) ? Brand.warn : Brand.text3)
                            }
                        }
                        Spacer()
                        Text("\(Int(m.daysOfSupply.rounded(.down)))d")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(DoseEngine.needsRefillSoon(m) ? Brand.warn : Brand.text2)
                        Button { refillMed = m } label: { Image(systemName: "plus.circle").foregroundStyle(Brand.live) }
                            .accessibilityLabel("Log refill for \(m.name)")
                    }
                    .padding(.vertical, 4)
                    if m.id != upcoming.last?.id { Divider().overlay(Brand.hairline) }
                }
            }
        }
        .glassCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "History")
                Spacer()
                if totalCost > 0 { Text(String(format: "$%.0f total", totalCost)).font(Brand.mono(12)).foregroundStyle(Brand.text3) }
            }
            if refills.isEmpty {
                Text("No refills logged yet.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(refills) { r in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.medication?.name ?? "—").font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                            Text("\(r.date.formatted(.dateTime.month(.abbreviated).day().year()))\(r.pharmacy.isEmpty ? "" : " · \(r.pharmacy)")")
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("+\(Int(r.quantity))").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.live)
                            if r.cost > 0 { Text(String(format: "$%.0f", r.cost)).font(.caption2).foregroundStyle(Brand.text3) }
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(role: .destructive) {
                            if confirmDeletes { pendingDelete = r } else { delete(r) }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    if r.id != refills.last?.id { Divider().overlay(Brand.hairline) }
                }
            }
        }
        .glassCard()
    }

    private func delete(_ r: Refill) {
        if let m = r.medication { m.quantityOnHand = max(0, m.quantityOnHand - r.quantity) }
        context.delete(r); try? context.save(); Haptics.warning()
    }
}

struct RefillEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let med: Medication
    @State private var date = Date()
    @State private var quantity = 30.0
    @State private var pharmacy = ""
    @State private var cost = 0.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quantity added").foregroundStyle(Brand.text2)
                            Spacer()
                            TextField("30", value: $quantity, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).font(Brand.mono(20, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 100)
                        }
                        Divider().overlay(Brand.hairline)
                        DatePicker("Date", selection: $date, displayedComponents: .date).tint(Brand.text).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        TextField("Pharmacy (optional)", text: $pharmacy).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Cost").foregroundStyle(Brand.text2)
                            Spacer()
                            TextField("0", value: $cost, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).font(Brand.mono(15)).foregroundStyle(Brand.text).frame(width: 80)
                        }
                    }
                    .font(.subheadline).glassCard()
                    Text("Adds to \(med.name)'s supply (currently \(Int(med.quantityOnHand))).")
                        .font(.caption).foregroundStyle(Brand.text3)
                }.padding()
            }
            .navigationTitle("Log Refill")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(quantity <= 0)
                }
            }
        }
    }

    private func save() {
        let r = Refill(date: date, quantity: max(0, quantity), pharmacy: pharmacy, cost: max(0, cost), medication: med)
        context.insert(r)
        med.quantityOnHand += max(0, quantity)
        try? context.save(); Haptics.success(); dismiss()
    }
}
