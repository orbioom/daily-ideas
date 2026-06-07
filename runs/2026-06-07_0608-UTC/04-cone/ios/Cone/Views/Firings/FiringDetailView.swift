import SwiftUI
import SwiftData

struct FiringDetailView: View {
    @Bindable var firing: Firing
    @AppStorage("cone.celsius") private var celsius = false
    @AppStorage("cone.kilnKW") private var kilnKW = 8.0
    @AppStorage("cone.pricePerKWh") private var pricePerKWh = 0.16
    @State private var showingEdit = false

    private var cost: Double {
        ConeMath.estimatedCost(hours: firing.totalHours, kilnKW: kilnKW, pricePerKWh: pricePerKWh)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                scheduleCard
                resultCard
            }
            .padding()
        }
        .navigationTitle(firing.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Edit") { showingEdit = true } } }
        .sheet(isPresented: $showingEdit) { FiringEditView(existing: firing) }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text(firing.date, format: .dateTime.weekday(.wide).month().day().year())
                .font(.caption).foregroundStyle(Brand.text3)
            let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                StatTile(value: "△\(firing.targetCone)", label: "Target cone")
                StatTile(value: ConeMath.formatHours(firing.totalHours), label: "Total time")
                StatTile(value: ConeMath.formatTemp(Int(firing.peakTempF), celsius: celsius), label: "Peak")
                StatTile(value: firing.kind, label: "Type")
                StatTile(value: firing.atmosphere, label: "Atmosphere")
                StatTile(value: String(format: "$%.2f", cost), label: "Est. cost", accent: Brand.live)
            }
            if let ct = ConeMath.coneTemp(firing.targetCone) {
                Text("Cone \(firing.targetCone) ≈ \(ConeMath.formatTemp(firing.fastRamp ? ct.fastF : ct.slowF, celsius: celsius)) at \(firing.fastRamp ? "270" : "108")°F/hr")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Ramp schedule")
            if firing.orderedSegments.isEmpty {
                Text("No segments. Edit to add ramp steps.").font(.caption).foregroundStyle(Brand.text3)
            } else {
                HStack {
                    Text("Rate").frame(width: 80, alignment: .leading)
                    Text("Target").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Hold").frame(width: 60, alignment: .trailing)
                }
                .font(Brand.mono(10, weight: .medium)).foregroundStyle(Brand.text3)
                ForEach(Array(firing.orderedSegments.enumerated()), id: \.element.id) { i, seg in
                    HStack {
                        Text(seg.rate <= 0 ? "AFAP" : "\(Int(seg.rate))°/hr")
                            .frame(width: 80, alignment: .leading).foregroundStyle(Brand.text2)
                        Text(ConeMath.formatTemp(Int(seg.targetTempF), celsius: celsius))
                            .frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Brand.text)
                        Text(seg.holdMinutes > 0 ? "\(Int(seg.holdMinutes))m" : "—")
                            .frame(width: 60, alignment: .trailing).foregroundStyle(Brand.text2)
                    }
                    .font(Brand.mono(13))
                    if i < firing.orderedSegments.count - 1 { Divider().overlay(Brand.hairline) }
                }
            }
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Result")
            HStack {
                Text(firing.result).font(.headline)
                    .foregroundStyle(firing.result == "Success" ? Brand.live :
                                        (firing.result == "Issues" ? Brand.warn : Brand.text2))
                Spacer()
            }
            if !firing.resultNotes.isEmpty {
                Text(firing.resultNotes).font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                Text("No result notes yet.").font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
