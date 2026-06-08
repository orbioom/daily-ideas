import SwiftUI
import SwiftData

struct RemindersView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue

    @State private var showAdd = false
    @State private var editing: ServiceReminder?

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }

    private var active: [ServiceReminder] {
        vehicle.reminders.filter { $0.isActive }
    }
    private var inactive: [ServiceReminder] {
        vehicle.reminders.filter { !$0.isActive }
    }

    private func status(_ r: ServiceReminder) -> GarageEngine.ReminderStatus {
        GarageEngine.status(for: r, currentOdometerKm: vehicle.odometerKm)
    }

    private func rank(_ s: GarageEngine.ReminderState) -> Int {
        switch s { case .overdue: return 0; case .dueSoon: return 1; case .ok: return 2 }
    }

    private var sortedActive: [ServiceReminder] {
        active.sorted { rank(status($0).state) < rank(status($1).state) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if vehicle.reminders.isEmpty {
                    EmptyStateView(icon: "bell.badge",
                                   title: "No reminders",
                                   message: "Set reminders by distance or date so you never miss an oil change or renewal.")
                } else {
                    List {
                        Section("Active") {
                            ForEach(sortedActive) { r in
                                Button { editing = r } label: { row(r) }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.white.opacity(0.001))
                                    .swipeActions {
                                        Button("Done") { markDone(r) }.tint(Brand.live)
                                    }
                            }
                        }
                        if !inactive.isEmpty {
                            Section("Completed") {
                                ForEach(inactive) { r in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.live)
                                        Text(r.title).foregroundStyle(Brand.text2)
                                        Spacer()
                                        Button("Reactivate") { r.isActive = true; try? context.save() }
                                            .font(.caption)
                                    }
                                    .listRowBackground(Color.white.opacity(0.001))
                                }
                                .onDelete { offsets in
                                    for i in offsets { context.delete(inactive[i]) }
                                    try? context.save()
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add reminder")
                }
            }
            .sheet(isPresented: $showAdd) { ReminderEditorView(vehicle: vehicle, mode: .create) }
            .sheet(item: $editing) { r in ReminderEditorView(vehicle: vehicle, mode: .edit(r)) }
        }
    }

    private func row(_ r: ServiceReminder) -> some View {
        let s = status(r)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(color(s.state).opacity(0.16)).frame(width: 38, height: 38)
                Image(systemName: r.type.icon).foregroundStyle(color(s.state))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(r.title).font(.body.weight(.medium)).foregroundStyle(Brand.text)
                Text(s.detail).font(.caption).foregroundStyle(color(s.state))
            }
            Spacer()
            Button { markDone(r) } label: {
                Image(systemName: "checkmark.circle").font(.title3).foregroundStyle(Brand.text3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(r.title) done")
        }
        .padding(.vertical, 2)
    }

    private func color(_ s: GarageEngine.ReminderState) -> Color {
        switch s { case .overdue: return Brand.danger; case .dueSoon: return Brand.warn; case .ok: return Brand.live }
    }

    private func markDone(_ r: ServiceReminder) {
        GarageEngine.roll(r, currentOdometerKm: vehicle.odometerKm)
        try? context.save()
        Haptics.success()
    }
}
