import SwiftUI
import SwiftData

/// The centerpiece: a full weight & balance breakdown for one saved flight — the
/// four scenarios, allowable CG range, loadings breakdown, and the CG envelope
/// chart with the scenario points plotted and colored by status.
struct FlightDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var flight: Flight
    @Query private var aircraft: [Aircraft]
    @AppStorage("datum.confirmDelete") private var confirmDelete = true

    @State private var isComputing = true
    @State private var result: WBEngine.FlightResult?
    @State private var editing = false
    @State private var showDelete = false

    private var matchingAircraft: Aircraft? {
        aircraft.first { $0.tailNumber == flight.aircraftTail }
    }

    private var inputs: WBEngine.FlightInputs {
        WBEngine.FlightInputs(flight: flight, aircraft: matchingAircraft)
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            if isComputing {
                loadingView
            } else if let result {
                ScrollView {
                    VStack(spacing: 16) {
                        headerCard(result)
                        scenarioTable(result)
                        cgRangeCard(result)
                        chartCard(result)
                        breakdownCard(result)
                        if !flight.notes.isEmpty { notesCard }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle(flight.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editing = true } label: { Label("Edit flight", systemImage: "pencil") }
                    Button(role: .destructive) {
                        if confirmDelete { showDelete = true } else { performDelete() }
                    } label: {
                        Label("Delete flight", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Flight actions")
            }
        }
        .sheet(isPresented: $editing) {
            FlightEditView(flight: flight, aircraft: matchingAircraft) { recompute() }
        }
        .confirmationDialog("Delete this flight?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete flight", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        }
        .task(id: flight.id) { recompute() }
    }

    // MARK: - Compute

    private func recompute() {
        isComputing = true
        // The math is light but this models a loading state and keeps the first
        // frame snappy; respects Reduce Motion by skipping the fade if needed.
        let computed = WBEngine.evaluate(inputs)
        DispatchQueue.main.async {
            withAnimation(Brand.ease(0.25)) {
                result = computed
                isComputing = false
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Computing weight & balance…")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Computing weight and balance")
    }

    // MARK: - Cards

    private func headerCard(_ result: WBEngine.FlightResult) -> some View {
        let ok = result.allOK
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "\(flight.aircraftTail) · \(flight.aircraftModel)")
                Spacer()
                Badge(text: ok ? "In envelope" : "Out", color: ok ? Brand.live : Brand.danger)
            }
            HStack(spacing: 10) {
                StatTile(value: rampWeightString(result), label: "Ramp lb")
                StatTile(value: rampCGString(result), label: "CG in")
                StatTile(value: Fmt.gal(flight.fuelGal), label: "Fuel", accent: Brand.info)
            }
            HStack(spacing: 8) {
                StatusDot(color: ok ? Brand.live : Brand.danger)
                Text(statusSummary(result))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ok ? Brand.live : Brand.danger)
            }
        }
        .glassCard()
    }

    private func scenarioTable(_ result: WBEngine.FlightResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Scenarios")
            VStack(spacing: 0) {
                HStack {
                    Text("PHASE").frame(maxWidth: .infinity, alignment: .leading)
                    Text("WEIGHT").frame(width: 80, alignment: .trailing)
                    Text("CG").frame(width: 56, alignment: .trailing)
                    Text("").frame(width: 30)
                }
                .font(Brand.mono(9, weight: .medium))
                .foregroundStyle(Brand.text3)
                .padding(.bottom, 6)

                ForEach(result.scenarios) { s in
                    Divider().background(Brand.hairline)
                    HStack {
                        Text(s.scenario.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(Fmt.weight(s.point.weight))
                            .font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(s.withinWeightLimit ? Brand.text : Brand.danger)
                            .frame(width: 80, alignment: .trailing)
                        Text(Fmt.arm(s.point.cg))
                            .font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(Brand.text)
                            .frame(width: 56, alignment: .trailing)
                        Image(systemName: s.isOK ? "checkmark.circle.fill" : "xmark.octagon.fill")
                            .foregroundStyle(s.isOK ? Brand.live : Brand.danger)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(s.scenario.rawValue): \(Fmt.lb(s.point.weight)), CG \(Fmt.arm(s.point.cg)) inches, \(s.isOK ? "OK" : (s.withinWeightLimit ? "out of envelope" : "over weight limit"))")
                }
            }
        }
        .glassCard()
    }

    private func cgRangeCard(_ result: WBEngine.FlightResult) -> some View {
        Group {
            if let range = result.allowableCGRange,
               let takeoff = result.scenarios.first(where: { $0.scenario == .takeoff }) {
                let span = max(0.0001, range.upperBound - range.lowerBound)
                let fraction = (takeoff.point.cg - range.lowerBound) / span
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Allowable CG at takeoff weight")
                    HStack {
                        Text("\(Fmt.arm(range.lowerBound)) in")
                            .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("CG \(Fmt.arm(takeoff.point.cg)) in")
                            .font(Brand.mono(13, weight: .semibold))
                            .foregroundStyle(takeoff.isOK ? Brand.text : Brand.danger)
                        Spacer()
                        Text("\(Fmt.arm(range.upperBound)) in")
                            .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text2)
                    }
                    MeterBar(fraction: fraction, color: takeoff.isOK ? Brand.live : Brand.danger, height: 10)
                    Text("Forward and aft CG limits at \(Fmt.lb(takeoff.point.weight)).")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .glassCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Allowable CG range at takeoff: \(Fmt.arm(range.lowerBound)) to \(Fmt.arm(range.upperBound)) inches. Current takeoff CG \(Fmt.arm(takeoff.point.cg)) inches.")
            }
        }
    }

    private func chartCard(_ result: WBEngine.FlightResult) -> some View {
        let pts = result.scenarios.map {
            ChartScenarioPoint(label: $0.scenario.rawValue, cg: $0.point.cg, weight: $0.point.weight, isOK: $0.isOK)
        }
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "CG envelope")
            EnvelopeChart(
                envelope: flight.envelopeVertices,
                points: pts,
                height: 300,
                accessibilitySummary: chartSummary(result)
            )
            legend
        }
        .glassCard()
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: Brand.info, label: "Envelope")
            legendItem(color: Brand.live, label: "In")
            legendItem(color: Brand.danger, label: "Out")
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text2)
        }
    }

    private func breakdownCard(_ result: WBEngine.FlightResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Loadings (ramp)")
            VStack(spacing: 0) {
                HStack {
                    Text("ITEM").frame(maxWidth: .infinity, alignment: .leading)
                    Text("WT").frame(width: 60, alignment: .trailing)
                    Text("ARM").frame(width: 48, alignment: .trailing)
                    Text("MOMENT").frame(width: 80, alignment: .trailing)
                }
                .font(Brand.mono(9, weight: .medium))
                .foregroundStyle(Brand.text3)
                .padding(.bottom, 6)
                ForEach(result.items) { item in
                    Divider().background(Brand.hairline)
                    HStack {
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(Fmt.weight(item.weight))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                            .frame(width: 60, alignment: .trailing)
                        Text(Fmt.arm(item.arm))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                            .frame(width: 48, alignment: .trailing)
                        Text(Fmt.weight(item.moment))
                            .font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 7)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.label): \(Fmt.lb(item.weight)) at arm \(Fmt.arm(item.arm)) inches, moment \(Fmt.weight(item.moment))")
                }
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            Text(flight.notes)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
    }

    // MARK: - Strings

    private func rampWeightString(_ r: WBEngine.FlightResult) -> String {
        r.scenarios.first { $0.scenario == .ramp }.map { Fmt.weight($0.point.weight) } ?? "—"
    }
    private func rampCGString(_ r: WBEngine.FlightResult) -> String {
        r.scenarios.first { $0.scenario == .ramp }.map { Fmt.arm($0.point.cg) } ?? "—"
    }

    private func statusSummary(_ r: WBEngine.FlightResult) -> String {
        if r.allOK { return "Within envelope and weight limits in every phase." }
        let failing = r.scenarios.filter { !$0.isOK }.map { $0.scenario.rawValue }
        return "Check \(failing.joined(separator: ", ")) — out of envelope or over limit."
    }

    private func chartSummary(_ r: WBEngine.FlightResult) -> String {
        let phases = r.scenarios.map { "\($0.scenario.rawValue) \(Fmt.arm($0.point.cg)) inches at \(Fmt.weight($0.point.weight)) pounds, \($0.isOK ? "in" : "out")" }
        return "Envelope with \(r.scenarios.count) plotted points. " + phases.joined(separator: ". ") + "."
    }

    private func performDelete() {
        Haptics.warning()
        context.delete(flight)
        try? context.save()
        dismiss()
    }
}
