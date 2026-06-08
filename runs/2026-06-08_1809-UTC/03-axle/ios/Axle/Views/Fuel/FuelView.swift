import SwiftUI
import SwiftData

struct FuelView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("axle.volumeUnit") private var volumeUnitRaw = VolumeUnit.liter.rawValue
    @AppStorage("axle.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var showAdd = false
    @State private var editing: FuelEntry?

    private var fmt: UnitFormatter {
        UnitFormatter(distance: DistanceUnit(rawValue: distanceUnitRaw) ?? .km,
                      volume: VolumeUnit(rawValue: volumeUnitRaw) ?? .liter,
                      currencyCode: currency)
    }

    private var entries: [FuelEntry] {
        vehicle.fuelEntries.sorted { $0.odometerKm > $1.odometerKm }
    }

    private var summary: GarageEngine.FuelSummary { GarageEngine.fuelSummary(vehicle.fuelEntries) }

    /// Economy (L/100km) keyed by the full-tank entry that closes each interval.
    private var economyByEntry: [PersistentIdentifier: Double] {
        let sorted = vehicle.fuelEntries.sorted { $0.odometerKm < $1.odometerKm }
        var result: [PersistentIdentifier: Double] = [:]
        var lastFull: FuelEntry? = nil
        var liters = 0.0
        for e in sorted {
            if let lf = lastFull {
                liters += e.liters
                if e.isFullTank {
                    let km = e.odometerKm - lf.odometerKm
                    if km > 0 { result[e.persistentModelID] = liters / (km / 100) }
                    lastFull = e; liters = 0
                }
            } else if e.isFullTank {
                lastFull = e; liters = 0
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if vehicle.fuelEntries.isEmpty {
                    EmptyStateView(icon: "fuelpump",
                                   title: "No fill-ups yet",
                                   message: "Log a fuel fill-up to start tracking real economy and cost.")
                } else {
                    List {
                        Section {
                            summaryRow
                                .listRowBackground(Color.white.opacity(0.001))
                        }
                        Section("Fill-ups") {
                            ForEach(entries) { e in
                                Button { editing = e } label: { row(e) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Fuel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add fill-up")
                }
            }
            .sheet(isPresented: $showAdd) { FuelEditorView(vehicle: vehicle, mode: .create) }
            .sheet(item: $editing) { e in FuelEditorView(vehicle: vehicle, mode: .edit(e)) }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 0) {
            stat(fmt.economyString(km: summary.totalDistanceKm, liters: GarageEngine.economyPoints(vehicle.fuelEntries).reduce(0) { $0 + $1.liters }), "average")
            Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
            stat(fmt.money(summary.totalCost), "total cost")
            Rectangle().fill(Brand.hairline).frame(width: 1, height: 30)
            stat(fmt.volumeString(liters: summary.totalLiters, decimals: 0), "total fuel")
        }
        .padding(.vertical, 4)
    }

    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.subheadline.weight(.bold)).foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ e: FuelEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(fmt.volumeString(liters: e.liters)).font(.body.weight(.medium)).foregroundStyle(Brand.text)
                    if !e.isFullTank {
                        Text("partial").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Brand.hairline, in: Capsule())
                    }
                }
                Text("\(Format.shortDate.string(from: e.date)) · \(fmt.distanceString(km: e.odometerKm))")
                    .font(.caption2).foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(fmt.money(e.totalCost)).font(.body.weight(.medium)).foregroundStyle(Brand.text)
                if let eco = economyByEntry[e.persistentModelID] {
                    Text(String(format: "%.1f L/100km", eco)).font(Brand.mono(10)).foregroundStyle(Color(hex: 0x4E6BA8))
                } else {
                    Text(fmt.money(e.pricePerLiter) + "/" + (VolumeUnit(rawValue: volumeUnitRaw) ?? .liter).label)
                        .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(entries[i]) }
        try? context.save()
        Haptics.warning()
    }
}
