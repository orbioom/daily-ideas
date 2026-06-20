import SwiftUI
import SwiftData

struct ScriptDetailView: View {
    @Bindable var project: ScriptProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [ScriptSettings]

    private var settings: ScriptSettings? { allSettings.first }
    private var hasPro: Bool { settings?.hasPro ?? false }

    private var characters: [String] {
        let elements = FountainParser.parse(text: project.content)
        var seen = Set<String>()
        var result: [String] = []
        for el in elements where el.type == .character {
            var name = el.text
            // Strip extensions like (V.O.) (O.S.) (CONT'D)
            if let parenRange = name.range(of: "(") {
                name = String(name[name.startIndex..<parenRange.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
            }
            if !name.isEmpty && !seen.contains(name) {
                seen.insert(name)
                result.append(name)
            }
        }
        return result.sorted()
    }

    private var sceneHeadings: [String] {
        FountainParser.parse(text: project.content)
            .filter { $0.type == .sceneHeading }
            .map { $0.text.uppercased() }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Title Page") {
                    DetailLabeledField(label: "Title", value: $project.title)
                    DetailLabeledField(label: "Author", value: $project.author)
                    Picker("Genre", selection: $project.genre) {
                        ForEach(ScriptTheme.genres, id: \.self) { g in
                            Text(g).tag(g)
                        }
                    }
                    Picker("Draft", selection: $project.draftNumber) {
                        ForEach(ScriptTheme.draftNumbers, id: \.self) { d in
                            Text(d).tag(d)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Logline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("One sentence summary…", text: $project.logline, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                }

                Section("Story Notes") {
                    if hasPro {
                        TextEditor(text: $project.storyNotes)
                            .font(.custom("Courier", size: 13))
                            .frame(minHeight: 120)
                    } else {
                        ProLockedRow(label: "Story notes require Script Pro")
                    }
                }

                if !characters.isEmpty {
                    Section("Characters (\(characters.count))") {
                        if hasPro {
                            ForEach(characters, id: \.self) { char in
                                Text(char)
                                    .font(.custom("Courier", size: 13))
                            }
                        } else {
                            ProLockedRow(label: "Character list requires Script Pro")
                        }
                    }
                }

                if !sceneHeadings.isEmpty {
                    Section("Scenes (\(sceneHeadings.count))") {
                        if hasPro {
                            ForEach(Array(sceneHeadings.enumerated()), id: \.offset) { i, scene in
                                HStack(spacing: 8) {
                                    Text("\(i + 1)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(.secondary)
                                        .frame(width: 28, alignment: .trailing)
                                    Text(scene)
                                        .font(.custom("Courier", size: 12))
                                }
                            }
                        } else {
                            ProLockedRow(label: "Scene navigator requires Script Pro")
                        }
                    }
                }

                Section("Statistics") {
                    LabeledContent("Created", value: project.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Last Modified", value: project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Word Count", value: "\(project.content.split(separator: " ").count)")
                    LabeledContent("Est. Pages", value: "\(FountainParser.estimatePageCount(elements: FountainParser.parse(text: project.content)))")
                    if !characters.isEmpty {
                        LabeledContent("Characters", value: "\(characters.count)")
                    }
                    if !sceneHeadings.isEmpty {
                        LabeledContent("Scenes", value: "\(sceneHeadings.count)")
                    }
                }
            }
            .navigationTitle("Script Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        project.updatedAt = .now
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct DetailLabeledField: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            TextField(label, text: $value)
        }
    }
}

struct ProLockedRow: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("PRO")
                .font(.caption2.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.scriptAmber)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
