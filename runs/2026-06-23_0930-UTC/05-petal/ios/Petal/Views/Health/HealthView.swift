import SwiftUI
import SwiftData

/// Health tab — cross-pet medical overview: recent vet visits, vaccination
/// status, and quick access to each pet's records.
struct HealthView: View {
    @Bindable var settings: AppSettings
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    private var recentVisits: [VetVisit] {
        pets.flatMap { $0.vetVisits }.sorted { $0.date > $1.date }.prefix(6).map { $0 }
    }

    private var overdueVaccines: [(Pet, Vaccination)] {
        pets.flatMap { pet in
            pet.vaccinations.compactMap { vax -> (Pet, Vaccination)? in
                guard let due = vax.nextDue, Fmt.daysBetween(.now, due) < 0 else { return nil }
                return (pet, vax)
            }
        }.sorted { ($0.1.nextDue ?? .distantPast) < ($1.1.nextDue ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    EmptyStateView(symbol: "cross.case",
                                   title: "No health records",
                                   message: "Add a pet to start logging vaccinations and vet visits.")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            statRow
                            if !overdueVaccines.isEmpty { overdueSection }
                            visitsSection
                            petsSection
                        }
                        .padding(16)
                    }
                }
            }
            .petalScreenBackground()
            .navigationTitle("Health")
            .navigationDestination(for: UUID.self) { id in
                if let pet = pets.first(where: { $0.id == id }) {
                    PetDetailView(pet: pet, settings: settings)
                }
            }
        }
    }

    private var statRow: some View {
        let medCount = pets.flatMap { $0.medications }.filter { $0.isActive }.count
        let vaxCount = pets.flatMap { $0.vaccinations }.count
        let visitCount = pets.flatMap { $0.vetVisits }.count
        return HStack(spacing: Theme.Metrics.spacing) {
            stat("pills.fill", Theme.accent, "\(medCount)", "Active meds")
            stat("syringe.fill", Theme.amber, "\(vaxCount)", "Vaccines")
            stat("stethoscope", Theme.blue, "\(visitCount)", "Visits")
        }
    }

    private func stat(_ symbol: String, _ tint: Color, _ value: String, _ label: String) -> some View {
        PetalCard {
            VStack(spacing: 6) {
                Image(systemName: symbol).foregroundStyle(tint).font(.title3).accessibilityHidden(true)
                Text(value).font(.title3.bold()).foregroundStyle(Theme.primaryText)
                Text(label).font(.caption2).foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Overdue boosters")
            PetalCard {
                VStack(spacing: 0) {
                    ForEach(Array(overdueVaccines.enumerated()), id: \.offset) { idx, pair in
                        let (pet, vax) = pair
                        IconRow(symbol: "exclamationmark.triangle.fill", tint: Theme.danger,
                                title: "\(vax.name) — \(pet.name)",
                                subtitle: vax.nextDue.map { Fmt.duePhrase(for: $0) } ?? "")
                        if idx < overdueVaccines.count - 1 { Divider().overlay(Theme.divider) }
                    }
                }
            }
        }
    }

    private var visitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Recent vet visits")
            if recentVisits.isEmpty {
                PetalCard {
                    Text("No vet visits logged yet.")
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                PetalCard {
                    VStack(spacing: 0) {
                        ForEach(Array(recentVisits.enumerated()), id: \.element.id) { idx, visit in
                            let petName = pets.first { $0.vetVisits.contains { $0.id == visit.id } }?.name ?? ""
                            IconRow(symbol: visit.reason.symbol, tint: Theme.blue,
                                    title: "\(visit.reason.label) — \(petName)",
                                    subtitle: visit.diagnosis.isEmpty ? Fmt.mediumDate.string(from: visit.date) : visit.diagnosis,
                                    trailing: Fmt.dayMonth.string(from: visit.date))
                            if idx < recentVisits.count - 1 { Divider().overlay(Theme.divider) }
                        }
                    }
                }
            }
        }
    }

    private var petsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Records by pet")
            PetalCard {
                VStack(spacing: 0) {
                    ForEach(Array(pets.enumerated()), id: \.element.id) { idx, pet in
                        NavigationLink(value: pet.id) {
                            HStack(spacing: 12) {
                                PetAvatar(symbol: pet.avatarSymbol, tint: pet.avatarTint.color, size: 38)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pet.name).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                                    Text("\(pet.vaccinations.count) vaccines · \(pet.vetVisits.count) visits")
                                        .font(.caption).foregroundStyle(Theme.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                                    .foregroundStyle(Theme.secondaryText).accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens \(pet.name)'s records")
                        if idx < pets.count - 1 { Divider().overlay(Theme.divider) }
                    }
                }
            }
        }
    }
}

#Preview {
    HealthView(settings: AppSettings(hasOnboarded: true))
        .modelContainer(PersistenceController.preview.container)
}
