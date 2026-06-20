import SwiftUI
import SwiftData

struct AddEditTripView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let trip: CampTrip?

    @State private var name = ""
    @State private var campsite = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 2)
    @State private var campType: CampType = .car
    @State private var status: TripStatus = .planned
    @State private var rating = 0
    @State private var notes = ""

    private var isEditing: Bool { trip != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Info") {
                    TextField("Trip Name", text: $name)
                        .accessibilityLabel("Trip name")
                    TextField("Campsite / Park", text: $campsite)
                        .accessibilityLabel("Campsite name")
                    TextField("Location / State", text: $location)
                        .accessibilityLabel("Location")
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        .accessibilityLabel("Start date")
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .accessibilityLabel("End date")
                }

                Section("Details") {
                    Picker("Camp Type", selection: $campType) {
                        ForEach(CampType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .accessibilityLabel("Camp type")

                    Picker("Status", selection: $status) {
                        ForEach(TripStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    .accessibilityLabel("Trip status")
                }

                if isEditing {
                    Section("Rating") {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Button(action: { rating = (rating == i ? 0 : i) }) {
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                }
                                .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                            }
                            Spacer()
                            if rating > 0 {
                                Text("\(rating)/5")
                                    .font(.caption)
                                    .foregroundColor(CampfireTheme.secondaryLabel)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Trip notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let t = trip else { return }
        name = t.name
        campsite = t.campsite
        location = t.location
        startDate = t.startDate
        endDate = t.endDate
        campType = t.campType
        status = t.status
        rating = t.rating
        notes = t.notes
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let t = trip {
            t.name = trimmed
            t.campsite = campsite
            t.location = location
            t.startDate = startDate
            t.endDate = endDate
            t.campType = campType
            t.status = status
            t.rating = rating
            t.notes = notes
        } else {
            let t = CampTrip(name: trimmed, startDate: startDate, endDate: endDate)
            t.campsite = campsite
            t.location = location
            t.campType = campType
            t.status = status
            t.notes = notes
            context.insert(t)
        }
        try? context.save()
        dismiss()
    }
}
