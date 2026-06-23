import SwiftUI
import SwiftData

/// Medications for a single pet, with give/complete actions and full CRUD.
struct MedicationListView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var editing: Medication?
    @State private var showingAdd = false

    private var meds: [Medication] {
        pet.medications.sorted { ($0.isActive ? 0 : 1, $0.nextDue) < ($1.isActive ? 0 : 1, $1.nextDue) }
    }

    var body: some View {
        Group {
            if meds.isEmpty {
                EmptyStateView(symbol: "pills", title: "No medications",
                               message: "Add a medication course to track doses and reminders.",
                               actionTitle: "Add medication", action: { showingAdd = true })
            } else {
                List {
                    ForEach(meds) { med in
                        MedicationRow(med: med, settings: settings, onGive: { give(med) })
                            .contentShape(Rectangle())
                            .onTapGesture { editing = med }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { delete(med) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                if med.isActive {
                                    Button { give(med) } label: { Label("Give", systemImage: "checkmark") }
                                        .tint(Theme.success)
                                }
                            }
                            .listRowBackground(Theme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .petalScreenBackground()
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add medication")
            }
        }
        .sheet(isPresented: $showingAdd) {
            MedicationFormView(pet: pet, settings: settings, medication: nil)
        }
        .sheet(item: $editing) { med in
            MedicationFormView(pet: pet, settings: settings, medication: med)
        }
    }

    private func give(_ med: Medication) {
        med.markGiven()
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
    }

    private func delete(_ med: Medication) {
        context.delete(med)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }
}

struct MedicationRow: View {
    let med: Medication
    let settings: AppSettings
    var onGive: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((med.isActive ? Theme.accent : Theme.secondaryText).opacity(0.16))
                Image(systemName: "pills.fill")
                    .foregroundStyle(med.isActive ? Theme.accent : Theme.secondaryText)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(med.name).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                Text([med.dosage, med.frequency.label].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(Theme.secondaryText)
                if med.isActive {
                    let phrase = Fmt.duePhrase(for: med.nextDue)
                    PillLabel(text: phrase,
                              tint: phrase.contains("overdue") ? Theme.danger : Theme.accent)
                } else {
                    PillLabel(text: "Completed", tint: Theme.secondaryText)
                }
            }
            Spacer()
            if med.isActive {
                Button(action: onGive) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.success)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(med.name) given")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(med.name), \(med.dosage) \(med.frequency.label)")
        .accessibilityValue(med.isActive ? Fmt.duePhrase(for: med.nextDue) : "Completed")
    }
}

#Preview {
    NavigationStack {
        if let pet = try? PersistenceController.preview.container.mainContext.fetch(FetchDescriptor<Pet>()).first {
            MedicationListView(pet: pet, settings: AppSettings(hasOnboarded: true))
        }
    }
    .modelContainer(PersistenceController.preview.container)
}
