import SwiftUI
import SwiftData

struct CoursesView: View {
    @Query private var terms: [AcademicTerm]
    @Environment(\.modelContext) private var ctx
    @State private var showAddTerm = false
    @State private var showAddCourse = false
    @State private var selectedTerm: AcademicTerm?

    private var activeTerm: AcademicTerm? { terms.first(where: { $0.isActive }) }

    var body: some View {
        NavigationStack {
            ZStack {
                TermTheme.bg.ignoresSafeArea()
                if terms.isEmpty {
                    EmptyTermsView { showAddTerm = true }
                } else {
                    List {
                        ForEach(terms) { term in
                            Section {
                                if term.courses.isEmpty {
                                    Button {
                                        selectedTerm = term
                                        showAddCourse = true
                                    } label: {
                                        Label("Add first course", systemImage: "plus")
                                            .foregroundStyle(TermTheme.accent)
                                    }
                                } else {
                                    ForEach(term.courses) { course in
                                        NavigationLink(value: course) {
                                            CourseRow(course: course)
                                        }
                                    }
                                    .onDelete { offsets in deleteCourses(offsets: offsets, in: term) }
                                }
                            } header: {
                                TermSectionHeader(term: term, onAddCourse: {
                                    selectedTerm = term
                                    showAddCourse = true
                                })
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(TermTheme.bg)
                    .navigationDestination(for: Course.self) { CourseDetailView(course: $0) }
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showAddTerm = true } label: {
                        Label("Add Term", systemImage: "plus.rectangle")
                    }
                    .accessibilityLabel("Add new term")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if activeTerm != nil {
                        Button {
                            selectedTerm = activeTerm
                            showAddCourse = true
                        } label: {
                            Label("Add Course", systemImage: "plus")
                        }
                        .accessibilityLabel("Add course to active term")
                    }
                }
            }
            .sheet(isPresented: $showAddTerm) { AddTermSheet() }
            .sheet(isPresented: $showAddCourse) {
                if let t = selectedTerm { AddCourseSheet(term: t) }
            }
        }
    }

    private func deleteCourses(offsets: IndexSet, in term: AcademicTerm) {
        for i in offsets { ctx.delete(term.courses[i]) }
    }
}

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: course.colorHex))
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.subheadline.bold())
                Text(course.code)
                    .font(.caption)
                    .foregroundStyle(TermTheme.subtle)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(course.letterGrade)
                    .font(.headline.bold())
                    .foregroundStyle(TermTheme.gradeColor(course.currentGrade))
                Text(String(format: "%.1f%%", course.currentGrade))
                    .font(.caption)
                    .foregroundStyle(TermTheme.subtle)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(course.name), \(course.code), grade \(course.letterGrade)")
    }
}

private struct TermSectionHeader: View {
    let term: AcademicTerm
    let onAddCourse: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(term.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .textCase(nil)
                if term.isActive {
                    Text("Active · GPA \(String(format: "%.2f", term.gpa))")
                        .font(.caption)
                        .foregroundStyle(TermTheme.accent)
                        .textCase(nil)
                }
            }
            Spacer()
            Button(action: onAddCourse) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(TermTheme.accent)
            }
            .accessibilityLabel("Add course to \(term.name)")
        }
    }
}

private struct EmptyTermsView: View {
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 52))
                .foregroundStyle(TermTheme.accent)
            Text("No Terms Yet")
                .font(.title2.bold())
            Text("Create your first academic term to start tracking courses and grades.")
                .font(.subheadline)
                .foregroundStyle(TermTheme.subtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: onAdd) {
                Label("Add Term", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(TermTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

struct AddTermSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Term Name") {
                    TextField("e.g. Fall 2025", text: $name)
                }
                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Term")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let t = AcademicTerm(name: name.trimmingCharacters(in: .whitespaces), startDate: startDate, endDate: endDate)
        ctx.insert(t)
        dismiss()
    }
}

struct AddCourseSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let term: AcademicTerm

    @State private var name = ""
    @State private var code = ""
    @State private var instructor = ""
    @State private var credits = 3.0
    @State private var colorHex = "#5C6BC0"

    private let palette = ["#5C6BC0","#26A69A","#EF5350","#FFA726","#66BB6A","#AB47BC","#42A5F5","#EC407A"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Course Info") {
                    TextField("Course Name", text: $name)
                    TextField("Code (e.g. CS101)", text: $code)
                    TextField("Instructor", text: $instructor)
                }
                Section("Credits") {
                    Stepper("\(String(format: "%.1f", credits)) credits", value: $credits, in: 0.5...6.0, step: 0.5)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(.white, lineWidth: colorHex == hex ? 3 : 0))
                                .onTapGesture { colorHex = hex }
                                .accessibilityLabel("Color option")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let c = Course(
            name: name.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespaces),
            instructor: instructor,
            colorHex: colorHex,
            credits: credits
        )
        ctx.insert(c)
        term.courses.append(c)
        dismiss()
    }
}
