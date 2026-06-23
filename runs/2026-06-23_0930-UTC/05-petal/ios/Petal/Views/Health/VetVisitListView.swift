import SwiftUI
import SwiftData

/// Vet visit log for a single pet.
struct VetVisitListView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var editing: VetVisit?
    @State private var showingAdd = false

    private var visits: [VetVisit] {
        pet.vetVisits.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if visits.isEmpty {
                EmptyStateView(symbol: "stethoscope", title: "No vet visits",
                               message: "Log checkups, illnesses and procedures with diagnoses and follow-ups.",
                               actionTitle: "Add visit", action: { showingAdd = true })
            } else {
                List {
                    ForEach(visits) { visit in
                        VetVisitRow(visit: visit, settings: settings)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = visit }
                            .swipeActions {
                                Button(role: .destructive) { delete(visit) } label: {
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
        .navigationTitle("Vet Visits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add vet visit")
            }
        }
        .sheet(isPresented: $showingAdd) {
            VetVisitFormView(pet: pet, settings: settings, visit: nil)
        }
        .sheet(item: $editing) { visit in
            VetVisitFormView(pet: pet, settings: settings, visit: visit)
        }
    }

    private func delete(_ visit: VetVisit) {
        context.delete(visit)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }
}

struct VetVisitRow: View {
    let visit: VetVisit
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.blue.opacity(0.16))
                Image(systemName: visit.reason.symbol).foregroundStyle(Theme.blue)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(visit.reason.label).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                Text(Fmt.mediumDate.string(from: visit.date))
                    .font(.caption).foregroundStyle(Theme.secondaryText)
                if !visit.diagnosis.isEmpty {
                    Text(visit.diagnosis).font(.caption).foregroundStyle(Theme.secondaryText).lineLimit(1)
                }
                if let f = visit.followUpDate {
                    PillLabel(text: "Follow-up \(Fmt.duePhrase(for: f).lowercased())",
                              tint: Fmt.daysBetween(.now, f) < 0 ? Theme.danger : Theme.blue)
                }
            }
            Spacer()
            if visit.cost > 0 {
                Text(String(format: "$%.0f", visit.cost))
                    .font(.subheadline).foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(visit.reason.label) on \(Fmt.mediumDate.string(from: visit.date))")
    }
}

#Preview {
    NavigationStack {
        if let pet = try? PersistenceController.preview.container.mainContext.fetch(FetchDescriptor<Pet>()).first {
            VetVisitListView(pet: pet, settings: AppSettings(hasOnboarded: true))
        }
    }
    .modelContainer(PersistenceController.preview.container)
}
