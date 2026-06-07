import SwiftUI
import SwiftData

/// A self-contained sheet: pick a course, then keep score. Finishing or closing
/// dismisses the whole sheet.
struct NewRoundFlow: View {
    @State private var startedRound: Round?

    var body: some View {
        NavigationStack {
            if let round = startedRound {
                ScorecardView(round: round)
            } else {
                CoursePickerView { round in startedRound = round }
            }
        }
    }
}

private struct CoursePickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DiscCourse.name) private var courses: [DiscCourse]
    @State private var weather = "Calm"
    var onStart: (Round) -> Void

    private let weathers = ["Calm", "Breezy", "Windy", "Wet", "Cold"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if courses.isEmpty {
                    EmptyStateView(icon: "map",
                                   title: "Add a course first",
                                   message: "Head to the Courses tab to build a layout, then come back to start a round.")
                        .padding(.top, 30)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Conditions")
                        Picker("Weather", selection: $weather) {
                            ForEach(weathers, id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.segmented)
                    }.glassCard()

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle(text: "Choose a course")
                        ForEach(courses) { course in
                            Button { start(course) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(course.name).font(.headline).foregroundStyle(Brand.text)
                                        Text("\(course.holeCount) holes · Par \(course.par)")
                                            .font(.subheadline).foregroundStyle(Brand.text2)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2).foregroundStyle(Brand.text)
                                }
                                .padding(.vertical, 6)
                            }.buttonStyle(.plain)
                            if course.id != courses.last?.id { Divider().overlay(Brand.hairline) }
                        }
                    }.glassCard()
                }
            }
            .padding()
        }
        .navigationTitle("New round")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }.tint(Brand.text2)
            }
        }
    }

    private func start(_ course: DiscCourse) {
        let round = Round(date: Date(), courseName: course.name, ssa: course.ssa,
                          pointsPerThrow: course.pointsPerThrow, weather: weather)
        for hole in course.orderedHoles {
            round.scores.append(HoleScore(holeNumber: hole.number, par: hole.par,
                                          distanceFeet: hole.distanceFeet,
                                          strokes: hole.par, putts: 0, penalties: 0))
        }
        context.insert(round)
        try? context.save()
        Haptics.tap()
        onStart(round)
    }
}
