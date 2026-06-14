import SwiftUI

/// The playable board: top bar (mine counter, timer, reset), the zoomable grid,
/// a flag-mode toggle, and a win/lose overlay. Persists the in-progress game on
/// background and respects Reduce Motion.
struct GameBoardView: View {
    @ObservedObject var vm: GameViewModel
    /// Called to start a fresh board within the same screen (Play again / New game).
    var onPlayAgain: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("haptics") private var haptics = true
    @AppStorage("confirmNewGame") private var confirmNewGame = true

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var showResetConfirm = false
    @State private var showOverlay = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                topBar
                boardArea
                bottomBar
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            if showOverlay {
                resultOverlay
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationTitle(titleText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    requestNewGame()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("New game")
            }
        }
        .onChange(of: vm.phase) { _, phase in
            if phase == .won || phase == .lost {
                vm.recordResultIfNeeded()
                withAnimation(reduceMotion ? nil : .spring(response: 0.4)) {
                    showOverlay = true
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                if vm.phase == .ready { vm.resumeTimerIfNeeded() }
            default:
                vm.stopTimer()
                vm.persist()
            }
        }
        .onAppear {
            if vm.phase == .won || vm.phase == .lost {
                showOverlay = true
            } else {
                vm.resumeTimerIfNeeded()
            }
        }
        .onDisappear { vm.stopTimer(); vm.persist() }
        .confirmationDialog("Start a new game?",
                            isPresented: $showResetConfirm,
                            titleVisibility: .visible) {
            Button("New game", role: .destructive) { restart() }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("Your current progress will be cleared.")
        }
    }

    private var titleText: String {
        switch vm.kind {
        case .standard(let d): return d.title
        case .daily: return "Daily Challenge"
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            counterTile(systemImage: "flag.fill",
                        value: "\(vm.minesRemainingDisplay)",
                        tint: Theme.flag,
                        label: "Mines remaining")
            Spacer()
            flagModeToggle
            Spacer()
            counterTile(systemImage: "timer",
                        value: Formatters.clock(vm.elapsed),
                        tint: Theme.accent,
                        label: "Elapsed time")
        }
    }

    private func counterTile(systemImage: String, value: String, tint: Color, label: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(Theme.mono(18, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private var flagModeToggle: some View {
        Button {
            vm.flagMode.toggle()
            if haptics { Haptics.flag() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: vm.flagMode ? "flag.fill" : "hand.tap.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(vm.flagMode ? "Flag" : "Dig")
                    .font(Theme.rounded(15, .semibold))
            }
            .foregroundStyle(vm.flagMode ? Color.white : Theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(vm.flagMode ? Theme.flag : Theme.accentSoft)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(vm.flagMode ? "Flag mode on" : "Dig mode on")
        .accessibilityHint("Toggle between revealing and flagging cells")
    }

    // MARK: - Board area (zoom + pan)

    private var boardArea: some View {
        GeometryReader { geo in
            let baseCell = idealCellSize(in: geo.size)
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                BoardGrid(vm: vm, cellSize: baseCell * zoom, haptics: haptics)
                    .padding(8)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Theme.hairline)
            )
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let next = lastZoom * value.magnification
                        zoom = min(2.4, max(0.6, next))
                    }
                    .onEnded { _ in lastZoom = zoom }
            )
        }
    }

    /// Cell size that fits the whole board into the available width at zoom 1.
    private func idealCellSize(in size: CGSize) -> CGFloat {
        let cols = CGFloat(max(1, vm.cols))
        let usableW = max(40, size.width - 16)
        let byWidth = usableW / cols
        // Clamp so beginner boards aren't gigantic and expert boards stay tappable.
        return min(46, max(22, byWidth))
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            zoomButton(systemImage: "minus.magnifyingglass") {
                setZoom(zoom - 0.2)
            }
            .accessibilityLabel("Zoom out")
            zoomButton(systemImage: "1.magnifyingglass") {
                setZoom(1)
            }
            .accessibilityLabel("Reset zoom")
            zoomButton(systemImage: "plus.magnifyingglass") {
                setZoom(zoom + 0.2)
            }
            .accessibilityLabel("Zoom in")
            Spacer()
            if vm.noGuessRequested {
                TagPill(text: vm.noGuessFellBack ? "NO-GUESS UNAVAILABLE" : "NO-GUESS",
                        tint: vm.noGuessFellBack ? Theme.inkFaint : Theme.good)
            }
        }
        .padding(.bottom, 6)
    }

    private func zoomButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Theme.hairline)
                )
        }
        .buttonStyle(.plain)
    }

    private func setZoom(_ value: CGFloat) {
        let clamped = min(2.4, max(0.6, value))
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            zoom = clamped
        }
        lastZoom = clamped
    }

    // MARK: - Result overlay

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { withAnimation { showOverlay = false } }
            GlassCard {
                VStack(spacing: 16) {
                    Image(systemName: vm.didWin ? "checkmark.seal.fill" : "burst.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(vm.didWin ? Theme.good : Theme.bad)
                        .accessibilityHidden(true)
                    Text(vm.didWin ? "Field cleared!" : "Boom.")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(vm.didWin
                         ? "Solved in \(Formatters.clock(vm.elapsed))."
                         : "You hit a mine. Want another go?")
                        .font(Theme.rounded(16))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        StatChip(label: "Time", value: Formatters.clock(vm.elapsed))
                        StatChip(label: "Size", value: "\(vm.rows)×\(vm.cols)")
                        StatChip(label: "Mines", value: "\(vm.config.mines)")
                    }
                    .padding(.vertical, 4)

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Play again", systemImage: "arrow.counterclockwise") {
                            restart()
                        }
                        Button("Back to Home") { dismiss() }
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Actions

    private func requestNewGame() {
        if vm.isOver || !confirmNewGame {
            restart()
        } else {
            showResetConfirm = true
        }
    }

    private func restart() {
        withAnimation(reduceMotion ? nil : .easeInOut) { showOverlay = false }
        onPlayAgain()
    }
}
