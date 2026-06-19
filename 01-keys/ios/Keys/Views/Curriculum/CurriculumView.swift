import SwiftUI
import SwiftData

struct CurriculumView: View {
    @Query private var settingsQuery: [UserSettings]

    private var settings: UserSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            Group {
                if Curriculum.modules.isEmpty {
                    ContentUnavailableView(
                        "No Modules",
                        systemImage: "book.closed",
                        description: Text("Curriculum is loading...")
                    )
                } else {
                    List {
                        ForEach(Curriculum.modules) { module in
                            NavigationLink(destination: LessonListView(module: module)) {
                                ModuleRow(module: module, settings: settings)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(KeysTheme.background)
            .navigationTitle("Learn")
        }
    }
}

struct ModuleRow: View {
    let module: CurriculumModule
    let settings: UserSettings?

    private var completedCount: Int {
        guard let settings else { return 0 }
        return module.lessons.filter { settings.isLessonCompleted($0.id) }.count
    }

    private var progress: Double {
        guard !module.lessons.isEmpty else { return 0 }
        return Double(completedCount) / Double(module.lessons.count)
    }

    private var isComplete: Bool { completedCount == module.lessons.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(module.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: module.icon)
                        .font(.title2)
                        .foregroundStyle(module.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(module.title)
                            .font(.headline)
                            .foregroundStyle(KeysTheme.text)
                        Spacer()
                        if isComplete {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(module.color)
                        }
                    }

                    Text("\(completedCount)/\(module.lessons.count) lessons")
                        .font(.subheadline)
                        .foregroundStyle(KeysTheme.textSecondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(module.color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(module.color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(module.title), \(completedCount) of \(module.lessons.count) lessons complete")
    }
}
