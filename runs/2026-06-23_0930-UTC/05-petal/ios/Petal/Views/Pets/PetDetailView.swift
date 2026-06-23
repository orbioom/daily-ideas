import SwiftUI
import SwiftData
import Charts

/// Full profile for a single pet: snapshot, mini weight chart, and quick links
/// into medications, vaccinations, vet visits and feedings.
struct PetDetailView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings

    @Environment(\.modelContext) private var context
    @State private var showingEdit = false

    private var sortedWeights: [WeightEntry] {
        pet.weightEntries.sorted { $0.date < $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Metrics.spacing) {
                header
                weightSnapshot
                quickStats
                recordLinks
                if !pet.notes.isEmpty {
                    PetalCard {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeader(title: "Notes")
                            Text(pet.notes)
                                .font(.body)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .padding(16)
        }
        .petalScreenBackground()
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            PetFormView(settings: settings, mode: .edit(pet))
        }
    }

    private var header: some View {
        PetalCard {
            HStack(spacing: 16) {
                PetAvatar(symbol: pet.avatarSymbol, tint: pet.avatarTint.color, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name).font(.title2.bold()).foregroundStyle(Theme.primaryText)
                    Text([pet.species.label, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline).foregroundStyle(Theme.secondaryText)
                    if let age = pet.ageText {
                        PillLabel(text: age, tint: pet.avatarTint.color)
                    }
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var weightSnapshot: some View {
        PetalCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(
                    title: "Weight",
                    trailing: pet.latestWeight.map { Fmt.weight($0.kilograms, unit: settings.preferredWeightUnit) }
                )
                if sortedWeights.count >= 2 {
                    Chart(sortedWeights) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.displayWeight(in: settings.preferredWeightUnit))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.lilac)
                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.displayWeight(in: settings.preferredWeightUnit))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(colors: [Theme.lilac.opacity(0.3), .clear],
                                                        startPoint: .top, endPoint: .bottom))
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 120)
                    .accessibilityLabel("Weight trend chart for \(pet.name)")
                } else {
                    Text("Add at least two weigh-ins to see a trend.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: Theme.Metrics.spacing) {
            statTile("pills.fill", Theme.accent, "\(pet.medications.filter { $0.isActive }.count)", "Meds")
            statTile("syringe.fill", Theme.amber, "\(pet.vaccinations.count)", "Vaccines")
            statTile("stethoscope", Theme.blue, "\(pet.vetVisits.count)", "Visits")
        }
    }

    private func statTile(_ symbol: String, _ tint: Color, _ value: String, _ label: String) -> some View {
        PetalCard {
            VStack(spacing: 6) {
                Image(systemName: symbol).foregroundStyle(tint).font(.title3)
                    .accessibilityHidden(true)
                Text(value).font(.title3.bold()).foregroundStyle(Theme.primaryText)
                Text(label).font(.caption).foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var recordLinks: some View {
        PetalCard {
            VStack(spacing: 0) {
                NavigationLink(value: PetRecordRoute.medications(pet.id)) {
                    IconRow(symbol: "pills.fill", tint: Theme.accent, title: "Medications",
                            subtitle: "\(pet.medications.count) total", trailing: "›")
                }
                Divider().overlay(Theme.divider)
                NavigationLink(value: PetRecordRoute.vaccinations(pet.id)) {
                    IconRow(symbol: "syringe.fill", tint: Theme.amber, title: "Vaccinations",
                            subtitle: "\(pet.vaccinations.count) on record", trailing: "›")
                }
                Divider().overlay(Theme.divider)
                NavigationLink(value: PetRecordRoute.vetVisits(pet.id)) {
                    IconRow(symbol: "stethoscope", tint: Theme.blue, title: "Vet Visits",
                            subtitle: "\(pet.vetVisits.count) logged", trailing: "›")
                }
                Divider().overlay(Theme.divider)
                NavigationLink(value: PetRecordRoute.feedings(pet.id)) {
                    IconRow(symbol: "fork.knife", tint: Theme.pink, title: "Feeding Schedule",
                            subtitle: "\(pet.feedings.filter { $0.isActive }.count) active", trailing: "›")
                }
            }
        }
        .buttonStyle(.plain)
        .navigationDestination(for: PetRecordRoute.self) { route in
            destination(for: route)
        }
    }

    @ViewBuilder
    private func destination(for route: PetRecordRoute) -> some View {
        switch route {
        case .medications: MedicationListView(pet: pet, settings: settings)
        case .vaccinations: VaccinationListView(pet: pet, settings: settings)
        case .vetVisits: VetVisitListView(pet: pet, settings: settings)
        case .feedings: FeedingListView(pet: pet, settings: settings)
        }
    }
}

/// Routes for the per-pet record lists.
enum PetRecordRoute: Hashable {
    case medications(UUID)
    case vaccinations(UUID)
    case vetVisits(UUID)
    case feedings(UUID)
}

#Preview {
    NavigationStack {
        if let pet = try? PersistenceController.preview.container.mainContext.fetch(FetchDescriptor<Pet>()).first {
            PetDetailView(pet: pet, settings: AppSettings(hasOnboarded: true))
        }
    }
    .modelContainer(PersistenceController.preview.container)
}
