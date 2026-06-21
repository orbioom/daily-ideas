import SwiftUI
import SwiftData

struct PackSelectView: View {
    @Query private var records: [PushRecord]
    @Query private var prefs: [PushPrefs]

    private var isPro: Bool { prefs.first?.isPro ?? false }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(allPacks) { pack in
                        if pack.id == 5 {
                            // Daily pack shown differently
                            NavigationLink {
                                DailyView()
                            } label: {
                                DailyPackCard(pack: pack, records: records)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                LevelSelectView(pack: pack)
                            } label: {
                                PackCard(pack: pack, records: records, isPro: isPro)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(PushTheme.background.ignoresSafeArea())
            .navigationTitle("Push")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Pack Card

struct PackCard: View {
    let pack: LevelPack
    let records: [PushRecord]
    let isPro: Bool

    private var solved: Int {
        records.filter { $0.packId == pack.id }.count
    }

    private var isLocked: Bool { pack.requiresPro && !isPro }

    var body: some View {
        HStack(spacing: 16) {
            // Color swatch
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PushTheme.packColor(pack.id))
                .frame(width: 56, height: 56)
                .overlay(
                    Group {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .bold))
                        } else {
                            Text("\(pack.id)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(pack.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(PushTheme.wall)
                    if isLocked {
                        Text("PRO")
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(PushTheme.accent))
                    }
                    Spacer()
                    Text("\(solved)/\(pack.levelCount)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(PushTheme.packColor(pack.id))
                }

                Text(pack.description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.55))
                    .lineLimit(2)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(PushTheme.floor)
                            .frame(height: 5)
                        Capsule()
                            .fill(PushTheme.packColor(pack.id))
                            .frame(
                                width: geo.size.width * CGFloat(solved) / CGFloat(max(pack.levelCount, 1)),
                                height: 5
                            )
                            .animation(.spring(duration: 0.6), value: solved)
                    }
                }
                .frame(height: 5)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(PushTheme.wall.opacity(0.3))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .opacity(isLocked ? 0.85 : 1.0)
    }
}

// MARK: - Daily Pack Card

struct DailyPackCard: View {
    let pack: LevelPack
    let records: [PushRecord]

    private var todayString: String { DailyLevelPicker.dateString() }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PushTheme.pack5)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Daily Puzzle")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundColor(PushTheme.wall)
                    Spacer()
                    Text(formattedToday)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(PushTheme.wall.opacity(0.45))
                }
                Text("A fresh challenge every day.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.55))
            }

            Image(systemName: "chevron.right")
                .foregroundColor(PushTheme.wall.opacity(0.3))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
    }

    private var formattedToday: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }
}

#Preview {
    PackSelectView()
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
