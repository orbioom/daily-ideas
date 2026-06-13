import SwiftUI

/// A read-only view of a past reflection, reached from the Path recent list.
struct ReflectionDetailView: View {
    let reflection: Reflection

    private var promptSet: PromptSet? { PromptLibrary.set(for: reflection.promptKey) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label(reflection.kind.title, systemImage: reflection.kind.icon)
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        VirtueBadge(virtue: reflection.virtue)
                    }

                    if reflection.kind == .evening && reflection.mood > 0 {
                        Card {
                            HStack {
                                Text("Mood")
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text("\(reflection.mood) / 5")
                                    .font(Theme.rounded(18, .bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Mood: \(reflection.mood) out of 5")
                    }

                    ForEach(entries, id: \.offset) { item in
                        Card {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.prompt)
                                    .font(Theme.rounded(13, .bold))
                                    .foregroundStyle(Theme.inkSoft)
                                Text(item.answer.isEmpty ? "—" : item.answer)
                                    .font(Theme.serif(17, .regular))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(Fmt.relativeDay(reflection.date))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var entries: [(offset: Int, prompt: String, answer: String)] {
        let prompts = promptSet?.prompts ?? []
        return reflection.responses.enumerated().map { idx, answer in
            let prompt = prompts.indices.contains(idx) ? prompts[idx] : "Reflection"
            return (idx, prompt, answer.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
