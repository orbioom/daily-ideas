import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showHints") private var showHints = false
    @AppStorage("defaultDifficulty") private var defaultDifficulty = PuzzleDifficulty.beginner.rawValue
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var ctx
    @Query private var results: [PuzzleResult]
    @Query private var saves: [PuzzleSave]
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                PieceTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        gameplaySection
                        proSection
                        dataSection
                        aboutSection
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog(
                "Clear all saved games and stats?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear All Data", role: .destructive) { clearData() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var gameplaySection: some View {
        settingsCard(title: "Gameplay") {
            toggleRow(label: "Haptics", icon: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
            Divider().background(Color.white.opacity(0.08))
            toggleRow(label: "Show Hints", icon: "lightbulb.fill", isOn: $showHints)
            Divider().background(Color.white.opacity(0.08))

            VStack(alignment: .leading, spacing: 10) {
                Label("Default Difficulty", systemImage: "dial.medium")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    ForEach(PuzzleDifficulty.allCases) { d in
                        Button {
                            defaultDifficulty = d.rawValue
                        } label: {
                            Text(d.label)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(defaultDifficulty == d.rawValue
                                    ? PieceTheme.difficultyColor(d)
                                    : Color.white.opacity(0.08))
                                .foregroundStyle(defaultDifficulty == d.rawValue ? .black : .white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var proSection: some View {
        settingsCard(title: "Pro") {
            if isPro {
                HStack {
                    Label("Pro Unlocked", systemImage: "crown.fill")
                        .foregroundStyle(PieceTheme.amber)
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(PieceTheme.completionGreen)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlock Pro", systemImage: "crown.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(PieceTheme.amber)
                    Text("Get Aurora and Floral Mandala puzzles, plus any future artwork packs.")
                        .font(.caption)
                        .foregroundStyle(PieceTheme.subtleText)
                    Button {
                        isPro = true
                    } label: {
                        Text("Unlock Pro")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(PieceTheme.amber)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dataSection: some View {
        settingsCard(title: "Data") {
            HStack {
                Label("Games Completed", systemImage: "checkmark.square.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(results.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(PieceTheme.subtleText)
            }
            Divider().background(Color.white.opacity(0.08))
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutSection: some View {
        settingsCard(title: "About") {
            infoRow(label: "Version", value: "1.0")
            Divider().background(Color.white.opacity(0.08))
            infoRow(label: "Build", value: "1")
        }
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(PieceTheme.subtleText)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(PieceTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
    }

    private func toggleRow(label: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .tint(PieceTheme.amber)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(PieceTheme.subtleText)
        }
    }

    private func clearData() {
        for r in results { ctx.delete(r) }
        for s in saves { ctx.delete(s) }
        try? ctx.save()
    }
}
