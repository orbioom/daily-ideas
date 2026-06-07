import SwiftUI
import SwiftData
import Charts

/// Rocket detail: stability read-out with a CG/CP diagram, the airframe specs,
/// an inline flight Simulator (pick a motor, run, see results + altitude chart,
/// and log the flight), and recent flights for this rocket.
struct RocketDetailView: View {
    @Bindable var rocket: Rocket
    @Environment(\.modelContext) private var context
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue

    @Query(sort: \Motor.totalImpulseNs) private var motors: [Motor]
    @Query(sort: \Flight.date, order: .reverse) private var allFlights: [Flight]

    @State private var selectedMotorID: UUID?
    @State private var result: FlightResult?
    @State private var isComputing = false
    @State private var simError: String?
    @State private var didLog = false
    @State private var showingEdit = false

    private var units: LengthUnit { LengthUnit(rawValue: unitsRaw) ?? .meters }

    private var selectedMotor: Motor? {
        motors.first { $0.id == selectedMotorID }
    }

    /// Flights logged for this rocket, newest first.
    private var rocketFlights: [Flight] {
        allFlights.filter { $0.rocket?.id == rocket.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                stabilityCard
                specsCard
                simulatorCard
                if !rocketFlights.isEmpty { recentFlightsCard }
            }
            .padding(16)
        }
        .background(Brand.pageBackground)
        .navigationTitle(rocket.name.isEmpty ? "Rocket" : rocket.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RocketEditView(rocket: rocket)
        }
        .onAppear {
            if selectedMotorID == nil { selectedMotorID = defaultMotor()?.id }
        }
    }

    // MARK: - Stability

    private var stabilityCard: some View {
        let status = rocket.stability
        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: "Stability")
                    Spacer()
                    Badge(text: status.label, color: status.color)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Format.number(rocket.stabilityCal, decimals: 2))
                        .font(Brand.mono(40, weight: .bold))
                        .foregroundStyle(status.color)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("cal")
                        .font(Brand.mono(18, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Stability margin \(Format.calibers(rocket.stabilityCal)), \(status.label)")

                CGCPDiagram(lengthMm: rocket.lengthMm,
                            cgFromNoseMm: rocket.cgFromNoseMm,
                            cpFromNoseMm: rocket.cpFromNoseMm,
                            statusColor: status.color)

                Text(status.advice)
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Specs

    private var specsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Airframe")
                InfoRow(label: "Diameter", value: Format.mm(rocket.diameterMm), mono: true)
                InfoRow(label: "Dry mass", value: Format.grams(rocket.massGramsDry), mono: true)
                InfoRow(label: "Length", value: Format.mm(rocket.lengthMm), mono: true)
                InfoRow(label: "Drag (Cd)", value: Format.number(rocket.cd, decimals: 2), mono: true)
                InfoRow(label: "CG / CP", value: "\(Format.mm(rocket.cgFromNoseMm)) / \(Format.mm(rocket.cpFromNoseMm))", mono: true)
                if !rocket.notes.isEmpty {
                    Divider().overlay(Brand.hairline)
                    Text(rocket.notes)
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Simulator

    private var simulatorCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Eyebrow(text: "Simulator")
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }

                if motors.isEmpty {
                    Text("No motors in the catalog. Add one from the Motors tab.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                } else {
                    motorPicker

                    Button {
                        runSimulation()
                    } label: {
                        if isComputing {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Computing…")
                            }
                        } else {
                            Text("Run simulation")
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                    .disabled(isComputing || selectedMotor == nil)

                    if let simError {
                        Label(simError, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Brand.danger)
                    }

                    if let result, let motor = selectedMotor {
                        resultsView(result, motor: motor)
                    } else if !isComputing {
                        Text("Pick a motor and run the simulation to predict altitude, speed and the ideal ejection delay.")
                            .font(.footnote)
                            .foregroundStyle(Brand.text2)
                    }
                }
            }
        }
    }

    private var motorPicker: some View {
        Menu {
            ForEach(motors) { motor in
                Button {
                    Haptics.selection()
                    selectedMotorID = motor.id
                    result = nil
                    didLog = false
                } label: {
                    Text("\(motor.designation) · \(motor.manufacturer)")
                }
            }
        } label: {
            HStack {
                Text("Motor")
                    .foregroundStyle(Brand.text2)
                Spacer()
                Text(selectedMotor.map { "\($0.designation) · \($0.manufacturer)" } ?? "Select")
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
        }
        .accessibilityLabel("Motor selection")
        .accessibilityValue(selectedMotor?.designation ?? "None")
    }

    @ViewBuilder
    private func resultsView(_ r: FlightResult, motor: Motor) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Big apogee number.
            VStack(alignment: .leading, spacing: 2) {
                Text("Predicted apogee")
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(Brand.text3)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(Format.number(units.from(meters: r.apogeeM), decimals: 0))
                        .font(Brand.mono(38, weight: .bold))
                        .foregroundStyle(Brand.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(units.symbol)
                        .font(Brand.mono(18, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Predicted apogee \(Format.altitude(r.apogeeM, unit: units))")

            // Stat grid.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatTile(value: Format.velocity(r.maxVelocityMS, unit: units), label: "Max speed")
                StatTile(value: Format.seconds(r.timeToApogeeS), label: "To apogee")
                StatTile(value: delayText(r), label: "Eject delay")
                StatTile(value: Format.ratio(r.thrustToWeight), label: "Thrust:weight",
                         accent: r.thrustToWeightIsLow ? Brand.warn : Brand.text)
            }

            if r.thrustToWeightIsLow {
                Label("Thrust-to-weight is below 5:1 — the rocket may leave the rod too slowly. Consider a punchier motor.",
                      systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AltitudeChart(result: r, units: units)
                .frame(height: 200)

            // Log this flight.
            Button {
                logFlight(r, motor: motor)
            } label: {
                Label(didLog ? "Logged" : "Log this flight",
                      systemImage: didLog ? "checkmark.circle.fill" : "plus.circle")
            }
            .buttonStyle(GlassButtonStyle())
            .disabled(didLog)
        }
        .padding(.top, 2)
    }

    private func delayText(_ r: FlightResult) -> String {
        if let nearest = r.nearestAvailableDelayS {
            return "\(Format.number(nearest, decimals: 0)) s"
        }
        return Format.seconds(r.recommendedDelayS)
    }

    // MARK: - Recent flights

    private var recentFlightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Recent flights")
                ForEach(rocketFlights.prefix(4)) { flight in
                    NavigationLink {
                        FlightDetailView(flight: flight)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(flight.motorDesignation)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.text)
                                Text(Format.date.string(from: flight.date))
                                    .font(Brand.mono(11))
                                    .foregroundStyle(Brand.text3)
                            }
                            Spacer()
                            Text(Format.altitude(flight.hasActual ? flight.actualAltitudeM : flight.predictedAltitudeM, unit: units))
                                .font(Brand.mono(13, weight: .medium))
                                .foregroundStyle(Brand.text2)
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.text3)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    if flight.id != rocketFlights.prefix(4).last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    /// Pick a sensible default motor: the largest that fits the body diameter.
    private func defaultMotor() -> Motor? {
        let fitting = motors.filter { $0.diameterMm <= rocket.diameterMm + 0.5 }
        return (fitting.isEmpty ? motors : fitting).max { $0.totalImpulseNs < $1.totalImpulseNs }
    }

    /// Run the simulation off the main actor's critical path with a brief
    /// computing state, then publish the result on the main actor.
    private func runSimulation() {
        guard let motor = selectedMotor else { return }
        guard rocket.diameterMm > 0, rocket.massGramsDry > 0 else {
            simError = "This rocket needs a positive diameter and mass before it can be simulated."
            return
        }
        simError = nil
        didLog = false
        isComputing = true
        Haptics.tap()
        // Snapshot the values needed by the pure engine on the main actor so the
        // detached compute never touches the SwiftData models off their context.
        let input = FlightEngine.Input(rocket: rocket, motor: motor)
        Task { @MainActor in
            // Small delay so the computing state is visible even though the sim
            // itself is fast; keeps the UI honest about the work happening.
            try? await Task.sleep(nanoseconds: 350_000_000)
            let r = await Task.detached(priority: .userInitiated) {
                FlightEngine.simulate(input)
            }.value
            result = r
            isComputing = false
            if r.apogeeM <= 0 {
                simError = "The simulation produced no altitude — check the rocket's mass and the motor's burn time."
            } else {
                Haptics.success()
            }
        }
    }

    private func logFlight(_ r: FlightResult, motor: Motor) {
        Haptics.success()
        let flight = Flight(
            date: Date(),
            rocketName: rocket.name,
            motorDesignation: motor.designation,
            predictedAltitudeM: r.apogeeM,
            actualAltitudeM: 0,
            maxVelocityMS: r.maxVelocityMS,
            recommendedDelayS: r.recommendedDelayS,
            delayUsedS: r.nearestAvailableDelayS ?? r.recommendedDelayS,
            thrustToWeight: r.thrustToWeight,
            stabilityCal: rocket.stabilityCal,
            recoveryRaw: Recovery.parachute.rawValue,
            windKph: 0,
            notes: "",
            rocket: rocket)
        context.insert(flight)
        try? context.save()
        withAnimation(Brand.ease()) { didLog = true }
    }
}

/// Altitude-vs-time chart with burnout and apogee marked.
private struct AltitudeChart: View {
    let result: FlightResult
    let units: LengthUnit
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var apogeePoint: TrajectoryPoint? {
        result.trajectory.max { $0.altitude < $1.altitude }
    }

    var body: some View {
        Chart {
            ForEach(result.trajectory) { p in
                LineMark(
                    x: .value("Time", p.t),
                    y: .value("Altitude", units.from(meters: p.altitude))
                )
                .foregroundStyle(Brand.info)
                .interpolationMethod(.catmullRom)
            }

            // Burnout marker.
            RuleMark(x: .value("Burnout", burnoutTime))
                .foregroundStyle(Brand.warn.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Burnout")
                        .font(Brand.mono(9, weight: .medium))
                        .foregroundStyle(Brand.warn)
                }

            // Apogee point.
            if let ap = apogeePoint {
                PointMark(
                    x: .value("Time", ap.t),
                    y: .value("Altitude", units.from(meters: ap.altitude))
                )
                .foregroundStyle(Brand.magic)
                .symbolSize(80)
                .annotation(position: .top) {
                    Text("Apogee")
                        .font(Brand.mono(9, weight: .medium))
                        .foregroundStyle(Brand.magic)
                }
            }
        }
        .chartXAxisLabel("Time (s)")
        .chartYAxisLabel("Altitude (\(units.symbol))")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel().font(Brand.mono(9))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel().font(Brand.mono(9))
            }
        }
        .animation(reduceMotion ? nil : Brand.ease(), value: result.apogeeM)
        .accessibilityElement()
        .accessibilityLabel("Altitude over time chart")
        .accessibilityValue("Peak altitude \(Format.altitude(result.apogeeM, unit: units)) reached at \(Format.seconds(result.timeToApogeeS)). Burnout at \(Format.seconds(burnoutTime)).")
    }

    /// Approximate burnout time = time to apogee minus recommended delay.
    private var burnoutTime: Double {
        max(0, result.timeToApogeeS - result.recommendedDelayS)
    }
}
