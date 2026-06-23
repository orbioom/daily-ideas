import SwiftUI
import SwiftData

/// Edit an existing trip's metadata (does not regenerate items).
struct EditTripSheet: View {
    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var destination: String
    @State private var start: Date
    @State private var end: Date
    @State private var type: TripType
    @State private var travelers: Int
    @State private var selected: Set<Activity>
    @State private var notes: String

    init(trip: Trip) {
        self.trip = trip
        _name = State(initialValue: trip.name)
        _destination = State(initialValue: trip.destination)
        _start = State(initialValue: trip.startDate)
        _end = State(initialValue: trip.endDate)
        _type = State(initialValue: trip.tripType)
        _travelers = State(initialValue: trip.travelerCount)
        _selected = State(initialValue: Set(trip.activities))
        _notes = State(initialValue: trip.notes)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDest: String { destination.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty && !trimmedDest.isEmpty && end >= start }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Trip name", text: $name)
                    TextField("Destination", text: $destination)
                }
                Section("Dates") {
                    DatePicker("Departure", selection: $start, displayedComponents: .date)
                    DatePicker("Return", selection: $end, in: start..., displayedComponents: .date)
                }
                Section("Trip type") {
                    Picker("Type", selection: $type) {
                        ForEach(TripType.allCases) { t in
                            Label(t.title, systemImage: t.symbol).tag(t)
                        }
                    }
                }
                Section("Travelers") {
                    Stepper(value: $travelers, in: 1...12) {
                        Text("\(travelers) traveler\(travelers == 1 ? "" : "s")")
                    }
                }
                Section("Activities") {
                    ForEach(Activity.allCases) { activity in
                        Button {
                            if selected.contains(activity) { selected.remove(activity) }
                            else { selected.insert(activity) }
                        } label: {
                            HStack {
                                Label(activity.title, systemImage: activity.symbol)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if selected.contains(activity) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        trip.name = trimmedName
        trip.destination = trimmedDest
        trip.startDate = start
        trip.endDate = end
        trip.tripTypeRaw = type.rawValue
        trip.travelerCount = max(1, travelers)
        trip.activityRaws = selected.map(\.rawValue)
        trip.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }
}
