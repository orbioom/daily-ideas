import SwiftUI
import SwiftData

struct RivalOnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [RivalSettings]
    @State private var step = 0
    @State private var username = ""
    @State private var favoriteSport: Sport = .nfl

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.18, green: 0.06, blue: 0.06), Color(red: 0.06, green: 0.05, blue: 0.08)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == step ? RivalTheme.red : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: step)
                    }
                }
                .padding(.top, 60)
                .accessibilityLabel("Step \(step+1) of 3")

                Spacer()

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: usernameStep
                    default: sportStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.spring(response: 0.4), value: step)

                Spacer()

                Button(action: advance) {
                    Text(step == 2 ? "Start Picking" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(RivalTheme.red))
                }
                .disabled(step == 1 && username.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Text("🏆").font(.system(size: 80)).accessibilityHidden(true)
            Text("Welcome to Rival")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("Make picks, track predictions, and see how your sports instincts stack up over the season.")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var usernameStep: some View {
        VStack(spacing: 20) {
            Text("👤").font(.system(size: 80)).accessibilityHidden(true)
            Text("What's your name?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            TextField("Your name or handle", text: $username)
                .font(.title3)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14).padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.15)))
                .padding(.horizontal, 32)
                .accessibilityLabel("Your name or handle")
        }
    }

    private var sportStep: some View {
        VStack(spacing: 20) {
            Text("🎯").font(.system(size: 80)).accessibilityHidden(true)
            Text("Favorite Sport?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            VStack(spacing: 8) {
                ForEach(Sport.allCases, id: \.self) { sport in
                    Button(action: { favoriteSport = sport }) {
                        HStack {
                            Image(systemName: sport.icon)
                            Text(sport.rawValue)
                            Spacer()
                            if favoriteSport == sport {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(RivalTheme.gold)
                            }
                        }
                        .font(.headline)
                        .foregroundColor(favoriteSport == sport ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 20).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(favoriteSport == sport ? RivalTheme.red.opacity(0.5) : Color.white.opacity(0.1)))
                    }
                    .accessibilityLabel(sport.rawValue + (favoriteSport == sport ? ", selected" : ""))
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func advance() {
        if step < 2 { step += 1 } else { complete() }
    }

    private func complete() {
        let s = settingsQ.first ?? { let ns = RivalSettings(); context.insert(ns); return ns }()
        s.username = username.trimmingCharacters(in: .whitespaces)
        s.favoriteSport = favoriteSport
        s.onboardingComplete = true
        try? context.save()

        // Seed NFL and NBA leagues
        let (nflLeague, nflTeams) = RivalLeague.seededNFL()
        context.insert(nflLeague)
        for (name, city, abbr) in nflTeams {
            let team = RivalTeam(name: name, city: city, abbreviation: abbr, league: nflLeague)
            context.insert(team)
        }
        let (nbaLeague, nbaTeams) = RivalLeague.seededNBA()
        context.insert(nbaLeague)
        for (name, city, abbr) in nbaTeams {
            let team = RivalTeam(name: name, city: city, abbreviation: abbr, league: nbaLeague)
            context.insert(team)
        }
        try? context.save()
    }
}
