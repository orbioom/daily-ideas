import SwiftUI
import SwiftData

struct SessionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var skills: [ArtSkill]
    @Query private var allSettings: [AtelierSettings]

    let existing: ArtSession?

    @State private var date: Date
    @State private var durationMinutes: Int
    @State private var medium: ArtMedium
    @State private var practiceType: PracticeType
    @State private var subject: String
    @State private var skillWorked: String
    @State private var mood: SessionMood
    @State private var rating: Int
    @State private var notes: String
    @State private var showError = false

    init(session: ArtSession?) {
        self.existing = session
        _date = State(initialValue: session?.date ?? .now)
        _durationMinutes = State(initialValue: session?.durationMinutes ?? 60)
        _medium = State(initialValue: session?.medium ?? .pencil)
        _practiceType = State(initialValue: session?.practiceType ?? .sketch)
        _subject = State(initialValue: session?.subject ?? "")
        _skillWorked = State(initialValue: session?.skillWorked ?? "")
        _mood = State(initialValue: session?.mood ?? .good)
        _rating = State(initialValue: session?.rating ?? 3)
        _notes = State(initialValue: session?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(durationMinutes)).foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(durationMinutes) },
                            set: { durationMinutes = Int($0) }
                        ), in: 5...360, step: 5)
                        .tint(AtelierTheme.amber)
                        .accessibilityLabel("Duration: \(formatDuration(durationMinutes))")
                    }
                }
                Section("What") {
                    Picker("Medium", selection: $medium) {
                        ForEach(ArtMedium.allCases) { m in
                            Label(m.rawValue, systemImage: m.sfSymbol).tag(m)
                        }
                    }
                    Picker("Type", selection: $practiceType) {
                        ForEach(PracticeType.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    HStack {
                        Text("Subject")
                        Spacer()
                        TextField("e.g. Portrait study", text: $subject)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Skill worked")
                        Spacer()
                        TextField("e.g. Cross hatching", text: $skillWorked)
                            .multilineTextAlignment(.trailing)
                    }
                    if !skills.isEmpty {
                        Menu("Pick skill from library") {
                            ForEach(skills) { skill in
                                Button(skill.name) { skillWorked = skill.name }
                            }
                        }
                        .foregroundStyle(AtelierTheme.amber)
                    }
                }
                Section("How it went") {
                    Picker("Mood", selection: $mood) {
                        ForEach(SessionMood.allCases) { m in
                            Label("\(m.emoji) \(m.rawValue)", systemImage: "face.smiling").tag(m)
                        }
                    }
                    HStack {
                        Text("Rating")
                        Spacer()
                        AtelierEditableRating(rating: $rating)
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Session notes")
                }
            }
            .navigationTitle(existing == nil ? "Log Session" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AtelierTheme.amber)
                }
            }
        }
    }

    private func formatDuration(_ m: Int) -> String {
        let h = m / 60; let mn = m % 60
        if h > 0 && mn > 0 { return "\(h)h \(mn)m" }
        if h > 0 { return "\(h)h" }
        return "\(mn)m"
    }

    private func save() {
        if let s = existing {
            s.date = date; s.durationMinutes = durationMinutes; s.medium = medium
            s.practiceType = practiceType; s.subject = subject; s.skillWorked = skillWorked
            s.mood = mood; s.rating = rating; s.notes = notes
        } else {
            let s = ArtSession(date: date, durationMinutes: durationMinutes, medium: medium,
                practiceType: practiceType, subject: subject, skillWorked: skillWorked,
                mood: mood, notes: notes, rating: rating)
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}

struct AtelierEditableRating: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    rating = i
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(i <= rating ? AtelierTheme.amber : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(i) star\(i == 1 ? "" : "s")")
                .accessibilityAddTraits(i == rating ? .isSelected : [])
            }
        }
    }
}
