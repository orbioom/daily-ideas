import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout

    @AppStorage("brio.countInSeconds") private var countInSeconds = 5
    @State private var showPlayer = false

    private var items: [WorkoutItem] { workout.orderedItems }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                statRow

                if items.isEmpty {
                    EmptyStateView(icon: "list.bullet",
                                   title: "No moves yet",
                                   message: "Edit this workout in the Build tab to add exercises.")
                        .glassCard()
                } else {
                    sequence
                }
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(Brand.pageBackground)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Haptics.tap()
                showPlayer = true
            } label: {
                Label("Start Workout", systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(items.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            SessionPlayerView(workout: workout, countInSeconds: countInSeconds)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TagChip(text: workout.category.label, systemImage: workout.category.symbol, tint: workout.category.tint)
                TagChip(text: workout.difficulty.label, tint: workout.difficulty.tint)
            }
            if !workout.summary.isEmpty {
                Text(workout.summary)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            StatTile(value: Format.estimate(workout.estimatedSeconds).replacingOccurrences(of: "~", with: ""), label: "Est. time", tint: workout.category.tint)
            StatTile(value: "\(workout.rounds)", label: "Rounds")
            StatTile(value: "\(items.count)", label: "Moves")
        }
    }

    private var sequence: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: workout.rounds > 1 ? "Each round" : "The sequence")
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(Brand.mono(13, weight: .semibold))
                            .foregroundStyle(Brand.text3)
                            .frame(width: 22)
                        Image(systemName: item.symbol)
                            .font(.body)
                            .foregroundStyle(workout.category.tint)
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exerciseName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(item.detailLine)
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Image(systemName: item.kind == .timed ? "timer" : "number")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Move \(idx + 1): \(item.exerciseName), \(item.detailLine)")
                    if idx < items.count - 1 {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
            .glassCard()

            if workout.rounds > 1 || workout.restBetweenExercisesSec > 0 {
                Text(restNote)
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }
        }
    }

    private var restNote: String {
        var parts: [String] = []
        if workout.restBetweenExercisesSec > 0 {
            parts.append("\(workout.restBetweenExercisesSec)s rest between moves")
        }
        if workout.rounds > 1, workout.restBetweenRoundsSec > 0 {
            parts.append("\(workout.restBetweenRoundsSec)s between rounds")
        }
        return parts.joined(separator: " · ")
    }
}
