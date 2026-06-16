import SwiftUI
import SwiftData

/// Configure a game for a chosen mode (player names, CPU count/difficulty), then start.
struct NewGameSheet: View {
    let mode: GameMode
    let onStart: (GameConfig) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \PlayerProfile.createdAt) private var profiles: [PlayerProfile]

    @State private var soloName = "You"
    @State private var playerNames: [String] = ["Player 1", "Player 2"]
    @State private var cpuCount = 1
    @State private var difficulty: CPUDifficulty = .sharp
    @State private var showPaywall = false

    private var maxPassPlayers: Int {
        isPro ? FreeLimits.maxPassAndPlayPlayersPro : FreeLimits.maxPassAndPlayPlayersFree
    }

    var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .solo, .daily:
                    soloSection
                case .passAndPlay:
                    passSection
                case .vsCPU:
                    cpuSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(mode.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }
                        .fontWeight(.bold)
                        .disabled(!canStart)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var canStart: Bool {
        switch mode {
        case .passAndPlay:
            return playerNames.count >= 2
        default:
            return true
        }
    }

    private var soloSection: some View {
        Section {
            TextField("Your name", text: $soloName)
                .textInputAutocapitalization(.words)
            profilePicker { soloName = $0 }
        } header: {
            Text("Player")
        } footer: {
            Text("Beat your own best. Three rolls per turn, thirteen categories to fill.")
        }
    }

    private var passSection: some View {
        Group {
            Section {
                ForEach(playerNames.indices, id: \.self) { i in
                    HStack {
                        Image(systemName: "person.fill").foregroundStyle(Theme.accent)
                        TextField("Player \(i + 1)", text: Binding(
                            get: { playerNames.indices.contains(i) ? playerNames[i] : "" },
                            set: { if playerNames.indices.contains(i) { playerNames[i] = $0 } }
                        ))
                        .textInputAutocapitalization(.words)
                        if playerNames.count > 2 {
                            Button {
                                if playerNames.indices.contains(i) { playerNames.remove(at: i) }
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(Theme.bad)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove player \(i + 1)")
                        }
                    }
                }
            } header: {
                Text("Players (\(playerNames.count))")
            }

            Section {
                if playerNames.count < maxPassPlayers {
                    Button {
                        playerNames.append("Player \(playerNames.count + 1)")
                    } label: {
                        Label("Add player", systemImage: "plus.circle.fill")
                    }
                } else if !isPro && playerNames.count >= FreeLimits.maxPassAndPlayPlayersFree {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Add 3rd & 4th player", systemImage: "lock.fill")
                            Spacer()
                            ProLockBadge()
                        }
                    }
                }
            } footer: {
                Text(isPro
                     ? "Up to 4 players. Hand the phone around — Pip rotates turns automatically."
                     : "Free supports 2 players. Pip Pro unlocks 3–4 around the table.")
            }
        }
    }

    private var cpuSection: some View {
        Group {
            Section {
                TextField("Your name", text: $soloName)
                    .textInputAutocapitalization(.words)
            } header: { Text("You") }

            Section {
                Stepper(value: $cpuCount, in: 1...3) {
                    HStack {
                        Text("CPU opponents")
                        Spacer()
                        Text("\(cpuCount)").foregroundStyle(Theme.accent).fontWeight(.bold)
                    }
                }
            } header: { Text("Opponents") }

            Section {
                ForEach(CPUDifficulty.allCases) { d in
                    Button {
                        difficulty = d
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(d.rawValue).foregroundStyle(Theme.ink).fontWeight(.semibold)
                                Text(d.subtitle).font(.footnote).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            if difficulty == d {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            } header: { Text("Difficulty") }
        }
    }

    @ViewBuilder
    private func profilePicker(_ apply: @escaping (String) -> Void) -> some View {
        if !profiles.isEmpty {
            Menu {
                ForEach(profiles) { p in
                    Button(p.name) { apply(p.name) }
                }
            } label: {
                Label("Use a saved profile", systemImage: "person.crop.circle")
            }
        }
    }

    private func start() {
        let config: GameConfig
        switch mode {
        case .solo:
            config = .solo(name: soloName)
        case .daily:
            config = .daily(name: soloName, date: .now)
        case .passAndPlay:
            config = .passAndPlay(names: playerNames)
        case .vsCPU:
            config = .vsCPU(playerName: soloName, cpuCount: cpuCount, difficulty: difficulty)
        }
        onStart(config)
    }
}
