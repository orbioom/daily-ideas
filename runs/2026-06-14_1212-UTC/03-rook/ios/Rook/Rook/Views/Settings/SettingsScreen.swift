import SwiftUI
import SwiftData

/// Settings: board theme, piece style, dots, default level, confirm-move, haptics + Pro/About/Export.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var games: [GameRecord]
    @Query private var puzzles: [PuzzleResult]

    @State private var showPaywall = false
    @State private var showExport = false
    @State private var showAbout = false
    @State private var seedConfirm = false
    @State private var seedDone = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                gameplaySection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .premiumBoard) }
            .sheet(isPresented: $showExport) { ExportView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .alert("Load sample data?", isPresented: $seedConfirm) {
                Button("Load", role: .none) { loadSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Adds a batch of example games and puzzle results so you can explore the Stats screen.")
            }
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            Picker("Board theme", selection: boardThemeBinding) {
                ForEach(BoardTheme.allCases) { theme in
                    HStack {
                        Text(theme.label)
                        if theme.isPremium && !isPro { Image(systemName: "lock.fill") }
                    }
                    .tag(theme)
                }
            }
            Picker("Piece style", selection: pieceStyleBinding) {
                ForEach(PieceStyle.allCases) { style in
                    Text(style.label).tag(style)
                }
            }
            Toggle("Show legal-move dots", isOn: $settings.showLegalDots)
            boardPreview
        } header: {
            Text("Appearance")
        } footer: {
            Text("Legal-move dots mark where the selected piece can go. Premium boards are part of Rook Pro.")
        }
        .listRowBackground(Theme.surface)
    }

    private var boardPreview: some View {
        BoardView(board: Board.standard,
                  theme: settings.effectiveBoardTheme(isPro: isPro),
                  pieceStyle: settings.pieceStyle,
                  showCoordinates: false)
            .frame(height: 150)
            .padding(.vertical, 4)
            .accessibilityLabel("Board theme preview")
    }

    // MARK: Gameplay

    private var gameplaySection: some View {
        Section {
            Picker("Default difficulty", selection: defaultLevelBinding) {
                ForEach(AILevel.allCases) { lvl in
                    Text(lvl.label).tag(lvl)
                }
            }
            Toggle("Confirm before moving", isOn: $settings.confirmMoves)
            Toggle("Haptics", isOn: $settings.hapticsEnabled)
        } header: {
            Text("Gameplay")
        } footer: {
            Text("Default difficulty pre-selects the computer level when you start a new game.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Rook Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").foregroundStyle(Theme.inkSoft)
                }
                Button("Lock Pro (demo reset)") { isPro = false }
                    .foregroundStyle(Theme.bad)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Unlock Rook Pro · \(Pro.priceLabel)", systemImage: "crown.fill")
                }
                Button("Restore Purchase") { showPaywall = true }
            }
        } header: {
            Text("Rook Pro")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                showExport = true
            } label: {
                Label("Export last game", systemImage: "square.and.arrow.up")
            }
            Button {
                seedConfirm = true
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
            if seedDone {
                Label("Sample data loaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.good)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Everything is stored privately on this device. Export copies a game as shareable text.")
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                Label("About Rook", systemImage: "info.circle")
            }
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: Bindings (with Pro-aware board theme)

    private var boardThemeBinding: Binding<BoardTheme> {
        Binding(get: { settings.boardTheme }, set: { newValue in
            if newValue.isPremium && !isPro {
                showPaywall = true
            } else {
                settings.boardTheme = newValue
            }
        })
    }

    private var pieceStyleBinding: Binding<PieceStyle> {
        Binding(get: { settings.pieceStyle }, set: { settings.pieceStyle = $0 })
    }

    private var defaultLevelBinding: Binding<AILevel> {
        Binding(get: { settings.defaultLevel }, set: { settings.defaultLevel = $0 })
    }

    // MARK: Sample data

    private func loadSample() {
        SeedData.load(context: context, existingGames: games.count, existingPuzzles: puzzles.count)
        seedDone = true
        Haptics.success(settings.hapticsEnabled)
    }
}
