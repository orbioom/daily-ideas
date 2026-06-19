import SwiftUI
import SwiftData

struct LessonListView: View {
    let module: CurriculumModule
    @Query private var settingsQuery: [UserSettings]

    private var settings: UserSettings? { settingsQuery.first }

    var body: some View {
        List {
            ForEach(module.lessons) { lesson in
                NavigationLink(destination: PianoSessionView(lesson: lesson, module: module)) {
                    LessonRow(lesson: lesson, isCompleted: settings?.isLessonCompleted(lesson.id) ?? false)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(KeysTheme.background)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct LessonRow: View {
    let lesson: LessonContent
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Completion indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? KeysTheme.accent : KeysTheme.surface)
                    .frame(width: 36, height: 36)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(KeysTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KeysTheme.text)
                Text(lesson.subtitle)
                    .font(.caption)
                    .foregroundStyle(KeysTheme.textSecondary)
            }

            Spacer()

            // Type badge
            Text(lesson.type.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(lesson.type.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(lesson.type.color.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel("\(lesson.title), \(lesson.type.displayName) exercise\(isCompleted ? ", completed" : "")")
    }
}
