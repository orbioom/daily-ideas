import SwiftUI
import SwiftData

/// Create or edit a session's date, location, duration, and notes. On cancel of a
/// brand-new session, the inserted record is removed so we never persist an empty stub.
struct SessionEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Location.name) private var locations: [Location]

    @Bindable var session: Session
    var isNew: Bool

    @State private var date: Date
    @State private var locationID: UUID?
    @State private var hours: Int
    @State private var minutes: Int
    @State private var notes: String
    @State private var showingNewLocation = false

    init(session: Session, isNew: Bool) {
        self.session = session
        self.isNew = isNew
        _date = State(initialValue: session.date)
        _locationID = State(initialValue: session.location?.id)
        _hours = State(initialValue: session.durationMinutes / 60)
        _minutes = State(initialValue: session.durationMinutes % 60)
        _notes = State(initialValue: session.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Where") {
                    Picker("Location", selection: $locationID) {
                        Text("None").tag(UUID?.none)
                        ForEach(locations) { location in
                            Text(location.name).tag(UUID?.some(location.id))
                        }
                    }
                    Button {
                        showingNewLocation = true
                    } label: {
                        Label("Add location", systemImage: "plus.circle")
                    }
                }

                Section("Duration") {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<13, id: \.self) { Text("\($0) h").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        Picker("Minutes", selection: $minutes) {
                            ForEach([0, 15, 30, 45], id: \.self) { Text("\($0) m").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 110)
                }

                Section("Notes") {
                    TextField("How did it feel?", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Session" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingNewLocation) {
                LocationEditView { newLocation in
                    locationID = newLocation.id
                }
            }
        }
    }

    private func save() {
        session.date = date
        session.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        session.durationMinutes = max(0, hours * 60 + minutes)
        session.location = locations.first { $0.id == locationID }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func cancel() {
        // Discard a freshly-created empty session so we never leave a stub behind.
        if isNew && session.attempts.isEmpty {
            context.delete(session)
        }
        dismiss()
    }
}
