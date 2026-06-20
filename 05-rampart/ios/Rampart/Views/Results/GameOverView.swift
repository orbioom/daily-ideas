import SwiftUI
import SwiftData

struct GameOverView: View {
    let game: RampartGame
    let onRestart: () -> Void
    let onExit: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.172, green: 0.141, blue: 0.086)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("💀")
                    .font(.system(size: 72))

                VStack(spacing: 8) {
                    Text("Defeated")
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundStyle(.red)

                    Text("The walls have fallen.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                        .italic()
                }

                // Stats
                VStack(spacing: 12) {
                    ResultRow(label: "Map", value: game.map.name, icon: "map")
                    ResultRow(label: "Wave Reached", value: "\(game.wave) of \(game.totalWaves)", icon: "flag")
                    ResultRow(label: "Score", value: "\(game.score)", icon: "star.fill")
                    ResultRow(label: "Lives Lost", value: "\(20 - game.lives)", icon: "heart.slash.fill")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1))
                )
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        saveRecord()
                        dismiss()
                        onRestart()
                    }) {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
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
                        Label("Change Map", systemImage: "map")
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
        .onAppear { saveRecord() }
    }

    private func saveRecord() {
        let rec = GameRecord(
            mapID: game.map.id,
            mapName: game.map.name,
            wave: game.wave,
            score: game.score,
            won: false
        )
        modelContext.insert(rec)
        try? modelContext.save()
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
