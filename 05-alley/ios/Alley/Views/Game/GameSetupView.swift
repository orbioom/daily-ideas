import SwiftUI

struct GameSetupView: View {
    @Bindable var viewModel: GameViewModel
    @Query private var settingsArr: [AlleySettings]
    @Environment(\.modelContext) private var ctx
    @FocusState private var focusedField: Int?

    var settings: AlleySettings? { settingsArr.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AlleyTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header card
                        VStack(spacing: 8) {
                            Image(systemName: "figure.bowling")
                                .font(.system(size: 48))
                                .foregroundStyle(AlleyTheme.accent)
                            Text("New Game")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 20)

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Location (optional)", systemImage: "mappin.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AlleyTheme.laneColor)

                            TextField("Bowling alley name", text: $viewModel.location)
                                .padding(12)
                                .background(AlleyTheme.frameBackground)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)

                        // Players
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Players", systemImage: "person.2.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AlleyTheme.laneColor)
                                Spacer()
                                Text("\(viewModel.playerNames.count)/6")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            ForEach(Array(viewModel.playerNames.enumerated()), id: \.offset) { index, _ in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(AlleyTheme.accent.opacity(0.25))
                                            .frame(width: 32, height: 32)
                                        Text("\(index + 1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(AlleyTheme.accent)
                                    }

                                    TextField("Player \(index + 1)", text: Binding(
                                        get: { viewModel.playerNames[index] },
                                        set: { viewModel.playerNames[index] = $0 }
                                    ))
                                    .padding(10)
                                    .background(AlleyTheme.frameBackground)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .focused($focusedField, equals: index)
                                    .submitLabel(index < viewModel.playerNames.count - 1 ? .next : .done)
                                    .onSubmit {
                                        if index < viewModel.playerNames.count - 1 {
                                            focusedField = index + 1
                                        } else {
                                            focusedField = nil
                                        }
                                    }

                                    if viewModel.playerNames.count > 1 {
                                        Button {
                                            viewModel.removePlayer(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red.opacity(0.7))
                                                .font(.title3)
                                        }
                                    }
                                }
                            }

                            if viewModel.canAddPlayer {
                                Button {
                                    let newIndex = viewModel.playerNames.count
                                    viewModel.addPlayer()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        focusedField = newIndex
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Player")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AlleyTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AlleyTheme.accent.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AlleyTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Start button
                        Button {
                            // Apply default player count from settings if no names set
                            if let s = settings, viewModel.playerNames.count == 1 && viewModel.playerNames[0] == "Player 1" {
                                let count = s.defaultPlayerCount
                                if count > 1 {
                                    viewModel.playerNames = (1...count).map { "Player \($0)" }
                                }
                            }
                            viewModel.startGame()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                Text("Start Game")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AlleyTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: AlleyTheme.accent.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                if let s = settings {
                    let count = s.defaultPlayerCount
                    if count > 1 && viewModel.playerNames.count == 1 {
                        viewModel.playerNames = (1...count).map { "Player \($0)" }
                    }
                }
            }
        }
    }
}
