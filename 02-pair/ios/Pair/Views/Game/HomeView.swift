import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var settingsList: [PairSettings]
    @Query private var results: [PairResult]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTheme: CardTheme = .animals
    @State private var selectedGridSize: GridSize = .easy
    @State private var showSettings = false
    @State private var showProAlert = false
    @State private var navigateToGame = false
    @State private var navigateToDaily = false

    private var settings: PairSettings? { settingsList.first }
    private var hasPro: Bool { settings?.hasPro ?? false }

    var todaySeed: UInt64 {
        UInt64(Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1)
    }

    var bestMoves: Int? {
        let filtered = results.filter { $0.gridSize == selectedGridSize.rawValue }
        return filtered.map(\.moves).min()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PairTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        themeSelector
                        gridSizeSelector
                        actionButtons
                        statsPreview
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(PairTheme.textSecondary)
                        .padding(16)
                }
                .padding(.top, 44)
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameView(theme: selectedTheme, gridSize: selectedGridSize)
            }
            .navigationDestination(isPresented: $navigateToDaily) {
                GameView(theme: selectedTheme, gridSize: .easy, isDaily: true, seed: todaySeed)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Unlock Pro", isPresented: $showProAlert) {
                Button("Unlock for $2.99") {
                    if let s = settings {
                        s.hasPro = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Nature & Classic themes, Hard grid, and Daily Challenge archive require Pro.")
            }
            .onAppear {
                ensureSettings()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(PairTheme.accent)
                        .frame(width: 52, height: 52)
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pair")
                        .font(.largeTitle.bold())
                        .foregroundStyle(PairTheme.textPrimary)
                    Text("Find the match. Clear the board.")
                        .font(.caption)
                        .foregroundStyle(PairTheme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.headline)
                .foregroundStyle(PairTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            hasPro: hasPro
                        ) {
                            if theme.isPro && !hasPro {
                                showProAlert = true
                            } else {
                                selectedTheme = theme
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    private var gridSizeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grid Size")
                .font(.headline)
                .foregroundStyle(PairTheme.textSecondary)

            HStack(spacing: 10) {
                ForEach(GridSize.allCases, id: \.rawValue) { size in
                    Button {
                        if size.isPro && !hasPro {
                            showProAlert = true
                        } else {
                            selectedGridSize = size
                        }
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text(size.rawValue)
                                    .font(.subheadline.bold())
                                if size.isPro && !hasPro {
                                    ProBadge()
                                }
                            }
                            Text(size.displayDescription)
                                .font(.caption2)
                                .foregroundStyle(
                                    selectedGridSize == size ? PairTheme.background.opacity(0.7) : PairTheme.textSecondary
                                )
                        }
                        .foregroundStyle(selectedGridSize == size ? PairTheme.background : PairTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedGridSize == size ? PairTheme.accent : PairTheme.surface
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                navigateToGame = true
            } label: {
                Text("Play")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(PairTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button {
                navigateToDaily = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text("Daily Challenge")
                        .font(.headline)
                }
                .foregroundStyle(PairTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(PairTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PairTheme.accent.opacity(0.3), lineWidth: 1)
                }
            }
        }
    }

    private var statsPreview: some View {
        HStack(spacing: 16) {
            statCard(
                value: "\(results.count)",
                label: "Games Played",
                icon: "gamecontroller"
            )

            statCard(
                value: bestMoves.map { "\($0)" } ?? "—",
                label: "Best Moves (\(selectedGridSize.rawValue))",
                icon: "trophy"
            )
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PairTheme.accent)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(PairTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(PairTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(PairTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func ensureSettings() {
        if settingsList.isEmpty {
            let s = PairSettings()
            modelContext.insert(s)
        }
    }
}

struct ThemeCard: View {
    let theme: CardTheme
    let isSelected: Bool
    let hasPro: Bool
    let onTap: () -> Void

    private var isLocked: Bool { theme.isPro && !hasPro }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.cardBackColor)
                        .frame(width: 64, height: 64)

                    if theme == .classic {
                        LazyVGrid(columns: [GridItem(.fixed(20)), GridItem(.fixed(20)), GridItem(.fixed(20))], spacing: 4) {
                            ForEach(theme.previewEmojis, id: \.self) { sym in
                                Image(systemName: sym)
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.accentColor)
                            }
                        }
                    } else {
                        HStack(spacing: 2) {
                            ForEach(theme.previewEmojis, id: \.self) { emoji in
                                Text(emoji)
                                    .font(.system(size: 16))
                            }
                        }
                    }

                    if isLocked {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.black.opacity(0.45))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                }

                Text(theme.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? PairTheme.accent : PairTheme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? PairTheme.accent.opacity(0.15) : PairTheme.surface)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(PairTheme.accent, lineWidth: 2)
                        }
                    }
            )
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [PairResult.self, PairSettings.self], inMemory: true)
}
