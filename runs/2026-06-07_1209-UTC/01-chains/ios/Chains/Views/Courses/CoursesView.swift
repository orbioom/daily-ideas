import SwiftUI
import SwiftData

struct CoursesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiscCourse.name) private var courses: [DiscCourse]
    @AppStorage("chains.units") private var units = "feet"
    @State private var showNew = false

    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "map",
                                       title: "No courses yet",
                                       message: "Add the layouts you play. Set each hole's par and distance once, then score rounds in seconds.")
                            .padding(.top, 40)
                        Button { showNew = true } label: {
                            Label("Add a course", systemImage: "plus")
                        }.buttonStyle(InkButtonStyle()).padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(courses) { course in
                                NavigationLink {
                                    CourseDetailView(course: course)
                                } label: { CourseRow(course: course, units: units) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Courses")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                        .tint(Brand.text)
                }
            }
            .sheet(isPresented: $showNew) {
                CourseEditView(course: nil)
            }
        }
    }
}

private struct CourseRow: View {
    let course: DiscCourse
    let units: String
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name).font(.headline).foregroundStyle(Brand.text)
                if !course.location.isEmpty {
                    Text(course.location).font(.subheadline).foregroundStyle(Brand.text2)
                }
                HStack(spacing: 8) {
                    Badge(text: "\(course.holeCount) holes")
                    Badge(text: "Par \(course.par)")
                    if course.totalDistanceFeet > 0 {
                        Badge(text: Fmt.distance(feet: course.totalDistanceFeet, units: units))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}
