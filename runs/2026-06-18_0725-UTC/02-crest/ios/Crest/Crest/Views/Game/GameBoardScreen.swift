import SwiftUI
import SwiftData

struct GameBoardScreen: View {
    @Bindable var vm: GameViewModel
    let onExit: () -> Void
    let onRestart: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var showExitConfirm = false

    var body: some View {
        ZStack {
            settings.feltTheme.gradient(dark: colorScheme == .dark)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                hud
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                Spacer(minLength: 4)
                BoardArea(vm: vm)
                    .padding(.horizontal, 10)
                Spacer(minLength: 4)
                pilesRow
                    .padding(.horizontal, 20)
                controls
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
            }
        }
        .overlay { outcomeOverlay }
        .confirmationDialog("Leave this game?", isPresented: $showExitConfirm, titleVisibility: .visible) {
            Button("Save & exit") { onExit() }
            Button("Keep playing", role: .cancel) { }
        } message: {
            Text("Your progress is saved automatically.")
        }
        .onChange(of: vm.outcome) { _, newValue in
            if newValue != .playing {
                vm.recordResultIfNeeded(into: context)
            }
        }
        .onAppear {
            vm.resumeClock()
            if vm.outcome != .playing {
                vm.recordResultIfNeeded(into: context)
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                showExitConfirm = true
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(.white.opacity(0.18)))
            }
            .accessibilityLabel("Exit game")
            Spacer()
            Text(vm.layout.title + (vm.isDaily ? " · Daily" : ""))
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(.white)
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                Label(Format.clock(vm.elapsed(at: ctx.date)), systemImage: "clock")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.18)))
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(Format.clock(vm.elapsed(at: ctx.date)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    // MARK: HUD

    private var hud: some View {
        HStack(spacing: 10) {
            hudPill(label: "Score", value: Format.score(vm.score), icon: "star.fill")
            hudPill(label: "Combo", value: vm.combo > 0 ? "x\(vm.combo)" : "—", icon: "flame.fill",
                    highlight: vm.combo >= 3)
            hudPill(label: "Left", value: "\(vm.state.tableau.filter { $0 != nil }.count)", icon: "rectangle.stack")
        }
    }

    private func hudPill(label: String, value: String, icon: String, highlight: Bool = false) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(highlight ? Theme.gold : .white.opacity(0.8))
                Text(value)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Text(label.uppercased())
                .font(Theme.rounded(10, .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.12)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(highlight ? Theme.gold.opacity(0.7) : .clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    // MARK: Stock / Waste row

    private var pilesRow: some View {
        HStack {
            if settings.leftHanded { wastePile; Spacer(); stockPile }
            else { stockPile; Spacer(); wastePile }
        }
        .frame(height: 108)
    }

    private var stockPile: some View {
        Button {
            _ = vm.draw(settings: settings)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.cardBack1, Theme.cardBack2],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 74, height: 104)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )
                    .opacity(vm.canDraw ? 1 : 0.45)
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(vm.stockCount)")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
        }
        .buttonStyle(PressableStyle())
        .disabled(!vm.canDraw)
        .accessibilityLabel("Stock pile")
        .accessibilityValue("\(vm.stockCount) cards remaining")
        .accessibilityHint("Draws a card to the waste")
    }

    private var wastePile: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                    .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 74, height: 104)
                if let waste = vm.topWaste {
                    CardView(card: waste, faceUp: true)
                        .frame(width: 74, height: 104)
                        .id(waste.id)
                        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            Text("Waste")
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: vm.topWaste)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Waste pile")
        .accessibilityValue(vm.topWaste?.accessibilityName ?? "empty")
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            controlButton(title: "Undo", icon: "arrow.uturn.backward", enabled: vm.canUndo) {
                vm.undo(settings: settings)
                vm.persist(into: context)
            }
            controlButton(title: "Hint", icon: "lightbulb.fill", enabled: vm.outcome == .playing) {
                vm.requestHint(settings: settings)
            }
            controlButton(title: "Restart", icon: "arrow.clockwise", enabled: true) {
                onRestart()
            }
        }
    }

    private func controlButton(title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(Theme.rounded(12, .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous).fill(.white.opacity(0.14)))
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityHint("\(title) action")
    }

    // MARK: Outcome overlay

    @ViewBuilder
    private var outcomeOverlay: some View {
        if vm.outcome != .playing {
            GameOutcomeOverlay(
                outcome: vm.outcome,
                score: vm.score,
                cardsCleared: vm.cardsCleared,
                longestCombo: vm.longestCombo,
                elapsed: vm.elapsed(at: Date()),
                onPlayAgain: onRestart,
                onHome: onExit
            )
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
        }
    }
}
