import Foundation
import SwiftUI
import SwiftData

/// Drives the create/edit trip flow and the list generation step.
@MainActor
@Observable
final class TripFormViewModel {
    // Form fields
    var name: String = ""
    var destination: String = ""
    var startDate: Date = Calendar.current.startOfDay(for: .now)
    var endDate: Date = Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now
    var tripType: TripType = .city
    var travelerCount: Int = 1
    var selectedActivities: Set<Activity> = []
    var notes: String = ""

    // Generation state
    var isGenerating = false
    var generatedItems: [GeneratedItem] = []

    /// Set when the user is editing an existing trip.
    private(set) var editingTrip: Trip?

    init(defaultTravelers: Int = 1) {
        travelerCount = max(1, defaultTravelers)
    }

    /// Load an existing trip into the form for editing.
    func load(_ trip: Trip) {
        editingTrip = trip
        name = trip.name
        destination = trip.destination
        startDate = trip.startDate
        endDate = trip.endDate
        tripType = trip.tripType
        travelerCount = trip.travelerCount
        selectedActivities = Set(trip.activities)
        notes = trip.notes
    }

    var isEditing: Bool { editingTrip != nil }

    // MARK: Validation

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedDestination: String { destination.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isValid: Bool {
        !trimmedName.isEmpty && !trimmedDestination.isEmpty && endDate >= startDate
    }

    var validationMessage: String? {
        if trimmedName.isEmpty { return "Give your trip a name." }
        if trimmedDestination.isEmpty { return "Add a destination." }
        if endDate < startDate { return "Return date can't be before departure." }
        return nil
    }

    var nights: Int {
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: min(startDate, endDate)),
            to: cal.startOfDay(for: max(startDate, endDate))
        ).day ?? 0
        return max(1, days)
    }

    func toggleActivity(_ activity: Activity) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }

    // MARK: Generation

    /// Generates the preview list asynchronously (simulated compute for a
    /// genuine loading state) using the engine.
    func generate(style: PackingStyle) async {
        isGenerating = true
        generatedItems = []
        // Yield so the loading state can render; the work itself is instant.
        try? await Task.sleep(nanoseconds: 450_000_000)
        let items = PackingEngine.generate(
            tripType: tripType,
            nights: nights,
            travelers: travelerCount,
            activities: Array(selectedActivities),
            style: style
        )
        generatedItems = items
        isGenerating = false
    }

    var generationSummary: String {
        PackingEngine.summary(
            nights: nights,
            travelers: travelerCount,
            activityCount: selectedActivities.count
        )
    }

    // MARK: Persistence

    /// Creates a new Trip with the generated items and inserts it.
    @discardableResult
    func createTrip(in context: ModelContext) -> Trip {
        let trip = Trip(
            name: trimmedName,
            destination: trimmedDestination,
            startDate: startDate,
            endDate: endDate,
            tripType: tripType,
            travelerCount: travelerCount,
            activities: Array(selectedActivities),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(trip)
        for (idx, g) in generatedItems.enumerated() {
            let item = PackItem(
                name: g.name,
                quantity: g.quantity,
                category: g.category,
                sortOrder: idx
            )
            item.trip = trip
            trip.items.append(item)
            context.insert(item)
        }
        try? context.save()
        return trip
    }

    /// Applies edited fields to the existing trip. Does not touch items.
    func applyEdits() {
        guard let trip = editingTrip else { return }
        trip.name = trimmedName
        trip.destination = trimmedDestination
        trip.startDate = startDate
        trip.endDate = endDate
        trip.tripTypeRaw = tripType.rawValue
        trip.travelerCount = travelerCount
        trip.activityRaws = selectedActivities.map(\.rawValue)
        trip.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
