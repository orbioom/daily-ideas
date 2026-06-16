import SwiftUI

/// The full chart for a single profile.
struct ReadingView: View {
    let profile: Profile
    var showsChooser: Bool = true

    @EnvironmentObject private var settings: AppSettings
    @State private var chart: NumerologyChart?
    @State private var isLoading = false
    @State private var detail: CoreNumber?
    @State private var showShare = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if isLoading || chart == nil {
                    ProgressView("Casting the chart…")
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let chart {
                    if !chart.masterNumbers.isEmpty || !chart.karmicDebts.isEmpty {
                        highlights(chart: chart)
                    }
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(chart.cores) { core in
                            CoreNumberCard(core: core) {
                                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                                detail = core
                            }
                        }
                    }
                    shareButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .task(id: taskKey) { await recompute() }
        .sheet(item: $detail) { core in
            CoreNumberDetailView(core: core, profile: profile)
        }
        .sheet(isPresented: $showShare) {
            if let chart {
                ShareCardView(profile: profile, chart: chart)
            }
        }
        .navigationTitle(showsChooser ? profile.displayName : "")
        .navigationBarTitleDisplayMode(showsChooser ? .inline : .automatic)
    }

    private var taskKey: String {
        "\(profile.persistentModelID.storageIdentifier)|\(settings.systemRaw)|\(settings.reduceMasterNumbers)"
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(profile.displayName)
                .font(Theme.serif(.largeTitle))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(profile.birthdate, format: .dateTime.day().month(.wide).year())
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text("\(settings.system.rawValue) system")
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func highlights(chart: NumerologyChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !chart.masterNumbers.isEmpty {
                highlightRow(
                    symbol: "star.circle.fill",
                    tint: Theme.accent,
                    title: "Master Numbers",
                    text: "This chart carries " + chart.masterNumbers.map { "\($0)" }.joined(separator: ", ") + " — rare, high-voltage energy."
                )
            }
            if !chart.karmicDebts.isEmpty {
                highlightRow(
                    symbol: "exclamationmark.triangle.fill",
                    tint: Theme.warn,
                    title: "Karmic Debt",
                    text: "Debt number(s) " + chart.karmicDebts.map { "\($0)" }.joined(separator: ", ") + " surfaced — lessons to repay through conscious effort."
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.cornerM))
    }

    private func highlightRow(symbol: String, tint: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                Text(text).font(.footnote).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var shareButton: some View {
        Button {
            Haptics.impact(.medium, enabled: settings.hapticsEnabled)
            showShare = true
        } label: {
            Label("Create share card", systemImage: "square.and.arrow.up")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .padding(.top, 4)
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 220_000_000)
        chart = NumerologyEngine.chart(for: profile, config: settings.engineConfig)
        isLoading = false
    }
}

/// A single tappable core-number card.
struct CoreNumberCard: View {
    let core: CoreNumber
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: core.position.symbol)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Spacer()
                    if core.reduction.isMaster {
                        TagPill(text: "Master", tint: Theme.accent)
                    } else if core.reduction.karmicDebt != nil {
                        TagPill(text: "Karmic", tint: Theme.warn)
                    }
                }
                NumberGlyph(value: core.value, size: 46, isMaster: core.reduction.isMaster)
                Text(core.position.rawValue)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(InterpretationLibrary.meaning(for: core.value).title)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerM))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(core.position.rawValue) number \(core.value), \(InterpretationLibrary.meaning(for: core.value).title)")
        .accessibilityHint("Opens the full interpretation")
        .accessibilityAddTraits(.isButton)
    }
}
