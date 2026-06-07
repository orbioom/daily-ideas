import SwiftUI
import SwiftData

/// The Flights tab: a list of saved weight & balance plans, each with its ramp
/// weight, CG and an in/out-of-envelope badge. New-flight flow and detail nav.
struct FlightsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Flight.date, order: .reverse) private var flights: [Flight]
    @Query private var aircraft: [Aircraft]
    @AppStorage("datum.confirmDelete") private var confirmDelete = true

    @State private var startNewFlight = false
    @State private var pendingDelete: Flight?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Flights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        startNewFlight = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New flight")
                }
            }
            .navigationDestination(for: Flight.self) { flight in
                FlightDetailView(flight: flight)
            }
            .sheet(isPresented: $startNewFlight) {
                NewFlightFlow()
            }
            .confirmationDialog(
                "Delete this flight?",
                isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete flight", role: .destructive) {
                    if let f = pendingDelete { delete(f) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if flights.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "airplane",
                    title: aircraft.isEmpty ? "Add an aircraft first" : "No flights yet",
                    message: aircraft.isEmpty
                        ? "Create an aircraft profile in the Aircraft tab, then plan your first flight here."
                        : "Tap + to plan a flight: pick an aircraft, load it up, and see your weight & balance instantly."
                )
                if !aircraft.isEmpty {
                    Button {
                        Haptics.tap()
                        startNewFlight = true
                    } label: {
                        Label("New flight", systemImage: "plus")
                    }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 24)
                }
            }
        } else {
            List {
                ForEach(flights) { flight in
                    NavigationLink(value: flight) {
                        FlightRow(flight: flight, aircraft: matchingAircraft(for: flight))
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if confirmDelete { pendingDelete = flight } else { delete(flight) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func matchingAircraft(for flight: Flight) -> Aircraft? {
        aircraft.first { $0.tailNumber == flight.aircraftTail }
    }

    private func delete(_ flight: Flight) {
        Haptics.warning()
        context.delete(flight)
        try? context.save()
    }
}

/// A flight summary row with ramp weight, CG and status badge.
struct FlightRow: View {
    let flight: Flight
    let aircraft: Aircraft?

    private var result: WBEngine.FlightResult {
        WBEngine.evaluate(WBEngine.FlightInputs(flight: flight, aircraft: aircraft))
    }

    private var ramp: WBEngine.ScenarioResult? {
        result.scenarios.first { $0.scenario == .ramp }
    }

    var body: some View {
        let ok = result.allOK
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(flight.name.isEmpty ? "Untitled flight" : flight.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    Text("\(flight.aircraftTail) · \(Fmt.date(flight.date))")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(1)
                }
                Spacer()
                Badge(text: ok ? "In envelope" : "Out", color: ok ? Brand.live : Brand.danger)
            }
            HStack(spacing: 18) {
                metric("RAMP WT", ramp.map { Fmt.lb($0.point.weight) } ?? "—")
                metric("CG", ramp.map { Fmt.arm($0.point.cg) + " in" } ?? "—")
                Spacer()
            }
        }
        .glassCard()
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(flight.name), \(flight.aircraftTail), ramp weight \(ramp.map { Fmt.lb($0.point.weight) } ?? "unknown"), CG \(ramp.map { Fmt.arm($0.point.cg) } ?? "unknown") inches, \(ok ? "in envelope" : "out of envelope")")
        .accessibilityHint("Opens the full weight and balance breakdown")
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Brand.mono(9, weight: .medium))
                .foregroundStyle(Brand.text3)
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
        }
    }
}
