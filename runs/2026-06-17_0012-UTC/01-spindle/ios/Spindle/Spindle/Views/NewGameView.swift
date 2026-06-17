import SwiftUI

/// Sheet to start a new game: suit-count picker, Today's Deal, numbered deal, Random.
/// 4-suit is shown but locked behind Pro.
struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @AppStorage(PrefKey.lastSuitMode) private var lastSuitModeRaw: Int = SuitMode.one.rawValue

    /// Called with the chosen mode + deal kind. The host starts the game.
    let onStart: (SuitMode, DealKind) -> Void

    @State private var selectedMode: SuitMode = .one
    @State private var dealNumberText: String = ""
    @State private var showPaywall = false

    private var todaySeed: Int { DealSeed.dailySeedInt(for: .now) }

    var body: some View {
        NavigationStack {
            ZStack {
                SpindleBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        difficultyCard
                        startOptionsCard
                        numberedCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear { selectedMode = SuitMode(rawValue: lastSuitModeRaw) ?? .one }
        }
    }

    // MARK: Difficulty

    private var difficultyCard: some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Difficulty")
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                ForEach(SuitMode.allCases) { mode in
                    difficultyRow(mode)
                }
            }
        }
    }

    private func difficultyRow(_ mode: SuitMode) -> some View {
        let locked = mode.requiresPro && !isPro
        let selected = selectedMode == mode
        return Button {
            if locked {
                showPaywall = true
            } else {
                selectedMode = mode
                Haptics.selection()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? SpindleTheme.emerald : SpindleTheme.secondaryText(scheme))
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SpindleTheme.primaryText(scheme))
                    Text(mode.difficultyLabel)
                        .font(.caption)
                        .foregroundStyle(SpindleTheme.secondaryText(scheme))
                }
                Spacer()
                if locked {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SpindleTheme.goldDeep)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title), \(mode.difficultyLabel)\(locked ? ", Pro locked" : "")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Start options

    private var startOptionsCard: some View {
        SpindleCard {
            VStack(spacing: 12) {
                Button {
                    start(.daily(todaySeed))
                } label: {
                    Label("Today's Deal", systemImage: "calendar")
                }
                .buttonStyle(SpindlePrimaryButtonStyle())

                Button {
                    start(.random)
                } label: {
                    Label("Random Deal", systemImage: "shuffle")
                }
                .buttonStyle(SpindleSecondaryButtonStyle())

                Text("Today's Deal #\(todaySeed) is the same for everyone — compare your score!")
                    .font(.caption)
                    .foregroundStyle(SpindleTheme.secondaryText(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: Numbered

    private var numberedCard: some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Numbered Deal")
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                Text("Enter a deal number to replay an exact board.")
                    .font(.caption)
                    .foregroundStyle(SpindleTheme.secondaryText(scheme))
                HStack {
                    TextField("e.g. 1024", text: $dealNumberText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Deal number")
                    Button("Deal") {
                        let trimmed = dealNumberText.trimmingCharacters(in: .whitespaces)
                        if let n = Int(trimmed), n > 0 {
                            start(.numbered(n))
                        } else {
                            start(.numbered(1024))
                        }
                    }
                    .buttonStyle(SpindleSecondaryButtonStyle())
                    .frame(width: 96)
                }
            }
        }
    }

    private func start(_ kind: DealKind) {
        let mode: SuitMode = (selectedMode.requiresPro && !isPro) ? .two : selectedMode
        lastSuitModeRaw = mode.rawValue
        onStart(mode, kind)
        dismiss()
    }
}
