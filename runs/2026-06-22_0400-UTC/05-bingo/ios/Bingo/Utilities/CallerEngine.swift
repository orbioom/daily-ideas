import Foundation
import AVFoundation

@Observable
class CallerEngine: NSObject {
    var calledItems: [String] = []
    var remainingItems: [String] = []
    var lastCalled: String = ""
    var isRunning: Bool = false
    var isPaused: Bool = false
    var callDelay: Double = 5.0
    var speechEnabled: Bool = true
    var onWinCheck: (() -> Void)?
    var onItemCalled: ((String) -> Void)?

    private var timer: Timer?
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func startGame(items: [String]) {
        calledItems = []
        remainingItems = items.shuffled()
        lastCalled = ""
        isRunning = true
        isPaused = false
    }

    func startAutoAdvance() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: callDelay, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning, !self.isPaused else { return }
            self.callNext()
        }
    }

    func stopAutoAdvance() {
        timer?.invalidate()
        timer = nil
    }

    func callNext() {
        guard !remainingItems.isEmpty, isRunning else {
            if remainingItems.isEmpty {
                isRunning = false
            }
            return
        }
        let item = remainingItems.removeFirst()
        calledItems.append(item)
        lastCalled = item
        onItemCalled?(item)
        speakItem(item)
    }

    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        isPaused = false
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        synthesizer.stopSpeaking(at: .immediate)
        calledItems = []
        remainingItems = []
        lastCalled = ""
        isRunning = false
        isPaused = false
    }

    private func speakItem(_ item: String) {
        guard speechEnabled else { return }
        let spokenText: String
        if item == "FREE" {
            spokenText = "Free space"
        } else if item.count >= 2, let firstChar = item.first, "BINGO".contains(firstChar), Int(item.dropFirst()) != nil {
            let letter = String(item.prefix(1))
            let number = String(item.dropFirst())
            spokenText = "\(letter) \(number)"
        } else {
            spokenText = item
        }

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: spokenText)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func announceWinner(cardLabel: String) {
        guard speechEnabled else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: "Bingo! We have a winner! \(cardLabel)")
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.2
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    var totalItems: Int {
        calledItems.count + remainingItems.count
    }

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(calledItems.count) / Double(totalItems)
    }
}

extension CallerEngine: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Called when speech utterance finishes — reserved for future use
    }
}
