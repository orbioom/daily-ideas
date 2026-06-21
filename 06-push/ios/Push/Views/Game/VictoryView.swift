import SwiftUI

/// Full-screen celebration overlay shown when a level is solved.
/// Presents a trophy, star rating, move/push stats, and action buttons.
struct VictoryView: View {
    let level: SokobanLevel
    let moves: Int
    let pushes: Int
    let stars: Int
    let parMoves: Int
    let onNextLevel: () -> Void
    let onReplay: () -> Void
    let onBack: () -> Void

    @State private var trophyScale: CGFloat = 0.4
    @State private var trophyOpacity: Double = 0
    @State private var contentOffset: CGFloat = 40
    @State private var contentOpacity: Double = 0
    @State private var starScales: [CGFloat] = [0.2, 0.2, 0.2]

    private var beatPar: Bool { moves <= parMoves }

    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 0) {
                // Trophy + stars
                trophySection
                    .padding(.top, 36)
                    .padding(.bottom, 20)

                // Title
                titleSection
                    .padding(.bottom, 24)

                // Stats
                statsRow
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)

                // Actions
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                // Back
                backButton
                    .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(PushTheme.background)
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            )
            .padding(.horizontal, 24)
            .offset(y: contentOffset)
            .opacity(contentOpacity)
        }
        .onAppear { runEntranceAnimation() }
    }

    // MARK: - Trophy Section

    private var trophySection: some View {
        VStack(spacing: 14) {
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [PushTheme.accent.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 52))
                    .foregroundColor(PushTheme.accent)
                    .scaleEffect(trophyScale)
                    .opacity(trophyOpacity)
            }

            // Stars
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .font(.system(size: 30))
                        .foregroundColor(i < stars ? .yellow : PushTheme.wall.opacity(0.18))
                        .scaleEffect(starScales[i])
                }
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("Level Complete!")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .foregroundColor(PushTheme.wall)

            Text(level.title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.45))

            if beatPar {
                Label("Under par!", systemImage: "checkmark.seal.fill")
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundColor(PushTheme.boxOnTarget)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(moves)",
                label: "Moves",
                icon: "arrow.up.arrow.down",
                highlight: beatPar
            )
            Divider().frame(height: 44).opacity(0.3)
            statCell(
                value: "\(pushes)",
                label: "Pushes",
                icon: "arrow.right.square",
                highlight: false
            )
            Divider().frame(height: 44).opacity(0.3)
            statCell(
                value: "\(parMoves)",
                label: "Par",
                icon: "star",
                highlight: false
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    private func statCell(value: String, label: String, icon: String, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(highlight ? PushTheme.boxOnTarget : PushTheme.wall.opacity(0.35))
            Text(value)
                .font(.system(.title, design: .rounded, weight: .black))
                .foregroundColor(highlight ? PushTheme.boxOnTarget : PushTheme.wall)
                .monospacedDigit()
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Replay button
            Button(action: onReplay) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Replay")
                }
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundColor(PushTheme.wall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(PushTheme.wall.opacity(0.18), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // Next Level button
            Button(action: onNextLevel) {
                HStack(spacing: 6) {
                    Text("Next Level")
                    Image(systemName: "arrow.right")
                }
                .font(.system(.callout, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(PushTheme.accent)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Text("Back to Levels")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Entrance Animation

    private func runEntranceAnimation() {
        // Card slides up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
            contentOffset = 0
            contentOpacity = 1
        }

        // Trophy pops
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.2)) {
            trophyScale = 1
            trophyOpacity = 1
        }

        // Stars cascade in
        for i in 0..<3 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.38 + Double(i) * 0.12)) {
                starScales[i] = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        PushTheme.background.ignoresSafeArea()
        VictoryView(
            level: allLevels[0],
            moves: 2,
            pushes: 1,
            stars: 3,
            parMoves: 2,
            onNextLevel: { },
            onReplay: { },
            onBack: { }
        )
    }
}
