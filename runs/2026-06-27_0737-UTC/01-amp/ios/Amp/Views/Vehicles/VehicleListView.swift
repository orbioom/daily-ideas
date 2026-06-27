import SwiftUI
import SwiftData

struct VehicleListView: View {
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @Environment(\.modelContext) private var context
    @State private var showAdd = false
    @State private var selectedVehicle: Vehicle? = nil
    @Query private var settingsArr: [AmpSettings]
    private var currencySymbol: String { settingsArr.first?.currencySymbol ?? "$" }

    var body: some View {
        NavigationStack {
            Group {
                if vehicles.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(vehicles) { v in
                            VehicleRowView(vehicle: v, currencySymbol: currencySymbol)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedVehicle = v }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        context.delete(v)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add vehicle")
                }
            }
            .sheet(isPresented: $showAdd) { AddVehicleView() }
            .sheet(item: $selectedVehicle) { v in
                VehicleDetailView(vehicle: v, currencySymbol: currencySymbol)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No vehicles yet")
                .font(.title3.bold())
            Text("Add your EV to start tracking charges")
                .foregroundStyle(.secondary)
            Button("Add Vehicle") { showAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let currencySymbol: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: vehicle.colorHex) ?? .blue)
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.displayName)
                    .font(.headline)
                Text("\(vehicle.year) · \(vehicle.batteryKWh, specifier: "%.0f") kWh battery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(vehicle.sessionCount) charges")
                    .font(.subheadline.bold())
                Text("\(currencySymbol)\(vehicle.totalCost, specifier: "%.0f") total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vehicle.displayName), \(vehicle.sessionCount) charges, \(currencySymbol)\(vehicle.totalCost, specifier: "%.0f") total cost")
    }
}
