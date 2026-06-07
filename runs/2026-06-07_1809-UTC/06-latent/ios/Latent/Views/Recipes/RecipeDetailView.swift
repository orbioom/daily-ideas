import SwiftUI
import SwiftData
import Charts

/// Recipe detail: the base recipe parameters, a temperature-compensation mini
/// chart + table (dev time at 18/20/22/24 °C), recent sessions, and a "Develop
/// now" shortcut that opens the Develop setup prefilled with this recipe.
struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue

    @State private var editing = false
    @State private var showDevelop = false

    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    /// What-if table across a useful working range.
    private var table: [TempTimePoint] {
        DevEngine.tempTable(baseTimeSec: recipe.baseTimeSec,
                            baseTempC: recipe.baseTempC,
                            from: 18, to: 26, step: 1)
    }

    /// The four common reference temperatures highlighted in the table.
    private var keyTemps: [Double] { [18, 20, 22, 24] }

    private var sortedSessions: [DevSession] {
        recipe.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    parametersCard
                    compensationCard
                    if !recipe.agitationNote.isEmpty || !recipe.notes.isEmpty {
                        notesCard
                    }
                    sessionsCard
                    developButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(recipe.filmStock.isEmpty ? "Recipe" : recipe.filmStock)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
            }
        }
        .sheet(isPresented: $editing) {
            RecipeEditorView(recipe: recipe)
        }
        .navigationDestination(isPresented: $showDevelop) {
            DevelopSetupView(prefill: DevelopPrefill(recipe: recipe))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Recipe")
            Text(recipe.name.isEmpty ? recipe.summary : recipe.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
            Text(recipe.summary)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            HStack(spacing: 6) {
                Badge(text: "ISO \(recipe.boxISO)", color: Brand.info)
                Badge(text: "Base \(DevEngine.clock(recipe.baseTimeSec)) @ 20 °C", color: Brand.magic)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Phase plan at 20 °C, box speed")
            InfoRow(label: "Develop", value: DevEngine.clock(recipe.baseTimeSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Stop", value: DevEngine.clock(recipe.stopSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Fix", value: DevEngine.clock(recipe.fixSec), mono: true)
            Divider().overlay(Brand.hairline)
            InfoRow(label: "Wash", value: DevEngine.clock(recipe.washSec), mono: true)
        }
        .glassCard()
    }

    private var compensationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Temperature compensation")
            Text("Develop time as the chemistry temperature changes (box speed).")
                .font(.footnote)
                .foregroundStyle(Brand.text2)

            TempCompChart(points: table)
                .frame(height: 160)

            VStack(spacing: 0) {
                ForEach(keyTemps, id: \.self) { t in
                    let sec = DevEngine.adjustedDevSec(baseTimeSec: recipe.baseTimeSec,
                                                       baseTempC: recipe.baseTempC,
                                                       tempC: t, pushPull: 0)
                    HStack {
                        Text(Format.tempString(t, unit: tempUnit, decimals: 0))
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(t == recipe.baseTempC ? Brand.magic : Brand.text)
                        Spacer()
                        Text(DevEngine.clock(sec))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    .padding(.vertical, 7)
                    if t != keyTemps.last {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !recipe.agitationNote.isEmpty {
                SectionTitle(text: "Agitation")
                Text(recipe.agitationNote)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text)
            }
            if !recipe.notes.isEmpty {
                if !recipe.agitationNote.isEmpty { Divider().overlay(Brand.hairline) }
                SectionTitle(text: "Notes")
                Text(recipe.notes)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text)
            }
        }
        .glassCard()
    }

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent sessions")
            if sortedSessions.isEmpty {
                Text("No sessions developed with this recipe yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                ForEach(sortedSessions.prefix(4)) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Format.relativeDate(session.date))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text("\(Format.tempString(session.tempC, unit: tempUnit, decimals: 1)) · \(session.pushPullLabel)")
                                .font(Brand.mono(12))
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Text(DevEngine.clock(session.devSec))
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    .padding(.vertical, 4)
                    if session.id != sortedSessions.prefix(4).last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }

    private var developButton: some View {
        Button {
            Haptics.tap()
            showDevelop = true
        } label: {
            Label("Develop now", systemImage: "timer")
        }
        .buttonStyle(InkButtonStyle())
        .padding(.top, 4)
    }
}

/// A small line chart of develop time vs. temperature used in the recipe detail
/// and reference screens.
struct TempCompChart: View {
    let points: [TempTimePoint]

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Temp", point.tempC),
                y: .value("Seconds", point.devSec)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Brand.magic)

            AreaMark(
                x: .value("Temp", point.tempC),
                y: .value("Seconds", point.devSec)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Brand.magic.opacity(0.12))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 2)) { value in
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel {
                    if let t = value.as(Double.self) {
                        Text("\(Int(t))°")
                            .font(Brand.mono(10))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine().foregroundStyle(Brand.hairline)
                AxisValueLabel {
                    if let s = value.as(Int.self) {
                        Text(DevEngine.clock(s))
                            .font(Brand.mono(10))
                            .foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .accessibilityLabel("Develop time versus temperature chart")
    }
}
