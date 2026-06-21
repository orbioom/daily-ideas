import SwiftUI
import SwiftData

struct LevelSelectView: View {
    let pack: LevelPack
    @Query private var records: [PushRecord]
    @Query private var prefs: [PushPrefs]

    private var isPro: Bool { prefs.first?.isPro ?? false }
    private var isLocked: Bool { pack.requiresPro && !isPro }

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            if isLocked {
                lockedView
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(pack.levels) { level in
                        NavigationLink {
                            PuzzleView(level: level)
                        } label: {
                            LevelCardView(
                                level: level,
                                record: records.first(where: { $0.levelId == level.id })
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .background(PushTheme.background.ignoresSafeArea())
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var lockedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 52))
                .foregroundColor(PushTheme.accent)

            VStack(spacing: 8) {
                Text("Expert Pack")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.wall)
                Text("Unlock all 10 expert levels\nwith a one-time purchase.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                // IAP handled in SettingsView
            } label: {
                Text("Unlock for $2.99")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(PushTheme.accent))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(40)
    }
}

#Preview {
    NavigationStack {
        LevelSelectView(pack: allPacks[0])
    }
    .modelContainer(for: [PushRecord.self, PushPrefs.self], inMemory: true)
}
