import SwiftUI

struct SessionDetailView: View {
    @Bindable var session: ChargingSession
    let currencySymbol: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Charge") {
                    row("kWh Added", value: String(format: "%.2f kWh", session.kwhAdded), icon: "bolt.fill")
                    row("Cost", value: "\(currencySymbol)\(String(format: "%.2f", session.cost))", icon: "creditcard")
                    row("Rate", value: "\(currencySymbol)\(String(format: "%.3f", session.costPerKWh))/kWh", icon: "tag")
                    if session.durationMinutes > 0 {
                        row("Duration", value: String(format: "%.0f min", session.durationMinutes), icon: "clock")
                    }
                }
                Section("State of Charge") {
                    if session.startSoC > 0 || session.endSoC > 0 {
                        row("Start SoC", value: "\(Int(session.startSoC))%", icon: "battery.0percent")
                        row("End SoC", value: "\(Int(session.endSoC))%", icon: "battery.100percent")
                        row("Added", value: "+\(Int(session.chargeAdded))%", icon: "arrow.up")
                    }
                }
                Section("Details") {
                    row("Charger Type", value: session.chargerType.rawValue, icon: session.chargerType.icon)
                    row("Speed", value: session.chargerType.speedLabel, icon: "speedometer")
                    if !session.locationName.isEmpty {
                        row("Location", value: session.locationName, icon: "mappin")
                    }
                    if session.odometer > 0 {
                        row("Odometer", value: String(format: "%.0f mi", session.odometer), icon: "gauge.with.dots.needle.50percent")
                    }
                    if let v = session.vehicle {
                        row("Vehicle", value: v.displayName, icon: "car.fill")
                    }
                }
                if !session.notes.isEmpty {
                    Section("Notes") {
                        Text(session.notes)
                            .font(.body)
                    }
                }
            }
            .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddSessionView(editing: session)
            }
        }
    }

    private func row(_ label: String, value: String, icon: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
