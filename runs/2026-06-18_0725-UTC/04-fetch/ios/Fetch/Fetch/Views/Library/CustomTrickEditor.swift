import SwiftUI
import SwiftData

/// Create or edit a custom trick (Pro). Steps and tips are entered one per line.
struct CustomTrickEditor: View {
    var existing: CustomTrick? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @State private var summary = ""
    @State private var category: TrickCategory = .tricks
    @State private var difficulty: Difficulty = .easy
    @State private var stepsText = ""
    @State private var tipsText = ""
    @State private var estimatedDays = 7

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Card {
                            VStack(spacing: 12) {
                                LabeledField(title: "Trick name", text: $name, prompt: "e.g. Spin Left")
                                LabeledField(title: "Short summary", text: $summary, prompt: "What this trick is")
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Picker("Category", selection: $category) {
                                    ForEach(TrickCategory.allCases) { c in
                                        Text(c.rawValue).tag(c)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Theme.accent)

                                Text("Difficulty")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Picker("Difficulty", selection: $difficulty) {
                                    ForEach(Difficulty.allCases) { d in
                                        Text(d.label).tag(d)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Stepper("Estimated days: \(estimatedDays)", value: $estimatedDays, in: 1...90)
                                    .font(Theme.rounded(15, .medium))
                                    .foregroundStyle(Theme.ink)
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Steps (one per line)", systemImage: "list.number")
                                TextEditor(text: $stepsText)
                                    .font(Theme.rounded(15))
                                    .frame(minHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceAlt))
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "Tips (one per line)", systemImage: "lightbulb")
                                TextEditor(text: $tipsText)
                                    .font(Theme.rounded(15))
                                    .frame(minHeight: 80)
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceAlt))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(existing == nil ? "New Trick" : "Edit Trick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let e = existing else { return }
        name = e.name
        summary = e.summary
        category = e.category
        difficulty = e.difficulty
        stepsText = e.steps.joined(separator: "\n")
        tipsText = e.tips.joined(separator: "\n")
        estimatedDays = e.estimatedDays
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let steps = stepsText.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let tips = tipsText.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        if let e = existing {
            e.name = trimmedName
            e.summary = summary
            e.categoryRaw = category.rawValue
            e.difficultyRaw = difficulty.rawValue
            e.stepsText = steps.joined(separator: "\n")
            e.tipsText = tips.joined(separator: "\n")
            e.estimatedDays = max(1, estimatedDays)
        } else {
            let trick = CustomTrick(
                name: trimmedName,
                category: category,
                difficulty: difficulty,
                summary: summary,
                steps: steps,
                tips: tips,
                estimatedDays: estimatedDays
            )
            context.insert(trick)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
