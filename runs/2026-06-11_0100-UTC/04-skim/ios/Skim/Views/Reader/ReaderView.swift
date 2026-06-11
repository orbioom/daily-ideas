import SwiftUI
import SwiftData

struct ReaderView: View {
    @Bindable var article: Article
    @Environment(\.modelContext) private var modelContext
    @AppStorage("skim.speedWPM") private var speedWPM = 300
    @AppStorage("skim.chunkSize") private var chunkSize = 1
    @AppStorage("skim.theme") private var themeRaw = SkimTheme.ReaderBackground.cream.rawValue
    @AppStorage("skim.fontSize") private var fontSize = 36

    @State private var isPlaying = false
    @State private var wordIndex = 0
    @State private var displayChunk = ""
    @State private var timer: Timer? = nil
    @State private var sessionStart = Date()
    @State private var showSpeedSlider = false

    private var words: [String] {
        article.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }

    private var theme: SkimTheme.ReaderBackground {
        SkimTheme.ReaderBackground(rawValue: themeRaw) ?? .cream
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(wordIndex) / Double(words.count)
    }

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: progress)
                    .tint(SkimTheme.accent)
                    .accessibilityLabel("Reading progress: \(Int(progress * 100))%")

                // RSVP display area
                rsvpArea

                // Controls
                controlArea
            }
        }
        .background(theme.background)
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(SkimTheme.ReaderBackground.allCases, id: \.self) { t in
                        Button(t.rawValue) { themeRaw = t.rawValue }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                }
                .accessibilityLabel("Change reading theme")
            }
        }
        .onDisappear { stopAndSave() }
        .onAppear {
            // Resume from last position
            if let last = article.sessions.max(by: { $0.date < $1.date }), !last.completed {
                wordIndex = min(last.wordIndex, words.count - 1)
            }
            updateDisplay()
        }
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    // MARK: RSVP area

    private var rsvpArea: some View {
        ZStack {
            theme.background

            // Focus guide lines
            HStack(spacing: 0) {
                Rectangle().fill(SkimTheme.focusLine).frame(width: 2)
                Spacer()
                Rectangle().fill(SkimTheme.focusLine).frame(width: 2)
            }
            .padding(.horizontal, 40)

            // Word display
            Text(displayChunk.isEmpty ? "↑ Tap play to start" : displayChunk)
                .font(.system(size: CGFloat(fontSize), weight: .bold, design: .serif))
                .foregroundStyle(theme.text)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .padding(.horizontal, 24)
                .animation(.none, value: displayChunk)
                .accessibilityLabel(displayChunk.isEmpty ? "Tap play to start reading" : displayChunk)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: Controls

    private var controlArea: some View {
        VStack(spacing: 12) {
            // Speed display + slider toggle
            HStack {
                Text("\(speedWPM) WPM")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.text.opacity(0.7))
                    .onTapGesture { showSpeedSlider.toggle() }
                    .accessibilityLabel("Current reading speed: \(speedWPM) words per minute. Tap to adjust.")
                Spacer()
                Text("Font")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.text.opacity(0.5))
                Stepper("", value: $fontSize, in: 20...60, step: 4)
                    .labelsHidden()
                    .accessibilityLabel("Font size: \(fontSize). Adjust with stepper.")
            }
            .padding(.horizontal, 20)

            if showSpeedSlider {
                VStack(spacing: 4) {
                    Slider(value: Binding(
                        get: { Double(speedWPM) },
                        set: { speedWPM = Int($0) }
                    ), in: 100...1000, step: 25)
                    .tint(SkimTheme.accent)
                    .padding(.horizontal, 20)
                    HStack {
                        Text("100").font(.caption).foregroundStyle(theme.text.opacity(0.5))
                        Spacer()
                        Text("1000").font(.caption).foregroundStyle(theme.text.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                }
            }

            // Play/pause + seek buttons
            HStack(spacing: 24) {
                seekButton(backward: true)

                Button {
                    isPlaying ? pause() : play()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.text)
                        .frame(width: 64, height: 64)
                        .background(SkimTheme.accent.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")

                seekButton(backward: false)
            }

            // Position indicator
            Text("\(wordIndex + 1) / \(words.count)")
                .font(.system(size: 12))
                .foregroundStyle(theme.text.opacity(0.4))
                .accessibilityLabel("Word \(wordIndex + 1) of \(words.count)")

            Spacer(minLength: 20)
        }
        .padding(.top, 12)
        .background(theme.background)
    }

    private func seekButton(backward: Bool) -> some View {
        Button {
            if backward {
                let step = max(0, wordIndex - 20)
                wordIndex = step
            } else {
                let step = min(words.count - 1, wordIndex + 20)
                wordIndex = step
            }
            updateDisplay()
        } label: {
            Image(systemName: backward ? "backward.fill" : "forward.fill")
                .font(.system(size: 20))
                .foregroundStyle(theme.text.opacity(0.7))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(backward ? "Skip back 20 words" : "Skip forward 20 words")
    }

    // MARK: Logic

    private func play() {
        guard !words.isEmpty else { return }
        isPlaying = true
        sessionStart = Date()
        tick()
    }

    private func pause() {
        isPlaying = false
        timer?.invalidate()
        saveSession(completed: false)
    }

    private func tick() {
        guard isPlaying, wordIndex < words.count else {
            if wordIndex >= words.count {
                isPlaying = false
                saveSession(completed: true)
            }
            return
        }

        let interval = 60.0 / Double(speedWPM)
        let count = min(chunkSize, words.count - wordIndex)
        displayChunk = words[wordIndex..<(wordIndex + count)].joined(separator: " ")
        wordIndex += count

        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            tick()
        }
    }

    private func updateDisplay() {
        guard !words.isEmpty, wordIndex < words.count else { return }
        let count = min(chunkSize, words.count - wordIndex)
        displayChunk = words[wordIndex..<(wordIndex + count)].joined(separator: " ")
    }

    private func stopAndSave() {
        timer?.invalidate()
        if isPlaying { saveSession(completed: false) }
        isPlaying = false
    }

    private func saveSession(completed: Bool) {
        let duration = Date().timeIntervalSince(sessionStart)
        guard duration > 1 else { return }
        let session = ReadingSession(
            wordIndex: wordIndex,
            speedWPM: speedWPM,
            durationSeconds: duration,
            completed: completed
        )
        session.article = article
        modelContext.insert(session)
        article.sessions.append(session)
    }
}
