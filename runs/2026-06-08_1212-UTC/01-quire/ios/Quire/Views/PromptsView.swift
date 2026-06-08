import SwiftUI
import SwiftData

struct PromptsView: View {
    @Environment(\.modelContext) private var context
    @State private var category: PromptCategory? = nil
    @State private var editing: JournalEntry?

    private var prompts: [JournalPrompt] {
        if let c = category { return PromptLibrary.category(c) }
        return PromptLibrary.all
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        featured
                        categoryFilter
                        ForEach(prompts) { prompt in
                            promptRow(prompt)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Prompts")
            .sheet(item: $editing) { EntryEditorView(entry: $0) }
        }
    }

    private var featured: some View {
        let p = PromptLibrary.promptOfDay()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles").foregroundStyle(Color.accentColor)
                Eyebrow(text: "Prompt of the Day")
                Spacer()
            }
            Text(p.text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
            Button("Write from this") { start(p) }
                .buttonStyle(InkButtonStyle())
        }
        .glassCard()
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", symbol: "square.grid.2x2", isOn: category == nil) {
                    withAnimation(Brand.ease(0.2)) { category = nil }
                }
                ForEach(PromptCategory.allCases) { c in
                    chip(title: c.rawValue, symbol: c.symbol, isOn: category == c) {
                        withAnimation(Brand.ease(0.2)) { category = c }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func chip(title: String, symbol: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.caption)
                Text(title).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isOn ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.12))
            )
            .foregroundStyle(isOn ? Color.accentColor : Brand.text2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func promptRow(_ prompt: JournalPrompt) -> some View {
        Button { start(prompt) } label: {
            HStack(spacing: 12) {
                Image(systemName: prompt.category.symbol)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(prompt.text)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(prompt.category.rawValue)
                        .font(Brand.mono(10))
                        .foregroundStyle(Brand.text3)
                }
                Spacer()
                Image(systemName: "square.and.pencil").foregroundStyle(Brand.text3)
            }
            .glassCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Start a new entry from this prompt")
    }

    private func start(_ prompt: JournalPrompt) {
        Haptics.tap()
        let entry = JournalEntry(promptText: prompt.text)
        context.insert(entry)
        editing = entry
    }
}
