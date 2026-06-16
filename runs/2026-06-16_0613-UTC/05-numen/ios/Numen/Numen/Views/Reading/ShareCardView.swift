import SwiftUI

/// Generates and shares a clean image summary of a profile's reading.
struct ShareCardView: View {
    let profile: Profile
    let chart: NumerologyChart

    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    @State private var rendered: UIImage?
    @State private var showPaywall = false
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ShareCard(profile: profile, chart: chart)
                        .frame(width: 320, height: 480)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerL))
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                        .padding(.top, 12)
                        .accessibilityLabel("Share card preview for \(profile.displayName)")

                    if isPro {
                        if let rendered {
                            ShareLink(
                                item: Image(uiImage: rendered),
                                preview: SharePreview("\(profile.displayName)'s Numen reading", image: Image(uiImage: rendered))
                            ) {
                                Label("Share image", systemImage: "square.and.arrow.up")
                                    .font(Theme.rounded(15, .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                        } else {
                            ProgressView("Rendering…").tint(Theme.accent)
                        }
                    } else {
                        VStack(spacing: 10) {
                            Text("Exporting share cards is a Numen Pro feature.")
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                            Button {
                                showPaywall = true
                            } label: {
                                Label("Unlock with Pro", systemImage: "lock.open.fill")
                                    .font(Theme.rounded(15, .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .task(id: isPro) { await render() }
        }
    }

    @MainActor
    private func render() async {
        guard isPro else { return }
        let renderer = ImageRenderer(content:
            ShareCard(profile: profile, chart: chart)
                .frame(width: 320, height: 480)
                .environmentObject(settings)
        )
        renderer.scale = max(displayScale, 2)
        if let image = renderer.uiImage {
            rendered = image
        }
    }
}

/// The visual content of the share card — screenshot-worthy.
struct ShareCard: View {
    let profile: Profile
    let chart: NumerologyChart

    var body: some View {
        ZStack {
            Theme.heroGradient
            Starfield(count: 60, twinkle: false)
                .opacity(0.8)
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("NUMEN")
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .tracking(6)
                        .foregroundStyle(Theme.accent)
                    Text(profile.displayName)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(profile.birthdate, format: .dateTime.day().month(.wide).year())
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 32)

                Spacer(minLength: 8)

                heroNumber

                Spacer(minLength: 8)

                grid
                    .padding(.horizontal, 24)

                Spacer(minLength: 8)

                Text("Read in full on Numen")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 22)
            }
        }
    }

    private var heroNumber: some View {
        VStack(spacing: 2) {
            Text("\(chart.lifePath.value)")
                .font(.system(size: 96, weight: .bold, design: .serif))
                .foregroundStyle(Theme.goldGradient)
            Text("LIFE PATH · \(InterpretationLibrary.meaning(for: chart.lifePath.value).title)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var grid: some View {
        let items: [(String, Int)] = [
            ("Expression", chart.expression.value),
            ("Soul Urge", chart.soulUrge.value),
            ("Personality", chart.personality.value),
            ("Maturity", chart.maturity.value)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 2) {
                    Text("\(item.1)")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Theme.accent)
                    Text(item.0.uppercased())
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
