import SwiftUI

struct DropOnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage: Int = 0
    @State private var animateBoard: Bool = false
    @State private var selectedDifficulty: Int = 2

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.22),
                    Color(red: 0.10, green: 0.14, blue: 0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? DropTheme.accent : .white.opacity(0.3))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animateBoard = true
            }
        }
    }

    // MARK: - Page 1: Intro

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon area
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [DropTheme.accent.opacity(0.25), DropTheme.boardColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )

                Text("⬇️")
                    .font(.system(size: 48))
            }

            VStack(spacing: 12) {
                Text("Drop")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(DropTheme.accent)

                Text("Four in a row wins.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Classic Connect Four — no ads,\npure strategy, real AI.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Mini animated board preview
            miniBoard
                .padding(.horizontal, 24)
                .frame(height: 180)

            Spacer()

            nextButton("Get Started") {
                withAnimation { currentPage = 1 }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private var miniBoard: some View {
        let previewGrid: [[DropCell]] = {
            var g = Array(repeating: Array(repeating: DropCell.empty, count: 7), count: 6)
            // Place some pieces to show the game
            g[5][0] = .human;  g[5][1] = .cpu;   g[5][2] = .human
            g[5][3] = .cpu;    g[4][3] = .human;  g[4][2] = .cpu
            g[3][3] = .human;  g[3][2] = .cpu;    g[2][3] = .human
            return g
        }()
        let winCells: Set<[Int]> = [[2,3],[3,3],[4,3],[5,3]]

        return GeometryReader { geo in
            let cellSize = min(geo.size.width / 7, geo.size.height / 6)
            let boardW = cellSize * 7
            let boardH = cellSize * 6
            let offsetX = (geo.size.width - boardW) / 2
            let offsetY = (geo.size.height - boardH) / 2

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: cellSize * 0.15)
                    .fill(DropTheme.boardColor)
                    .frame(width: boardW, height: boardH)
                    .offset(x: offsetX, y: offsetY)

                ForEach(0..<6, id: \.self) { row in
                    ForEach(0..<7, id: \.self) { col in
                        let cx = offsetX + CGFloat(col) * cellSize + cellSize / 2
                        let cy = offsetY + CGFloat(row) * cellSize + cellSize / 2
                        let pad = cellSize * 0.1
                        let r = (cellSize - pad * 2) / 2
                        let cell = previewGrid[row][col]
                        let isWin = winCells.contains([row, col])

                        ZStack {
                            Circle()
                                .fill(DropTheme.slotColor)
                                .frame(width: r * 2, height: r * 2)

                            if cell != .empty {
                                Circle()
                                    .fill(cell == .human ? DropTheme.humanColor : DropTheme.cpuColor)
                                    .frame(width: r * 2, height: r * 2)
                                    .overlay(
                                        Circle()
                                            .fill(RadialGradient(
                                                colors: [.white.opacity(0.3), .clear],
                                                center: UnitPoint(x: 0.35, y: 0.3),
                                                startRadius: 0,
                                                endRadius: r * 0.8
                                            ))
                                    )
                                    .overlay(
                                        isWin ? Circle()
                                            .stroke(Color.white.opacity(animateBoard ? 1.0 : 0.4),
                                                    lineWidth: animateBoard ? 3 : 1.5)
                                            .scaleEffect(animateBoard ? 1.1 : 1.0) : nil
                                    )
                            }
                        }
                        .position(x: cx, y: cy)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Page 2: Difficulty

    private var page2: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "cpu.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [DropTheme.accent, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: DropTheme.accent.opacity(0.5), radius: 10)

            VStack(spacing: 12) {
                Text("Challenge the CPU")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Pick your difficulty and face\na minimax AI that plays to win.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Difficulty cards
            VStack(spacing: 12) {
                ForEach([
                    (1, "Easy", "Warm up your strategy", "🌱"),
                    (2, "Medium", "A real challenge awaits", "⚡"),
                    (3, "Hard", "Full depth AI — good luck", "🔥")
                ], id: \.0) { level, name, desc, emoji in
                    Button {
                        selectedDifficulty = level
                        UserDefaults.standard.set(level, forKey: "drop_difficulty")
                    } label: {
                        HStack(spacing: 16) {
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.white.opacity(0.08)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            Spacer()

                            if selectedDifficulty == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DropTheme.accent)
                                    .font(.title3)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(selectedDifficulty == level ? 0.14 : 0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            selectedDifficulty == level ? DropTheme.accent.opacity(0.6) : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        )
                    }
                    .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            nextButton("Continue") {
                withAnimation { currentPage = 2 }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Page 3: Stats

    private var page3: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [Color.green, DropTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .shadow(color: Color.green.opacity(0.4), radius: 10)

            VStack(spacing: 12) {
                Text("Track Your Wins")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Every game is recorded. Watch\nyour win rate climb over time.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Stats preview cards
            HStack(spacing: 16) {
                statPreviewCard(value: "—", label: "Wins", color: .green)
                statPreviewCard(value: "—", label: "Losses", color: .red)
                statPreviewCard(value: "—", label: "Draws", color: .orange)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DropTheme.accent)
                    Text("Ad-free forever")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(DropTheme.accent)
                    Text("Plays fully offline")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .foregroundStyle(DropTheme.accent)
                    Text("Real minimax AI opponent")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.07))
            )
            .padding(.horizontal, 24)

            Spacer()

            nextButton("Let's Play") {
                onComplete()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private func statPreviewCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func nextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(DropTheme.accent)
                )
                .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.38))
        }
    }
}
