import SwiftUI
import SwiftData

struct CompletedView: View {
    @Query private var allProgress: [SceneProgress]

    private var completedScenes: [(PixelSceneData, SceneProgress)] {
        SceneLibrary.all.compactMap { scene in
            guard let prog = allProgress.first(where: { $0.sceneId == scene.id }),
                  prog.completedAt != nil else { return nil }
            return (scene, prog)
        }
    }

    var body: some View {
        Group {
            if completedScenes.isEmpty {
                ContentUnavailableView {
                    Label("No Completed Scenes", systemImage: "paintpalette")
                } description: {
                    Text("Finish coloring a scene to see it here.")
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(completedScenes, id: \.0.id) { (scene, prog) in
                            CompletedCard(scene: scene, progress: prog)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CompletedCard: View {
    let scene: PixelSceneData
    let progress: SceneProgress

    @State private var showShare = false
    @State private var exportedImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ScenePreviewView(scene: scene, progress: progress)
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack {
                    HStack {
                        Spacer()
                        Button {
                            exportedImage = renderScene()
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color("StippleAccent"))
                                .background(Color.white.clipShape(Circle()))
                        }
                        .padding(6)
                    }
                    Spacer()
                }
            }

            HStack {
                Text(scene.emoji + " " + scene.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showShare) {
            if let img = exportedImage {
                ShareSheet(activityItems: [img])
            }
        }
    }

    private func renderScene() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uc = progress.loadCells()
        return renderer.image { ctx in
            let cw = size.width / CGFloat(scene.width)
            let ch = size.height / CGFloat(scene.height)
            for y in 0..<scene.height {
                for x in 0..<scene.width {
                    let idx = y * scene.width + x
                    let rect = CGRect(x: CGFloat(x)*cw, y: CGFloat(y)*ch, width: cw, height: ch)
                    let uChoice = uc[safe: idx] ?? -1
                    if uChoice >= 0 && uChoice < scene.palette.count {
                        UIColor(scene.palette[uChoice]).setFill()
                    } else {
                        UIColor.systemGray5.setFill()
                    }
                    ctx.fill(rect)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
