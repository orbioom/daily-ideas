import SwiftUI

struct ShooterView: View {
    let game: OrbGame
    let gridRect: CGRect
    let colorBlindMode: Bool
    let hapticsEnabled: Bool
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient strip
                LinearGradient(
                    colors: [OrbTheme.background, OrbTheme.surface.opacity(0.6), OrbTheme.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Divider()
                        .background(OrbTheme.accent.opacity(0.3))

                    Spacer()

                    // Bubbles row: next | shooter | swap
                    HStack(spacing: 0) {
                        // Next bubble indicator
                        VStack(spacing: 4) {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(OrbTheme.textSecondary)
                            BubbleCircleView(
                                color: game.nextBubble.displayColor(colorBlind: colorBlindMode),
                                size: 42
                            )
                        }
                        .frame(width: 80)

                        Spacer()

                        // Main shooter bubble with launcher base
                        ZStack {
                            // Launcher base platform
                            RoundedRectangle(cornerRadius: 10)
                                .fill(OrbTheme.surfaceAlt)
                                .frame(width: 64, height: 28)
                                .offset(y: 20)

                            // Aim direction indicator arrow
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(OrbTheme.accent.opacity(0.6))
                                .offset(y: -38)
                                .rotationEffect(.radians(game.aimAngle + .pi / 2))
                                .animation(.easeOut(duration: 0.05), value: game.aimAngle)

                            // Current bubble
                            BubbleCircleView(
                                color: game.currentBubble.displayColor(colorBlind: colorBlindMode),
                                size: 60
                            )
                            .shadow(
                                color: game.currentBubble.displayColor(colorBlind: colorBlindMode).opacity(0.6),
                                radius: 12
                            )
                        }

                        Spacer()

                        // Swap button
                        VStack(spacing: 4) {
                            Button(action: {
                                if hapticsEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                game.swapBubbles()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(OrbTheme.accent)
                                    Text("SWAP")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(OrbTheme.textSecondary)
                                }
                                .frame(width: 56, height: 56)
                                .background(OrbTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .frame(width: 80)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Instructions hint
                    Text("Drag to aim  •  Release to shoot")
                        .font(.caption2)
                        .foregroundColor(OrbTheme.textSecondary.opacity(0.6))
                        .padding(.bottom, 8)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        isDragging = true

                        // Compute shooter center in global coordinates
                        let shooterGlobalX = gridRect.midX
                        // Place shooter conceptually just below the grid
                        let shooterGlobalY = gridRect.maxY + 30.0

                        let dx = Double(value.location.x - shooterGlobalX)
                        let dy = Double(value.location.y - shooterGlobalY)

                        // Only update aim if drag is meaningfully upward
                        if dy < 0 || abs(dx) > 20 {
                            let angle = atan2(dy, dx)
                            game.setAimAngle(angle)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        shoot()
                    }
            )
        }
    }

    private func shoot() {
        guard game.phase == .playing else { return }
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        game.shoot(gridRect: gridRect)
    }
}

struct BubbleCircleView: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)

            // Large highlight blob (top-left)
            Ellipse()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.45, height: size * 0.38)
                .offset(x: -size * 0.1, y: -size * 0.2)

            // Small specular dot
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: size * 0.18, height: size * 0.18)
                .offset(x: -size * 0.2, y: -size * 0.28)

            // Outline
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1.2)
                .frame(width: size, height: size)
        }
        .shadow(color: color.opacity(0.5), radius: size * 0.2)
    }
}
