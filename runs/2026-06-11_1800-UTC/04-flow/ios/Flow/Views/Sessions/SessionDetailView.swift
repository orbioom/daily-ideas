import SwiftUI

struct SessionDetailView: View {
    let session: YogaSession
    @State private var showPlayer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    FlowTheme.gradient(for: session)
                        .frame(height: 220)
                        .ignoresSafeArea(edges: .top)

                    VStack(spacing: 8) {
                        Text(session.emoji)
                            .font(.system(size: 64))
                            .accessibilityHidden(true)
                        Text(session.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            Label("\(session.totalDurationMinutes) min", systemImage: "clock.fill")
                            Label("\(session.poseCount) poses", systemImage: "figure.yoga")
                            Label(session.difficulty.rawValue, systemImage: "chart.bar.fill")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.bottom, 24)
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text(session.description)
                        .font(.body)
                        .foregroundStyle(FlowTheme.subtle)
                        .padding(.horizontal)

                    Button {
                        showPlayer = true
                    } label: {
                        Label("Begin Session", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(FlowTheme.gradient(for: session))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .accessibilityHint("Start the guided yoga session")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sequence")
                            .font(.headline)
                            .foregroundStyle(FlowTheme.text)
                            .padding(.horizontal)

                        ForEach(session.steps) { step in
                            HStack(spacing: 12) {
                                Text(step.pose.emoji)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(FlowTheme.card, in: RoundedRectangle(cornerRadius: 10))
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.pose.name + (step.side == .left ? " (Left)" : step.side == .right ? " (Right)" : ""))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(FlowTheme.text)
                                    Text("\(step.durationSeconds)s · \(step.pose.category.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(FlowTheme.subtle)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.bottom, 32)
            }
        }
        .background(FlowTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPlayer) {
            SessionPlayerView(session: session)
        }
    }
}
