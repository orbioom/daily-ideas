import SwiftUI
import SwiftData

struct LevelSelectView: View {
    @Query(sort: \BrickHighScore.level) private var scores: [BrickHighScore]
    @State private var playingLevel: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(1...BrickLayout.levels.count, id: \.self) { lvl in
                            LevelCard(level: lvl, highScore: scores.first(where: { $0.level == lvl })?.score ?? 0) {
                                playingLevel = lvl
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Brick")
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.12), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $playingLevel) { lvl in
                GameContainerView(startLevel: lvl, isPresented: Binding(
                    get: { playingLevel == lvl },
                    set: { if !$0 { playingLevel = nil } }
                ))
            }
        }
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}

private struct LevelCard: View {
    let level: Int
    let highScore: Int
    let action: () -> Void

    private let gradient = LinearGradient(
        colors: [Color(red: 1, green: 0.5, blue: 0.1), Color(red: 0.9, green: 0.2, blue: 0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(gradient)
                            .frame(width: 52, height: 52)
                        Text("\(level)")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    Text("Level \(level)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    if highScore > 0 {
                        Label("\(highScore)", systemImage: "trophy.fill")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.yellow)
                    } else {
                        Text("Play to unlock")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(.plain)
    }
}
