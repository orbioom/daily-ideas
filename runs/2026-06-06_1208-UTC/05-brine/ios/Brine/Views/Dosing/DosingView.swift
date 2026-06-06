import SwiftUI
import SwiftData

/// The dosing log: what supplement, how much, when.
struct DosingView: View {
    @Bindable var tank: Tank
    @Environment(\.modelContext) private var context
    @State private var adding = false

    private var doses: [DoseEntry] { tank.doses.sorted { $0.date > $1.date } }
    private var last7Count: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        return tank.doses.filter { $0.date >= cutoff }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if doses.isEmpty {
                        EmptyStateView(icon: "eyedropper", title: "No doses logged",
                                       message: "Record what you add to the tank to keep a clean dosing history.")
                    } else { list }
                }
            }
            .navigationTitle("Dosing")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Log dose")
                }
            }
            .sheet(isPresented: $adding) { DoseEditView(tank: tank) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack(spacing: 10) {
                    StatTile(value: "\(tank.doses.count)", label: "Total doses")
                    StatTile(value: "\(last7Count)", label: "Last 7 days", tint: Brand.live)
                }
                ForEach(doses) { dose in
                    HStack(spacing: 14) {
                        Image(systemName: "drop.fill").foregroundStyle(Brand.info)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dose.supplement).font(.headline).foregroundStyle(Brand.text)
                            Text(dose.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(Brand.text3)
                            if !dose.note.isEmpty { Text(dose.note).font(.caption).foregroundStyle(Brand.text3) }
                        }
                        Spacer()
                        Text(String(format: "%.1f mL", dose.amountMl))
                            .font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.text)
                    }
                    .glassCard()
                    .contextMenu {
                        Button(role: .destructive) { delete(dose) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func delete(_ d: DoseEntry) { context.delete(d); try? context.save(); Haptics.warning() }
}

/// Add a dose.
struct DoseEditView: View {
    let tank: Tank
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var supplement = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""

    private let common = ["Alk (Part 1)", "Calcium (Part 2)", "Magnesium", "Trace", "Phyto", "Amino acids"]
    private var canSave: Bool {
        !supplement.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement") {
                    TextField("Name", text: $supplement)
                    if supplement.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(common, id: \.self) { name in
                                    Button { supplement = name } label: { Pill(text: name) }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                Section("Dose") {
                    HStack {
                        Text("Amount (mL)"); Spacer()
                        TextField("0", text: $amountText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    DatePicker("When", selection: $date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle("Log Dose").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let dose = DoseEntry(supplement: supplement.trimmingCharacters(in: .whitespaces),
                             amountMl: max(0, Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0),
                             date: date)
        dose.note = note.trimmingCharacters(in: .whitespaces)
        dose.tank = tank
        tank.doses.append(dose)
        context.insert(dose)
        try? context.save(); Haptics.success(); dismiss()
    }
}
