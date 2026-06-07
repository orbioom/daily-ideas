import SwiftUI
import SwiftData

/// Flight detail: every recorded parameter, the predicted-vs-actual comparison,
/// and inline editing of the measured altitude and field conditions.
struct FlightDetailView: View {
    @Bindable var flight: Flight
    @Environment(\.modelContext) private var context
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue
    @State private var showingEdit = false

    private var units: LengthUnit { LengthUnit(rawValue: unitsRaw) ?? .meters }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                comparisonCard
                paramsCard
                conditionsCard
                if !flight.notes.isEmpty { notesCard }
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(flight.rocketName.isEmpty ? "Flight" : flight.rocketName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            FlightEditView(flight: flight)
        }
    }

    private var comparisonCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: "Altitude")
                    Spacer()
                    Badge(text: flight.motorDesignation, color: Brand.info)
                }
                HStack(spacing: 12) {
                    altColumn(title: "Predicted", value: flight.predictedAltitudeM, accent: Brand.text2)
                    Divider().frame(height: 48).overlay(Brand.hairline)
                    if flight.hasActual {
                        altColumn(title: "Measured", value: flight.actualAltitudeM, accent: Brand.text)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MEASURED")
                                .font(Brand.mono(10, weight: .medium))
                                .foregroundStyle(Brand.text3)
                            Text("Not recorded")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text3)
                            Button("Add measurement") { showingEdit = true }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.info)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if flight.hasActual {
                    let up = flight.altitudeDeltaM >= 0
                    let pct = flight.predictionErrorFraction.map { Format.number($0 * 100, decimals: 1) + "%" } ?? "—"
                    HStack {
                        Label(
                            "\(up ? "Flew higher" : "Flew lower") by \(Format.altitude(abs(flight.altitudeDeltaM), unit: units))",
                            systemImage: up ? "arrow.up.right" : "arrow.down.right")
                            .foregroundStyle(up ? Brand.live : Brand.warn)
                        Spacer()
                        Text("\(pct) off")
                            .font(Brand.mono(12, weight: .medium))
                            .foregroundStyle(Brand.text2)
                    }
                    .font(.footnote)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(up ? "Flew higher" : "Flew lower") by \(Format.altitude(abs(flight.altitudeDeltaM), unit: units)), \(pct) off prediction")
                }
            }
        }
    }

    private func altColumn(title: String, value: Double, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Brand.mono(10, weight: .medium))
                .foregroundStyle(Brand.text3)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Format.number(units.from(meters: value), decimals: 0))
                    .font(Brand.mono(26, weight: .bold))
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(units.symbol)
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) altitude \(Format.altitude(value, unit: units))")
    }

    private var paramsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Flight parameters")
                InfoRow(label: "Date", value: Format.date.string(from: flight.date))
                InfoRow(label: "Max velocity", value: Format.velocity(flight.maxVelocityMS, unit: units), mono: true)
                InfoRow(label: "Recommended delay", value: Format.seconds(flight.recommendedDelayS), mono: true)
                InfoRow(label: "Delay used", value: Format.seconds(flight.delayUsedS), mono: true)
                InfoRow(label: "Thrust : weight", value: Format.ratio(flight.thrustToWeight), mono: true)
                InfoRow(label: "Stability", value: Format.calibers(flight.stabilityCal), mono: true)
            }
        }
    }

    private var conditionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Conditions")
                InfoRow(label: "Recovery", value: flight.recovery.label)
                InfoRow(label: "Wind", value: "\(Format.number(flight.windKph, decimals: 0)) kph", mono: true)
            }
        }
    }

    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(text: "Notes")
                Text(flight.notes)
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
