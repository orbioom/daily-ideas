import SwiftUI
import SwiftData

struct RidesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]
    @Query(sort: \Bike.createdAt) private var bikes: [Bike]
    @AppStorage("cog.miles") private var miles = false
    @AppStorage("cog.confirmDeletes") private var confirmDeletes = true
    @State private var rideBike: Bike?
    @State private var pendingDelete: Ride?

    var body: some View {
        NavigationStack {
            Group {
                if rides.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "road.lanes", title: "No rides yet",
                                       message: bikes.isEmpty ? "Add a bike first, then log rides." : "Log a ride from a bike or the + button.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            weeklyCard
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "All rides")
                                ForEach(rides) { r in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(r.bike?.name ?? "—").font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                            Text("\(r.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))\(r.note.isEmpty ? "" : " · \(r.note)")")
                                                .font(.caption).foregroundStyle(Brand.text3).lineLimit(1)
                                        }
                                        Spacer()
                                        Text(Units.format(r.distanceKm, miles: miles, decimals: 1))
                                            .font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text2)
                                    }
                                    .padding(.vertical, 4)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = r } else { delete(r) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                                    if r.id != rides.last?.id { Divider().overlay(Brand.hairline) }
                                }
                            }
                            .glassCard()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rides")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(bikes) { b in Button(b.name) { rideBike = b } }
                    } label: { Image(systemName: "plus") }
                    .disabled(bikes.isEmpty)
                    .accessibilityLabel("Log ride")
                }
            }
            .background(Brand.pageBackground)
            .sheet(item: $rideBike) { b in RideEditView(bike: b, existing: nil) }
            .confirmationDialog("Delete this ride? Its distance is removed from the odometer.",
                                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let r = pendingDelete { delete(r) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private var weeklyCard: some View {
        let weeks = 8
        let totals = WearEngine.weeklyDistance(rides: rides, weeks: weeks)
        let maxV = max(1, totals.max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: "Last \(weeks) weeks")
                Spacer()
                Text(Units.format(totals.reduce(0, +), miles: miles)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<weeks, id: \.self) { i in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4).fill(Brand.hairline).frame(height: 90)
                            RoundedRectangle(cornerRadius: 4).fill(Brand.live)
                                .frame(height: max(2, 90 * totals[i] / maxV))
                        }
                        Text(i == weeks - 1 ? "now" : "\(weeks - 1 - i)w").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityLabel("Weekly distance chart")
        }
        .glassCard()
    }

    private func delete(_ r: Ride) {
        if let b = r.bike { b.odometerKm = max(0, b.odometerKm - r.distanceKm) }
        context.delete(r); try? context.save(); Haptics.warning()
    }
}
