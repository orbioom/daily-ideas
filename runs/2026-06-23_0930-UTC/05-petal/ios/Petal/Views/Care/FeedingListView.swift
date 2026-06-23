import SwiftUI
import SwiftData

/// Recurring feeding schedule for a single pet.
struct FeedingListView: View {
    @Bindable var pet: Pet
    @Bindable var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var editing: FeedingSchedule?
    @State private var showingAdd = false

    private var feedings: [FeedingSchedule] {
        pet.feedings.sorted { $0.timeMinutes < $1.timeMinutes }
    }

    var body: some View {
        Group {
            if feedings.isEmpty {
                EmptyStateView(symbol: "fork.knife", title: "No feedings",
                               message: "Add meals so they appear in your daily care timeline.",
                               actionTitle: "Add feeding", action: { showingAdd = true })
            } else {
                List {
                    ForEach(feedings) { feeding in
                        FeedingRow(feeding: feeding, settings: settings) { toggle(feeding) }
                            .contentShape(Rectangle())
                            .onTapGesture { editing = feeding }
                            .swipeActions {
                                Button(role: .destructive) { delete(feeding) } label: {
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
        .navigationTitle("Feeding Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add feeding")
            }
        }
        .sheet(isPresented: $showingAdd) {
            FeedingFormView(pet: pet, settings: settings, feeding: nil)
        }
        .sheet(item: $editing) { feeding in
            FeedingFormView(pet: pet, settings: settings, feeding: feeding)
        }
    }

    private func toggle(_ feeding: FeedingSchedule) {
        feeding.isActive.toggle()
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    private func delete(_ feeding: FeedingSchedule) {
        context.delete(feeding)
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }
}

struct FeedingRow: View {
    let feeding: FeedingSchedule
    let settings: AppSettings
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((feeding.isActive ? Theme.pink : Theme.secondaryText).opacity(0.16))
                Image(systemName: "fork.knife")
                    .foregroundStyle(feeding.isActive ? Theme.pink : Theme.secondaryText)
            }
            .frame(width: 40, height: 40)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(feeding.label).font(.body.weight(.medium)).foregroundStyle(Theme.primaryText)
                Text([feeding.portion, feeding.food].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(feeding.timeText).font(.subheadline.weight(.medium)).foregroundStyle(Theme.primaryText)
                Toggle("", isOn: Binding(get: { feeding.isActive }, set: { _ in onToggle() }))
                    .labelsHidden()
                    .accessibilityLabel("\(feeding.label) active")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feeding.label) at \(feeding.timeText)")
        .accessibilityValue(feeding.isActive ? "Active" : "Paused")
    }
}

#Preview {
    NavigationStack {
        if let pet = try? PersistenceController.preview.container.mainContext.fetch(FetchDescriptor<Pet>()).first {
            FeedingListView(pet: pet, settings: AppSettings(hasOnboarded: true))
        }
    }
    .modelContainer(PersistenceController.preview.container)
}
