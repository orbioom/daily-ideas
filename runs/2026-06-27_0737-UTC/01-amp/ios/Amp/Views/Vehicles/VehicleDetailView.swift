import SwiftUI
import SwiftData
import Charts

struct VehicleDetailView: View {
    @Bindable var vehicle: Vehicle
    let currencySymbol: String
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false

    private var recentSessions: [ChargingSession] {
        vehicle.sessions.sorted { $0.date > $1.date }.prefix(20).map { $0 }
    }

    private var monthly: [MonthlyBucket] {
        ChargingEngine.monthlyBuckets(from: vehicle.sessions, months: 6)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(hex: vehicle.colorHex) ?? .blue)
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                            }
                            .accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(vehicle.displayName)
                                .font(.headline)
                            Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                                .foregroundStyle(.secondary)
                            Text("\(vehicle.batteryKWh, specifier: "%.0f") kWh · \(vehicle.rangeKm, specifier: "%.0f") km range")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Stats") {
                    statRow("Total Sessions", value: "\(vehicle.sessionCount)")
                    statRow("Total kWh", value: String(format: "%.1f kWh", vehicle.totalKWh))
                    statRow("Total Cost", value: "\(currencySymbol)\(vehicle.totalCost, specifier: "%.2f")")
                    if vehicle.sessionCount > 0 {
                        statRow("Avg per Session", value: String(format: "%.1f kWh", vehicle.totalKWh / Double(vehicle.sessionCount)))
                    }
                }
                if !monthly.isEmpty && monthly.contains(where: { $0.kwhAdded > 0 }) {
                    Section("Monthly kWh") {
                        Chart(monthly) { m in
                            BarMark(x: .value("Month", m.id), y: .value("kWh", m.kwhAdded))
                                .foregroundStyle(Color.accentColor.gradient)
                        }
                        .frame(height: 120)
                        .chartYAxisLabel("kWh")
                    }
                }
                if !recentSessions.isEmpty {
                    Section("Recent Charges") {
                        ForEach(recentSessions) { s in
                            HStack {
                                Image(systemName: s.chargerType.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text(s.locationName.isEmpty ? s.chargerType.rawValue : s.locationName)
                                        .font(.subheadline)
                                    Text(s.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.1f kWh", s.kwhAdded))
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                }
            }
            .navigationTitle(vehicle.displayName)
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
                AddVehicleView(editing: vehicle)
            }
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
