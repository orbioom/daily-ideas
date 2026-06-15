import SwiftUI
import SwiftData

/// Ranked correlation cards: factor → outcome, with r, strength, direction, a same-day / next-day
/// lag toggle, and a time range. Tapping a card opens a scatter chart + plain-English reading.
/// Next-day (lag) analysis is a Pro feature; the toggle gates to the paywall when locked.
struct InsightsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var trackers: [Tracker]

    @StateObject private var vm = InsightsViewModel()
    @State private var range: TimeRange = .days30
    @State private var lagNextDay = false
    @State private var paywallReason: PaywallReason?
    @State private var selected: CorrelationEngine.Result?
    @State private var didInit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    controls

                    if vm.isLoading {
                        loadingState
                    } else if vm.usableFactorCount == 0 || vm.usableOutcomeCount == 0 {
                        notEnoughTrackers
                    } else if vm.results.isEmpty {
                        notEnoughData
                    } else {
                        resultsList
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .sheet(item: $selected) { result in
                CorrelationDetailView(result: result,
                                      trackers: trackers,
                                      lag: lagNextDay ? 1 : 0)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .task {
            if !didInit {
                range = settings.defaultRange
                didInit = true
            }
            await recompute()
        }
        .onChange(of: range) { _, _ in Task { await recompute() } }
        .onChange(of: lagNextDay) { _, _ in Task { await recompute() } }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Time range", selection: $range) {
                ForEach(TimeRange.allCases) { r in
                    Text(r.label).tag(r)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 10) {
                lagButton(title: "Same day", isOn: !lagNextDay) {
                    lagNextDay = false
                    Haptics.select(settings.hapticsEnabled)
                }
                lagButton(title: "Next day", isOn: lagNextDay, locked: !isPro) {
                    if isPro {
                        lagNextDay = true
                        Haptics.select(settings.hapticsEnabled)
                    } else {
                        paywallReason = .lag
                    }
                }
            }
        }
    }

    private func lagButton(title: String, isOn: Bool, locked: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 11)).accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(14, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isOn ? .white : Theme.inkSoft)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(isOn ? Theme.accent : Theme.surfaceAlt)
            )
        }
        .accessibilityLabel(title + (locked ? ", Pro feature" : ""))
        .accessibilityValue(isOn ? "Selected" : "Not selected")
    }

    // MARK: States

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Crunching your correlations…")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var notEnoughTrackers: some View {
        CardView {
            EmptyStateView(symbol: "sparkles",
                           title: "Add a factor and an outcome",
                           message: "Correlations need at least one factor (like Caffeine) and one outcome (a symptom or mood). Turn a couple on in Trackers, then log a few days.")
        }
    }

    private var notEnoughData: some View {
        CardView {
            EmptyStateView(symbol: "chart.dots.scatter",
                           title: "Need a little more data",
                           message: "Inkling needs at least 4 days where a factor and an outcome were both logged. Keep logging for a few more days and patterns will appear here.")
        }
    }

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top correlations",
                          subtitle: "\(lagNextDay ? "Next-day" : "Same-day") · \(range.label) · ranked by strength")
            ForEach(vm.results.prefix(20)) { result in
                Button {
                    Haptics.select(settings.hapticsEnabled)
                    selected = result
                } label: {
                    CorrelationCard(result: result)
                }
                .buttonStyle(.plain)
            }
            Text("Correlation isn't causation — these are patterns to notice, not medical advice.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private func recompute() async {
        await vm.recompute(trackers: trackers, range: range, lag: lagNextDay ? 1 : 0)
    }
}
