import SwiftUI
import SwiftData

/// Add or edit an itinerary item, including moving it to another day.
struct ItineraryItemEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let day: TripDay
    let item: ItineraryItem?
    @Bindable var trip: Trip

    @State private var title = ""
    @State private var category: ItemCategory = .activity
    @State private var hasTime = false
    @State private var time = Date()
    @State private var durationMin = 60
    @State private var address = ""
    @State private var cost = ""
    @State private var booked = false
    @State private var notes = ""
    @State private var targetDayID: UUID = UUID()
    @State private var showValidation = false

    private var isEditing: Bool { item != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var titleValid: Bool { !trimmedTitle.isEmpty }
    private var days: [TripDay] { TripService.orderedDays(trip) }

    private let durations = [15, 30, 45, 60, 90, 120, 180, 240]

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    TextField("Title (e.g. Lunch at the harbor)", text: $title)
                    if showValidation && !titleValid {
                        Label("Add a title", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.danger)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { c in
                            Label(c.label, systemImage: c.symbol).tag(c)
                        }
                    }
                }

                Section("Time") {
                    Toggle("Set a time", isOn: $hasTime.animation())
                    if hasTime {
                        DatePicker("Start", selection: $time, displayedComponents: .hourAndMinute)
                        Picker("Duration", selection: $durationMin) {
                            ForEach(durations, id: \.self) { Text(ItineraryEngine.durationLabel($0)).tag($0) }
                        }
                    } else {
                        Text("Shows under \"Anytime\" and can be reordered.")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Section("Details") {
                    TextField("Address (plain text)", text: $address)
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    Toggle("Booked / confirmed", isOn: $booked)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                if days.count > 1 {
                    Section("Day") {
                        Picker("On day", selection: $targetDayID) {
                            ForEach(Array(days.enumerated()), id: \.element.id) { idx, d in
                                Text("Day \(idx + 1) · \(d.date.formatted(date: .abbreviated, time: .omitted))").tag(d.id)
                            }
                        }
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) { remove() } label: {
                            Label("Delete plan", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Plan" : "New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        targetDayID = day.id
        guard let item else { return }
        title = item.title
        category = item.category
        hasTime = item.isTimed
        if item.isTimed {
            let cal = ItineraryEngine.calendar
            time = cal.date(bySettingHour: item.startTimeMinutes / 60,
                            minute: item.startTimeMinutes % 60,
                            second: 0, of: Date()) ?? Date()
        }
        durationMin = item.durationMin > 0 ? item.durationMin : 60
        address = item.address
        cost = item.cost > 0 ? numberString(item.cost) : ""
        booked = item.booked
        notes = item.notes
        targetDayID = item.day?.id ?? day.id
    }

    private func save() {
        guard titleValid else {
            showValidation = true
            Haptics.warning()
            return
        }
        let cal = ItineraryEngine.calendar
        let minutes: Int
        if hasTime {
            let comps = cal.dateComponents([.hour, .minute], from: time)
            minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        } else {
            minutes = -1
        }
        let costValue = Double(cost.replacingOccurrences(of: ",", with: ".")) ?? 0
        let destinationDay = days.first(where: { $0.id == targetDayID }) ?? day

        let target: ItineraryItem
        if let item {
            target = item
        } else {
            target = ItineraryItem(title: trimmedTitle)
            target.sortOrder = (destinationDay.items.map { $0.sortOrder }.max() ?? -1) + 1
            context.insert(target)
        }
        target.title = trimmedTitle
        target.category = category
        target.startTimeMinutes = minutes
        target.durationMin = hasTime ? durationMin : 0
        target.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        target.cost = max(0, costValue)
        target.booked = booked
        target.notes = notes

        // Re-home to the chosen day if it changed. Setting the to-one side lets
        // SwiftData move the item between the two days' inverse collections.
        if target.day?.id != destinationDay.id {
            target.day = destinationDay
        }

        Haptics.success()
        dismiss()
    }

    private func remove() {
        guard let item else { return }
        Haptics.tap()
        context.delete(item)
        dismiss()
    }

    private func numberString(_ value: Double) -> String {
        let r = value.rounded()
        return abs(value - r) < 0.005 ? String(format: "%.0f", r) : String(format: "%.2f", value)
    }
}
