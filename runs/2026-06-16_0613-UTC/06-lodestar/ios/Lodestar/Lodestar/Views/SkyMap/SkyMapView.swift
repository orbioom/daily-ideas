import SwiftUI

/// The interactive Canvas sky chart screen.
struct SkyMapView: View {
    @Bindable var sky: SkyViewModel
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var heading: Double = 0
    @State private var zoom: Double = 1
    @State private var selected: SkyObject?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.heroGradient.ignoresSafeArea()
                content
            }
            .navigationTitle("Sky Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Constellation lines", isOn: $settings.showConstellationLines)
                        Toggle("Labels", isOn: $settings.showLabels)
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut) {
                                heading = 0; zoom = 1
                            }
                        } label: { Label("Reset view", systemImage: "arrow.counterclockwise") }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Chart options")
                }
            }
            .sheet(item: $selected) { obj in
                if let ctx = sky.context {
                    NavigationStack {
                        ObjectInfoSheet(object: obj, context: ctx)
                    }
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sky.state {
        case .idle, .loading:
            LoadingView(message: "Mapping the sky…")
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await sky.refresh(settings: settings, isPro: isPro) }
            }
        case .loaded(let snap):
            chart(snap)
        }
    }

    private func chart(_ snap: SkySnapshot) -> some View {
        VStack(spacing: 10) {
            headingBar(snap)

            SkyChartCanvas(
                snapshot: snap,
                showConstellations: settings.showConstellationLines,
                showLabels: settings.showLabels,
                isPro: isPro,
                heading: $heading,
                zoom: $zoom,
                onTapObject: { obj in
                    Haptics.selection(settings.hapticsEnabled)
                    selected = obj
                }
            )
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 8)

            footer(snap)
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    private func headingBar(_ snap: SkySnapshot) -> some View {
        let facing = HorizontalCoord(altitude: 0, azimuth: heading).compass16
        return HStack {
            Label("\(facing) • \(Int(heading))°", systemImage: "location.north.line.fill")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.accent)
            Spacer()
            Text(snap.context.name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Facing \(facing). Drag the chart to rotate.")
    }

    private func footer(_ snap: SkySnapshot) -> some View {
        VStack(spacing: 6) {
            Text("Drag to rotate • pinch to zoom • tap a body for details")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
            HStack(spacing: 14) {
                legendDot(Color(hex: 0xFFD24A), "Sun")
                legendDot(Color(hex: 0xE8ECF5), "Moon")
                legendDot(Color(hex: 0xE2725B), "Planet")
                legendDot(.white, "Star")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.bottom, 6)
        .accessibilityHidden(true)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
        }
    }
}
