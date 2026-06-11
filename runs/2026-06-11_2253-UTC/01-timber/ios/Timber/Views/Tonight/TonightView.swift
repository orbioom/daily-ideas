import SwiftUI
import SwiftData
import UIKit

struct TonightView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(RecorderEngine.self) private var recorder
    @Query(sort: \SleepFactor.name) private var factors: [SleepFactor]
    @Query(sort: \NightSession.startedAt, order: .reverse) private var sessions: [NightSession]
    @AppStorage("sensitivity") private var sensitivity = 14.0

    @State private var selectedFactorNames: Set<String> = []
    @State private var showMonitor = false
    @State private var finishedSession: NightSession?

    private var activeFactors: [SleepFactor] { factors.filter(\.isActive) }
    private var lastNight: NightSession? { sessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let last = lastNight {
                        lastNightCard(last)
                    }
                    factorPicker
                    startButton
                    if case .denied = recorder.state {
                        permissionCard
                    }
                    if case .failed(let message) = recorder.state {
                        errorCard(message)
                    }
                }
                .padding()
            }
            .background(Theme.background(scheme))
            .navigationTitle("Tonight")
            .fullScreenCover(isPresented: $showMonitor) {
                MonitoringView { result in
                    showMonitor = false
                    guard let result else { return }
                    saveSession(result)
                }
            }
            .sheet(item: $finishedSession) { session in
                SessionSummaryView(session: session)
            }
            .onChange(of: recorder.state) { _, newState in
                if case .monitoring = newState { showMonitor = true }
            }
        }
    }

    private func saveSession(_ result: (startedAt: Date, endedAt: Date,
                                        episodes: [SnoreDetector.Detected],
                                        minuteLevels: [Double])) {
        let chosen = activeFactors.filter { selectedFactorNames.contains($0.name) }
        let session = NightSession(startedAt: result.startedAt, endedAt: result.endedAt,
                                   levelSamples: result.minuteLevels)
        context.insert(session)
        session.factors = chosen
        for detected in result.episodes {
            let episode = SnoreEpisode(startOffset: detected.startOffset,
                                       duration: detected.duration,
                                       peakDB: detected.peakDB,
                                       intensity: detected.intensity)
            episode.session = session
            context.insert(episode)
        }
        selectedFactorNames = []
        Haptics.success()
        finishedSession = session
    }

    private func lastNightCard(_ session: NightSession) -> some View {
        let score = SnoreEngine.score(for: session)
        return HStack(spacing: 16) {
            ScoreDial(score: score, size: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text("Last night")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
                Text(SnoreEngine.grade(forScore: score).label)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.inkPrimary(scheme))
                Text("\(SnoreEngine.formatDuration(session.duration)) asleep · \(session.episodes.count) episodes")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            }
            Spacer()
        }
        .timberCard()
    }

    private var factorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tonight I…")
                .font(.headline)
                .foregroundStyle(Theme.inkPrimary(scheme))
            Text("Tag tonight so Timber can learn what helps.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary(scheme))
            if activeFactors.isEmpty {
                Text("No factors yet — add some in the Remedies tab.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary(scheme))
            } else {
                FlowChips(items: activeFactors.map { "\($0.emoji) \($0.name)" },
                          isSelected: { label in
                              selectedFactorNames.contains(stripEmoji(label))
                          },
                          onTap: { label in
                              let name = stripEmoji(label)
                              Haptics.tap()
                              if selectedFactorNames.contains(name) {
                                  selectedFactorNames.remove(name)
                              } else {
                                  selectedFactorNames.insert(name)
                              }
                          })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private func stripEmoji(_ label: String) -> String {
        // Labels are "emoji name"; factor names never contain a leading emoji.
        let parts = label.split(separator: " ", maxSplits: 1)
        return parts.count == 2 ? String(parts[1]) : label
    }

    private var startButton: some View {
        Button {
            recorder.sensitivity = sensitivity
            recorder.start()
        } label: {
            HStack {
                Image(systemName: "moon.zzz.fill")
                Text(recorder.state == .requestingPermission ? "Starting…" : "Start sleep session")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.amber)
        .foregroundStyle(.black)
        .disabled(recorder.state == .requestingPermission)
        .accessibilityHint("Begins listening for snoring. Keep your iPhone plugged in on the nightstand.")
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Microphone access needed", systemImage: "mic.slash.fill")
                .font(.headline)
                .foregroundStyle(Theme.ember)
            Text("Timber listens locally to detect snoring — audio never leaves your iPhone. Enable the microphone in Settings to start a session.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary(scheme))
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(Theme.amber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Couldn't start", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Theme.ember)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary(scheme))
            Button("Dismiss") { recorder.acknowledgeError() }
                .buttonStyle(.bordered)
                .tint(Theme.amber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }
}

/// Simple wrapping chip row.
struct FlowChips: View {
    let items: [String]
    let isSelected: (String) -> Bool
    let onTap: (String) -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button { onTap(item) } label: {
                    Text(item)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isSelected(item) ? Theme.amber : Theme.inkSecondary(scheme).opacity(0.12),
                            in: Capsule())
                        .foregroundStyle(isSelected(item) ? .black : Theme.inkPrimary(scheme))
                }
                .accessibilityAddTraits(isSelected(item) ? .isSelected : [])
            }
        }
    }
}

/// Minimal flow layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                      proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
