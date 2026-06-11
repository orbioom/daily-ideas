import SwiftUI
import SwiftData

struct CourseDetailView: View {
    @Bindable var course: Course
    @Environment(\.modelContext) private var ctx
    @State private var showAddWeight = false
    @State private var showAddAssignment = false
    @State private var showAddSchedule = false

    var body: some View {
        ZStack {
            TermTheme.bg.ignoresSafeArea()
            List {
                Section {
                    GradeHeader(course: course)
                }
                .listRowBackground(Color(hex: course.colorHex).opacity(0.12))

                Section {
                    if course.weights.isEmpty {
                        Text("No weights — using simple average")
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                        Button {
                            showAddWeight = true
                        } label: {
                            Label("Add grading weights", systemImage: "plus")
                                .foregroundStyle(TermTheme.accent)
                        }
                    } else {
                        ForEach(course.weights) { w in
                            WeightRow(weight: w)
                        }
                        .onDelete { offsets in
                            for i in offsets { ctx.delete(course.weights[i]) }
                        }
                        Button {
                            showAddWeight = true
                        } label: {
                            Label("Add category", systemImage: "plus")
                                .foregroundStyle(TermTheme.accent)
                        }
                    }
                } header: { SLabel("Grading Weights") }

                Section {
                    if course.assignments.isEmpty {
                        Text("No assignments yet")
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                    } else {
                        ForEach(course.assignments.sorted { $0.dueDate < $1.dueDate }) { a in
                            NavigationLink(value: a) {
                                AssignmentRow(assignment: a, showCourse: false, term: nil)
                            }
                        }
                        .onDelete { offsets in deleteAssignments(offsets: offsets) }
                    }
                    Button {
                        showAddAssignment = true
                    } label: {
                        Label("Add assignment", systemImage: "plus")
                            .foregroundStyle(TermTheme.accent)
                    }
                } header: { SLabel("Assignments") }

                Section {
                    if course.schedule.isEmpty {
                        Text("No schedule set")
                            .font(.caption)
                            .foregroundStyle(TermTheme.subtle)
                    } else {
                        ForEach(course.schedule.sorted { $0.weekday < $1.weekday }) { s in
                            ScheduleRow(schedule: s)
                        }
                        .onDelete { offsets in
                            for i in offsets { ctx.delete(course.schedule[i]) }
                        }
                    }
                    Button {
                        showAddSchedule = true
                    } label: {
                        Label("Add class time", systemImage: "plus")
                            .foregroundStyle(TermTheme.accent)
                    }
                } header: { SLabel("Schedule") }
            }
            .scrollContentBackground(.hidden)
            .background(TermTheme.bg)
        }
        .navigationTitle(course.code)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Assignment.self) { AssignmentEditorView(assignment: $0) }
        .sheet(isPresented: $showAddWeight) { AddWeightSheet(course: course) }
        .sheet(isPresented: $showAddAssignment) { AddAssignmentSheet(course: course) }
        .sheet(isPresented: $showAddSchedule) { AddScheduleSheet(course: course) }
    }

    private func deleteAssignments(offsets: IndexSet) {
        let sorted = course.assignments.sorted { $0.dueDate < $1.dueDate }
        for i in offsets { ctx.delete(sorted[i]) }
    }
}

private struct GradeHeader: View {
    let course: Course
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.headline)
                if !course.instructor.isEmpty {
                    Text(course.instructor)
                        .font(.caption)
                        .foregroundStyle(TermTheme.subtle)
                }
                Text("\(String(format: "%.1f", course.credits)) credits")
                    .font(.caption)
                    .foregroundStyle(TermTheme.subtle)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(course.letterGrade)
                    .font(.largeTitle.bold())
                    .foregroundStyle(TermTheme.gradeColor(course.currentGrade))
                Text(String(format: "%.1f%%", course.currentGrade))
                    .font(.subheadline)
                    .foregroundStyle(TermTheme.subtle)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct WeightRow: View {
    let weight: GradeWeight
    var body: some View {
        HStack {
            Text(weight.category)
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.0f%%", weight.weight * 100))
                .font(.subheadline.bold())
                .foregroundStyle(TermTheme.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weight.category), \(String(format: "%.0f", weight.weight * 100)) percent")
    }
}

private struct ScheduleRow: View {
    let schedule: ClassSchedule
    var body: some View {
        HStack {
            Text(schedule.weekdayName)
                .font(.subheadline.bold())
                .frame(width: 36, alignment: .leading)
            Text(schedule.startTime, style: .time)
            Text("–")
            Text(schedule.endTime, style: .time)
            Spacer()
            if !schedule.location.isEmpty {
                Text(schedule.location)
                    .font(.caption)
                    .foregroundStyle(TermTheme.subtle)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

private struct SLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(TermTheme.accent)
            .textCase(nil)
    }
}

struct AddWeightSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var category = ""
    @State private var weightPct = 20.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("e.g. Homework, Exams", text: $category)
                }
                Section("Weight") {
                    HStack {
                        Slider(value: $weightPct, in: 1...100, step: 1)
                            .tint(TermTheme.accent)
                        Text("\(Int(weightPct))%")
                            .font(.headline)
                            .frame(width: 44)
                    }
                }
                Section {
                    let totalExisting = course.weights.reduce(0.0) { $0 + $1.weight * 100 }
                    let remaining = 100 - totalExisting
                    Text("Remaining: \(Int(remaining))%")
                        .foregroundStyle(remaining < 0 ? .red : TermTheme.subtle)
                        .font(.caption)
                }
            }
            .navigationTitle("Grade Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let w = GradeWeight(category: category.trimmingCharacters(in: .whitespaces), weight: weightPct / 100.0)
        ctx.insert(w)
        course.weights.append(w)
        dismiss()
    }
}

struct AddAssignmentSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var name = ""
    @State private var category = ""
    @State private var dueDate = Date()
    @State private var maxPoints = 100.0

    private var categories: [String] {
        Array(Set(course.weights.map(\.category) + course.assignments.map(\.category))).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Assignment Name", text: $name)
                    if categories.isEmpty {
                        TextField("Category", text: $category)
                    } else {
                        Picker("Category", selection: $category) {
                            Text("Uncategorized").tag("")
                            ForEach(categories, id: \.self) { Text($0).tag($0) }
                        }
                    }
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Points") {
                    HStack {
                        Text("Max Points")
                        Spacer()
                        TextField("100", value: $maxPoints, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("New Assignment")
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
        let a = Assignment(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category.isEmpty ? "General" : category,
            dueDate: dueDate,
            maxPoints: maxPoints
        )
        ctx.insert(a)
        course.assignments.append(a)
        dismiss()
    }
}

struct AddScheduleSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var weekday = 2
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime   = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var location = ""

    private let days = [(2,"Mon"),(3,"Tue"),(4,"Wed"),(5,"Thu"),(6,"Fri"),(7,"Sat"),(1,"Sun")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    Picker("Weekday", selection: $weekday) {
                        ForEach(days, id: \.0) { d in Text(d.1).tag(d.0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Time") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                Section("Location") {
                    TextField("Room / Building (optional)", text: $location)
                }
            }
            .navigationTitle("Class Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                }
            }
        }
    }

    private func save() {
        let s = ClassSchedule(weekday: weekday, startTime: startTime, endTime: endTime, location: location)
        ctx.insert(s)
        course.schedule.append(s)
        dismiss()
    }
}
