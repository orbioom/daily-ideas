import SwiftUI
import SwiftData

struct PetsView: View {
    @Query(sort: \Pet.createdAt) private var pets: [Pet]
    @AppStorage("whisker.weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("whisker.soonWindow") private var soonWindow = 3
    @State private var adding = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var active: [Pet] { pets.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            Group {
                if active.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "pawprint.fill",
                                       title: "No pets",
                                       message: "Tap + to add your first companion and start tracking their care.")
                            .glassCard().padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(active) { pet in
                                NavigationLink {
                                    PetDetailView(pet: pet)
                                } label: {
                                    petCard(pet)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Pets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); adding = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add pet")
                }
            }
            .sheet(isPresented: $adding) { PetEditorView(pet: nil) }
        }
    }

    private func petCard(_ pet: Pet) -> some View {
        let dueCount = PetEngine.nextDueCount(for: pet, withinDays: soonWindow)
        return HStack(spacing: 14) {
            PetAvatar(pet: pet, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(pet.name).font(.headline).foregroundStyle(Brand.text)
                Text([pet.species.title, pet.breed].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(Brand.text3)
                HStack(spacing: 10) {
                    if let age = PetEngine.ageString(from: pet.birthday) {
                        Label(age, systemImage: "birthday.cake").font(.caption2).foregroundStyle(Brand.text2)
                    }
                    if let kg = pet.latestWeightKg {
                        Label(Format.weight(kg, unit: unit), systemImage: "scalemass")
                            .font(.caption2).foregroundStyle(Brand.text2)
                    }
                }
            }
            Spacer()
            if dueCount > 0 {
                VStack(spacing: 2) {
                    Text("\(dueCount)").font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.warn)
                    Text("due").font(.caption2).foregroundStyle(Brand.text3)
                }
                .accessibilityLabel("\(dueCount) care tasks due")
            }
            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }
}
