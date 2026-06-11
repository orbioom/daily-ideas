import SwiftUI

struct PracticeView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var selectedPrompt: Prompt?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    freeTalkHero
                    ForEach(PromptCategory.allCases) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.headline)
                                .foregroundStyle(Theme.ink(scheme))
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(PromptLibrary.prompts(in: category)) { prompt in
                                        promptCard(prompt)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background(scheme))
            .navigationTitle("Practice")
            .fullScreenCover(item: $selectedPrompt) { prompt in
                RecordingView(prompt: prompt)
            }
        }
    }

    private var freeTalkHero: some View {
        Button {
            Haptics.tap()
            selectedPrompt = PromptLibrary.freeTalk
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.violet)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free talk")
                        .font(Theme.display(22))
                        .foregroundStyle(Theme.ink(scheme))
                    Text("No prompt — just speak and get live pace + filler feedback.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft(scheme))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .accessibilityHidden(true)
            }
            .podiumCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Starts a recording without a prompt")
    }

    private func promptCard(_ prompt: Prompt) -> some View {
        Button {
            Haptics.tap()
            selectedPrompt = prompt
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink(scheme))
                    .multilineTextAlignment(.leading)
                Text(prompt.text)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                Spacer(minLength: 0)
                Label("Practice", systemImage: "mic.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.violet)
            }
            .padding(14)
            .frame(width: 200, height: 150, alignment: .topLeading)
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.05), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(prompt.title). \(prompt.text)")
        .accessibilityHint("Starts a recording for this prompt")
    }
}
