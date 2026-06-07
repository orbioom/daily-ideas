import SwiftUI
import SwiftData

struct CoursesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var showingEditor = false
    @State private var editTarget: Course?

    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "map", title: "No courses",
                                       message: "Add the courses you play to make logging rounds quick.")
                        .glassCard().padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(courses) { course in
                                Button {
                                    Haptics.tap(); editTarget = course
                                } label: { CourseRow(course: course) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(course); try? context.save(); Haptics.warning()
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add course")
                }
            }
            .background(Brand.pageBackground)
            .sheet(isPresented: $showingEditor) { CourseEditView(existing: nil) }
            .sheet(item: $editTarget) { course in CourseEditView(existing: course) }
        }
    }
}

private struct CourseRow: View {
    let course: Course
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name).font(.headline).foregroundStyle(Brand.text)
                    if !course.location.isEmpty {
                        Text(course.location).font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Par \(course.par)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("\(course.holeCount) holes").font(.caption).foregroundStyle(Brand.text3)
                }
            }
            if !course.tees.isEmpty {
                HStack(spacing: 6) {
                    ForEach(course.sortedTees) { t in
                        Badge(text: "\(t.name) \(String(format: "%.1f", t.courseRating))/\(t.slopeRating)")
                    }
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(course.name), par \(course.par), \(course.tees.count) tees")
    }
}
