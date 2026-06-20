import SwiftUI

struct WritingView: View {
    let word: HskWord
    let onResult: (Bool) -> Void

    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var isChecked = false
    @State private var showEncouragement = false

    private let encouragements = [
        "Great stroke!",
        "Beautiful character!",
        "Looking good!",
        "Keep it up!",
        "Excellent form!",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Prompt
            VStack(spacing: 8) {
                Text("Write this character")
                    .font(ShuTheme.labelFont(size: 15))
                    .foregroundStyle(ShuTheme.subtleText)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(word.character)
                            .font(.system(size: 52, weight: .thin))
                            .foregroundStyle(ShuTheme.gold)
                        Text(word.pinyin)
                            .font(ShuTheme.pinyinFont(size: 16))
                            .foregroundStyle(ShuTheme.toneColor(for: word.tone))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.english)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(ShuTheme.primaryText)
                        Text(word.exampleSentence)
                            .font(.system(size: 13))
                            .foregroundStyle(ShuTheme.subtleText)
                    }
                }

                // Speaker
                Button {
                    SpeechManager.speak(word.character)
                } label: {
                    Label("Hear it", systemImage: "speaker.wave.2.fill")
                        .font(ShuTheme.labelFont(size: 13))
                        .foregroundStyle(ShuTheme.gold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(ShuTheme.gold.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer(minLength: 16)

            // Canvas
            ZStack {
                // Grid guide lines
                canvasGuide

                // Ghost character (faint reference)
                Text(word.character)
                    .font(.system(size: 200, weight: .thin))
                    .foregroundStyle(Color.white.opacity(0.04))

                // User strokes
                Canvas { context, size in
                    let allStrokes = strokes + (currentStroke.isEmpty ? [] : [currentStroke])
                    for stroke in allStrokes {
                        guard stroke.count > 1 else { continue }
                        var path = Path()
                        path.move(to: stroke[0])
                        for pt in stroke.dropFirst() {
                            path.addLine(to: pt)
                        }
                        context.stroke(
                            path,
                            with: .color(ShuTheme.gold),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            currentStroke.append(value.location)
                        }
                        .onEnded { _ in
                            if !currentStroke.isEmpty {
                                strokes.append(currentStroke)
                                currentStroke = []
                            }
                        }
                )

                // Encouragement overlay
                if showEncouragement {
                    Text(encouragements.randomElement() ?? "Great!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ShuTheme.correctGreen)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(ShuTheme.correctGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(ShuTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: ShuTheme.cardRadius)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // Action buttons
            HStack(spacing: 12) {
                // Clear
                Button {
                    withAnimation {
                        strokes = []
                        currentStroke = []
                        showEncouragement = false
                        isChecked = false
                    }
                } label: {
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(ShuTheme.subtleText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
                }

                // Check
                Button {
                    guard !strokes.isEmpty else { return }
                    withAnimation {
                        showEncouragement = true
                        isChecked = true
                    }
                    SpeechManager.speak(word.character)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        onResult(true)
                    }
                } label: {
                    Label("Check", systemImage: "checkmark")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(strokes.isEmpty ? ShuTheme.subtleText : ShuTheme.darkNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(strokes.isEmpty ? Color.white.opacity(0.07) : ShuTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
                }
                .disabled(strokes.isEmpty || isChecked)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onChange(of: word.id) {
            strokes = []
            currentStroke = []
            showEncouragement = false
            isChecked = false
        }
    }

    // MARK: - Canvas Guide
    private var canvasGuide: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                // Vertical center line
                path.move(to: CGPoint(x: w / 2, y: 0))
                path.addLine(to: CGPoint(x: w / 2, y: h))
                // Horizontal center line
                path.move(to: CGPoint(x: 0, y: h / 2))
                path.addLine(to: CGPoint(x: w, y: h / 2))
                // Diagonals (lighter)
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: w, y: h))
                path.move(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: 0, y: h))
            }
            .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
        }
    }
}

#Preview {
    ZStack {
        ShuTheme.darkNavy.ignoresSafeArea()
        WritingView(word: hskWords[0], onResult: { _ in })
    }
}
