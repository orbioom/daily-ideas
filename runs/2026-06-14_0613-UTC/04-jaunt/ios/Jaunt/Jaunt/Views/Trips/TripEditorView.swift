import SwiftUI
import SwiftData

/// Add or edit a trip. Validates name + date order, then syncs TripDays.
struct TripEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// nil → creating a new trip.
    let trip: Trip?

    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var budgetText: String = ""
    @State private var currencySymbol: String = "$"
    @State private var notes: String = ""
    @State private var showValidation = false

    private var isEditing: Bool { trip != nil }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameValid: Bool { !trimmedName.isEmpty }
    private var canSave: Bool { nameValid && endDate >= startDate }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Name (e.g. Kyoto in Autumn)", text: $name)
                        .font(Theme.font(.body))
                    if showValidation && !nameValid {
                        Label("Give your trip a name", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.font(.caption))
                            .foregroundStyle(Theme.danger)
                    }
                    TextField("Destination", text: $destination)
                        .font(Theme.font(.body))
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { _, newValue in
                            if endDate < newValue { endDate = newValue }
                        }
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    Text("\(ItineraryEngine.durationDays(start: startDate, end: endDate)) day(s)")
                        .font(Theme.font(.caption))
                        .foregroundStyle(Theme.textSecondary)
                }

                Section("Budget") {
                    HStack {
                        Picker("Currency", selection: $currencySymbol) {
                            ForEach(AppSettings.currencyOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                        TextField("Amount", text: $budgetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 140)
                    }
                }

                Section("Notes") {
                    TextField("Anything to remember…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                        .font(Theme.font(.body))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let trip else {
            currencySymbol = settings.currencySymbol
            return
        }
        name = trip.name
        destination = trip.destination
        startDate = trip.startDate
        endDate = trip.endDate
        budgetText = trip.budgetAmount > 0 ? trimmedNumber(trip.budgetAmount) : ""
        currencySymbol = trip.currencyCode.isEmpty ? settings.currencySymbol : symbol(for: trip.currencyCode)
        notes = trip.notes
    }

    private func save() {
        guard canSave else {
            showValidation = true
            Haptics.warning()
            return
        }
        let budget = Double(budgetText.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let trip {
            trip.name = trimmedName
            trip.destination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
            trip.startDate = startDate
            trip.endDate = endDate
            trip.budgetAmount = max(0, budget)
            trip.currencyCode = currencySymbol
            trip.notes = notes
            TripService.syncDays(for: trip, context: context)
        } else {
            let hue = Double(abs(trimmedName.hashValue) % 1000) / 1000.0
            let newTrip = Trip(name: trimmedName,
                               destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
                               startDate: startDate,
                               endDate: endDate,
                               notes: notes,
                               budgetAmount: max(0, budget),
                               currencyCode: currencySymbol,
                               coverHue: hue)
            context.insert(newTrip)
            TripService.syncDays(for: newTrip, context: context)
        }
        Haptics.success()
        dismiss()
    }

    private func trimmedNumber(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.005 { return String(format: "%.0f", rounded) }
        return String(format: "%.2f", value)
    }

    /// We store the chosen symbol directly in currencyCode for simplicity.
    private func symbol(for code: String) -> String {
        if AppSettings.currencyOptions.contains(code) { return code }
        return settings.currencySymbol
    }
}
