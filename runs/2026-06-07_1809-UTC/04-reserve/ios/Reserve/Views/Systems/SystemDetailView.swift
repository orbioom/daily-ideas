import SwiftUI
import SwiftData
import Charts

/// The dashboard for a single system: headline metrics, battery/solar meters,
/// an energy-by-category donut, the inverter check, and the editable loads list.
struct SystemDetailView: View {
    @Bindable var system: PowerSystem

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showEditor = false
    @State private var loadEditorTarget: LoadEditorTarget?
    @State private var showCatalog = false
    @State private var pendingDeleteLoad: Load?
    @State private var appeared = false

    private var result: PowerResult { PowerEngine.evaluate(system) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                verdictHeader
                statGrid
                batteryCard
                solarCard
                inverterCard
                donutCard
                loadsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Brand.pageBackground)
        .navigationTitle(system.name.isEmpty ? "System" : system.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    showEditor = true
                } label: {
                    Label("Edit system", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            SystemEditorView(target: .edit(system))
        }
        .sheet(item: $loadEditorTarget) { target in
            LoadEditorView(target: target, system: system)
        }
        .sheet(isPresented: $showCatalog) {
            CatalogPickerView { appliance, qty in
                addFromCatalog(appliance, quantity: qty)
            }
        }
        .confirmationDialog(
            "Remove this load?",
            isPresented: deleteLoadBinding,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) { confirmDeleteLoad() }
            Button("Cancel", role: .cancel) { pendingDeleteLoad = nil }
        } message: {
            Text(pendingDeleteLoad?.name ?? "This load")
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : Brand.ease()) { appeared = true }
        }
    }

    // MARK: - Verdict header

    private var verdictHeader: some View {
        let verdict = SystemVerdict(result)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: "Daily balance")
                    Spacer()
                    HStack(spacing: 6) {
                        StatusDot(color: verdict.dotColor)
                        Text(verdict.title)
                            .font(Brand.mono(12, weight: .medium))
                            .foregroundStyle(verdict.color)
                    }
                }
                Text(balanceSentence)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(verdict.title). \(balanceSentence)")
    }

    private var balanceSentence: String {
        if system.solarWatts <= 0 {
            return "No solar configured. The bank alone lasts \(Fmt.days(result.daysAutonomyNoSolar)) days at this draw."
        }
        if result.isSelfSustaining {
            return "Solar covers the day with \(Fmt.signedWh(result.netDailyWh)) to spare. The bank stays topped up in good sun."
        }
        return "Solar falls short by \(Fmt.wh(abs(result.netDailyWh))) a day. With sun included, autonomy is about \(Fmt.days(result.effectiveAutonomyDays)) days."
    }

    // MARK: - Stat grid

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: Fmt.wh(result.systemDailyWh), label: "Daily energy")
            StatTile(value: Fmt.ah(result.dailyAh), label: "Daily draw")
            StatTile(value: Fmt.days(result.daysAutonomyNoSolar), label: "Autonomy · no sun", accent: autonomyColor)
            StatTile(value: Fmt.signedWh(result.netDailyWh), label: "Solar net / day", accent: result.netDailyWh >= 0 ? Brand.live : Brand.danger)
            StatTile(value: Fmt.days(result.effectiveAutonomyDays), label: "Autonomy · with sun", accent: result.isSelfSustaining ? Brand.live : Brand.warn)
            StatTile(value: Fmt.hours(result.rechargeHoursFromEmpty), label: "Recharge from empty")
        }
    }

    private var autonomyColor: Color {
        if !result.daysAutonomyNoSolar.isFinite { return Brand.live }
        if result.daysAutonomyNoSolar >= 2 { return Brand.live }
        if result.daysAutonomyNoSolar >= 1 { return Brand.warn }
        return Brand.danger
    }

    // MARK: - Battery card

    private var batteryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Usable battery")
                    Spacer()
                    Badge(text: "DoD \(Fmt.percent(result.usableDoD))", color: Brand.info)
                }
                MeterBar(fraction: appeared ? 1 : 0, color: Brand.live, height: 12)
                    .animation(reduceMotion ? nil : Brand.ease(0.6), value: appeared)
                InfoRow(label: "Usable", value: Fmt.wh(result.usableWh), mono: true)
                InfoRow(label: "Usable amp-hours", value: Fmt.ah(result.usableAh), mono: true)
                InfoRow(label: "Nameplate", value: "\(Fmt.int(system.batteryCapacityAh)) Ah · \(system.systemVoltage) V", mono: true)
            }
        }
    }

    // MARK: - Solar card

    private var solarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Solar coverage")
                    Spacer()
                    Badge(text: Fmt.percent(result.solarCoverageFraction), color: result.solarCoverageFraction >= 1 ? Brand.live : Brand.warn)
                }
                MeterBar(
                    fraction: appeared ? min(1, result.solarCoverageFraction) : 0,
                    color: result.solarCoverageFraction >= 1 ? Brand.live : Brand.warn,
                    height: 12
                )
                .animation(reduceMotion ? nil : Brand.ease(0.6), value: appeared)
                InfoRow(label: "Array", value: Fmt.watts(system.solarWatts), mono: true)
                InfoRow(label: "Daily harvest", value: Fmt.wh(result.solarHarvestWh), mono: true)
                InfoRow(label: "Peak sun", value: "\(Fmt.dec1(system.peakSunHours)) h", mono: true)
            }
        }
    }

    // MARK: - Inverter card

    @ViewBuilder private var inverterCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Inverter headroom")
                    Spacer()
                    Badge(text: result.inverterStatus.label, color: inverterColor)
                }
                switch result.inverterStatus {
                case .none:
                    Text("DC-only system — no inverter configured.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                case .noACLoads:
                    Text("Inverter rated \(Fmt.watts(system.inverterWatts)), but no AC loads draw from it yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                case .ok, .over:
                    MeterBar(
                        fraction: appeared ? result.inverterHeadroomFraction : 0,
                        color: inverterColor,
                        height: 12
                    )
                    .animation(reduceMotion ? nil : Brand.ease(0.6), value: appeared)
                    InfoRow(label: "Peak AC demand", value: Fmt.watts(result.peakACWatts), mono: true)
                    InfoRow(label: "Inverter rating", value: Fmt.watts(system.inverterWatts), mono: true)
                    if result.inverterStatus == .over {
                        Label("Peak AC exceeds the inverter. Stagger appliances or size up.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
        }
    }

    private var inverterColor: Color {
        switch result.inverterStatus {
        case .ok: return Brand.live
        case .over: return Brand.danger
        case .noACLoads: return Brand.text3
        case .none: return Brand.text3
        }
    }

    // MARK: - Donut card

    private var donutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(text: "Where the energy goes")
                if result.categoryBreakdown.isEmpty {
                    Text("Add loads to see the breakdown.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    Chart(result.categoryBreakdown) { slice in
                        SectorMark(
                            angle: .value("Energy", slice.dailyWh),
                            innerRadius: .ratio(0.62),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(slice.category.tint)
                    }
                    .frame(height: 180)
                    .chartLegend(.hidden)
                    .accessibilityLabel("Energy by category")
                    .accessibilityValue(breakdownAccessibility)

                    legend
                }
            }
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(result.categoryBreakdown) { slice in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(slice.category.tint)
                        .frame(width: 12, height: 12)
                    Text(slice.category.label)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text(Fmt.wh(slice.dailyWh))
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text2)
                    Text(Fmt.percent(shareOf(slice)))
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                        .frame(width: 42, alignment: .trailing)
                }
            }
        }
    }

    private func shareOf(_ slice: CategoryEnergy) -> Double {
        result.systemDailyWh > 0 ? slice.dailyWh / result.systemDailyWh : 0
    }

    private var breakdownAccessibility: String {
        result.categoryBreakdown
            .map { "\($0.category.label) \(Fmt.wh($0.dailyWh))" }
            .joined(separator: ", ")
    }

    // MARK: - Loads card

    private var loadsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Loads")
                    Spacer()
                    Text("\(system.loads.count)")
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }

                if system.loads.isEmpty {
                    Text("No loads yet. Add appliances to model your daily draw.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                        .padding(.vertical, 8)
                } else {
                    ForEach(sortedLoads) { load in
                        LoadRow(load: load)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptics.tap()
                                loadEditorTarget = .edit(load)
                            }
                            .contextMenu {
                                Button {
                                    Haptics.tap()
                                    loadEditorTarget = .edit(load)
                                } label: { Label("Edit", systemImage: "pencil") }
                                Button(role: .destructive) {
                                    Haptics.warning()
                                    pendingDeleteLoad = load
                                } label: { Label("Remove", systemImage: "trash") }
                            }
                        if load.id != sortedLoads.last?.id {
                            Divider().overlay(Brand.hairline)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        Haptics.tap()
                        showCatalog = true
                    } label: {
                        Label("From catalog", systemImage: "books.vertical")
                    }
                    .buttonStyle(GlassButtonStyle())

                    Button {
                        Haptics.tap()
                        loadEditorTarget = .new
                    } label: {
                        Label("Custom", systemImage: "plus")
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.top, 4)
            }
        }
    }

    private var sortedLoads: [Load] {
        system.loads.sorted { $0.dailyWh > $1.dailyWh }
    }

    // MARK: - Mutations

    private var deleteLoadBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteLoad != nil },
            set: { if !$0 { pendingDeleteLoad = nil } }
        )
    }

    private func confirmDeleteLoad() {
        guard let load = pendingDeleteLoad else { return }
        system.loads.removeAll { $0.id == load.id }
        context.delete(load)
        try? context.save()
        Haptics.success()
        pendingDeleteLoad = nil
    }

    private func addFromCatalog(_ appliance: CatalogAppliance, quantity: Int) {
        let load = appliance.makeLoad(quantity: quantity)
        load.system = system
        system.loads.append(load)
        context.insert(load)
        try? context.save()
        Haptics.success()
    }
}

/// One load row: name, watts × hours × qty, and the resulting daily Wh.
private struct LoadRow: View {
    let load: Load
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: load.category.icon)
                .font(.system(size: 16))
                .foregroundStyle(load.category.tint)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(load.name.isEmpty ? "Load" : load.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Badge(text: load.isAC ? "AC" : "DC", color: load.isAC ? Brand.danger : Brand.info)
                }
                Text("\(Fmt.int(load.watts)) W × \(Fmt.dec1(load.hoursPerDay)) h × \(load.quantity)")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(Fmt.wh(load.dailyWh))
                .font(Brand.mono(13, weight: .semibold))
                .foregroundStyle(Brand.text)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(load.name), \(load.isAC ? "AC" : "DC"), \(Fmt.wh(load.dailyWh)) per day")
    }
}
