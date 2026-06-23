import SwiftUI
import SwiftData

/// Vaccination records for a single pet.
struct VaccinationListView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var editing: Vaccination?
    @State private var showingAdd = false

    private var vaccines: [Vaccination] {
        pet.vaccinations.sorted { ($0.nextDue ?? .distantFuture) < ($1.nextDue ?? .distantFuture) }
    }

    var body: some View {
        Group {
            if vaccines.isEmpty {
                EmptyStateView(symbol: "syringe", title: "No vaccinations",
                               message: "Record vaccinations and their booster due dates.",
                               actionTitle: "Add vaccination", action: { showingAdd = true })
            } else {
                List {
                    ForEach(vaccines) { vax in
                        VaccinationRow(vax: vax)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = vax }
                            .swipeActions {
                                Button(role: .destructive) { delete(vax) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Theme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .petalScreenBackground()
        .navigationTitle("Vaccinations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add vaccination")
            }
        }
        .sheet(isPresented: $showingAdd) {
            VaccinationFormView(pet: pet, settings: settings, vaccination: nil)
        }
        .sheet(item: $editing) { vax in
            VaccinationFormView(pet: pet, settings: settings, vaccination: vax)
        }
    }

    private func delete(_ vax: Vaccination) {
        context.delete(vax)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }
}

struct VaccinationRow: View {
    let vax: Vaccination

    private var dueTint: Color {
        guard let due = vax.nextDue else { return Theme.secondaryText }
        let days = Fmt.daysBetween(.now, due)
        if days < 0 { return Theme.danger }
        if days <= 30 { return Theme.amber }
        return Theme.success
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.amber.opacity(0.16))
                Image(systemName: "syringe.fill").foregroundStyle(Theme.amber)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(vax.name).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                Text("Given \(Fmt.mediumDate.string(from: vax.dateAdministered))")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
                if let due = vax.nextDue {
                    PillLabel(text: "Booster \(Fmt.duePhrase(for: due).lowercased())", tint: dueTint)
                } else {
                    PillLabel(text: "No booster scheduled", tint: Theme.secondaryText)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vax.name), given \(Fmt.mediumDate.string(from: vax.dateAdministered))")
        .accessibilityValue(vax.nextDue.map { "Booster \(Fmt.duePhrase(for: $0))" } ?? "No booster scheduled")
    }
}

#Preview {
    NavigationStack {
        if let pet = try? PersistenceController.preview.container.mainContext.fetch(FetchDescriptor<Pet>()).first {
            VaccinationListView(pet: pet, settings: AppSettings(hasOnboarded: true))
        }
    }
    .modelContainer(PersistenceController.preview.container)
}
