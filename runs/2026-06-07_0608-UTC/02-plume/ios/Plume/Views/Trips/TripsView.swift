import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]
    @AppStorage("plume.confirmDeletes") private var confirmDeletes = true
    @State private var showingEditor = false
    @State private var pendingDelete: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "map", title: "No trips yet",
                                       message: "Create an outing to group the birds you see in one place.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(trips) { t in
                                NavigationLink { TripDetailView(trip: t) } label: { TripRow(trip: t) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if confirmDeletes { pendingDelete = t } else { delete(t) }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add trip")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { TripEditView(existing: nil) }
            .confirmationDialog("Delete this trip? Its sightings are kept.", isPresented: Binding(
                get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let t = pendingDelete { delete(t) }; pendingDelete = nil }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    private func delete(_ t: Trip) { context.delete(t); try? context.save(); Haptics.warning() }
}

private struct TripRow: View {
    let trip: Trip
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name).font(.headline).foregroundStyle(Brand.text)
                    Text("\(trip.location.isEmpty ? "—" : trip.location) · \(trip.date.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(trip.speciesCount)").font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("species").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            HStack(spacing: 8) {
                Badge(text: "\(trip.individuals) birds")
                Badge(text: "\(trip.sightings.count) records")
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(trip.speciesCount) species")
    }
}

struct TripEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Trip?
    @State private var name = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Trip name", text: $name).font(.headline).foregroundStyle(Brand.text)
                        Divider().overlay(Brand.hairline)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .tint(Brand.text).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        TextField("Location", text: $location).foregroundStyle(Brand.text2)
                    }
                    .font(.subheadline).glassCard()
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Notes")
                        TextField("Conditions, companions…", text: $notes, axis: .vertical)
                            .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
                    }
                    .glassCard()
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let e = existing { name = e.name; date = e.date; location = e.location; notes = e.notes }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let t: Trip
        if let existing { t = existing } else {
            t = Trip(name: trimmed, date: date, location: location, notes: notes); context.insert(t)
        }
        t.name = trimmed; t.date = date; t.location = location; t.notes = notes
        try? context.save(); Haptics.success(); dismiss()
    }
}
