import SwiftUI
import SwiftData

/// A single dive in full, with derived gas and physiology figures.
struct DiveDetailView: View {
    @Bindable var dive: Dive
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @State private var editing = false

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var fmt: DiveFmt { DiveFmt(unit: unit) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                profileCard
                gasCard
                if !dive.buddy.isEmpty || !dive.visibility.isEmpty || !dive.notes.isEmpty { notesCard }
            }
            .padding(.horizontal, 16).padding(.bottom, 32)
        }
        .background(Brand.pageBackground)
        .navigationTitle(dive.site?.name ?? "Dive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = true } label: { Image(systemName: "pencil") }.accessibilityLabel("Edit dive")
            }
        }
        .sheet(isPresented: $editing) { DiveEditView(dive: dive, isNew: false) }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(dive.type.label, systemImage: dive.type.symbol).font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                StarRating(rating: .constant(dive.rating))
            }
            Text(dive.date.formatted(date: .complete, time: .shortened))
                .font(.subheadline).foregroundStyle(Brand.text2)
            if let loc = dive.site?.location, !loc.isEmpty {
                Label(loc, systemImage: "mappin").font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Profile")
            HStack(spacing: 10) {
                StatTile(value: fmt.depth(dive.maxDepthM), label: "Max depth", tint: Brand.text)
                StatTile(value: fmt.duration(dive.durationMin), label: "Duration", tint: Brand.live)
                StatTile(value: dive.waterTempC != 0 ? fmt.temp(dive.waterTempC) : "—", label: "Temp")
            }
            if dive.avgDepthM > 0 {
                Text("Average depth \(fmt.depth(dive.avgDepthM)).").font(.caption).foregroundStyle(Brand.text3)
            }
        }
    }

    private var gasCard: some View {
        let ndl = DiveMath.ndl(oxygenPercent: dive.oxygenPercent, atDepth: dive.maxDepthM)
        let overPP = dive.maxPPO2 > 1.4
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Gas & consumption")
            HStack(spacing: 10) {
                StatTile(value: dive.gas.label, label: "Mix", tint: dive.gas.isAir ? Brand.text : Brand.live)
                StatTile(value: "\(Int(dive.gasUsedBar)) bar", label: "Gas used")
                StatTile(value: dive.sac > 0 ? String(format: "%.1f", dive.sac) : "—", label: "SAC L/min", tint: Brand.info)
            }
            HStack(spacing: 10) {
                StatTile(value: String(format: "%.2f", dive.maxPPO2), label: "Max ppO₂", tint: overPP ? Brand.danger : Brand.text)
                StatTile(value: ndl > 0 ? "\(ndl) min" : "—", label: "Air/EAD no-stop")
                StatTile(value: "\(dive.startPressureBar)→\(dive.endPressureBar)", label: "Pressure bar")
            }
            if overPP {
                Label("Recorded ppO₂ exceeded the 1.4 recreational limit at max depth.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(Brand.danger)
            }
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Notes")
            if !dive.buddy.isEmpty { Label(dive.buddy, systemImage: "person.2").font(.subheadline).foregroundStyle(Brand.text2) }
            if !dive.visibility.isEmpty { Label("Viz: \(dive.visibility)", systemImage: "eye").font(.subheadline).foregroundStyle(Brand.text2) }
            if !dive.notes.isEmpty { Text(dive.notes).font(.subheadline).foregroundStyle(Brand.text) }
        }
        .glassCard()
    }
}
