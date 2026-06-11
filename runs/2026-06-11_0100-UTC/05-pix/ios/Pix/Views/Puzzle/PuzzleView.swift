import SwiftUI
import SwiftData

struct PuzzleView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var vm: PixPuzzleViewModel
    let onDismiss: () -> Void

    @State private var showReset = false
    @State private var showWinSheet = false
    @State private var timerTask: Task<Void, Never>?

    private let columns = [GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                NonogramGridView(vm: vm, cellSize: PixTheme.cellSize)
                    .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(vm.puzzle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { stopAndSave(); onDismiss() }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(vm.puzzle.name)
                            .font(.headline)
                        Text(vm.elapsedFormatted)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) { showReset = true } label: {
                            Label("Reset Board", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Reset the board?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    vm.resetBoard()
                    vm.save(modelContext: modelContext)
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
            .sheet(isPresented: $showWinSheet) {
                WinSheet(vm: vm, onDismiss: { showWinSheet = false; onDismiss() })
                    .presentationDetents([.medium])
            }
            .onAppear {
                vm.startTimer()
                startTicking()
            }
            .onDisappear {
                stopAndSave()
            }
            .onChange(of: vm.solved) { _, isSolved in
                if isSolved {
                    vm.save(modelContext: modelContext)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showWinSheet = true
                    }
                }
            }
        }
    }

    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                vm.tick()
            }
        }
    }

    private func stopAndSave() {
        timerTask?.cancel()
        vm.stopTimer()
        vm.save(modelContext: modelContext)
    }
}

private struct WinSheet: View {
    let vm: PixPuzzleViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(PixTheme.accent)
                .padding(.top, 32)

            VStack(spacing: 6) {
                Text("Solved!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text(vm.puzzle.name)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 40) {
                statCol(label: "Time", value: vm.elapsedFormatted)
                statCol(label: "Size", value: "\(vm.puzzle.size)×\(vm.puzzle.size)")
                statCol(label: "Difficulty", value: String(repeating: "★", count: vm.puzzle.difficulty))
            }
            .padding(.horizontal)

            Button("Done") { onDismiss() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(PixTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
    }

    private func statCol(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(PixTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
