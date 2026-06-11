import SwiftUI
import SwiftData

struct AgendaView: View {
    @Query private var terms: [AcademicTerm]
    @Environment(\.modelContext) private var ctx

    private var activeTerm: AcademicTerm? { terms.first(where: { $0.isActive }) }

    private var todayClasses: [(ClassSchedule, Course)] {
        let wd = Calendar.current.component(.weekday, from: Date())
        guard let term = activeTerm else { return [] }
        return term.courses.flatMap { course in
            course.schedule.filter { $0.weekday == wd }.map { ($0, course) }
        }.sorted { $0.0.startTime < $1.0.startTime }
    }

    private var upcoming: [Assignment] {
        guard let term = activeTerm else { return [] }
        let now = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        return term.courses.flatMap(\.assignments)
            .filter { $0.status == .pending && $0.dueDate >= now && $0.dueDate <= cutoff }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var overdueAssignments: [Assignment] {
        guard let term = activeTerm else { return [] }
        return term.courses.flatMap(\.assignments)
            .filter(\.isOverdue)
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TermTheme.bg.ignoresSafeArea()
                if activeTerm == nil {
                    NoTermPlaceholder()
                } else {
                    List {
                        if !overdueAssignments.isEmpty {
                            Section {
                                ForEach(overdueAssignments) { a in
                                    AssignmentRow(assignment: a, showCourse: true, term: activeTerm)
                                }
                            } header: {
                                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption.bold())
                            }
                        }

                        Section {
                            if todayClasses.isEmpty {
                                Text("No classes today")
                                    .foregroundStyle(TermTheme.subtle)
                                    .font(.subheadline)
                            } else {
                                ForEach(todayClasses, id: \.0.startTime) { sched, course in
                                    ClassRow(schedule: sched, course: course)
                                }
                            }
                        } header: {
                            SectionHeader("Today's Classes", icon: "clock")
                        }

                        Section {
                            if upcoming.isEmpty {
                                Text("Nothing due in the next 14 days")
                                    .foregroundStyle(TermTheme.subtle)
                                    .font(.subheadline)
                            } else {
                                ForEach(upcoming) { a in
                                    AssignmentRow(assignment: a, showCourse: true, term: activeTerm)
                                }
                            }
                        } header: {
                            SectionHeader("Upcoming (14 days)", icon: "calendar")
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(TermTheme.bg)
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                if let term = activeTerm {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text(term.name)
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                    }
                }
            }
        }
    }
}

struct ClassRow: View {
    let schedule: ClassSchedule
    let course: Course

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: course.colorHex))
                .frame(width: 4, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(schedule.weekdayName)
                    Text("·")
                    Text(schedule.startTime, style: .time)
                    Text("–")
                    Text(schedule.endTime, style: .time)
                }
                .font(.caption)
                .foregroundStyle(TermTheme.subtle)
                if !schedule.location.isEmpty {
                    Text(schedule.location)
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

struct AssignmentRow: View {
    @Bindable var assignment: Assignment
    let showCourse: Bool
    let term: AcademicTerm?

    private var courseName: String? {
        guard showCourse else { return nil }
        return term?.courses.first(where: { $0.assignments.contains(where: { $0.id == assignment.id }) })?.name
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: assignment.status.icon)
                .foregroundStyle(assignment.isOverdue ? .red : TermTheme.accent)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.name)
                    .font(.subheadline.bold())
                    .strikethrough(assignment.status == .graded)
                HStack(spacing: 4) {
                    if let cn = courseName {
                        Text(cn)
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                        Text("·")
                            .foregroundStyle(TermTheme.subtle)
                    }
                    Text(assignment.category)
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if assignment.isOverdue {
                    Text("Overdue")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                } else {
                    Text(assignment.dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                }
                if let pct = assignment.percentage {
                    Text(String(format: "%.0f%%", pct))
                        .font(.caption.bold())
                        .foregroundStyle(TermTheme.gradeColor(pct))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct NoTermPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(TermTheme.subtle)
            Text("No Active Term")
                .font(.headline)
            Text("Add a term from the Courses tab to get started.")
                .font(.subheadline)
                .foregroundStyle(TermTheme.subtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String
    init(_ title: String, icon: String) { self.title = title; self.icon = icon }
    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(TermTheme.accent)
            .textCase(nil)
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8)  & 0xFF) / 255
        let b = Double(val         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
