import SwiftUI
import SwiftData

/// Pets tab — lists all pets with a quick health snapshot, supports add/edit/delete.
struct PetsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Pet.createdAt) private var pets: [Pet]

    @State private var showingAdd = false
    @State private var petToDelete: Pet?

    var body: some View {
        NavigationStack {
            Group {
                if pets.isEmpty {
                    EmptyStateView(
                        symbol: "pawprint.circle",
                        title: "No pets yet",
                        message: "Add your first companion to start tracking their care and health.",
                        actionTitle: "Add a pet",
                        action: { showingAdd = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Metrics.spacing) {
                            ForEach(pets) { pet in
                                NavigationLink(value: pet.id) {
                                    PetCardRow(pet: pet, settings: settings)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        petToDelete = pet
                                    } label: { Label("Delete \(pet.name)", systemImage: "trash") }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .petalScreenBackground()
            .navigationTitle("Pets")
            .navigationDestination(for: UUID.self) { id in
                if let pet = pets.first(where: { $0.id == id }) {
                    PetDetailView(pet: pet, settings: settings)
                } else {
                    EmptyStateView(symbol: "questionmark.circle", title: "Pet not found",
                                   message: "This pet may have been removed.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add pet")
                }
            }
            .sheet(isPresented: $showingAdd) {
                PetFormView(settings: settings, mode: .create)
            }
            .confirmationDialog(
                "Delete \(petToDelete?.name ?? "pet")?",
                isPresented: Binding(get: { petToDelete != nil }, set: { if !$0 { petToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pet = petToDelete { delete(pet) }
                    petToDelete = nil
                }
                Button("Cancel", role: .cancel) { petToDelete = nil }
            } message: {
                Text("This permanently removes all of their records.")
            }
        }
    }

    private func delete(_ pet: Pet) {
        Haptics.notify(.warning, enabled: settings.hapticsEnabled)
        context.delete(pet)
        try? context.save()
    }
}

/// A summary card for a single pet shown in the list.
struct PetCardRow: View {
    let pet: Pet
    let settings: AppSettings

    private var dueCount: Int {
        let items = CareTimeline.build(for: [pet])
        return items.filter {
            let b = $0.bucket(soonWindowDays: settings.soonWindowDays)
            return b == .overdue || b == .today
        }.count
    }

    var body: some View {
        PetalCard {
            HStack(spacing: 14) {
                PetAvatar(symbol: pet.avatarSymbol, tint: pet.avatarTint.color, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText)
                    Text([pet.species.label, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    HStack(spacing: 8) {
                        if let age = pet.ageText {
                            PillLabel(text: age, tint: pet.avatarTint.color)
                        }
                        if let w = pet.latestWeight {
                            PillLabel(text: Fmt.weight(w.kilograms, unit: settings.preferredWeightUnit),
                                      tint: Theme.lilac)
                        }
                    }
                }
                Spacer()
                VStack(spacing: 6) {
                    if dueCount > 0 {
                        PillLabel(text: "\(dueCount) due", tint: Theme.danger, filled: true)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Theme.success)
                            .accessibilityHidden(true)
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pet.name), \(pet.species.label)\(pet.breed.isEmpty ? "" : ", \(pet.breed)")")
        .accessibilityValue(dueCount > 0 ? "\(dueCount) care items due" : "Up to date")
        .accessibilityHint("Opens details")
    }
}

#Preview {
    PetsView(settings: AppSettings(hasOnboarded: true))
        .modelContainer(PersistenceController.preview.container)
}
