import SwiftUI
import SwiftData
import Charts

/// The Reference tab: a temperature-compensation explainer with a chart, the
/// push/pull factor guide, and the embedded film catalog. Each catalog entry can
/// become a saved recipe with one tap.
struct ReferenceView: View {
    @Environment(\.modelContext) private var context
    @Query private var recipes: [Recipe]

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue
    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    @State private var addedRefID: UUID?

    /// A representative curve (a 10-minute base time) for the explainer chart.
    private var sampleCurve: [TempTimePoint] {
        DevEngine.tempTable(baseTimeSec: 600, baseTempC: 20, from: 16, to: 28, step: 1)
    }

    private let pushAnchors: [(Int, Double)] = [
        (-2, 0.72), (-1, 0.85), (0, 1.0), (1, 1.25), (2, 1.5), (3, 2.0)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        tempExplainer
                        pushGuide
                        catalogSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Reference")
        }
    }

    // MARK: - Temperature explainer

    private var tempExplainer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Time & temperature")
            Text("Warmer chemistry develops faster")
                .font(.headline)
                .foregroundStyle(Brand.text)
            Text("Latent uses an exponential model of about −8 % development time per degree warmer (and +8 % per degree cooler) relative to your recipe's base temperature. The curve below is for a 10:00 base time at 20 °C.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .fixedSize(horizontal: false, vertical: true)

            TempCompChart(points: sampleCurve)
                .frame(height: 180)

            HStack(spacing: 10) {
                StatTile(value: DevEngine.clock(DevEngine.adjustedDevSec(baseTimeSec: 600, baseTempC: 20, tempC: 18, pushPull: 0)),
                         label: "@ 18°", accent: Brand.info)
                StatTile(value: "10:00", label: "@ 20°", accent: Brand.magic)
                StatTile(value: DevEngine.clock(DevEngine.adjustedDevSec(baseTimeSec: 600, baseTempC: 20, tempC: 24, pushPull: 0)),
                         label: "@ 24°", accent: Brand.warn)
            }
        }
        .glassCard()
    }

    // MARK: - Push / pull guide

    private var pushGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Push & pull")
            Text("Development factor by stops")
                .font(.headline)
                .foregroundStyle(Brand.text)
            Text("Pushing (rating film faster) extends development; pulling shortens it. These factors multiply the temperature-compensated develop time.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(pushAnchors, id: \.0) { stop, factor in
                    HStack {
                        Text(label(forStops: stop))
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(stop == 0 ? Brand.magic : Brand.text)
                        Spacer()
                        Text(String(format: "×%.2f", factor))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    .padding(.vertical, 7)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(label(forStops: stop)): factor \(String(format: "%.2f", factor))")
                    if stop != pushAnchors.last?.0 {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }

    private func label(forStops stop: Int) -> String {
        if stop == 0 { return "Box speed (0)" }
        return stop > 0 ? "Push +\(stop)" : "Pull −\(abs(stop))"
    }

    // MARK: - Catalog

    private var catalogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Film catalog")
            Text("Common base times at 20 °C")
                .font(.headline)
                .foregroundStyle(Brand.text)
            Text("Tap any combination to save it as a recipe you can develop from.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)

            LazyVStack(spacing: 10) {
                ForEach(FilmCatalog.all) { ref in
                    CatalogRow(
                        ref: ref,
                        alreadySaved: isSaved(ref),
                        justAdded: addedRefID == ref.id
                    ) {
                        add(ref)
                    }
                }
            }
        }
        .glassCard()
    }

    private func isSaved(_ ref: FilmReference) -> Bool {
        recipes.contains {
            $0.filmStock == ref.filmStock &&
            $0.developer == ref.developer &&
            $0.dilution == ref.dilution
        }
    }

    private func add(_ ref: FilmReference) {
        let recipe = Recipe(
            name: ref.suggestedName,
            filmStock: ref.filmStock,
            developer: ref.developer,
            dilution: ref.dilution,
            boxISO: ref.boxISO,
            baseTimeSec: ref.baseTimeSec,
            baseTempC: 20.0,
            agitationNote: ref.agitationNote,
            stopSec: ref.stopSec,
            fixSec: ref.fixSec,
            washSec: ref.washSec
        )
        context.insert(recipe)
        try? context.save()
        Haptics.success()
        withAnimation(Brand.ease(0.3)) { addedRefID = ref.id }
    }
}

/// A single catalog row with a one-tap add control.
struct CatalogRow: View {
    let ref: FilmReference
    let alreadySaved: Bool
    let justAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(ref.filmStock)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("\(ref.developer) \(ref.dilution) · ISO \(ref.boxISO)")
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            Text(ref.baseTimeClock)
                .font(Brand.mono(14, weight: .semibold))
                .foregroundStyle(Brand.text)
            addControl
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Brand.mist3.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ref.filmStock) in \(ref.developer) \(ref.dilution), base time \(ref.baseTimeClock)")
        .accessibilityHint(alreadySaved ? "Already saved as a recipe" : "Double tap to save as a recipe")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var addControl: some View {
        if alreadySaved || justAdded {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Brand.live)
                .accessibilityHidden(true)
        } else {
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Brand.magic)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Save \(ref.filmStock) recipe")
        }
    }
}
