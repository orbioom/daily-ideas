import SwiftUI
import SwiftData

struct ScriptEditorView: View {
    let script: Script?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultWPM") private var defaultWPM = 150.0

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var showValidation = false
    @State private var playAfterSave = false
    @State private var playingScript: Script?
    @FocusState private var bodyFocused: Bool

    private var wordCount: Int { TextStats.wordCount(bodyText) }
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Title", text: $title)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 10)
                    .accessibilityLabel("Script title")

                Divider()

                TextEditor(text: $bodyText)
                    .font(.system(.body, design: .serif))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 14)
                    .focused($bodyFocused)
                    .accessibilityLabel("Script body")
                    .overlay(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("Write or paste your script here.\nBlank lines become paragraph breaks.")
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Theme.textSecondary.opacity(0.6))
                                .padding(.horizontal, 19)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }

                HStack {
                    Text("\(wordCount) words")
                    Spacer()
                    Text("~\(TextStats.formatDuration(TextStats.estimatedDuration(words: wordCount, wordsPerMinute: defaultWPM))) spoken at \(Int(defaultWPM)) wpm")
                }
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.bgElevated)
            }
            .background(Theme.bgPrimary)
            .navigationTitle(script == nil ? "New script" : "Edit script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save(thenPlay: false) }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        save(thenPlay: true)
                    } label: {
                        Label("Save & prompt", systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .disabled(!isValid)
                    .accessibilityHint("Saves the script and opens it in the teleprompter")
                }
            }
            .alert("Add a title and some text", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("A script needs both a title and a body before it can be saved.")
            }
            .fullScreenCover(item: $playingScript, onDismiss: { dismiss() }) { s in
                PrompterView(script: s)
            }
            .onAppear {
                if let script {
                    title = script.title
                    bodyText = script.body
                } else {
                    bodyFocused = true
                }
            }
        }
    }

    private func save(thenPlay: Bool) {
        guard isValid else {
            showValidation = true
            return
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let saved: Script
        if let script {
            script.title = trimmedTitle
            script.body = bodyText
            script.updatedAt = .now
            saved = script
        } else {
            let new = Script(title: trimmedTitle, body: bodyText)
            context.insert(new)
            saved = new
        }
        Haptics.success()
        if thenPlay {
            playingScript = saved
        } else {
            dismiss()
        }
    }
}
