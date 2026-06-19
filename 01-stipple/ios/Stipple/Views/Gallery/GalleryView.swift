import SwiftUI
import SwiftData

struct GalleryView: View {
    @Query private var allProgress: [SceneProgress]
    @Query private var prefs: [StipplePrefs]
    private var isPro: Bool { prefs.first?.isPro == true }

    @State private var selectedCategory: PixelSceneData.SceneCategory? = nil
    @State private var showingProAlert = false

    private var filteredScenes: [PixelSceneData] {
        let scenes = SceneLibrary.all
        if let cat = selectedCategory {
            return scenes.filter { $0.category == cat }
        }
        return scenes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(label: "All", category: nil)
                        ForEach(PixelSceneData.SceneCategory.allCases, id: \.self) { cat in
                            categoryChip(label: cat.rawValue, category: cat)
                        }
                    }
                    .padding(.horizontal)
                }

                // Scene grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredScenes) { scene in
                        sceneCard(scene: scene)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 32)
            }
            .padding(.top, 12)
        }
        .navigationTitle("Stipple")
        .navigationBarTitleDisplayMode(.large)
        .alert("Unlock All Scenes", isPresented: $showingProAlert) {
            Button("Unlock for $4.99") {
                if let pref = prefs.first { pref.isPro = true }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Get all 15 scenes + bonus color palettes.\n(Simulated — no real payment)")
        }
    }

    private func sceneCard(scene: PixelSceneData) -> some View {
        let prog = allProgress.first { $0.sceneId == scene.id }
        let completed = prog?.completedAt != nil
        let fraction = progressFraction(scene: scene, progress: prog)
        let locked = scene.isPro && !isPro

        return NavigationLink(destination: locked ? AnyView(lockedPlaceholder(scene)) : AnyView(CanvasView(scene: scene))) {
            VStack(spacing: 0) {
                // Mini pixel preview
                ZStack {
                    ScenePreviewView(scene: scene, progress: prog)
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    if completed {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .background(Color.white.clipShape(Circle()))
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                    if locked {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.45))
                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scene.emoji)
                        Text(scene.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                    ProgressView(value: fraction)
                        .tint(completed ? .green : Color("StippleAccent"))
                    Text(scene.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            if locked { showingProAlert = true }
        })
        .accessibilityLabel("\(scene.name), \(completed ? "completed" : "\(Int(fraction * 100))% done")\(locked ? ", locked" : "")")
    }

    private func lockedPlaceholder(_ scene: PixelSceneData) -> some View {
        VStack(spacing: 20) {
            Text("🔒")
                .font(.system(size: 64))
            Text("\(scene.name) is a Pro scene")
                .font(.title2.bold())
            Button("Unlock Stipple Pro — $4.99") { showingProAlert = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle(scene.name)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func progressFraction(scene: PixelSceneData, progress: SceneProgress?) -> Double {
        guard let prog = progress else { return 0 }
        let cells = prog.loadCells()
        guard cells.count == scene.cells.count else { return 0 }
        let filled = cells.filter { $0 >= 0 }.count
        return Double(filled) / Double(scene.cells.count)
    }

    private func categoryChip(label: String, category: PixelSceneData.SceneCategory?) -> some View {
        let selected = selectedCategory == category
        return Button(label) { selectedCategory = category }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(selected ? Color("StippleAccent") : Color(.secondarySystemBackground))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(Capsule())
    }
}

// Mini scene preview drawn in Canvas
struct ScenePreviewView: View {
    let scene: PixelSceneData
    let progress: SceneProgress?

    private var userCells: [Int] {
        guard let p = progress else { return [Int](repeating: -1, count: scene.cells.count) }
        let cells = p.loadCells()
        return cells.count == scene.cells.count ? cells : [Int](repeating: -1, count: scene.cells.count)
    }

    var body: some View {
        Canvas { ctx, size in
            let cw = size.width / CGFloat(scene.width)
            let ch = size.height / CGFloat(scene.height)
            let uc = userCells
            for y in 0..<scene.height {
                for x in 0..<scene.width {
                    let idx = y * scene.width + x
                    let rect = CGRect(x: CGFloat(x)*cw, y: CGFloat(y)*ch, width: cw, height: ch)
                    let uChoice = uc[safe: idx] ?? -1
                    if uChoice >= 0 && uChoice < scene.palette.count {
                        ctx.fill(Path(rect), with: .color(scene.palette[uChoice]))
                    } else {
                        // Show target color dimmed (preview hint)
                        let ti = scene.cells[safe: idx] ?? 0
                        let col = ti < scene.palette.count ? scene.palette[ti].opacity(0.18) : Color(.systemGray6)
                        ctx.fill(Path(rect), with: .color(col))
                    }
                }
            }
        }
    }
}
