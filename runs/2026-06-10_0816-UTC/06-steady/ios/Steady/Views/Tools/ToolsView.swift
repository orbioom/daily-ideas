import SwiftUI

/// The coping toolbox: five short guided exercises for the moments when a
/// full thought record is too much.
struct ToolsView: View {
    @State private var active: CopingTool?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        Text("For right now — short, steadying exercises. The thought record can wait until the wave passes.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassCard()
                        ForEach(CopingTools.all) { tool in
                            Button {
                                Haptics.tap()
                                active = tool
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: tool.symbol)
                                        .font(.title2)
                                        .foregroundStyle(Brand.text2)
                                        .frame(width: 36)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tool.title)
                                            .font(.headline)
                                            .foregroundStyle(Brand.text)
                                        Text(tool.duration)
                                            .font(Brand.mono(12))
                                            .foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                        .accessibilityHidden(true)
                                }
                                .glassCard()
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(tool.title), \(tool.duration)")
                            .accessibilityHint("Opens the guided exercise")
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Tools")
            .fullScreenCover(item: $active) { tool in
                ToolPlayerView(tool: tool)
            }
        }
    }
}

/// One-step-at-a-time player for a coping exercise.
struct ToolPlayerView: View {
    let tool: CopingTool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private var isLast: Bool { index >= tool.steps.count - 1 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 24) {
                    ProgressView(value: Double(index + 1), total: Double(tool.steps.count))
                        .tint(Brand.live)
                        .padding(.horizontal, 16)
                        .accessibilityLabel("Step \(index + 1) of \(tool.steps.count)")

                    Spacer()

                    Image(systemName: tool.symbol)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Brand.text2)
                        .accessibilityHidden(true)

                    if tool.steps.indices.contains(index) {
                        Text(tool.steps[index])
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .id(index)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        if index > 0 {
                            Button("Back") {
                                withAnimation(reduceMotion ? nil : Brand.ease(0.3)) { index -= 1 }
                            }
                            .buttonStyle(GlassButtonStyle())
                            .frame(width: 110)
                        }
                        Button(isLast ? "Done" : "Next") {
                            if isLast {
                                Haptics.success()
                                dismiss()
                            } else {
                                Haptics.tap()
                                withAnimation(reduceMotion ? nil : Brand.ease(0.3)) { index += 1 }
                            }
                        }
                        .buttonStyle(InkButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle(tool.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close exercise")
                }
            }
        }
    }
}
