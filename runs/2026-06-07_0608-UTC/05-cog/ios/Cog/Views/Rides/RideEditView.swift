import SwiftUI
import SwiftData

/// Logs or edits a ride. New rides add their distance to the bike's odometer;
/// edits adjust the odometer by the delta so totals stay consistent.
struct RideEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cog.miles") private var miles = false
    let bike: Bike
    let existing: Ride?

    @State private var date = Date()
    @State private var distance = 0.0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Distance (\(Units.label(miles: miles)))").foregroundStyle(Brand.text2)
                            Spacer()
                            TextField("0", value: $distance, format: .number).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).font(Brand.mono(20, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 110)
                        }
                        Divider().overlay(Brand.hairline)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .tint(Brand.text).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        TextField("Note (route, weather…)", text: $note).foregroundStyle(Brand.text)
                    }
                    .font(.subheadline).glassCard()
                    Text("Logging a ride for \(bike.name) updates its odometer and every component's wear.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }.padding()
            }
            .navigationTitle(existing == nil ? "Log Ride" : "Edit Ride")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(distance <= 0)
                }
            }
            .onAppear {
                if let r = existing { date = r.date; distance = Units.kmTo(r.distanceKm, miles: miles); note = r.note }
            }
        }
    }

    private func save() {
        let newKm = Units.toKm(max(0, distance), miles: miles)
        if let r = existing {
            let delta = newKm - r.distanceKm
            r.date = date; r.distanceKm = newKm; r.note = note
            bike.odometerKm = max(0, bike.odometerKm + delta)
        } else {
            let r = Ride(date: date, distanceKm: newKm, note: note)
            r.bike = bike
            context.insert(r)
            bike.odometerKm += newKm
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
