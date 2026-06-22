import SwiftUI
import PencilKit

struct ResultView: View {
    @Bindable var engine: ScrawlGameEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background
            (engine.isCorrect
                ? Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
                : Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255))
                .ignoresSafeArea()
                .opacity(0.15)

            Color(red: 1.0, green: 254 / 255, blue: 245 / 255)
                .ignoresSafeArea()
                .opacity(0.85)

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Result icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                engine.isCorrect
                                    ? Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
                                        .opacity(0.2)
                                    : Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
                                        .opacity(0.2)
                            )
                            .frame(width: 120, height: 120)

                        Text(engine.isCorrect ? "🎉" : "😅")
                            .font(.system(size: 60))
                    }
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.65),
                        value: showContent
                    )

                    VStack(spacing: 8) {
                        Text(engine.isCorrect ? "Correct!" : "Not quite!")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                engine.isCorrect
                                    ? Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
                                    : Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
                            )

                        if engine.isCorrect, let team = engine.currentTeam {
                            Text("\(team.name) earns a point!")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(
                                    Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))
                        }
                    }
                    .opacity(showContent ? 1.0 : 0)
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.2), value: showContent)
                }

                Spacer().frame(height: 28)

                // Word reveal
                VStack(spacing: 8) {
                    Text("The word was:")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))

                    Text(engine.currentWord)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.3), value: showContent)

                Spacer().frame(height: 20)

                // Scores
                VStack(spacing: 8) {
                    Text("Scores")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))

                    HStack(spacing: 10) {
                        ForEach(engine.teams) { team in
                            VStack(spacing: 4) {
                                Text("\(team.score)")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        team.id == engine.currentTeam?.id
                                            ? Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255)
                                            : Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
                                    )
                                Text(team.name)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(
                                        Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                team.id == engine.currentTeam?.id
                                    ? Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255)
                                        .opacity(0.12)
                                    : Color.white
                            )
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.4), value: showContent)

                Spacer()

                // Next turn button
                Button {
                    engine.advanceTurn()
                } label: {
                    HStack(spacing: 10) {
                        Text(isLastTurn ? "See Final Scores!" : "Next Turn")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Image(systemName: isLastTurn ? "trophy.fill" : "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))
                    .cornerRadius(20)
                    .shadow(
                        color: Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255).opacity(0.4),
                        radius: 12, x: 0, y: 6
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(showContent ? 1.0 : 0)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.5), value: showContent)
                .accessibilityLabel(isLastTurn ? "See final scores" : "Next turn")
            }
        }
        .onAppear {
            withAnimation { showContent = true }
        }
    }

    private var isLastTurn: Bool {
        engine.roundsRemaining <= 1 && engine.currentTeamIndex >= engine.teams.count - 1
    }
}
