import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Bindable var vehicle: Vehicle
    let vehicles: [Vehicle]
    @Binding var selectedID: PersistentIdentifier?

    @Environment(\.modelContext) private var context
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("axle.volumeUnit") private var volumeUnitRaw = VolumeUnit.liter.rawValue
    @AppStorage("axle.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var showOdometer = false
    @State private var showAddVehicle = false
    @State private var showEditVehicle = false
    @State private var showSettings = false

    private var fmt: UnitFormatter {
        UnitFormatter(distance: DistanceUnit(rawValue: distanceUnitRaw) ?? .km,
                      volume: VolumeUnit(rawValue: volumeUnitRaw) ?? .liter,
                      currencyCode: currency)
    }

    private var fuelSummary: GarageEngine.FuelSummary {
        GarageEngine.fuelSummary(vehicle.fuelEntries)
    }

    private var upcoming: [(ServiceReminder, GarageEngine.ReminderStatus)] {
        vehicle.reminders
            .filter { $0.isActive }
            .map { ($0, GarageEngine.status(for: $0, currentOdometerKm: vehicle.odometerKm)) }
            .sorted { lhs, rhs in
                stateRank(lhs.1.state) < stateRank(rhs.1.state)
            }
    }

    private func stateRank(_ s: GarageEngine.ReminderState) -> Int {
        switch s { case .overdue: return 0; case .dueSoon: return 1; case .ok: return 2 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    odometerCard
                    metricsGrid
                    if !economyData.isEmpty { economyChart }
                    if !upcoming.isEmpty { remindersPreview }
                    recentActivity
                }
                .padding()
            }
            .background(Brand.pageBackground)
            .navigationTitle(vehicle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Vehicle", selection: Binding(
                            get: { selectedID ?? vehicle.persistentModelID },
                            set: { selectedID = $0 })) {
                            ForEach(vehicles) { v in
                                Text(v.name).tag(v.persistentModelID as PersistentIdentifier?)
                            }
                        }
                        Divider()
                        Button("Add vehicle", systemImage: "plus") { showAddVehicle = true }
                        Button("Edit this vehicle", systemImage: "pencil") { showEditVehicle = true }
                    } label: {
                        Image(systemName: "car.2")
                    }
                    .accessibilityLabel("Switch or manage vehicles")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showOdometer) { OdometerSheet(vehicle: vehicle) }
            .sheet(isPresented: $showAddVehicle) { VehicleEditorView(mode: .create) }
            .sheet(isPresented: $showEditVehicle) { VehicleEditorView(mode: .edit(vehicle)) }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var odometerCard: some View {
        Button { showOdometer = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Odometer")
                    Text(fmt.distanceString(km: vehicle.odometerKm))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.text)
                    Text(vehicle.displaySubtitle.isEmpty ? vehicle.fuelType.title : vehicle.displaySubtitle)
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                Image(systemName: "square.and.pencil")
                    .font(.title3).foregroundStyle(Color(hex: 0x4E6BA8))
            }
            .glassCard(padding: 18)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Odometer \(fmt.distanceString(km: vehicle.odometerKm)). Tap to update.")
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metric("Avg economy",
                   fuelSummary.averageL100 > 0 ? fmt.economyString(km: fuelSummary.totalDistanceKm, liters: litersInIntervals) : "—",
                   "fuelpump")
            metric("This month", fmt.money(GarageEngine.spendThisMonth(vehicle)), "calendar")
            metric("Total spend", fmt.money(GarageEngine.totalSpend(vehicle)), "creditcard")
            metric("Fill-ups", "\(vehicle.fuelEntries.count)", "number")
        }
    }

    // sum of liters within measured intervals, to pair with totalDistanceKm
    private var litersInIntervals: Double {
        GarageEngine.economyPoints(vehicle.fuelEntries).reduce(0) { $0 + $1.liters }
    }

    private func metric(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(Color(hex: 0x4E6BA8))
            Text(value).font(.title3.weight(.bold)).foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var economyData: [GarageEngine.EconomyPoint] {
        GarageEngine.economyPoints(vehicle.fuelEntries)
    }

    private var economyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Fuel economy trend")
            Chart(economyData) { p in
                LineMark(x: .value("Date", p.date), y: .value("L/100km", p.l100))
                    .foregroundStyle(Color(hex: 0x4E6BA8))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", p.date), y: .value("L/100km", p.l100))
                    .foregroundStyle(Color(hex: 0x4E6BA8))
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 160)
            .accessibilityLabel("Line chart of fuel economy over time")
            Text("Lower is more efficient (L/100km).")
                .font(.caption2).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var remindersPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Upcoming maintenance")
            ForEach(Array(upcoming.prefix(3)), id: \.0.persistentModelID) { reminder, status in
                HStack(spacing: 10) {
                    Image(systemName: reminder.type.icon)
                        .foregroundStyle(color(status.state)).frame(width: 22)
                    Text(reminder.title).foregroundStyle(Brand.text)
                    Spacer()
                    Text(status.detail).font(.caption).foregroundStyle(color(status.state))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func color(_ s: GarageEngine.ReminderState) -> Color {
        switch s { case .overdue: return Brand.danger; case .dueSoon: return Brand.warn; case .ok: return Brand.live }
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Recent activity")
            let fuels = vehicle.fuelEntries.map { ActivityItem(date: $0.date, title: "Fuel", detail: fmt.volumeString(liters: $0.liters), cost: $0.totalCost, icon: "fuelpump") }
            let svcs = vehicle.services.map { ActivityItem(date: $0.date, title: $0.type.title, detail: "", cost: $0.cost, icon: $0.type.icon) }
            let items = (fuels + svcs).sorted { $0.date > $1.date }.prefix(5)
            if items.isEmpty {
                Text("No activity yet. Add a fill-up or service.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(Array(items)) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.icon).foregroundStyle(Brand.text2).frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(.subheadline).foregroundStyle(Brand.text)
                            Text(Format.shortDate.string(from: item.date)).font(.caption2).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(fmt.money(item.cost)).font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private struct ActivityItem: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let detail: String
        let cost: Double
        let icon: String
    }
}

private struct OdometerSheet: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @State private var text = ""

    private var unit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current odometer (\(unit.label))") {
                    TextField("0", text: $text).keyboardType(.decimalPad).font(.title3)
                }
            }
            .navigationTitle("Update Odometer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let v = Double(text.replacingOccurrences(of: ",", with: ".")), v >= 0 {
                            vehicle.odometerKm = unit.toKm(v)
                            try? context.save(); Haptics.success()
                        }
                        dismiss()
                    }
                }
            }
            .onAppear { text = String(format: "%.0f", unit.fromKm(vehicle.odometerKm)) }
        }
    }
}
