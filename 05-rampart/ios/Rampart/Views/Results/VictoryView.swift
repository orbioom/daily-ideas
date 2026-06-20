import SwiftUI
import SwiftData

struct VictoryView: View {
    let game: RampartGame
    let onRestart: () -> Void
    let onExit: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color(red: 0.172, green: 0.141, blue: 0.086)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("👑")
                    .font(.system(size: 80))
                    .scaleEffect(showConfetti ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showConfetti)

                VStack(spacing: 8) {
                    Text("Victory!")
                        .font(.system(size: 40, weight: .black, design: .serif))
                        .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))

                    Text("The walls stand strong.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                        .italic()
                }

                // Stats
                VStack(spacing: 12) {
                    ResultRow(label: "Map", value: game.map.name, icon: "map")
                    ResultRow(label: "Waves Survived", value: "\(game.wave) of \(game.totalWaves)", icon: "flag.fill")
                    ResultRow(label: "Final Score", value: "\(game.score)", icon: "star.fill")
                    ResultRow(label: "Lives Remaining", value: "\(game.lives)", icon: "heart.fill")
                    ResultRow(label: "Towers Built", value: "\(game.towers.count)", icon: "building.2.fill")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.5), lineWidth: 1.5))
                )
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        saveRecord()
                        dismiss()
                        onRestart()
                    }) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(red: 0.17, green: 0.13, blue: 0.08))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.831, green: 0.686, blue: 0.216))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: {
                        saveRecord()
                        dismiss()
                        onExit()
                    }) {
                        Label("Choose Map", systemImage: "map")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            saveRecord()
            showConfetti = true
        }
    }

    private func saveRecord() {
        let rec = GameRecord(
            mapID: game.map.id,
            mapName: game.map.name,
            wave: game.wave,
            score: game.score,
            won: true
        )
        modelContext.insert(rec)
        try? modelContext.save()
    }
}
