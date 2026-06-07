import SwiftUI
import SwiftData

struct ComputeView: View {
    @Query(sort: \Telescope.name) private var scopes: [Telescope]
    @Query(sort: \Eyepiece.focalLength, order: .reverse) private var eyepieces: [Eyepiece]
    @AppStorage("defaultBarlow") private var defaultBarlow = 1.0
    @AppStorage("warnOverMag") private var warnOverMag = true

    @State private var scopeID: PersistentIdentifier?
    @State private var eyepieceID: PersistentIdentifier?
    @State private var barlow = 1.0
    @State private var loaded = false

    private var scope: Telescope? { scopes.first { $0.persistentModelID == scopeID } }
    private var eyepiece: Eyepiece? { eyepieces.first { $0.persistentModelID == eyepieceID } }

    private var view: OpticalView? {
        guard let s = scope, let e = eyepiece else { return nil }
        return Optics.view(scopeFL: s.focalLength, aperture: s.aperture,
                           eyepieceFL: e.focalLength, apparentFOV: e.apparentFOV, barlow: barlow)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if scopes.isEmpty || eyepieces.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "function",
                                       title: "Add gear to compute",
                                       message: "You need at least one telescope and one eyepiece. Add them in the Gear tab.")
                            .padding(.top, 60)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            scopePicker
                            eyepiecePicker
                            barlowPicker
                            if let v = view { resultCard(v) }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Compute")
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        barlow = defaultBarlow
        scopeID = (scopes.first { $0.isPrimary } ?? scopes.first)?.persistentModelID
        eyepieceID = eyepieces.first?.persistentModelID
    }

    private var scopePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Telescope")
            chips(scopes.map { ($0.persistentModelID, $0.name) }, selected: scopeID) { scopeID = $0 }
        }
        .glassCard()
    }

    private var eyepiecePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Eyepiece")
            chips(eyepieces.map { ($0.persistentModelID, "\(Int($0.focalLength))mm") }, selected: eyepieceID) { eyepieceID = $0 }
        }
        .glassCard()
    }

    private func chips(_ items: [(PersistentIdentifier, String)], selected: PersistentIdentifier?,
                       onSelect: @escaping (PersistentIdentifier) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.0) { id, label in
                    Button {
                        Haptics.selection(); onSelect(id)
                    } label: {
                        Text(label).font(Brand.mono(13, weight: .medium))
                            .foregroundStyle(selected == id ? .white : Brand.text)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selected == id ? AnyShapeStyle(Brand.inkGradient)
                                                       : AnyShapeStyle(.ultraThinMaterial),
                                        in: Capsule())
                    }
                    .accessibilityLabel(label)
                }
            }
        }
    }

    private var barlowPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Barlow / reducer")
            Picker("Barlow", selection: $barlow) {
                Text("None").tag(1.0)
                Text("2×").tag(2.0)
                Text("3×").tag(3.0)
            }
            .pickerStyle(.segmented)
            .onChange(of: barlow) { _, _ in Haptics.selection() }
        }
        .glassCard()
    }

    private func resultCard(_ v: OpticalView) -> some View {
        let over = warnOverMag && (scope.map { v.magnification > $0.maxUsefulMag } ?? false)
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                StatTile(value: Fmt.mag(v.magnification), label: "Magnification",
                         accent: over ? Brand.warn : Brand.text)
                StatTile(value: Fmt.deg(v.trueFOVDegrees), label: "True field", accent: Brand.info)
                StatTile(value: String(format: "%.1f", v.exitPupilMM), label: "Exit pupil mm", accent: Brand.magic)
            }
            HStack(spacing: 10) {
                Image(systemName: over ? "exclamationmark.triangle" : "sparkle")
                    .foregroundStyle(over ? Brand.warn : Brand.live).accessibilityHidden(true)
                Text(over ? "Beyond this scope's max useful power (\(Fmt.mag(scope?.maxUsefulMag ?? 0)))."
                          : v.quality)
                    .font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
            }
            .glassCard(padding: 14)

            if let s = scope {
                HStack(spacing: 12) {
                    StatTile(value: Fmt.mag(s.minUsefulMag), label: "Min useful")
                    StatTile(value: Fmt.mag(s.maxUsefulMag), label: "Max useful", accent: Brand.warn)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}
