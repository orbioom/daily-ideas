import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var editingWordCount = false
    @State private var wordCountInput = ""

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress header
                VStack(spacing: 8) {
                    ProgressView(value: project.progressFraction)
                        .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
                    HStack {
                        Button(action: { editingWordCount = true }) {
                            Text("\(project.currentWordCount.formatted()) words")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                        }
                        Spacer()
                        Text("Goal: \(project.targetWordCount.formatted())")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))

                Picker("Section", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Characters").tag(1)
                    Text("Chapters").tag(2)
                    Text("Plot").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                TabView(selection: $selectedTab) {
                    OverviewTab(project: project)
                        .tag(0)
                    CharactersTab(project: project)
                        .tag(1)
                    ChaptersTab(project: project)
                        .tag(2)
                    PlotTab(project: project)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Update Word Count", isPresented: $editingWordCount) {
            TextField("Word count", text: $wordCountInput)
                .keyboardType(.numberPad)
            Button("Save") {
                if let n = Int(wordCountInput), n >= 0 {
                    project.currentWordCount = n
                    project.updatedAt = Date()
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your current word count")
        }
        .onAppear { wordCountInput = "\(project.currentWordCount)" }
    }
}

struct OverviewTab: View {
    @Bindable var project: DraftProject
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                fieldSection("Genre") {
                    Picker("Genre", selection: $project.genre) {
                        ForEach(ProjectGenre.allCases, id: \.rawValue) { g in
                            Text(g.rawValue).tag(g.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                fieldSection("Status") {
                    Picker("Status", selection: $project.statusRaw) {
                        ForEach(ProjectStatus.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(s.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                fieldSection("Logline") {
                    TextEditor(text: $project.logline)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .font(.system(size: 15, design: .rounded))
                        .frame(minHeight: 60)
                        .onChange(of: project.logline) { _, _ in project.updatedAt = Date() }
                }

                fieldSection("Synopsis") {
                    TextEditor(text: $project.synopsis)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(.white)
                        .font(.system(size: 15, design: .rounded))
                        .frame(minHeight: 120)
                        .onChange(of: project.synopsis) { _, _ in project.updatedAt = Date() }
                }

                fieldSection("Word Count Goal") {
                    Stepper("\(project.targetWordCount.formatted())", value: $project.targetWordCount, in: 1000...500000, step: 5000)
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.08, green: 0.06, blue: 0.02))
    }

    private func fieldSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            content()
                .padding(12)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CharactersTab: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if project.characters.isEmpty {
                    emptyState("No characters yet", "Tap + to add characters to your story.")
                } else {
                    ForEach(project.characters.sorted(by: { $0.name < $1.name })) { c in
                        NavigationLink(destination: CharacterDetailView(character: c, project: project)) {
                            CharacterRowView(character: c)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { modelContext.delete(c) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.08, green: 0.06, blue: 0.02))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddCharacterSheet(project: project)
        }
    }

    private func emptyState(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.3))
            Text(title).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct CharacterRowView: View {
    let character: DraftCharacter

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(roleColor(character.role).opacity(0.25))
                    .frame(width: 42, height: 42)
                Text(character.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(roleColor(character.role))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(character.name.isEmpty ? "Unnamed" : character.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(character.role.rawValue)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.caption)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func roleColor(_ role: CharacterRole) -> Color {
        switch role {
        case .protagonist: return .yellow
        case .antagonist: return .red
        case .deuteragonist: return .orange
        case .mentor: return .blue
        case .loveInterest: return .pink
        default: return .gray
        }
    }
}

struct CharacterDetailView: View {
    @Bindable var character: DraftCharacter
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    fieldEdit("Name", text: $character.name)
                    pickerField("Role", rawValue: $character.roleRaw, cases: CharacterRole.allCases.map(\.rawValue))
                    fieldEdit("Age", text: $character.age)
                    textAreaField("Key Traits", text: $character.traits, height: 80)
                    textAreaField("Motivation / Goal", text: $character.motivation, height: 80)
                    textAreaField("Character Arc", text: $character.arc, height: 80)
                    textAreaField("Notes", text: $character.notes, height: 100)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(character.name.isEmpty ? "Character" : character.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fieldEdit(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            TextField(label, text: text)
                .foregroundStyle(.white)
                .font(.system(size: 15, design: .rounded))
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func pickerField(_ label: String, rawValue: Binding<String>, cases: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Picker("", selection: rawValue) {
                ForEach(cases, id: \.self) { c in Text(c).tag(c) }
            }
            .pickerStyle(.menu)
            .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func textAreaField(_ label: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .font(.system(size: 14, design: .rounded))
                .frame(minHeight: height)
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct AddCharacterSheet: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role = CharacterRole.supporting.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
                Form {
                    Section {
                        TextField("Character Name", text: $name)
                        Picker("Role", selection: $role) {
                            ForEach(CharacterRole.allCases, id: \.rawValue) { r in
                                Text(r.rawValue).tag(r.rawValue)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("New Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let c = DraftCharacter(name: name.isEmpty ? "Unnamed" : name, role: CharacterRole(rawValue: role) ?? .supporting, project: project)
                        modelContext.insert(c)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ChaptersTab: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if project.chapters.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.number")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("No chapters yet")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tap + to add chapters.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(40)
                } else {
                    ForEach(project.orderedChapters) { ch in
                        NavigationLink(destination: ChapterDetailView(chapter: ch, project: project)) {
                            ChapterRowView(chapter: ch)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { modelContext.delete(ch) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.08, green: 0.06, blue: 0.02))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAdd = true }) {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddChapterSheet(project: project)
        }
    }
}

struct ChapterRowView: View {
    let chapter: DraftChapter

    var body: some View {
        HStack(spacing: 14) {
            Text("\(chapter.number)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title.isEmpty ? "Chapter \(chapter.number)" : chapter.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(chapter.wordCount.formatted()) words · \(chapter.status.rawValue)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.3))
                .font(.caption)
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ChapterDetailView: View {
    @Bindable var chapter: DraftChapter
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @State private var showAddScene = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TITLE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("Chapter title", text: $chapter.title)
                            .foregroundStyle(.white)
                            .font(.system(size: 16, design: .rounded))
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Picker("", selection: $chapter.statusRaw) {
                                ForEach(ChapterStatus.allCases, id: \.rawValue) { s in Text(s.rawValue).tag(s.rawValue) }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WORDS")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Stepper("\(chapter.wordCount)", value: $chapter.wordCount, in: 0...100000, step: 100)
                                .foregroundStyle(.white)
                                .font(.system(size: 14, design: .rounded))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("SYNOPSIS")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                        TextEditor(text: $chapter.synopsis)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .font(.system(size: 14, design: .rounded))
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("SCENES (\(chapter.scenes.count))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                            Button(action: { showAddScene = true }) {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                            }
                        }
                        ForEach(chapter.scenes.sorted { $0.order < $1.order }) { scene in
                            sceneRow(scene)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTES")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                        TextEditor(text: $chapter.notes)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .font(.system(size: 14, design: .rounded))
                            .frame(minHeight: 80)
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Ch. \(chapter.number)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddScene) {
            AddSceneSheet(chapter: chapter)
        }
    }

    private func sceneRow(_ scene: DraftScene) -> some View {
        HStack {
            Image(systemName: "film")
                .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text(scene.title.isEmpty ? "Untitled Scene" : scene.title)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white)
                if !scene.location.isEmpty {
                    Text(scene.location)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            Spacer()
            if !scene.povCharacter.isEmpty {
                Text("POV: \(scene.povCharacter)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .swipeActions { Button(role: .destructive) { modelContext.delete(scene) } label: { Label("Delete", systemImage: "trash") } }
    }
}

struct AddChapterSheet: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var number = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
                Form {
                    Section {
                        Stepper("Chapter \(number)", value: $number, in: 1...999)
                        TextField("Title (optional)", text: $title)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("New Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let ch = DraftChapter(number: project.chapters.count + 1, title: title, project: project)
                        modelContext.insert(ch)
                        try? modelContext.save()
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct AddSceneSheet: View {
    let chapter: DraftChapter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var location = ""
    @State private var pov = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
                Form {
                    Section {
                        TextField("Scene title", text: $title)
                        TextField("Location", text: $location)
                        TextField("POV character", text: $pov)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("New Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let s = DraftScene(order: chapter.scenes.count, title: title, chapter: chapter)
                        s.location = location
                        s.povCharacter = pov
                        modelContext.insert(s)
                        try? modelContext.save()
                        dismiss()
                    }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct PlotTab: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @State private var showTemplatePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if project.plotBeats.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.top, 30)
                        Text("No plot outline yet")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Button(action: { showTemplatePicker = true }) {
                            Label("Choose a Template", systemImage: "doc.badge.plus")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.85, green: 0.58, blue: 0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                } else {
                    HStack {
                        Text("\(project.plotBeats.filter(\.isChecked).count)/\(project.plotBeats.count) beats")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Button(action: { showTemplatePicker = true }) {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    ForEach(project.plotBeats.sorted { $0.order < $1.order }) { beat in
                        PlotBeatRow(beat: beat)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(red: 0.08, green: 0.06, blue: 0.02))
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerSheet(project: project)
        }
    }
}

struct PlotBeatRow: View {
    @Bindable var beat: PlotBeat
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: { beat.isChecked.toggle() }) {
                Image(systemName: beat.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(beat.isChecked ? Color(red: 0.85, green: 0.58, blue: 0.15) : .white.opacity(0.3))
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(beat.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(beat.isChecked ? .white.opacity(0.5) : .white)
                    .strikethrough(beat.isChecked, color: .white.opacity(0.3))

                TextField("Notes for this beat…", text: $beat.notes, axis: .vertical)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1...4)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

struct TemplatePickerSheet: View {
    let project: DraftProject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(PlotTemplate.allCases) { template in
                            Button(action: { applyTemplate(template) }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(template.rawValue)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text("\(template.beats.count) beats")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                    if !template.beats.isEmpty {
                                        Text(template.beats.prefix(3).joined(separator: " → ") + (template.beats.count > 3 ? " …" : ""))
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Plot Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func applyTemplate(_ template: PlotTemplate) {
        for beat in project.plotBeats { modelContext.delete(beat) }
        for (i, name) in template.beats.enumerated() {
            let beat = PlotBeat(order: i, name: name, project: project)
            modelContext.insert(beat)
        }
        try? modelContext.save()
        dismiss()
    }
}
