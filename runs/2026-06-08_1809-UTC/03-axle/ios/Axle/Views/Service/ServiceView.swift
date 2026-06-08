import SwiftUI
import SwiftData

struct ServiceView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("axle.volumeUnit") private var volumeUnitRaw = VolumeUnit.liter.rawValue
    @AppStorage("axle.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var showAdd = false
    @State private var editing: ServiceRecord?

    private var fmt: UnitFormatter {
        UnitFormatter(distance: DistanceUnit(rawValue: distanceUnitRaw) ?? .km,
                      volume: VolumeUnit(rawValue: volumeUnitRaw) ?? .liter,
                      currencyCode: currency)
    }

    private var records: [ServiceRecord] {
        vehicle.services.sorted { $0.date > $1.date }
    }

    private var totalCost: Double { vehicle.services.reduce(0) { $0 + $1.cost } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if vehicle.services.isEmpty {
                    EmptyStateView(icon: "wrench.and.screwdriver",
                                   title: "No service history",
                                   message: "Record oil changes, tires, repairs and more to build a full history.")
                } else {
                    List {
                        Section {
                            HStack {
                                Text("Total service spend").foregroundStyle(Brand.text2)
                                Spacer()
                                Text(fmt.money(totalCost)).font(.headline).foregroundStyle(Brand.text)
                            }
                            .listRowBackground(Color.white.opacity(0.001))
                        }
                        Section("History") {
                            ForEach(records) { r in
                                Button { editing = r } label: { row(r) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Service")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add service record")
                }
            }
            .sheet(isPresented: $showAdd) { ServiceEditorView(vehicle: vehicle, mode: .create) }
            .sheet(item: $editing) { r in ServiceEditorView(vehicle: vehicle, mode: .edit(r)) }
        }
    }

    private func row(_ r: ServiceRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: r.type.icon).foregroundStyle(Color(hex: 0x4E6BA8)).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(r.type.title).font(.body.weight(.medium)).foregroundStyle(Brand.text)
                Text("\(Format.shortDate.string(from: r.date)) · \(fmt.distanceString(km: r.odometerKm))")
                    .font(.caption2).foregroundStyle(Brand.text3)
                if !r.notes.isEmpty {
                    Text(r.notes).font(.caption).foregroundStyle(Brand.text2).lineLimit(1)
                }
            }
            Spacer()
            Text(fmt.money(r.cost)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { context.delete(records[i]) }
        try? context.save()
        Haptics.warning()
    }
}
