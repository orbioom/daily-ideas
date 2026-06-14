import SwiftUI

/// Configuration sheet for starting a new game.
struct NewGameSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var vsComputer: Bool
    @State private var humanSide: HumanSide
    @State private var level: AILevel

    let onStart: (_ vsComputer: Bool, _ humanSide: HumanSide, _ level: AILevel) -> Void

    init(defaultLevel: AILevel,
         onStart: @escaping (Bool, HumanSide, AILevel) -> Void) {
        _vsComputer = State(initialValue: true)
        _humanSide = State(initialValue: .white)
        _level = State(initialValue: defaultLevel)
        self.onStart = onStart
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    modeCard
                    if vsComputer {
                        sideCard
                        levelCard
                    } else {
                        passAndPlayNote
                    }
                    PrimaryButton(title: "Start game", systemImage: "play.fill") {
                        onStart(vsComputer, humanSide, level)
                        dismiss()
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var modeCard: some View {
        SectionCard(title: "Opponent", symbol: "person.2") {
            Picker("Opponent", selection: $vsComputer) {
                Text("Computer").tag(true)
                Text("Two players").tag(false)
            }
            .pickerStyle(.segmented)
        }
    }

    private var sideCard: some View {
        SectionCard(title: "Your side", symbol: "circle.lefthalf.filled") {
            Picker("Your side", selection: $humanSide) {
                ForEach(HumanSide.allCases) { side in
                    Text(side.label).tag(side)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var levelCard: some View {
        SectionCard(title: "Difficulty", symbol: "dial.medium") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Difficulty", selection: $level) {
                    ForEach(AILevel.allCases) { lvl in
                        Text(lvl.label).tag(lvl)
                    }
                }
                .pickerStyle(.segmented)
                Text(level.blurb)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var passAndPlayNote: some View {
        SectionCard(title: "Pass and play", symbol: "iphone.gen3") {
            Text("Two players share this device, taking turns to move. The board stays in White's orientation.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
