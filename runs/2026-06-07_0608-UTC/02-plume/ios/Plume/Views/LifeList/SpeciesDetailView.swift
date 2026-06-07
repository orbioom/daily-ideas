import SwiftUI
import SwiftData

struct SpeciesDetailView: View {
    @Bindable var species: Species

    private var sightings: [Sighting] {
        species.sightings.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if sightings.isEmpty {
                    EmptyStateView(icon: "binoculars", title: "No sightings",
                                   message: "This species has no observations yet.").glassCard()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Sightings")
                        ForEach(sightings) { s in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.location.isEmpty ? "Unknown location" : s.location)
                                        .font(.subheadline).foregroundStyle(Brand.text)
                                    Text(s.date, format: .dateTime.weekday().month().day().year())
                                        .font(.caption).foregroundStyle(Brand.text3)
                                    if !s.notes.isEmpty {
                                        Text(s.notes).font(.caption).foregroundStyle(Brand.text2)
                                    }
                                }
                                Spacer()
                                if s.id == species.sightings.min(by: { $0.date < $1.date })?.id {
                                    Badge(text: "Lifer", color: Brand.magic)
                                }
                                Text("×\(s.count)").font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text2)
                            }
                            .padding(.vertical, 2)
                            if s.id != sightings.last?.id { Divider().overlay(Brand.hairline) }
                        }
                    }
                    .glassCard()
                }
            }
            .padding()
        }
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }

    private var headerCard: some View {
        VStack(spacing: 6) {
            Text(species.commonName).font(.title2.weight(.bold)).foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text(species.scientificName).font(.subheadline).italic().foregroundStyle(Brand.text3)
            Badge(text: species.family)
            HStack(spacing: 18) {
                stat("\(species.sightingCount)", "Sightings")
                stat("\(species.totalIndividuals)", "Individuals")
                if let f = species.firstSeen {
                    stat(f.formatted(.dateTime.month(.abbreviated).year()), "First seen")
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassCard()
    }

    private func stat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
            Text(l.uppercased()).font(Brand.mono(9)).tracking(0.8).foregroundStyle(Brand.text3)
        }
    }
}
