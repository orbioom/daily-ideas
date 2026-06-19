import SwiftUI
import SwiftData

struct CustomQuestionsView: View {
    @Query(filter: #Predicate<Question> { $0.isCustom == true }, sort: \Question.createdAt, order: .reverse)
    private var customQuestions: [Question]

    @Query private var settingsQuery: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var editingQuestion: Question? = nil
    @State private var showProSheet = false

    private var settings: AppSettings? { settingsQuery.first }
    private var hasReachedFreeLimit: Bool {
        customQuestions.count >= 5 && settings?.hasPro != true
    }

    var body: some View {
        NavigationStack {
            Group {
                if customQuestions.isEmpty {
                    VStack(spacing: 20) {
                        ContentUnavailableView(
                            "No Custom Questions",
                            systemImage: "plus.square.on.square",
                            description: Text("Add your own questions for any mode. Tap + to get started.")
                        )

                        Button {
                            showAddSheet = true
                        } label: {
                            Label("Add Your First Question", systemImage: "plus")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background(VolleyTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                } else {
                    List {
                        if hasReachedFreeLimit {
                            Section {
                                ProPromptRow { showProSheet = true }
                            }
                        }

                        Section("\(customQuestions.count) Custom Questions") {
                            ForEach(customQuestions) { question in
                                CustomQuestionRow(question: question) {
                                    editingQuestion = question
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    modelContext.delete(customQuestions[index])
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(VolleyTheme.background)
            .navigationTitle("Custom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if hasReachedFreeLimit {
                            showProSheet = true
                        } else {
                            showAddSheet = true
                        }
                    } label: {
                        Image(systemName: hasReachedFreeLimit ? "lock.fill" : "plus")
                            .foregroundStyle(VolleyTheme.accent)
                    }
                    .accessibilityLabel(hasReachedFreeLimit ? "Upgrade to Pro to add more questions" : "Add custom question")
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditQuestionSheet(question: nil)
            }
            .sheet(item: $editingQuestion) { question in
                AddEditQuestionSheet(question: question)
            }
            .sheet(isPresented: $showProSheet) {
                VolleyProSheet()
            }
        }
    }
}

struct CustomQuestionRow: View {
    let question: Question
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.text)
                    .font(.subheadline)
                    .foregroundStyle(VolleyTheme.text)
                    .lineLimit(3)

                HStack(spacing: 6) {
                    if let mode = QuestionMode(rawValue: question.mode) {
                        Text(mode.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VolleyTheme.gradient(for: mode).first ?? .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (VolleyTheme.gradient(for: mode).first ?? .gray).opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }

                    Text(question.category.capitalized)
                        .font(.caption)
                        .foregroundStyle(VolleyTheme.textSecondary)
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(VolleyTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit question")
        }
        .padding(.vertical, 4)
    }
}

struct ProPromptRow: View {
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(VolleyTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("5-question limit reached")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VolleyTheme.text)
                Text("Upgrade to Pro for unlimited custom questions")
                    .font(.caption)
                    .foregroundStyle(VolleyTheme.textSecondary)
            }

            Spacer()

            Button("Upgrade", action: onUpgrade)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(VolleyTheme.accent)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct AddEditQuestionSheet: View {
    let question: Question?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var selectedMode: QuestionMode
    @State private var selectedCategory: QuestionCategory
    @State private var isEnabled: Bool

    init(question: Question?) {
        self.question = question
        _text = State(initialValue: question?.text ?? "")
        _selectedMode = State(initialValue: QuestionMode(rawValue: question?.mode ?? "") ?? .icebreaker)
        _selectedCategory = State(initialValue: QuestionCategory(rawValue: question?.category ?? "") ?? .friends)
        _isEnabled = State(initialValue: question?.isEnabled ?? true)
    }

    private var isEditing: Bool { question != nil }
    private var canSave: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question Text") {
                    TextField("Enter your question...", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Question text")
                }

                Section("Mode") {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(QuestionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(VolleyTheme.accent)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(QuestionCategory.allCases.filter { $0 != .all }) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Enabled in games", isOn: $isEnabled)
                        .tint(VolleyTheme.accent)
                }
            }
            .navigationTitle(isEditing ? "Edit Question" : "New Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                        .foregroundStyle(canSave ? VolleyTheme.accent : VolleyTheme.textSecondary)
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = question {
            existing.text = trimmed
            existing.mode = selectedMode.rawValue
            existing.category = selectedCategory.rawValue
            existing.isEnabled = isEnabled
        } else {
            let newQuestion = Question(
                text: trimmed,
                mode: selectedMode.rawValue,
                category: selectedCategory.rawValue,
                isCustom: true,
                isEnabled: isEnabled
            )
            modelContext.insert(newQuestion)
        }
        dismiss()
    }
}

struct VolleyProSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [AppSettings]
    @State private var isPurchasing = false

    private let features: [(String, String, String)] = [
        ("party.popper", "Unlock Party Mode", "Access the wildest category of questions"),
        ("infinity", "Unlimited Custom Questions", "Add as many as you want"),
        ("sparkles", "Priority Support", "Get help from the Volley team"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero gradient
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "F97316"), Color(hex: "DC2626")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                            Text("Volley Pro")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text("One-time · No subscription")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)

                    // Features
                    VStack(spacing: 16) {
                        ForEach(features, id: \.0) { icon, title, desc in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(VolleyTheme.accent.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: icon)
                                        .foregroundStyle(VolleyTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title).font(.subheadline.weight(.semibold))
                                    Text(desc).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Purchase button
                    VStack(spacing: 12) {
                        Button {
                            simulatePurchase()
                        } label: {
                            Group {
                                if isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Unlock for $1.99")
                                        .font(.headline.bold())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F97316"), Color(hex: "DC2626")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isPurchasing)

                        Button("Restore Purchase") {}
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)

                    Text("One-time purchase charged to your Apple ID. No recurring charges.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer(minLength: 32)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func simulatePurchase() {
        isPurchasing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let settings = settingsQuery.first {
                settings.hasPro = true
            }
            isPurchasing = false
            dismiss()
        }
    }
}
