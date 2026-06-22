import SwiftUI

struct WordRevealView: View {
    @Bindable var engine: ScrawlGameEngine
    @State private var isWordRevealed = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            ScrawlTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(engine.currentTeam?.name ?? "Team")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(ScrawlTheme.primaryText)
                            Text("Round \(engine.totalRounds - engine.roundsRemaining + 1) of \(engine.totalRounds)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(ScrawlTheme.secondaryText)
                        }
                        Spacer()
                        // Score pills
                        HStack(spacing: 6) {
                            ForEach(engine.teams) { team in
                                Text("\(team.score)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(team.id == engine.currentTeam?.id ? ScrawlTheme.coral : ScrawlTheme.skyBlue.opacity(0.7))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                // Warning
                VStack(spacing: 6) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ScrawlTheme.coral)
                    Text("Everyone else — look away!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ScrawlTheme.coral)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // Word reveal card
                VStack(spacing: 20) {
                    Text("Your secret word:")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.secondaryText)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ScrawlTheme.cardBackground)
                            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 6)

                        if isWordRevealed {
                            Text(engine.currentWord)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(ScrawlTheme.charcoal)
                                .multilineTextAlignment(.center)
                                .padding(24)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(ScrawlTheme.skyBlue)
                                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)

                                Text("Tap to reveal word")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ScrawlTheme.primaryText)

                                Text("Make sure nobody else is looking!")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundStyle(ScrawlTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .onTapGesture {
                        guard !isWordRevealed else { return }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isWordRevealed = true
                        }
                    }
                    .accessibilityLabel(isWordRevealed ? "Word: \(engine.currentWord)" : "Tap to reveal word")
                    .accessibilityHint(isWordRevealed ? "" : "Make sure other players aren't looking")
                }
                .padding(.horizontal, 24)

                Spacer()

                // Ready button
                if isWordRevealed {
                    Button {
                        engine.artistIsReady()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "pencil.tip")
                                .font(.system(size: 18, weight: .semibold))
                            Text("I'm Ready to Draw!")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(ScrawlTheme.skyBlue)
                        .cornerRadius(20)
                        .shadow(color: ScrawlTheme.skyBlue.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLabel("I am ready to draw")
                }
            }
        }
        .onAppear {
            isWordRevealed = false
            pulseAnimation = true
        }
    }
}
