import SwiftUI
import SwiftData

struct BikeDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var bike: Bike
    @AppStorage("cog.miles") private var miles = false
    @State private var showingRide = false
    @State private var showingComponent = false
    @State private var showingEditBike = false

    private var components: [Component] {
        bike.activeComponents.sorted { $0.wear > $1.wear }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                odometerCard
                componentsCard
                ridesSummaryCard
            }
            .padding()
        }
        .navigationTitle(bike.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingRide = true } label: { Label("Log ride", systemImage: "road.lanes") }
                    Button { showingComponent = true } label: { Label("Add component", systemImage: "plus") }
                    Button { showingEditBike = true } label: { Label("Edit bike", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingRide) { RideEditView(bike: bike, existing: nil) }
        .sheet(isPresented: $showingComponent) { ComponentEditView(bike: bike, existing: nil) }
        .sheet(isPresented: $showingEditBike) { BikeEditView(existing: bike) }
    }

    private var odometerCard: some View {
        VStack(spacing: 10) {
            Text(Units.format(bike.odometerKm, miles: miles))
                .font(Brand.mono(40, weight: .bold)).foregroundStyle(Brand.text)
            Text("\(bike.kind) · \(bike.rides.count) rides logged").font(.caption).foregroundStyle(Brand.text3)
            Button { Haptics.tap(); showingRide = true } label: {
                Label("Log a ride", systemImage: "plus").frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle())
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18).glassCard()
    }

    private var componentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Components")
                Spacer()
                Button { Haptics.tap(); showingComponent = true } label: { Image(systemName: "plus.circle") }
                    .accessibilityLabel("Add component")
            }
            if components.isEmpty {
                Text("No components yet. Add a chain, tyres, brake pads…").font(.caption).foregroundStyle(Brand.text3)
            } else {
                ForEach(components) { c in
                    NavigationLink { ComponentEditView(bike: bike, existing: c) } label: {
                        ComponentRow(component: c, miles: miles)
                    }.buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }

    private var ridesSummaryCard: some View {
        let last30 = WearEngine.distance(in: bike.rides, trailingDays: 30)
        let last7 = WearEngine.distance(in: bike.rides, trailingDays: 7)
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent riding")
            HStack(spacing: 10) {
                StatTile(value: Units.format(last7, miles: miles), label: "Last 7 days")
                StatTile(value: Units.format(last30, miles: miles), label: "Last 30 days")
                StatTile(value: Units.format(bike.dailyKm, miles: miles, decimals: 1) + "/d", label: "Avg/day")
            }
        }
        .glassCard()
    }
}

struct ComponentRow: View {
    let component: Component
    let miles: Bool

    private var status: WearEngine.Status { WearEngine.status(wear: component.wear) }
    private var barColor: Color {
        switch status { case .ok: return Brand.live; case .soon: return Brand.warn; case .due: return Brand.danger }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(component.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Spacer()
                Text("\(Int((component.wear * 100).rounded()))%")
                    .font(Brand.mono(13, weight: .semibold)).foregroundStyle(barColor)
            }
            MeterBar(fraction: min(1, component.wear), color: barColor)
            HStack {
                if component.lifespanKm > 0 {
                    Text("\(Units.format(component.distanceUsedKm, miles: miles)) / \(Units.format(component.lifespanKm, miles: miles))")
                        .font(.caption2).foregroundStyle(Brand.text3)
                } else if component.lifespanDays > 0 {
                    Text("\(component.daysUsed) / \(component.lifespanDays) days")
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
                Spacer()
                if let date = WearEngine.projectedReplacement(component: component, dailyKm: component.bike?.dailyKm ?? 0) {
                    Text(status == .due ? "Overdue" : "≈ \(date.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption2).foregroundStyle(status == .due ? Brand.danger : Brand.text3)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(component.name), \(Int(component.wear * 100)) percent worn, status \(status.label)")
    }
}
