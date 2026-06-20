import SwiftUI
import AVFoundation

struct StoryReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var story: FableStory
    @Query private var settingsQ: [FableSettings]

    @State private var currentPage = 0
    @State private var isPlaying = false
    @State private var synth = AVSpeechSynthesizer()
    @State private var darkMode = true

    private var pages: [String] {
        let sorted = story.sortedPages
        if !sorted.isEmpty { return sorted.map { $0.text } }
        // Split content into paragraphs as pages
        let paras = story.content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paras.isEmpty ? [story.content] : paras
    }

    private var bg: Color { darkMode ? Color(red: 0.08, green: 0.06, blue: 0.18) : Color(uiColor: .systemBackground) }
    private var fg: Color { darkMode ? .white : Color(uiColor: .label) }
    private var secondaryFg: Color { darkMode ? Color.white.opacity(0.6) : Color(uiColor: .secondaryLabel) }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                readerToolbar
                Spacer()
                pageText
                Spacer()
                navigationControls
            }
        }
        .onDisappear { stopSpeech() }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    private var readerToolbar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(secondaryFg)
            }
            .accessibilityLabel("Close reader")

            Spacer()

            Text(story.title)
                .font(.headline)
                .foregroundColor(fg)
                .lineLimit(1)

            Spacer()

            Button(action: { darkMode.toggle() }) {
                Image(systemName: darkMode ? "sun.max.fill" : "moon.fill")
                    .font(.title3)
                    .foregroundColor(secondaryFg)
            }
            .accessibilityLabel(darkMode ? "Switch to light mode" : "Switch to dark mode")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var pageText: some View {
        VStack(spacing: 20) {
            Text("\(currentPage + 1) / \(pages.count)")
                .font(.caption)
                .foregroundColor(secondaryFg)
                .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

            if currentPage < pages.count {
                Text(pages[currentPage])
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(fg)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    private var navigationControls: some View {
        VStack(spacing: 16) {
            Button(action: { toggleSpeech() }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(FableTheme.accent)
            }
            .accessibilityLabel(isPlaying ? "Pause narration" : "Play narration")

            HStack(spacing: 48) {
                Button(action: { goPage(-1) }) {
                    Image(systemName: "chevron.left.circle")
                        .font(.system(size: 36))
                        .foregroundColor(currentPage == 0 ? secondaryFg : fg)
                }
                .disabled(currentPage == 0)
                .accessibilityLabel("Previous page")

                Button(action: { goPage(1) }) {
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 36))
                        .foregroundColor(currentPage >= pages.count - 1 ? secondaryFg : fg)
                }
                .disabled(currentPage >= pages.count - 1)
                .accessibilityLabel("Next page")
            }
        }
        .padding(.bottom, 48)
    }

    private func goPage(_ delta: Int) {
        stopSpeech()
        let next = currentPage + delta
        guard next >= 0 && next < pages.count else { return }
        currentPage = next
    }

    private func toggleSpeech() {
        if isPlaying {
            stopSpeech()
        } else {
            guard currentPage < pages.count else { return }
            let utt = AVSpeechUtterance(string: pages[currentPage])
            let speed = settingsQ.first?.narrationSpeed ?? 0.5
            utt.rate = Float(AVSpeechUtteranceMinimumSpeechRate + (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * speed)
            utt.voice = AVSpeechSynthesisVoice(language: "en-US")
            utt.pitchMultiplier = 1.1
            synth.speak(utt)
            isPlaying = true
        }
    }

    private func stopSpeech() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isPlaying = false
    }
}
