import SwiftUI
import SwiftData

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsArray: [ScrawlSettings]
    @Query private var customLists: [CustomWordList]

    @State private var teamNames: [String] = ["Team 1", "Team 2"]
    @State private var selectedPackId: String = "animals"
    @State private var selectedCustomListId: String? = nil
    @State private var timerSeconds: Int = 60
    @State private var roundCount: Int = 3
    @State private var showingGame = false
    @State private var engine = ScrawlGameEngine()

    private var settings: ScrawlSettings? { settingsArray.first }

    private var selectedWords: [String] {
        if selectedPackId == "custom", let listId = selectedCustomListId {
            let list = customLists.first { $0.id.uuidString == listId }
            return list?.words ?? []
        }
        return WordPackLibrary.words(for: selectedPackId)
    }

    private var selectedPackName: String {
        if selectedPackId == "custom", let listId = selectedCustomListId {
            return customLists.first { $0.id.uuidString == listId }?.name ?? "Custom"
        }
        return WordPackLibrary.pack(for: selectedPackId)?.name ?? "Animals"
    }

    private var canStart: Bool {
        let validTeams = teamNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return validTeams.count >= 2 && selectedWords.count >= 5
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    teamsSection
                    wordPackSection
                    timerSection
                    roundsSection
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(ScrawlTheme.background.ignoresSafeArea())
            .navigationTitle("Game Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(ScrawlTheme.coral)
                        .accessibilityLabel("Cancel setup")
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                GameFlowView(engine: engine)
            }
        }
        .onAppear {
            if let s = settings {
                timerSeconds = s.timerSeconds
                roundCount = s.roundCount
            }
        }
    }

    // MARK: - Sections

    private var teamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Teams", icon: "person.2.fill")

            VStack(spacing: 8) {
                ForEach(teamNames.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(teamColor(index).opacity(0.2))
                                .frame(width: 36, height: 36)
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(teamColor(index))
                        }

                        TextField("Team \(index + 1) name", text: $teamNames[index])
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .textFieldStyle(.plain)
                            .accessibilityLabel("Team \(index + 1) name")

                        if teamNames.count > 2 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    teamNames.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(ScrawlTheme.coral)
                                    .font(.system(size: 20))
                            }
                            .accessibilityLabel("Remove team \(index + 1)")
                        }
                    }
                    .padding(14)
                    .scrawlCard()
                }
            }

            if teamNames.count < 8 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        teamNames.append("Team \(teamNames.count + 1)")
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Team")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(ScrawlTheme.skyBlue)
                }
                .accessibilityLabel("Add another team")
            }
        }
    }

    private var wordPackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Word Pack", icon: "rectangle.stack.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WordPackLibrary.allPacks) { pack in
                        PackSelectionCard(
                            pack: pack,
                            isSelected: selectedPackId == pack.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPackId = pack.id
                                selectedCustomListId = nil
                            }
                        }
                    }

                    // Custom lists
                    ForEach(customLists.filter { $0.isValid }) { list in
                        CustomPackCard(
                            list: list,
                            isSelected: selectedPackId == "custom" && selectedCustomListId == list.id.uuidString
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPackId = "custom"
                                selectedCustomListId = list.id.uuidString
                            }
                        }
                    }
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4)
            }
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Timer", icon: "timer")

            HStack(spacing: 10) {
                ForEach([30, 60, 90], id: \.self) { seconds in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            timerSeconds = seconds
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(seconds)s")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text(seconds == 30 ? "Quick" : seconds == 60 ? "Normal" : "Relaxed")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(timerSeconds == seconds ? ScrawlTheme.skyBlue : ScrawlTheme.cardBackground)
                        .foregroundStyle(timerSeconds == seconds ? .white : ScrawlTheme.primaryText)
                        .cornerRadius(12)
                        .shadow(color: timerSeconds == seconds ? ScrawlTheme.skyBlue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .accessibilityLabel("\(seconds) second timer")
                    .accessibilityAddTraits(timerSeconds == seconds ? .isSelected : [])
                }
            }
        }
    }

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Rounds", icon: "arrow.clockwise")

            HStack {
                Text("\(roundCount) \(roundCount == 1 ? "Round" : "Rounds")")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(ScrawlTheme.primaryText)

                Spacer()

                HStack(spacing: 16) {
                    Button {
                        if roundCount > 1 {
                            withAnimation(.spring(response: 0.2)) { roundCount -= 1 }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(roundCount > 1 ? ScrawlTheme.skyBlue : ScrawlTheme.warmGray)
                    }
                    .disabled(roundCount <= 1)
                    .accessibilityLabel("Decrease rounds")

                    Text("\(roundCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(ScrawlTheme.coral)
                        .frame(minWidth: 36)

                    Button {
                        if roundCount < 10 {
                            withAnimation(.spring(response: 0.2)) { roundCount += 1 }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(roundCount < 10 ? ScrawlTheme.skyBlue : ScrawlTheme.warmGray)
                    }
                    .disabled(roundCount >= 10)
                    .accessibilityLabel("Increase rounds")
                }
            }
            .padding(16)
            .scrawlCard()
        }
    }

    private var startButton: some View {
        Button {
            guard canStart else { return }
            let teams = teamNames
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { ScrawlTeam(name: $0) }
            let hapticsOn = settings?.hapticsEnabled ?? true
            engine.configure(
                teams: teams,
                wordPack: selectedPackName,
                words: selectedWords,
                rounds: roundCount,
                timerSeconds: timerSeconds,
                hapticsEnabled: hapticsOn
            )
            showingGame = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 18, weight: .semibold))
                Text("Start Drawing!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canStart ? ScrawlTheme.coral : ScrawlTheme.warmGray)
            .cornerRadius(20)
            .shadow(color: canStart ? ScrawlTheme.coral.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!canStart)
        .accessibilityLabel("Start the game")
    }

    // MARK: - Helpers

    private func teamColor(_ index: Int) -> Color {
        let colors: [Color] = [ScrawlTheme.skyBlue, ScrawlTheme.coral, ScrawlTheme.successGreen, ScrawlTheme.warningOrange, .purple, .pink, .teal, .indigo]
        return colors[index % colors.count]
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ScrawlTheme.skyBlue)
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(ScrawlTheme.primaryText)
        }
    }
}

struct PackSelectionCard: View {
    let pack: WordPack
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(pack.emoji)
                    .font(.system(size: 28))
                Text(pack.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("\(pack.wordCount) words")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : ScrawlTheme.secondaryText)
            }
            .padding(14)
            .frame(width: 100)
            .background(isSelected ? ScrawlTheme.skyBlue : ScrawlTheme.cardBackground)
            .foregroundStyle(isSelected ? .white : ScrawlTheme.primaryText)
            .cornerRadius(14)
            .shadow(color: isSelected ? ScrawlTheme.skyBlue.opacity(0.35) : .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .accessibilityLabel("\(pack.name) word pack, \(pack.wordCount) words")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CustomPackCard: View {
    let list: CustomWordList
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("✍️")
                    .font(.system(size: 28))
                Text(list.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("\(list.wordCount) words")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : ScrawlTheme.secondaryText)
            }
            .padding(14)
            .frame(width: 100)
            .background(isSelected ? ScrawlTheme.coral : ScrawlTheme.cardBackground)
            .foregroundStyle(isSelected ? .white : ScrawlTheme.primaryText)
            .cornerRadius(14)
            .shadow(color: isSelected ? ScrawlTheme.coral.opacity(0.35) : .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .accessibilityLabel("Custom word list: \(list.name), \(list.wordCount) words")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
