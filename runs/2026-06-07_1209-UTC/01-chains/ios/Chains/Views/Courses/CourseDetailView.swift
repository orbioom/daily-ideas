import SwiftUI
import SwiftData

struct CourseDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("chains.units") private var units = "feet"
    @AppStorage("chains.confirmDeletes") private var confirmDeletes = true
    @Bindable var course: DiscCourse
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatTile(value: "\(course.holeCount)", label: "Holes")
                    StatTile(value: "\(course.par)", label: "Par", accent: Brand.text)
                    StatTile(value: Fmt.distance(feet: course.totalDistanceFeet, units: units), label: "Distance")
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Rating baseline")
                    InfoRow(label: "Scratch average", value: String(format: "%.0f", course.ssa), mono: true)
                    Divider().overlay(Brand.hairline)
                    InfoRow(label: "Points / throw", value: String(format: "%.1f", course.pointsPerThrow), mono: true)
                    Text("A round shooting \(Int(course.ssa)) here rates ~1000.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }.glassCard()

                VStack(alignment: .leading, spacing: 0) {
                    SectionTitle(text: "Layout").padding(.bottom, 8)
                    ForEach(course.orderedHoles) { hole in
                        HStack {
                            Text("\(hole.number)")
                                .font(Brand.mono(15, weight: .semibold))
                                .foregroundStyle(Brand.text).frame(width: 28, alignment: .leading)
                            Badge(text: "Par \(hole.par)")
                            Spacer()
                            if hole.distanceFeet > 0 {
                                Text(Fmt.distance(feet: hole.distanceFeet, units: units))
                                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                            }
                        }
                        .padding(.vertical, 8)
                        if hole.id != course.orderedHoles.last?.id {
                            Divider().overlay(Brand.hairline)
                        }
                    }
                }.glassCard()
            }
            .padding()
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit course", systemImage: "pencil") }
                    Button(role: .destructive) {
                        if confirmDeletes { showDeleteConfirm = true } else { deleteCourse() }
                    } label: { Label("Delete course", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
                    .tint(Brand.text)
            }
        }
        .sheet(isPresented: $showEdit) { CourseEditView(course: course) }
        .confirmationDialog("Delete \(course.name)? Rounds you've already saved are kept.",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete course", role: .destructive) { deleteCourse() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func deleteCourse() {
        context.delete(course)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
