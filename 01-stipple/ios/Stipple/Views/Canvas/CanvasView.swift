import SwiftUI
import SwiftData

struct CanvasView: View {
    let scene: PixelSceneData
    @Environment(\.modelContext) private var ctx
    @Query private var allProgress: [SceneProgress]
    @Query private var prefs: [StipplePrefs]
    private var pref: StipplePrefs? { prefs.first }

    @State private var vm: CanvasViewModel?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var showingComplete = false
    @State private var showingReset = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    private var progress: SceneProgress? {
        allProgress.first { $0.sceneId == scene.id }
    }

    var body: some View {
        ZStack {
            Color("CanvasBG").ignoresSafeArea()

            if let vm {
                VStack(spacing: 0) {
                    progressBar(vm: vm)

                    // Main canvas
                    GeometryReader { geo in
                        let cellSize = min(geo.size.width, geo.size.height) / CGFloat(max(scene.width, scene.height)) * scale
                        let totalW = cellSize * CGFloat(scene.width)
                        let totalH = cellSize * CGFloat(scene.height)
                        let baseX = (geo.size.width - totalW) / 2 + offset.width
                        let baseY = (geo.size.height - totalH) / 2 + offset.height

                        ZStack {
                            Canvas { ctx, _ in
                                drawCanvas(ctx: ctx, cellSize: cellSize, baseX: baseX, baseY: baseY, vm: vm, showGrid: pref?.showGridLines ?? true)
                            }
                            .gesture(
                                TapGesture().onEnded { _ in }
                                    .simultaneously(with:
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { val in
                                                let x = Int((val.location.x - baseX) / cellSize)
                                                let y = Int((val.location.y - baseY) / cellSize)
                                                let idx = y * scene.width + x
                                                if x >= 0 && x < scene.width && y >= 0 && y < scene.height {
                                                    haptic()
                                                    vm.tap(cellIndex: idx)
                                                }
                                            }
                                    )
                            )
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { val in scale = max(1.0, min(8.0, lastScale * val)) }
                                    .onEnded { _ in lastScale = scale }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { val in
                                        if scale > 1.0 { offset = val.translation }
                                    }
                            )
                        }
                        .clipped()
                    }

                    paletteBar(vm: vm)
                }
            } else {
                ProgressView("Loading…")
            }

            if showingComplete {
                completeOverlay
            }
        }
        .navigationTitle(scene.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Fill All — \(vm?.selectedColorIndex.description ?? "0")", systemImage: "paintbucket.fill") {
                        vm?.colorAll(matchingIndex: vm?.selectedColorIndex ?? 0)
                    }
                    Button("Reset Scene", systemImage: "arrow.counterclockwise", role: .destructive) {
                        showingReset = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Reset?", isPresented: $showingReset) {
            Button("Reset", role: .destructive) { vm?.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clear all your coloring progress for this scene?")
        }
        .onAppear { loadVM() }
        .onChange(of: vm?.isComplete) { _, complete in
            if complete == true && !showingComplete {
                withAnimation(reduceMotion ? nil : .spring()) { showingComplete = true }
            }
        }
    }

    // MARK: - Canvas Drawing

    private func drawCanvas(ctx: GraphicsContext, cellSize: CGFloat, baseX: CGFloat, baseY: CGFloat, vm: CanvasViewModel, showGrid: Bool) {
        for y in 0..<scene.height {
            for x in 0..<scene.width {
                let idx = y * scene.width + x
                let rect = CGRect(x: baseX + CGFloat(x) * cellSize,
                                  y: baseY + CGFloat(y) * cellSize,
                                  width: cellSize, height: cellSize)
                // Fill cell
                let displayColor = vm.displayColor(for: idx)
                ctx.fill(Path(rect), with: .color(displayColor))

                // Show number if unfilled
                if vm.userCells[safe: idx] == -1 || vm.userCells[safe: idx] == -1 {
                    let target = vm.paletteIndex(for: idx)
                    if cellSize > 16 {
                        let text = Text("\(target + 1)").font(.system(size: min(cellSize * 0.45, 12)))
                            .foregroundStyle(Color.secondary)
                        ctx.draw(text, at: CGPoint(x: rect.midX, y: rect.midY))
                    }
                }

                // Grid lines
                if showGrid && cellSize > 4 {
                    ctx.stroke(Path(rect), with: .color(Color(.systemGray4).opacity(0.5)), lineWidth: 0.5)
                }
            }
        }
    }

    // MARK: - Sub-views

    private func progressBar(vm: CanvasViewModel) -> some View {
        VStack(spacing: 4) {
            ProgressView(value: vm.progressFraction)
                .tint(Color("StippleAccent"))
                .padding(.horizontal)
            HStack {
                Text("\(vm.filledCount) / \(vm.totalCells) cells")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", vm.progressFraction * 100))
                    .font(.caption.bold())
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
    }

    private func paletteBar(vm: CanvasViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scene.palette.indices, id: \.self) { i in
                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(scene.palette[i])
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(vm.selectedColorIndex == i ? Color.primary : Color.clear, lineWidth: 3)
                                        .padding(1)
                                )
                            Text("\(i + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                        }
                        Text(scene.paletteNames[safe: i] ?? "")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        vm.selectedColorIndex = i
                        haptic()
                    }
                    .accessibilityLabel("Color \(i+1): \(scene.paletteNames[safe: i] ?? "")")
                    .accessibilityAddTraits(vm.selectedColorIndex == i ? .isSelected : [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }

    private var completeOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎨")
                    .font(.system(size: 64))
                Text("Scene Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text(scene.name)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: 16) {
                    Button("Keep Coloring") {
                        withAnimation { showingComplete = false }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Gallery") {
                        dismiss()
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("StippleAccent"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(40)
        }
        .transition(.opacity)
    }

    // MARK: - Helpers

    private func loadVM() {
        let prog = progress ?? {
            let p = SceneProgress(sceneId: scene.id, cellCount: scene.cells.count)
            ctx.insert(p)
            return p
        }()
        vm = CanvasViewModel(scene: scene, progress: prog, prefs: pref)
    }

    private func haptic() {
        guard pref?.hapticsEnabled != false else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
