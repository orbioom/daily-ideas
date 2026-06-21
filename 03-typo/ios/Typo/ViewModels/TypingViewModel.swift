import Foundation
import SwiftUI
import Observation

enum TestState {
    case idle, running, finished
}

@Observable
final class TypingViewModel {
    var text: String = ""
    var typed: String = ""
    var state: TestState = .idle
    var timeRemaining: Int = 60
    var elapsedSeconds: Int = 0
    var liveWpm: Double = 0
    var mode: TypingMode = .words
    var duration: TestDuration = .sixty
    var wordCount: WordCount = .twenty

    private var timer: Timer?
    private var startTime: Date?
    private var totalDuration: Int = 60

    var currentIndex: Int { typed.count }

    var charStates: [(Character, CharState)] {
        var result: [(Character, CharState)] = []
        for (i, ch) in text.enumerated() {
            if i < typed.count {
                let typedChar = typed[typed.index(typed.startIndex, offsetBy: i)]
                result.append((ch, typedChar == ch ? .correct : .wrong))
            } else if i == typed.count {
                result.append((ch, .cursor))
            } else {
                result.append((ch, .pending))
            }
        }
        return result
    }

    var correctChars: Int {
        zip(text, typed).filter { $0.0 == $0.1 }.count
    }

    var totalTypedChars: Int { typed.count }

    var accuracy: Double {
        guard typed.count > 0 else { return 100 }
        return Double(correctChars) / Double(typed.count) * 100
    }

    var wpm: Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = Double(elapsedSeconds) / 60.0
        let words = Double(correctChars) / 5.0
        return words / minutes
    }

    var rawWpm: Double {
        guard elapsedSeconds > 0 else { return 0 }
        let minutes = Double(elapsedSeconds) / 60.0
        let words = Double(typed.count) / 5.0
        return words / minutes
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalDuration)
    }

    var isFinished: Bool { state == .finished }

    func configure(mode: TypingMode, duration: TestDuration, wordCount: WordCount) {
        self.mode = mode
        self.duration = duration
        self.wordCount = wordCount
        reset()
    }

    func reset() {
        stopTimer()
        totalDuration = duration.rawValue
        timeRemaining = totalDuration
        elapsedSeconds = 0
        liveWpm = 0
        typed = ""
        state = .idle
        text = TypingContent.generate(mode: mode, count: wordCount.rawValue)
    }

    func startIfNeeded() {
        guard state == .idle else { return }
        state = .running
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tick()
        }
    }

    func handleInput(_ newText: String) {
        guard state == .running || state == .idle else { return }
        if state == .idle { startIfNeeded() }
        if newText.count > text.count { return }
        typed = newText
        updateLiveWpm()
        if typed.count >= text.count { finish() }
    }

    private func tick() {
        elapsedSeconds += 1
        timeRemaining = max(0, totalDuration - elapsedSeconds)
        updateLiveWpm()
        if timeRemaining == 0 { finish() }
    }

    private func updateLiveWpm() {
        guard elapsedSeconds > 0 else { return }
        let minutes = Double(elapsedSeconds) / 60.0
        liveWpm = (Double(correctChars) / 5.0) / max(minutes, 0.01)
    }

    private func finish() {
        stopTimer()
        if state != .finished {
            state = .finished
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

enum CharState {
    case correct, wrong, cursor, pending
}
