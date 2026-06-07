import SwiftUI
import SwiftData

struct TonightView: View {
    @Query private var scopes: [Telescope]
    @Query(sort: \Eyepiece.focalLength, order: .reverse) private var eyepieces: [Eyepiece]
    @Query private var observations: [Observation]
    @State private var month = Calendar.current.component(.month, from: .now)
    @State private var logTarget: SkyTarget?

    private var primaryScope: Telescope? { scopes.first { $0.isPrimary } ?? scopes.first }
    private var targets: [SkyTarget] { TargetCatalog.best(in: month) }
    private var loggedNames: Set<String> { Set(observations.map(\.targetName)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        monthPicker
                        if targets.isEmpty {
                            EmptyStateView(icon: "moon.stars", title: "Nothing charted",
                                           message: "No showpiece targets listed for \(Fmt.monthName(month)).")
                        } else {
                            ForEach(targets) { t in targetCard(t) }
                        }
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
            .navigationTitle("Tonight")
            .sheet(item: $logTarget) { t in
                ObservationEditView(observation: nil, prefillTarget: t)
            }
        }
    }

    private var monthPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Best this month", trailing: "\(targets.count)")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { m in
                        Button {
                            Haptics.selection(); month = m
                        } label: {
                            Text(Fmt.shortMonth(m)).font(Brand.mono(13, weight: .medium))
                                .foregroundStyle(month == m ? .white : Brand.text)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(month == m ? AnyShapeStyle(Brand.inkGradient)
                                                       : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
                        }
                        .accessibilityLabel(Fmt.monthName(m))
                    }
                }
            }
        }
        .glassCard()
    }

    private func targetCard(_ t: SkyTarget) -> some View {
        let logged = loggedNames.contains(t.name)
        let rec = recommendedEyepiece(for: t)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: t.type.symbol).font(.title3).foregroundStyle(t.type.tint)
                    .frame(width: 28).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(t.name).font(.headline).foregroundStyle(Brand.text)
                    Text("\(t.designation == "—" ? t.type.label : t.designation) · \(t.constellation)")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Spacer()
                if logged {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Brand.live)
                        .accessibilityLabel("Observed")
                }
            }
            Text(t.note).font(.subheadline).foregroundStyle(Brand.text2)
            HStack(spacing: 8) {
                Chip(text: "mag \(Fmt.one(t.magnitude))")
                if t.sizeArcmin >= 1 { Chip(text: "\(Int(t.sizeArcmin))′") }
                Chip(text: t.type.label, tint: t.type.tint)
            }
            if let rec {
                HStack(spacing: 8) {
                    Image(systemName: "circle.circle").foregroundStyle(Brand.info).accessibilityHidden(true)
                    Text("Try your \(Int(rec.eyepiece.focalLength))mm — \(Fmt.mag(rec.mag)), \(Fmt.deg(rec.tfov)) field")
                        .font(.caption).foregroundStyle(Brand.text2)
                }
            }
            Button {
                Haptics.tap(); logTarget = t
            } label: {
                Label(logged ? "Log again" : "Log this", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard(padding: 16)
        .accessibilityElement(children: .contain)
    }

    private struct Recommendation { let eyepiece: Eyepiece; let mag: Double; let tfov: Double }

    /// Pick the eyepiece that best frames the target in the primary scope.
    private func recommendedEyepiece(for t: SkyTarget) -> Recommendation? {
        guard let s = primaryScope, !eyepieces.isEmpty else { return nil }
        let sizeDeg = t.sizeArcmin / 60.0
        let small = t.type == .planet || t.type == .double || t.type == .moon || sizeDeg < 0.2

        let views = eyepieces.map { e -> (Eyepiece, OpticalView) in
            (e, Optics.view(scopeFL: s.focalLength, aperture: s.aperture,
                            eyepieceFL: e.focalLength, apparentFOV: e.apparentFOV))
        }

        let chosen: (Eyepiece, OpticalView)?
        if small {
            // Highest power within the scope's max useful magnification.
            chosen = views.filter { $0.1.magnification <= s.maxUsefulMag }
                .max { $0.1.magnification < $1.1.magnification } ?? views.min { $0.1.magnification < $1.1.magnification }
        } else {
            // Highest power whose true field still frames the object (with headroom).
            let fitting = views.filter { $0.1.trueFOVDegrees >= sizeDeg * 1.4 }
            chosen = fitting.max { $0.1.magnification < $1.1.magnification }
                ?? views.max { $0.1.trueFOVDegrees < $1.1.trueFOVDegrees }
        }
        guard let c = chosen else { return nil }
        return Recommendation(eyepiece: c.0, mag: c.1.magnification, tfov: c.1.trueFOVDegrees)
    }
}
