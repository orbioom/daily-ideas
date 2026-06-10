import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Answer.createdAt, order: .reverse) private var answers: [Answer]
    @Query private var occasions: [Occasion]
    @AppStorage("nameA") private var nameA = ""
    @AppStorage("nameB") private var nameB = ""
    @AppStorage("includeSpark") private var includeSpark = true

    @State private var showAnswerFlow = false
    @State private var showOccasionEditor = false

    private var todayKey: String { DuetEngine.dateKey() }
    private var todayAnswer: Answer? { answers.first { $0.dateKey == todayKey } }

    private var question: Question {
        if let existing = todayAnswer, let q = QuestionBank.question(id: existing.questionID) {
            return q
        }
        let answered = Set(answers.filter { $0.revealed && $0.dateKey != todayKey }.map(\.questionID))
        return DuetEngine.questionOfDay(dateKey: todayKey,
                                        previouslyAnswered: answered,
                                        includeSpark: includeSpark)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        streakCard
                        questionCard
                        occasionsCard
                        if !favorites.isEmpty { favoritesCard }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Today")
            .fullScreenCover(isPresented: $showAnswerFlow) {
                AnswerFlowView(question: question, existing: todayAnswer)
            }
            .sheet(isPresented: $showOccasionEditor) {
                OccasionEditorView()
            }
        }
    }

    private var favorites: [Answer] {
        answers.filter { $0.favorite && $0.revealed && $0.dateKey != todayKey }
    }

    private var streakCard: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("\(DuetEngine.streak(answers: answers))")
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("day streak")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            .frame(maxWidth: .infinity)
            .glassCard(padding: 12)
            .accessibilityElement(children: .combine)
            VStack(spacing: 4) {
                Text("\(answers.filter(\.revealed).count)")
                    .font(Brand.mono(22, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("questions shared")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            .frame(maxWidth: .infinity)
            .glassCard(padding: 12)
            .accessibilityElement(children: .combine)
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(question.category.rawValue, systemImage: question.category.symbol)
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text3)
                Spacer()
                Text(Date.now, format: .dateTime.weekday(.wide).day().month())
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Text(question.text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)

            if let answer = todayAnswer, answer.revealed {
                Divider()
                revealedAnswers(answer)
            } else {
                Button {
                    Haptics.tap()
                    showAnswerFlow = true
                } label: {
                    Label(todayAnswer == nil ? "Answer together" : "Finish answering",
                          systemImage: "arrow.left.arrow.right")
                }
                .buttonStyle(InkButtonStyle())
                Text("You'll each answer privately on this phone, then reveal both at once.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    private func revealedAnswers(_ answer: Answer) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            answerBlock(name: nameA.isEmpty ? "Partner A" : nameA, text: answer.partnerAText)
            answerBlock(name: nameB.isEmpty ? "Partner B" : nameB, text: answer.partnerBText)
            HStack {
                HStack(spacing: 5) {
                    StatusDot()
                    Text("Answered together")
                        .font(.caption)
                        .foregroundStyle(Brand.live)
                }
                Spacer()
                Button {
                    answer.favorite.toggle()
                    Haptics.tap()
                } label: {
                    Image(systemName: answer.favorite ? "star.fill" : "star")
                        .foregroundStyle(answer.favorite ? Brand.warn : Brand.text3)
                }
                .accessibilityLabel(answer.favorite ? "Remove from favorites" : "Save to favorites")
            }
        }
    }

    private func answerBlock(name: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.uppercased())
                .font(Brand.mono(11, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Brand.text3)
            Text(text.isEmpty ? "—" : text)
                .font(.body)
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) answered: \(text)")
    }

    private var occasionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Coming up")
                Spacer()
                Button {
                    showOccasionEditor = true
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Brand.text2)
                }
                .accessibilityLabel("Add occasion")
            }
            let upcoming = occasions
                .compactMap { occ -> (Occasion, Date)? in
                    guard let next = DuetEngine.nextOccurrence(of: occ) else { return nil }
                    return (occ, next)
                }
                .sorted { $0.1 < $1.1 }
                .prefix(3)
            if upcoming.isEmpty {
                Text("No occasions yet — add your anniversary or the birthdays you must not miss.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                ForEach(Array(upcoming), id: \.0.persistentModelID) { occ, next in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(occ.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(next, format: .dateTime.weekday(.abbreviated).day().month(.wide))
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        let days = DuetEngine.daysUntil(next)
                        Text(days == 0 ? "today" : "in \(days)d")
                            .font(Brand.mono(13, weight: .semibold))
                            .foregroundStyle(days <= 7 ? Brand.live : Brand.text2)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .contextMenu {
                        Button(role: .destructive) {
                            context.delete(occ)
                            Haptics.warning()
                        } label: {
                            Label("Delete occasion", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    private var favoritesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Favorite answers")
            ForEach(favorites.prefix(3)) { fav in
                VStack(alignment: .leading, spacing: 4) {
                    Text(QuestionBank.question(id: fav.questionID)?.text ?? "A question")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Brand.text2)
                    Text("\(nameA.isEmpty ? "A" : nameA): \(fav.partnerAText)")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .lineLimit(2)
                    Text("\(nameB.isEmpty ? "B" : nameB): \(fav.partnerBText)")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .lineLimit(2)
                }
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
                if fav.id != favorites.prefix(3).last?.id { Divider() }
            }
        }
        .glassCard()
    }
}

/// Quick add for an annually recurring occasion.
struct OccasionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var repeats = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Occasion") {
                    TextField("Title (e.g. Sam's birthday)", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Repeats every year", isOn: $repeats)
                        .tint(Brand.live)
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle("New Occasion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else {
                            error = "Give the occasion a name."
                            return
                        }
                        context.insert(Occasion(title: t, date: date, repeatsAnnually: repeats))
                        Haptics.success()
                        dismiss()
                    }
                }
            }
        }
    }
}
