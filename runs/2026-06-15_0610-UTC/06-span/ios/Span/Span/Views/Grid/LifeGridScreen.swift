import SwiftUI
import SwiftData

/// The hero screen: the full life calendar. Renders 52 × expectancy week dots via Canvas,
/// colored by chapter, with the current week glowing. Tap a week for its detail.
struct LifeGridScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @Query private var profiles: [LifeProfile]
    @Query private var chapters: [Chapter]
    @Query private var milestones: [LifeMilestone]

    @State private var selection: WeekSelectionOptional?
    @State private var showProfileEditor = false
    @State private var paywallReason: PaywallReason?
    @State private var posterImage: PosterPayload?
    @State private var isExporting = false

    private var profile: LifeProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    content(for: profile)
                } else {
                    EmptyStateView(symbol: "calendar.badge.exclamationmark",
                                   title: "No life set up yet",
                                   message: "Add your birth date and life expectancy to see your weeks laid out in full.",
                                   actionTitle: "Set up profile") {
                        showProfileEditor = true
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Your Life in Weeks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if profile != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showProfileEditor = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .accessibilityLabel("Edit profile")
                    }
                }
            }
            .sheet(isPresented: $showProfileEditor) {
                ProfileEditorView(profile: profile)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(item: $posterImage) { payload in
                ShareSheet(items: [payload.image])
            }
        }
    }

    @ViewBuilder
    private func content(for profile: LifeProfile) -> some View {
        let engine = SpanEngine(profile: profile)
        let palette = settings.palette(isPro: isPro)
        let model = GridModel(engine: engine,
                              chapters: chapters,
                              milestones: milestones,
                              palette: palette)
        let stats = engine.stats()

        ScrollView {
            VStack(spacing: 18) {
                summaryStrip(stats: stats)

                gridCard(model: model)

                LegendView(model: model)

                exportButton(profile: profile, model: model, stats: stats)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(item: $selection) { sel in
            WeekDetailSheet(index: sel.index,
                            model: model,
                            milestones: milestones,
                            showWeekNumbers: settings.showWeekNumbers)
                .presentationDetents([.medium, .large])
        }
    }

    private func summaryStrip(stats: LifeStats) -> some View {
        HStack(spacing: 12) {
            miniStat("\(Fmt.grouped(stats.weeksLived))", "weeks lived")
            miniStat("\(Fmt.grouped(stats.weeksRemaining))", "weeks left")
            miniStat("\(Fmt.oneDecimal(stats.percentLived))%", "of life")
        }
    }

    private func miniStat(_ value: String, _ label: String) -> some View {
        CardView(padding: 12) {
            VStack(spacing: 2) {
                Text(value)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.accent)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(label)
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func gridCard(model: GridModel) -> some View {
        let glow = !reduceMotion
        return CardView(padding: 14) {
            VStack(spacing: 10) {
                if glow {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let pulse = 0.5 + 0.5 * sin(t * 2.2)
                        gridCanvas(model: model, pulse: pulse, glow: true)
                    }
                } else {
                    gridCanvas(model: model, pulse: 0, glow: false)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(gridSummaryLabel(model: model))
    }

    private func gridCanvas(model: GridModel, pulse: Double, glow: Bool) -> some View {
        LifeGridCanvas(model: model,
                       dotStyle: settings.dotStyle,
                       glowEnabled: glow,
                       pulse: pulse,
                       onSelect: { idx in
                           Haptics.select(settings.hapticsEnabled)
                           selection = WeekSelectionOptional(index: idx)
                       },
                       selectedIndex: selection?.index)
    }

    @ViewBuilder
    private func exportButton(profile: LifeProfile, model: GridModel, stats: LifeStats) -> some View {
        VStack(spacing: 6) {
            PrimaryButton(title: isExporting ? "Rendering…" : "Export life poster",
                          systemImage: "square.and.arrow.up",
                          enabled: !isExporting) {
                if isPro {
                    renderPoster(profile: profile, model: model, stats: stats)
                } else {
                    paywallReason = .poster
                }
            }
            Text(isPro ? "A high-resolution image to save or share."
                       : "Span Pro renders a shareable, high-resolution poster.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
        }
    }

    private func gridSummaryLabel(model: GridModel) -> String {
        let lived = model.currentIndex
        let total = model.totalWeeks
        let pct = total > 0 ? Int((Double(lived) / Double(total) * 100).rounded()) : 0
        return "Life calendar grid. \(Fmt.grouped(lived)) of \(Fmt.grouped(total)) weeks lived, about \(pct) percent. \(model.spans.count) chapters shown. Double tap a week in the detail screens to explore."
    }

    @MainActor
    private func renderPoster(profile: LifeProfile, model: GridModel, stats: LifeStats) {
        isExporting = true
        Haptics.light(settings.hapticsEnabled)
        let poster = PosterView(profile: profile, model: model, stats: stats,
                                dotStyle: settings.dotStyle)
        let renderer = ImageRenderer(content: poster)
        renderer.scale = 3.0
        renderer.proposedSize = ProposedViewSize(width: 1080, height: 1500)
        if let uiImage = renderer.uiImage {
            posterImage = PosterPayload(image: uiImage)
            Haptics.success(settings.hapticsEnabled)
        }
        isExporting = false
    }
}

/// Wrapper so a UIImage can drive an `.sheet(item:)`.
struct PosterPayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Identifiable selection used by the grid sheet.
struct WeekSelectionOptional: Identifiable {
    let index: Int
    var id: Int { index }
}
