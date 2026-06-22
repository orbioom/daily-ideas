import SwiftUI
import PencilKit

struct DrawPhaseView: View {
    @Bindable var engine: ScrawlGameEngine
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingConfirmPass = false
    @State private var selectedColor: UIColor = .black
    @State private var isErasing = false
    @State private var canvasView = PKCanvasView()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let drawColors: [(UIColor, String)] = [
        (.black, "Black"),
        (.systemRed, "Red"),
        (.systemBlue, "Blue"),
        (.systemGreen, "Green"),
        (UIColor(red: 255 / 255, green: 149 / 255, blue: 0, alpha: 1), "Orange"),
        (.systemPurple, "Purple"),
    ]

    var body: some View {
        ZStack {
            // Canvas
            DrawingCanvas(drawing: $engine.drawing, isEnabled: true)
                .ignoresSafeArea()
                .overlay(
                    // Warning border
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(
                            engine.showTimerWarning ? Color.red.opacity(0.6) : Color.clear,
                            lineWidth: 6
                        )
                        .ignoresSafeArea()
                        .animation(
                            engine.showTimerWarning && !reduceMotion
                                ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                                : .default,
                            value: engine.showTimerWarning
                        )
                )

            // UI overlays
            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                engine.pauseForBackground()
            } else if newPhase == .active {
                engine.resumeFromBackground()
            }
        }
        .confirmationDialog("Pass to guesser?", isPresented: $showingConfirmPass) {
            Button("Pass Phone Now") { engine.passToGuesser() }
            Button("Keep Drawing", role: .cancel) {}
        } message: {
            Text("Pass the phone to \(otherTeamName) to guess your drawing.")
        }
    }

    private var otherTeamName: String {
        guard engine.teams.count > 1 else { return "the other team" }
        let otherIndex = (engine.currentTeamIndex + 1) % engine.teams.count
        return engine.teams[otherIndex].name
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            // Word display
            VStack(alignment: .leading, spacing: 2) {
                Text("Draw this:")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text(engine.currentWord)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(14)

            Spacer()

            // Timer ring
            TimerRing(
                progress: engine.timerProgress,
                timeRemaining: engine.timeRemaining,
                isWarning: engine.showTimerWarning
            )
            .frame(width: 72, height: 72)
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Color picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Eraser toggle
                    Button {
                        isErasing.toggle()
                    } label: {
                        Image(systemName: isErasing ? "pencil" : "eraser")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                isErasing
                                    ? Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255) : .primary
                            )
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                    .accessibilityLabel(isErasing ? "Switch to pen" : "Switch to eraser")

                    Divider()
                        .frame(height: 28)

                    ForEach(drawColors, id: \.1) { (uiColor, name) in
                        Button {
                            isErasing = false
                            selectedColor = uiColor
                        } label: {
                            Circle()
                                .fill(Color(uiColor))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            .white,
                                            lineWidth: selectedColor == uiColor && !isErasing ? 3 : 0
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        }
                        .accessibilityLabel("\(name) color")
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .padding(.horizontal, 16)

            // Action buttons
            HStack(spacing: 12) {
                // Undo
                Button {
                    undoLastStroke()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                }
                .accessibilityLabel("Undo last stroke")

                // Clear
                Button {
                    withAnimation {
                        engine.drawing = PKDrawing()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255))
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                }
                .accessibilityLabel("Clear canvas")

                Spacer()

                // Done/Pass button
                Button {
                    showingConfirmPass = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Done Drawing")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))
                    .cornerRadius(14)
                    .shadow(
                        color: Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255).opacity(0.4),
                        radius: 8, x: 0, y: 4
                    )
                }
                .accessibilityLabel("Done drawing, pass to guesser")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private func undoLastStroke() {
        var strokes = engine.drawing.strokes
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        engine.drawing = PKDrawing(strokes: strokes)
    }
}
