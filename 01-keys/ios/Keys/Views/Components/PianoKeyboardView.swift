import SwiftUI

struct PianoKeyboardView: View {
    let startMidi: Int
    let endMidi: Int
    let highlightedNotes: Set<Int>
    let correctNotes: Set<Int>
    let showLabels: Bool
    let onNoteTap: (Int) -> Void

    init(
        startMidi: Int = 48,
        endMidi: Int = 84,
        highlightedNotes: Set<Int> = [],
        correctNotes: Set<Int> = [],
        showLabels: Bool = true,
        onNoteTap: @escaping (Int) -> Void
    ) {
        self.startMidi = startMidi
        self.endMidi = endMidi
        self.highlightedNotes = highlightedNotes
        self.correctNotes = correctNotes
        self.showLabels = showLabels
        self.onNoteTap = onNoteTap
    }

    private var whiteKeys: [Int] {
        (startMidi...endMidi).filter { !PianoEngine.isBlackKey($0) }
    }

    private var blackKeys: [Int] {
        (startMidi...endMidi).filter { PianoEngine.isBlackKey($0) }
    }

    // Width per white key
    private let whiteKeyWidth: CGFloat = 44
    private let whiteKeyHeight: CGFloat = 160
    private let blackKeyWidth: CGFloat = 28
    private let blackKeyHeight: CGFloat = 100

    // X offset of a midi note relative to start of keyboard
    private func xOffset(for midi: Int) -> CGFloat {
        let whitesBefore = (startMidi...midi).filter { !PianoEngine.isBlackKey($0) }.count
        if PianoEngine.isBlackKey(midi) {
            // Black key sits between two white keys
            let prevWhite = whitesBefore
            return CGFloat(prevWhite) * whiteKeyWidth - blackKeyWidth / 2 - 2
        } else {
            return CGFloat(whitesBefore - 1) * whiteKeyWidth
        }
    }

    private var totalWidth: CGFloat {
        CGFloat(whiteKeys.count) * whiteKeyWidth
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.self) { midi in
                        WhiteKey(
                            midi: midi,
                            isHighlighted: highlightedNotes.contains(midi),
                            isCorrect: correctNotes.contains(midi),
                            showLabel: showLabels,
                            width: whiteKeyWidth,
                            height: whiteKeyHeight
                        ) {
                            onNoteTap(midi)
                        }
                    }
                }

                // Black keys overlaid
                ForEach(blackKeys, id: \.self) { midi in
                    BlackKey(
                        midi: midi,
                        isHighlighted: highlightedNotes.contains(midi),
                        isCorrect: correctNotes.contains(midi),
                        width: blackKeyWidth,
                        height: blackKeyHeight
                    ) {
                        onNoteTap(midi)
                    }
                    .offset(x: xOffset(for: midi))
                }
            }
            .frame(width: totalWidth, height: whiteKeyHeight)
        }
        .frame(height: whiteKeyHeight)
    }
}

struct WhiteKey: View {
    let midi: Int
    let isHighlighted: Bool
    let isCorrect: Bool
    let showLabel: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false

    private var noteName: String {
        let names = ["C","","D","","E","F","","G","","A","","B"]
        return names[midi % 12]
    }

    private var keyColor: Color {
        if isCorrect { return Color.green.opacity(0.4) }
        if isHighlighted { return KeysTheme.accent.opacity(0.4) }
        if isPressed { return Color(.systemGray5) }
        return Color(.white)
    }

    var body: some View {
        Button(action: {
            isPressed = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(keyColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )

                if showLabel && !noteName.isEmpty {
                    Text(noteName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isHighlighted || isCorrect ? KeysTheme.accent : Color(.systemGray))
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(width: width - 2, height: height)
        .padding(.horizontal, 1)
        .buttonStyle(.plain)
        .accessibilityLabel("\(PianoEngine.noteName(midi)) key")
        .accessibilityHint("Tap to play note")
    }
}

struct BlackKey: View {
    let midi: Int
    let isHighlighted: Bool
    let isCorrect: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var isPressed = false

    private var keyColor: Color {
        if isCorrect { return Color.green }
        if isHighlighted { return KeysTheme.accent }
        if isPressed { return Color(red: 0.20, green: 0.20, blue: 0.25) }
        return KeysTheme.keyBlack
    }

    var body: some View {
        Button(action: {
            isPressed = true
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            RoundedRectangle(cornerRadius: 4)
                .fill(keyColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                )
        }
        .frame(width: width, height: height)
        .buttonStyle(.plain)
        .zIndex(1)
        .accessibilityLabel("\(PianoEngine.noteName(midi)) key")
        .accessibilityHint("Tap to play note")
    }
}
