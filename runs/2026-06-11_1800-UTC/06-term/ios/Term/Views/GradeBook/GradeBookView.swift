import SwiftUI
import SwiftData
import Charts

struct GradeBookView: View {
    @Query private var terms: [AcademicTerm]
    @State private var selectedTermIndex = 0

    private var displayedTerms: [AcademicTerm] { terms }
    private var currentTerm: AcademicTerm? {
        guard !terms.isEmpty, selectedTermIndex < terms.count else { return nil }
        return terms[selectedTermIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TermTheme.bg.ignoresSafeArea()
                if terms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(TermTheme.subtle)
                        Text("No Terms Yet")
                            .font(.headline)
                        Text("Add courses from the Courses tab to see grades here.")
                            .font(.subheadline)
                            .foregroundStyle(TermTheme.subtle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if terms.count > 1 {
                                Picker("Term", selection: $selectedTermIndex) {
                                    ForEach(terms.indices, id: \.self) { i in
                                        Text(terms[i].name).tag(i)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                            }

                            if let term = currentTerm {
                                GPASummaryCard(term: term)
                                CourseGradesChart(courses: term.courses)
                                WhatIfCalculator(courses: term.courses)
                                ForEach(term.courses) { course in
                                    CourseGradeDetail(course: course)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Grade Book")
        }
    }
}

private struct GPASummaryCard: View {
    let term: AcademicTerm
    var body: some View {
        HStack(spacing: 0) {
            StatBox(title: "GPA", value: String(format: "%.2f", term.gpa),
                    color: TermTheme.gpaColor(term.gpa))
            Divider().frame(height: 50)
            StatBox(title: "Courses", value: "\(term.courses.count)", color: TermTheme.accent)
            Divider().frame(height: 50)
            let avgGrade = term.courses.isEmpty ? 0.0 :
                term.courses.reduce(0.0) { $0 + $1.currentGrade } / Double(term.courses.count)
            StatBox(title: "Avg Grade",
                    value: String(format: "%.1f%%", avgGrade),
                    color: TermTheme.gradeColor(avgGrade))
        }
        .padding()
        .background(TermTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(TermTheme.subtle)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CourseGradesChart: View {
    let courses: [Course]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Course Grades")
                .font(.headline)
                .padding(.horizontal)
            Chart(courses) { course in
                BarMark(
                    x: .value("Grade", course.currentGrade),
                    y: .value("Course", course.code)
                )
                .foregroundStyle(Color(hex: course.colorHex))
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text(course.letterGrade)
                        .font(.caption.bold())
                        .foregroundStyle(TermTheme.gradeColor(course.currentGrade))
                }
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 60, 70, 80, 90, 100]) { v in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: max(60, CGFloat(courses.count) * 44))
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(TermTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct WhatIfCalculator: View {
    let courses: [Course]
    @State private var targetGPA = 3.5

    private func neededGrade(for course: Course) -> Double {
        let others = courses.filter { $0.id != course.id }
        let otherPoints = others.reduce(0.0) { $0 + GPACalculator.gradeToPoints($1.currentGrade) * $1.credits }
        let otherCredits = others.reduce(0.0) { $0 + $1.credits }
        let totalCredits = courses.reduce(0.0) { $0 + $1.credits }
        guard totalCredits > 0 else { return 0 }
        let neededPoints = targetGPA * totalCredits - otherPoints
        let needed = neededPoints / course.credits
        return needed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What-If GPA")
                    .font(.headline)
                Spacer()
                Text(String(format: "Target: %.1f", targetGPA))
                    .font(.subheadline)
                    .foregroundStyle(TermTheme.accent)
            }
            Slider(value: $targetGPA, in: 1.0...4.0, step: 0.1)
                .tint(TermTheme.accent)
                .accessibilityLabel("Target GPA slider")
            ForEach(courses) { course in
                let needed = neededGrade(for: course)
                HStack {
                    Circle()
                        .fill(Color(hex: course.colorHex))
                        .frame(width: 8, height: 8)
                    Text(course.code)
                        .font(.subheadline)
                    Spacer()
                    if needed <= 0 {
                        Text("Already met")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if needed > 4.0 {
                        Text("Not achievable")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else {
                        Text("Need \(GPACalculator.pointsToLetter(needed * 25)) (\(String(format: "%.1f GPA pts", needed)))")
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                    }
                }
            }
        }
        .padding()
        .background(TermTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct CourseGradeDetail: View {
    let course: Course
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Circle()
                        .fill(Color(hex: course.colorHex))
                        .frame(width: 10, height: 10)
                    Text(course.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(String(format: "%.1f%%", course.currentGrade))
                        .font(.subheadline)
                        .foregroundStyle(TermTheme.gradeColor(course.currentGrade))
                    Text(course.letterGrade)
                        .font(.subheadline.bold())
                        .foregroundStyle(TermTheme.gradeColor(course.currentGrade))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                }
            }
            .accessibilityLabel("\(course.name), \(course.letterGrade), \(String(format: "%.1f percent", course.currentGrade)), \(isExpanded ? "expanded" : "collapsed")")

            if isExpanded {
                let gradedAssignments = course.assignments.filter { $0.status == .graded }
                if gradedAssignments.isEmpty {
                    Text("No graded assignments")
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                        .padding(.leading, 18)
                } else {
                    ForEach(gradedAssignments.sorted { $0.dueDate > $1.dueDate }) { a in
                        HStack {
                            Text(a.name)
                                .font(.caption)
                                .padding(.leading, 18)
                            Spacer()
                            if let pct = a.percentage {
                                Text(String(format: "%.0f%%", pct))
                                    .font(.caption.bold())
                                    .foregroundStyle(TermTheme.gradeColor(pct))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(TermTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
