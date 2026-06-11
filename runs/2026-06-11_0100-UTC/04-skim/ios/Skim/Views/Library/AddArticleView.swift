import SwiftUI
import SwiftData

struct AddArticleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var pastedText = ""
    @State private var source = ""

    private let sampleArticle = """
The Science of Deep Work

In our increasingly distracted world, the ability to perform deep, focused cognitive work is becoming both rarer and more valuable. Psychologist Mihaly Csikszentmihalyi first documented the experience he called "flow"—a state of intense concentration where people report being most productive and fulfilled. Since then, researchers have built a compelling case that this mode of cognition represents the peak of human intellectual performance.

Neuroscientists have found that focused work strengthens neural pathways through a process called myelination. When we practice a skill or work through a complex problem repeatedly, the neurons involved become coated in myelin—a fatty substance that speeds up neural signals. This is why deliberate, concentrated practice produces mastery faster than diffuse, interrupted effort.

The modern workplace, however, works against this. Open offices, constant email, Slack notifications, and the compulsive checking of social media fragment our attention into ever-smaller shards. Research by Gloria Mark at the University of California found that workers average only 11 minutes on a task before being interrupted, and take over 23 minutes to regain focus afterward.

The implications are stark: if you spend eight hours at work but are interrupted every 11 minutes, you may never actually enter the deep work state at all. You spend the day feeling busy while accomplishing relatively little of genuine cognitive value.

The solution is structural, not motivational. Creating protected blocks of uninterrupted time—even two hours per day—can produce more meaningful output than eight hours of fragmented effort. The key is treating focus as a skill to be trained rather than a switch to be flipped. Start with 20-minute sessions and build up. Turn off notifications. Close irrelevant browser tabs. The mind, like a muscle, responds to progressive overload.

Those who master this discipline will have a significant competitive advantage in the years ahead. As artificial intelligence automates routine cognitive tasks, the ability to think deeply, make novel connections, and solve complex problems becomes the last truly defensible human skill.
"""

    var body: some View {
        NavigationStack {
            Form {
                Section("Article Details") {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Article title")
                    TextField("Source (optional)", text: $source)
                        .accessibilityLabel("Article source")
                }
                Section {
                    ZStack(alignment: .topLeading) {
                        if pastedText.isEmpty {
                            Text("Paste your text here…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $pastedText)
                            .frame(minHeight: 180)
                    }
                } header: {
                    Text("Text")
                } footer: {
                    Text("\(wordCount) words · ~\(estimatedMinutes) min at 250 WPM")
                        .accessibilityLabel("\(wordCount) words, approximately \(estimatedMinutes) minutes to read")
                }

                Section {
                    Button("Use Sample Article") {
                        title = "The Science of Deep Work"
                        source = "Sample"
                        pastedText = sampleArticle
                    }
                    .foregroundStyle(SkimTheme.accent)
                }
            }
            .navigationTitle("Add Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var wordCount: Int {
        pastedText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    private var estimatedMinutes: Int { max(1, wordCount / 250) }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !pastedText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        let c = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = source.trimmingCharacters(in: .whitespaces)
        let article = Article(title: t, content: c, source: s.isEmpty ? "Pasted Text" : s)
        modelContext.insert(article)
        dismiss()
    }
}
