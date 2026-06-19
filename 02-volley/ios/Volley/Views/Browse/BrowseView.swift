import SwiftUI
import SwiftData

struct BrowseView: View {
    @Query(sort: \Question.createdAt) private var questions: [Question]
    @State private var searchText = ""
    @State private var selectedMode: QuestionMode? = nil
    @Environment(\.modelContext) private var modelContext

    private var filteredQuestions: [Question] {
        questions.filter { q in
            let matchesSearch = searchText.isEmpty || q.text.localizedCaseInsensitiveContains(searchText)
            let matchesMode = selectedMode == nil || q.mode == selectedMode?.rawValue
            return matchesSearch && matchesMode
        }
    }

    private var groupedQuestions: [(QuestionMode, [Question])] {
        QuestionMode.allCases.compactMap { mode in
            let modeQuestions = filteredQuestions.filter { $0.mode == mode.rawValue }
            guard !modeQuestions.isEmpty else { return nil }
            return (mode, modeQuestions)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedMode == nil) {
                            selectedMode = nil
                        }
                        ForEach(QuestionMode.allCases) { mode in
                            FilterChip(
                                title: mode.rawValue,
                                isSelected: selectedMode == mode,
                                color: VolleyTheme.gradient(for: mode).first
                            ) {
                                selectedMode = selectedMode == mode ? nil : mode
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if filteredQuestions.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Questions" : "No Results",
                        systemImage: "magnifyingglass",
                        description: Text(
                            searchText.isEmpty
                            ? "Add custom questions or check your filters."
                            : "Try a different search term."
                        )
                    )
                } else {
                    List {
                        ForEach(groupedQuestions, id: \.0) { mode, modeQuestions in
                            Section {
                                ForEach(modeQuestions) { question in
                                    BrowseQuestionRow(question: question) { newValue in
                                        question.isEnabled = newValue
                                    }
                                }
                            } header: {
                                HStack(spacing: 8) {
                                    Image(systemName: VolleyTheme.icon(for: mode))
                                        .foregroundStyle(VolleyTheme.gradient(for: mode).first ?? .gray)
                                    Text(mode.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(VolleyTheme.text)
                                    Spacer()
                                    Text("\(modeQuestions.count)")
                                        .font(.caption)
                                        .foregroundStyle(VolleyTheme.textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(VolleyTheme.background)
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search questions")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color? = nil
    let onTap: () -> Void

    var chipColor: Color { color ?? VolleyTheme.accent }

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : VolleyTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? chipColor : VolleyTheme.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter\(isSelected ? ", selected" : "")")
    }
}

struct BrowseQuestionRow: View {
    let question: Question
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Mode color dot
            Circle()
                .fill(
                    VolleyTheme.gradient(
                        for: QuestionMode(rawValue: question.mode) ?? .icebreaker
                    ).first ?? .gray
                )
                .frame(width: 8, height: 8)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(question.text)
                    .font(.subheadline)
                    .foregroundStyle(question.isEnabled ? VolleyTheme.text : VolleyTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(question.category.capitalized)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(VolleyTheme.categoryColor(for: QuestionCategory(rawValue: question.category) ?? .all))
                        .clipShape(Capsule())

                    if question.isCustom {
                        Text("Custom")
                            .font(.caption)
                            .foregroundStyle(VolleyTheme.accent)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(VolleyTheme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(get: { question.isEnabled }, set: { onToggle($0) }))
                .labelsHidden()
                .tint(VolleyTheme.accent)
        }
        .padding(.vertical, 2)
        .opacity(question.isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(question.text)
        .accessibilityHint(question.isEnabled ? "Enabled — toggle to disable" : "Disabled — toggle to enable")
    }
}
