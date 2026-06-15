import SwiftUI
import SwiftData

/// Timed / word-count speed tests over a random stream of common words. The 30-second test is
/// free; other durations and the word-count sprint gate behind Pro.
struct TestView: View {
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \TestResult.date, order: .reverse) private var allResults: [TestResult]

    @State private var selectedDuration: TestDuration = .thirty
    @State private var useWordCount = false
    @State private var wordCount = 25
    @State private var paywallReason: PaywallReason?
    @State private var activeConfig: SessionConfig?
    @State private var streamSeed: UInt64 = 0

    /// Only test-mode results show in history here.
    private var testHistory: [TestResult] {
        allResults.filter { $0.mode == .test }.prefix(12).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    modeCard
                    startButton
                    historySection
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Test")
            .navigationDestination(item: $activeConfig) { cfg in
                TypingSessionView(config: cfg)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear { selectedDuration = settings.defaultTestDuration }
        }
    }

    // MARK: Mode selection

    private var modeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Choose your test", systemImage: "stopwatch.fill")

            Picker("Test type", selection: $useWordCount) {
                Text("Timed").tag(false)
                Text("Word count").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: useWordCount) { _, usesWords in
                if usesWords && !isPro {
                    useWordCount = false
                    paywallReason = .testMode
                }
            }

            if useWordCount {
                wordCountPicker
            } else {
                durationPicker
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkFaint)
            HStack(spacing: 10) {
                ForEach(TestDuration.allCases) { d in
                    durationChip(d)
                }
            }
        }
    }

    private func durationChip(_ d: TestDuration) -> some View {
        let locked = !d.isFree && !isPro
        let selected = selectedDuration == d && !useWordCount
        return Button {
            if locked {
                paywallReason = .testMode
            } else {
                selectedDuration = d
            }
        } label: {
            VStack(spacing: 4) {
                Text(d.label)
                    .font(Theme.mono(20, .bold))
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(selected ? .white : (locked ? Theme.inkFaint : Theme.ink))
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surfaceAlt))
            )
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel("\(d.label) test\(locked ? ", Pro, locked" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var wordCountPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Words")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                Text("\(wordCount)")
                    .font(Theme.mono(18, .bold))
                    .foregroundStyle(Theme.accentDeep)
                    .monospacedDigit()
            }
            Stepper("Words", value: $wordCount, in: 10...100, step: 5)
                .labelsHidden()
                .accessibilityLabel("Word count")
                .accessibilityValue("\(wordCount) words")
        }
    }

    private var startButton: some View {
        PrimaryButton(title: "Start test", systemImage: "play.fill") {
            startTest()
        }
    }

    // MARK: History

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent tests", systemImage: "clock.arrow.circlepath")
            if testHistory.isEmpty {
                EmptyStateView(
                    symbol: "stopwatch",
                    title: "No tests yet",
                    message: "Run a quick test above and your results will collect here."
                )
            } else {
                ForEach(testHistory) { r in
                    historyRow(r)
                }
            }
        }
        .padding(.top, 4)
    }

    private func historyRow(_ r: TestResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(r.wpm.rounded())) WPM")
                    .font(Theme.mono(18, .bold))
                    .foregroundStyle(Theme.accentDeep)
                Text(r.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int((r.accuracy * 100).rounded()))%")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(r.accuracy >= 0.95 ? Theme.good : Theme.ink)
                Text("\(Int(r.durationSeconds.rounded()))s")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(r.wpm.rounded())) WPM, \(Int((r.accuracy * 100).rounded())) percent, \(Int(r.durationSeconds.rounded())) seconds, \(r.date.formatted(date: .abbreviated, time: .shortened))")
    }

    // MARK: Start

    private func startTest() {
        streamSeed = UInt64(Date().timeIntervalSince1970 * 1000) ^ 0xA5A5A5A5

        if useWordCount {
            guard isPro else { paywallReason = .testMode; return }
            let words = WordBank.stream(count: wordCount, seed: streamSeed)
            let text = words.joined(separator: " ")
            activeConfig = SessionConfig(
                title: "\(wordCount)-word sprint",
                text: text.isEmpty ? "the quick brown fox" : text,
                mode: .test,
                strict: settings.strictMode,
                focusKeys: [],
                lessonID: nil,
                timeLimit: nil
            )
        } else {
            if !selectedDuration.isFree && !isPro {
                paywallReason = .testMode
                return
            }
            // Generate plenty of words to fill the time (≈ 200 wpm ceiling).
            let needed = max(40, Int(selectedDuration.rawValue) * 4)
            let words = WordBank.stream(count: needed, seed: streamSeed)
            let text = words.joined(separator: " ")
            activeConfig = SessionConfig(
                title: "\(selectedDuration.label) test",
                text: text.isEmpty ? "the quick brown fox" : text,
                mode: .test,
                strict: settings.strictMode,
                focusKeys: [],
                lessonID: nil,
                timeLimit: Double(selectedDuration.rawValue)
            )
        }
    }
}
