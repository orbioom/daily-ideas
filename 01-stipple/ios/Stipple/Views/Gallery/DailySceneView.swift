import SwiftUI
import SwiftData

struct DailySceneView: View {
    @Query private var allProgress: [SceneProgress]
    @Query private var prefs: [StipplePrefs]

    private var dailyScene: PixelSceneData {
        // Deterministic scene per calendar day using FNV hash
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let seed = UInt32(components.year ?? 2026) &* 366
               &+ UInt32(components.month ?? 1) &* 31
               &+ UInt32(components.day ?? 1)
        let freeScenes = SceneLibrary.free
        guard !freeScenes.isEmpty else { return SceneLibrary.all[0] }
        let idx = Int(seed % UInt32(freeScenes.count))
        return freeScenes[idx]
    }

    private var dailyProgress: SceneProgress? {
        allProgress.first { $0.sceneId == dailyScene.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Today's Scene")
                        .font(.title2.bold())
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Daily scene card
                NavigationLink(destination: CanvasView(scene: dailyScene)) {
                    ZStack {
                        ScenePreviewView(scene: dailyScene, progress: dailyProgress)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        if dailyProgress?.completedAt != nil {
                            VStack {
                                HStack {
                                    Spacer()
                                    Label("Complete!", systemImage: "checkmark.circle.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green)
                                        .clipShape(Capsule())
                                        .padding(10)
                                }
                                Spacer()
                            }
                        }

                        VStack {
                            Spacer()
                            HStack {
                                Text(dailyScene.emoji + "  " + dailyScene.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                                Spacer()
                                Text("Tap to color →")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(12)
                            .background(.ultraThinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                // Progress
                if let prog = dailyProgress {
                    let cells = prog.loadCells()
                    let filled = cells.filter { $0 >= 0 }.count
                    let total = dailyScene.cells.count
                    let pct = total > 0 ? Double(filled) / Double(total) : 0

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Progress")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(String(format: "%.0f%%", pct * 100))
                                .font(.subheadline)
                                .foregroundStyle(Color("StippleAccent"))
                        }
                        ProgressView(value: pct)
                            .tint(Color("StippleAccent"))
                        Text("\(filled) of \(total) cells colored")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Info card
                VStack(alignment: .leading, spacing: 10) {
                    Text("🗓 A new scene each day")
                        .font(.subheadline.bold())
                    Text("Come back tomorrow for a brand new pixel art scene. Complete today's scene to add it to your gallery!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .navigationTitle("Daily Scene")
        .navigationBarTitleDisplayMode(.large)
    }
}
