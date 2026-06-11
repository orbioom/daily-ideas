import SwiftUI
import SwiftData

/// Morning-after summary: score reveal, feel rating, optional note.
struct SessionSummaryView: View {
    @Bindable var session: NightSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    let score = SnoreEngine.score(for: session)
                    ScoreDial(score: score, size: 180)
                        .padding(.top, 16)
                    VStack(spacing: 4) {
                        Text(SnoreEngine.grade(forScore: score).label)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.inkPrimary(scheme))
                        Text(SnoreEngine.grade(forScore: score).detail)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSecondary(scheme))
                    }

                    HStack(spacing: 12) {
                        StatTile(title: "In bed", value: SnoreEngine.formatDuration(session.duration))
                        StatTile(title: "Episodes", value: "\(session.episodes.count)")
                        StatTile(title: "Snoring",
                                 value: SnoreEngine.formatDuration(
                                    session.episodes.reduce(0) { $0 + $1.duration }))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How do you feel?")
                            .font(.headline)
                            .foregroundStyle(Theme.inkPrimary(scheme))
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    Haptics.tap()
                                    session.morningRating = i
                                } label: {
                                    Image(systemName: i <= session.morningRating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(Theme.amber)
                                }
                                .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                                .accessibilityAddTraits(i == session.morningRating ? .isSelected : [])
                            }
                        }
                        TextField("Add a note about last night (optional)", text: $session.notes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .timberCard()
                }
                .padding()
            }
            .background(Theme.background(scheme))
            .navigationTitle("Good morning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
