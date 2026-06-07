import SwiftUI
import SwiftData

/// The Flights tab: a newest-first logbook with an insight header showing the
/// average prediction error across flights that have a measured altitude.
struct FlightsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Flight.date, order: .reverse) private var flights: [Flight]
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue

    private var units: LengthUnit { LengthUnit(rawValue: unitsRaw) ?? .meters }

    /// Flights that have a measured altitude recorded.
    private var withActual: [Flight] { flights.filter { $0.hasActual } }

    /// Mean absolute prediction error as a percentage, if any data exists.
    private var avgErrorPercent: Double? {
        let errors = withActual.compactMap { $0.predictionErrorFraction }
        guard !errors.isEmpty else { return nil }
        return errors.reduce(0, +) / Double(errors.count) * 100
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Flights")
        }
    }

    @ViewBuilder private var content: some View {
        if flights.isEmpty {
            EmptyStateView(
                icon: "list.bullet.clipboard",
                title: "No flights logged",
                message: "Open a rocket, run the simulator and tap “Log this flight” to start your logbook.")
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    insightCard
                    ForEach(flights) { flight in
                        NavigationLink {
                            FlightDetailView(flight: flight)
                        } label: {
                            FlightRow(flight: flight, units: units)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(flight)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var insightCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Logbook")
                    Text("\(flights.count) flight\(flights.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    if let avg = avgErrorPercent {
                        Text("Avg prediction error \(Format.number(avg, decimals: 1))% over \(withActual.count) measured")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text2)
                    } else {
                        Text("Record measured altitudes to see your prediction accuracy.")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if let avg = avgErrorPercent {
                    StatusDot(color: avg < 10 ? Brand.live : (avg < 20 ? Brand.warn : Brand.danger))
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func delete(_ flight: Flight) {
        Haptics.warning()
        withAnimation(Brand.ease()) {
            context.delete(flight)
            try? context.save()
        }
    }
}

private struct FlightRow: View {
    let flight: Flight
    let units: LengthUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: flight.recovery.icon)
                .font(.title3)
                .foregroundStyle(Brand.text2)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(flight.rocketName.isEmpty ? "Rocket" : flight.rocketName)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text("\(flight.motorDesignation) · \(Format.date.string(from: flight.date))")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Format.altitude(flight.predictedAltitudeM, unit: units))
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text)
                if flight.hasActual {
                    let up = flight.altitudeDeltaM >= 0
                    Text("\(up ? "▲" : "▼") \(Format.altitude(abs(flight.altitudeDeltaM), unit: units))")
                        .font(Brand.mono(10, weight: .medium))
                        .foregroundStyle(up ? Brand.live : Brand.warn)
                } else {
                    Text("predicted")
                        .font(Brand.mono(9))
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var s = "\(flight.rocketName) on \(flight.motorDesignation), \(Format.date.string(from: flight.date)). Predicted \(Format.altitude(flight.predictedAltitudeM, unit: units))."
        if flight.hasActual {
            s += " Measured \(Format.altitude(flight.actualAltitudeM, unit: units))."
        }
        return s
    }
}
