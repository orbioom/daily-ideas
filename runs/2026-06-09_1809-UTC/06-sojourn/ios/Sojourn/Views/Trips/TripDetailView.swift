import SwiftUI
import SwiftData

/// Edit a trip: title, optional date range, note, and its countries. Optionally
/// marks the trip's countries as visited in one tap.
struct TripDetailView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var marks: [VisitMark]

    @State private var hasStart: Bool
    @State private var hasEnd: Bool
    @State private var start: Date
    @State private var end: Date
    @State private var showPicker = false
    @State private var showDeleteConfirm = false

    /// When true this view created the trip, so Cancel should delete it.
    let isNew: Bool

    init(trip: Trip, isNew: Bool = false) {
        self.trip = trip
        self.isNew = isNew
        _hasStart = State(initialValue: trip.startDate != nil)
        _hasEnd = State(initialValue: trip.endDate != nil)
        _start = State(initialValue: trip.startDate ?? .now)
        _end = State(initialValue: trip.endDate ?? .now)
    }

    private var codesMissingVisited: [String] {
        let grounded = Set(marks.filter { $0.isGrounded }.map { $0.countryCode })
        return trip.countryCodes.filter { !grounded.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Trip title", text: $trip.title)
                    TextField("Note", text: $trip.note, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Dates") {
                    Toggle("Start date", isOn: $hasStart.animation(Brand.ease(0.25)))
                    if hasStart {
                        DatePicker("Starts", selection: $start, displayedComponents: .date)
                    }
                    Toggle("End date", isOn: $hasEnd.animation(Brand.ease(0.25)))
                    if hasEnd {
                        DatePicker("Ends", selection: $end, in: (hasStart ? start : .distantPast)..., displayedComponents: .date)
                    }
                }

                Section {
                    if trip.countryCodes.isEmpty {
                        Text("No countries yet.")
                            .foregroundStyle(Brand.text3)
                    } else {
                        ForEach(trip.countries) { country in
                            HStack(spacing: 10) {
                                Text(country.flagEmoji)
                                    .font(.system(size: 24))
                                    .accessibilityHidden(true)
                                Text(country.name).foregroundStyle(Brand.text)
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(country.name)
                        }
                        .onDelete(perform: removeCountry)
                    }
                    Button {
                        showPicker = true
                    } label: {
                        Label("Add countries", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Countries")
                } footer: {
                    if !trip.countryCodes.isEmpty {
                        Text("\(trip.countryCodes.count) \(trip.countryCodes.count == 1 ? "country" : "countries").")
                    }
                }

                if !codesMissingVisited.isEmpty {
                    Section {
                        Button {
                            markAllVisited()
                        } label: {
                            Label("Mark \(codesMissingVisited.count) as visited", systemImage: "checkmark.seal")
                        }
                    } footer: {
                        Text("Adds the countries on this trip that aren't yet on your map as visited.")
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete trip", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(trip.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                CountryPickerView(selectedCodes: $trip.countryCodes)
            }
            .confirmationDialog("Delete this trip?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete trip", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the trip. Your country marks stay on your map.")
            }
        }
    }

    // MARK: Logic

    private func removeCountry(at offsets: IndexSet) {
        var codes = trip.countryCodes
        codes.remove(atOffsets: offsets)
        trip.countryCodes = codes
        Haptics.tap()
    }

    private func markAllVisited() {
        let year = Calendar.current.component(.year, from: .now)
        let grounded = Set(marks.filter { $0.isGrounded }.map { $0.countryCode })
        let byCode = Dictionary(marks.map { ($0.countryCode, $0) }, uniquingKeysWith: { a, _ in a })
        for code in trip.countryCodes where !grounded.contains(code) {
            if let existing = byCode[code] {
                existing.status = .visited
                existing.firstVisitYear = existing.firstVisitYear ?? year
                existing.timesVisited = max(1, existing.timesVisited)
                existing.updatedAt = .now
            } else {
                let m = VisitMark(countryCode: code, status: .visited, firstVisitYear: year, timesVisited: 1)
                context.insert(m)
            }
        }
        try? context.save()
        Haptics.success()
    }

    private func save() {
        trip.startDate = hasStart ? start : nil
        trip.endDate = hasEnd ? end : nil
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        if isNew {
            context.delete(trip)
            try? context.save()
        }
        dismiss()
    }

    private func delete() {
        context.delete(trip)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
