import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("highlightConflicts") private var highlightConflicts = true

    @State private var session: GameSession
    @State private var timer: Timer?
    @State private var showWin = false
    @State private var paused = false

    init(session: GameSession) {
        _session = State(initialValue: session)
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 14) {
                statusBar
                BoardView(session: session)
                    .padding(.horizontal, 12)
                    .opacity(paused ? 0.05 : 1)
                    .overlay { if paused { pausedOverlay } }
                Spacer(minLength: 0)
                controls
                NumberPad(session: session)
            }
            .padding(.vertical, 8)

            if showWin { winOverlay }
        }
        .navigationTitle(session.difficulty.title + (session.game.isDaily ? " · Daily" : ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { togglePause() } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(paused ? "Resume" : "Pause")
                .disabled(session.isComplete)
            }
        }
        .onAppear { if session.isComplete { showWin = true } else { startTimer() } }
        .onDisappear { timer?.invalidate() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { timer?.invalidate() }
            else if !paused && !session.isComplete { startTimer() }
        }
        .onChange(of: session.justCompleted) { _, done in
            if done { timer?.invalidate(); withAnimation(Brand.ease()) { showWin = true } }
        }
    }

    private var statusBar: some View {
        HStack {
            Label(StatsEngine.format(session.elapsed), systemImage: "clock")
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text2)
                .contentTransition(.numericText())
            Spacer()
            Label("\(session.mistakes)", systemImage: "xmark.circle")
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(session.mistakes > 0 ? Brand.danger : Brand.text2)
            Spacer()
            Label("\(session.remaining) left", systemImage: "square.dashed")
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text2)
        }
        .padding(.horizontal, 22)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            controlButton("Undo", "arrow.uturn.backward", enabled: session.canUndo) { session.undo() }
            controlButton("Erase", "eraser", enabled: true) { session.clear() }
            controlButton(session.noteMode ? "Notes On" : "Notes", "pencil",
                          enabled: true, active: session.noteMode) {
                session.noteMode.toggle(); Haptics.selection()
            }
            controlButton("Hint", "lightbulb", enabled: !session.isComplete) { session.hint() }
        }
        .padding(.horizontal, 18)
    }

    private func controlButton(_ title: String, _ icon: String, enabled: Bool,
                               active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(active ? .white : Brand.text2)
            .background {
                if active { RoundedRectangle(cornerRadius: 12).fill(session.difficulty.tint) }
                else { RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial) }
            }
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }

    private var pausedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "pause.circle.fill").font(.system(size: 50)).foregroundStyle(Brand.text2)
            Text("Paused").font(.title3.bold()).foregroundStyle(Brand.text)
            Button("Resume") { togglePause() }.buttonStyle(InkButtonStyle()).frame(width: 160)
        }
    }

    private var winOverlay: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60)).foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("Solved!").font(.largeTitle.bold()).foregroundStyle(Brand.text)
                Text(session.difficulty.title + (session.game.isDaily ? " · Daily puzzle" : ""))
                    .font(.headline).foregroundStyle(session.difficulty.tint)
                HStack(spacing: 12) {
                    StatTile(value: StatsEngine.format(session.elapsed), label: "Time")
                    StatTile(value: "\(session.mistakes)", label: "Mistakes",
                             tint: session.mistakes == 0 ? Brand.live : Brand.text)
                    StatTile(value: "\(session.hintsUsed)", label: "Hints")
                }
                .padding(.horizontal, 24)
                if session.mistakes == 0 && session.hintsUsed == 0 {
                    Label("Flawless — no mistakes, no hints", systemImage: "star.fill")
                        .font(.subheadline).foregroundStyle(Brand.magic)
                }
                Button("Done") { dismiss() }
                    .buttonStyle(InkButtonStyle())
                    .padding(.horizontal, 40)
            }
            .padding()
        }
        .transition(.opacity)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard !paused else { return }
            session.tick()
        }
    }

    private func togglePause() {
        paused.toggle()
        Haptics.tap()
        if paused { timer?.invalidate() } else { startTimer() }
    }
}
