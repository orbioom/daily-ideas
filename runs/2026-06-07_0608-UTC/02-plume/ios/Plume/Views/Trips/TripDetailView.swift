import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var showingAddSighting = false
    @State private var showingEdit = false

    private var sightings: [Sighting] {
        trip.sightings.sorted { ($0.species?.taxonOrder ?? 0) < ($1.species?.taxonOrder ?? 0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                HStack(spacing: 10) {
                    StatTile(value: "\(trip.speciesCount)", label: "Species")
                    StatTile(value: "\(trip.individuals)", label: "Individuals")
                    StatTile(value: "\(trip.sightings.count)", label: "Records")
                }
                if !trip.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle(text: "Notes")
                        Text(trip.notes).font(.subheadline).foregroundStyle(Brand.text2)
                    }.glassCard()
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionTitle(text: "Checklist")
                        Spacer()
                        Button { Haptics.tap(); showingAddSighting = true } label: {
                            Label("Add", systemImage: "plus.circle")
                        }.font(.subheadline)
                    }
                    if sightings.isEmpty {
                        Text("No birds logged on this trip yet.")
                            .font(.subheadline).foregroundStyle(Brand.text3).padding(.vertical, 8)
                    } else {
                        ForEach(sightings) { s in
                            HStack {
                                Text(s.species?.commonName ?? "Unknown").foregroundStyle(Brand.text)
                                Spacer()
                                Text("×\(s.count)").font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text2)
                                Button(role: .destructive) {
                                    context.delete(s); try? context.save(); Haptics.warning()
                                } label: { Image(systemName: "minus.circle").foregroundStyle(Brand.danger) }
                                .accessibilityLabel("Remove \(s.species?.commonName ?? "sighting")")
                            }
                            .font(.subheadline)
                            if s.id != sightings.last?.id { Divider().overlay(Brand.hairline) }
                        }
                    }
                }
                .glassCard()
            }
            .padding()
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEdit = true } }
        }
        .sheet(isPresented: $showingAddSighting) { SightingEditView(existing: nil, trip: trip) }
        .sheet(isPresented: $showingEdit) { TripEditView(existing: trip) }
    }

    private var headerCard: some View {
        VStack(spacing: 4) {
            Text(trip.location.isEmpty ? "Outing" : trip.location)
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            Text(trip.date, format: .dateTime.weekday(.wide).month().day().year())
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).glassCard()
    }
}
