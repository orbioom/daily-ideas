import SwiftUI
import SwiftData

/// Create or edit a round: choose course/tee/date, then enter the scorecard
/// hole by hole. Saves a self-contained snapshot for stable handicap math.
struct RoundEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]

    let existing: Round?

    @State private var selectedCourse: Course?
    @State private var teeName: String = ""
    @State private var courseRating: Double = 72
    @State private var slopeRating: Int = 113
    @State private var date = Date()
    @State private var pars: [Int] = []
    @State private var strokeIndex: [Int] = []
    @State private var scores: [Int] = []
    @State private var putts: [Int] = []
    @State private var fairway: [Bool] = []
    @State private var gir: [Bool] = []
    @State private var notes = ""

    private var holeCount: Int { pars.count }
    private var runningTotal: Int { scores.filter { $0 > 0 }.reduce(0, +) }
    private var canSave: Bool { selectedCourse != nil && holeCount > 0 && scores.contains { $0 > 0 } }

    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    EmptyStateView(icon: "map", title: "No courses",
                                   message: "Add a course on the Courses tab before logging a round.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            setupCard
                            if holeCount > 0 {
                                runningCard
                                nine(title: "Front nine", range: 0..<min(9, holeCount))
                                if holeCount > 9 { nine(title: "Back nine", range: 9..<holeCount) }
                                notesCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Round" : "Edit Round")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: setup

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Course").foregroundStyle(Brand.text2)
                Spacer()
                Picker("Course", selection: Binding(
                    get: { selectedCourse },
                    set: { applyCourse($0) })) {
                    Text("Select").tag(Course?.none)
                    ForEach(courses) { c in Text(c.name).tag(Course?.some(c)) }
                }
                .tint(Brand.text)
            }
            if let course = selectedCourse, !course.sortedTees.isEmpty {
                Divider().overlay(Brand.hairline)
                HStack {
                    Text("Tee").foregroundStyle(Brand.text2)
                    Spacer()
                    Picker("Tee", selection: Binding(
                        get: { teeName },
                        set: { name in
                            teeName = name
                            if let t = course.tees.first(where: { $0.name == name }) {
                                courseRating = t.courseRating; slopeRating = t.slopeRating
                            }
                        })) {
                        ForEach(course.sortedTees) { t in Text(t.name).tag(t.name) }
                    }
                    .tint(Brand.text)
                }
            }
            Divider().overlay(Brand.hairline)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .tint(Brand.text)
                .foregroundStyle(Brand.text2)
        }
        .font(.subheadline)
        .glassCard()
    }

    private var runningCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Running total").font(.caption).foregroundStyle(Brand.text3)
                Text("\(runningTotal)").font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
            }
            Spacer()
            let played = zip(pars, scores).filter { $0.1 > 0 }.map { $0.0 }.reduce(0, +)
            Text(toParText(runningTotal - played))
                .font(.headline)
                .foregroundStyle(runningTotal - played <= 0 ? Brand.live : Brand.text2)
        }
        .glassCard()
    }

    private func nine(title: String, range: Range<Int>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: title)
            ForEach(range, id: \.self) { i in holeRow(i) }
        }
        .glassCard()
    }

    private func holeRow(_ i: Int) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(i + 1)")
                    .font(Brand.mono(15, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Par \(pars[i])").font(.caption).foregroundStyle(Brand.text2)
                    Text("SI \(strokeIndex[i])").font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                Spacer()
                Stepper(value: $scores[i], in: 0...15) {
                    Text(scores[i] > 0 ? "\(scores[i])" : "–")
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(ScoreColor.color(gross: scores[i], par: pars[i]))
                        .frame(width: 30)
                }
                .labelsHidden()
                .accessibilityLabel("Hole \(i + 1) score")
                .accessibilityValue(scores[i] > 0 ? "\(scores[i])" : "not entered")
            }
            if scores[i] > 0 {
                HStack(spacing: 14) {
                    Stepper("Putts \(putts[i])", value: $putts[i], in: 0...10)
                        .font(.caption).foregroundStyle(Brand.text2)
                        .fixedSize()
                    Spacer()
                    if pars[i] >= 4 {
                        Toggle(isOn: $fairway[i]) { Text("FIR").font(.caption) }
                            .toggleStyle(.button).tint(Brand.live)
                            .accessibilityLabel("Fairway hit, hole \(i + 1)")
                    }
                    Toggle(isOn: $gir[i]) { Text("GIR").font(.caption) }
                        .toggleStyle(.button).tint(Brand.live)
                        .accessibilityLabel("Green in regulation, hole \(i + 1)")
                }
            }
            Divider().overlay(Brand.hairline)
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            TextField("How did it go?", text: $notes, axis: .vertical)
                .lineLimit(2...5)
                .font(.subheadline)
                .foregroundStyle(Brand.text)
        }
        .glassCard()
    }

    // MARK: data

    private func load() {
        if let r = existing {
            selectedCourse = r.course
            teeName = r.teeName
            courseRating = r.courseRating
            slopeRating = r.slopeRating
            date = r.date
            pars = r.holePars; strokeIndex = r.holeStrokeIndex
            scores = r.holeScores; putts = r.holePutts
            fairway = r.fairwayHit; gir = r.greenInRegulation
            notes = r.notes
        } else if courses.count == 1 {
            applyCourse(courses.first)
        }
    }

    private func applyCourse(_ c: Course?) {
        selectedCourse = c
        guard let c else { pars = []; return }
        pars = c.holePars
        strokeIndex = c.holeStrokeIndex
        let n = c.holeCount
        scores = Array(repeating: 0, count: n)
        putts = Array(repeating: 0, count: n)
        fairway = Array(repeating: false, count: n)
        gir = Array(repeating: false, count: n)
        if let t = c.sortedTees.first {
            teeName = t.name; courseRating = t.courseRating; slopeRating = t.slopeRating
        }
    }

    private func save() {
        guard let course = selectedCourse else { return }
        let r: Round
        if let existing { r = existing } else {
            r = Round(date: date, courseName: course.name, teeName: teeName,
                      courseRating: courseRating, slopeRating: slopeRating,
                      holePars: pars, holeStrokeIndex: strokeIndex, course: course)
            context.insert(r)
        }
        r.date = date
        r.courseName = course.name
        r.teeName = teeName
        r.courseRating = courseRating
        r.slopeRating = slopeRating
        r.holePars = pars
        r.holeStrokeIndex = strokeIndex
        r.holeScores = scores
        r.holePutts = putts
        r.fairwayHit = fairway
        r.greenInRegulation = gir
        r.notes = notes
        r.course = course
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
