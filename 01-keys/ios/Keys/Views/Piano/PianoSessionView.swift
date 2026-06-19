import SwiftUI
import SwiftData

struct PianoSessionView: View {
    let lesson: LessonContent
    let module: CurriculumModule

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [UserSettings]
    @State private var engine = PianoEngine()

    // Exercise state
    @State private var currentExerciseIndex = 0
    @State private var correctCount = 0
    @State private var showCorrectFeedback = false
    @State private var showWrongFeedback = false
    @State private var sessionComplete = false
    @State private var startTime = Date()
    @State private var highlightedNote: Int? = nil
    @State private var correctNote: Int? = nil
    @State private var earTrainPlayedNote: Int? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var settings: UserSettings? { settingsQuery.first }

    // Shuffled exercise notes for the session
    private let exerciseSequence: [Int]

    init(lesson: LessonContent, module: CurriculumModule) {
        self.lesson = lesson
        self.module = module
        self.exerciseSequence = lesson.exerciseNotes
    }

    private var totalExercises: Int { exerciseSequence.count }
    private var progress: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(currentExerciseIndex) / Double(totalExercises)
    }

    private var currentTargetNote: Int? {
        guard currentExerciseIndex < exerciseSequence.count else { return nil }
        return exerciseSequence[currentExerciseIndex]
    }

    var body: some View {
        ZStack {
            KeysTheme.background.ignoresSafeArea()

            if sessionComplete {
                SessionCompleteView(
                    score: correctCount * 100 / max(totalExercises, 1),
                    correctCount: correctCount,
                    totalExercises: totalExercises,
                    lessonTitle: lesson.title,
                    moduleColor: module.color
                ) {
                    dismiss()
                }
            } else {
                VStack(spacing: 0) {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(KeysTheme.surface)
                                .frame(height: 4)
                            Rectangle()
                                .fill(module.color)
                                .frame(width: geo.size.width * progress, height: 4)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: progress)
                        }
                    }
                    .frame(height: 4)

                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Text(lesson.type.displayName.uppercased())
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(module.color)
                                    .tracking(1.5)

                                Text(lesson.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(KeysTheme.text)

                                Text("\(currentExerciseIndex + 1) / \(totalExercises)")
                                    .font(.subheadline)
                                    .foregroundStyle(KeysTheme.textSecondary)
                            }
                            .padding(.top, 24)

                            // Instruction card
                            InstructionCard(
                                lesson: lesson,
                                targetNote: currentTargetNote,
                                earTrainNote: earTrainPlayedNote,
                                showCorrect: showCorrectFeedback,
                                showWrong: showWrongFeedback,
                                moduleColor: module.color
                            )
                            .padding(.horizontal)

                            // Ear train "Play note" button
                            if lesson.type == .earTrain {
                                Button {
                                    if let note = currentTargetNote {
                                        engine.playNote(note)
                                        earTrainPlayedNote = note
                                    }
                                } label: {
                                    Label("Play Note", systemImage: "speaker.wave.2.fill")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(module.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .padding(.horizontal)
                                .accessibilityLabel("Play the note to identify")
                            }

                            // Tips
                            if !lesson.tips.isEmpty {
                                TipsCard(tips: lesson.tips)
                                    .padding(.horizontal)
                            }

                            Spacer(minLength: 16)
                        }
                    }

                    // Piano keyboard at bottom
                    VStack(spacing: 0) {
                        Divider()
                        PianoKeyboardView(
                            startMidi: max(36, (currentTargetNote ?? 60) - 12),
                            endMidi: min(96, (currentTargetNote ?? 60) + 12),
                            highlightedNotes: highlightedNoteSet,
                            correctNotes: correctNote.map { Set([$0]) } ?? [],
                            showLabels: settings?.showNoteLabels ?? true,
                            onNoteTap: handleKeyTap
                        )
                        .padding(.vertical, 16)
                        .background(KeysTheme.pianoBackground)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTime = .now
            if lesson.type == .playNote || lesson.type == .scale || lesson.type == .song {
                // Highlight the target note
                highlightedNote = currentTargetNote
            }
        }
    }

    private var highlightedNoteSet: Set<Int> {
        var set = Set<Int>()
        if let h = highlightedNote { set.insert(h) }
        return set
    }

    private func handleKeyTap(_ midi: Int) {
        guard !sessionComplete, !showCorrectFeedback else { return }

        // Play sound
        if settings?.soundEnabled ?? true {
            engine.playNote(midi)
        }
        if settings?.hapticsEnabled ?? true {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }

        guard let target = currentTargetNote else { return }

        let isCorrect: Bool
        switch lesson.type {
        case .noteIdentify, .playNote, .earTrain, .song:
            isCorrect = midi == target
        case .scale, .chord:
            isCorrect = midi == target
        }

        if isCorrect {
            correctCount += 1
            correctNote = midi
            showCorrectFeedback = true
            if settings?.hapticsEnabled ?? true {
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                advanceExercise()
            }
        } else {
            showWrongFeedback = true
            if settings?.hapticsEnabled ?? true {
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.error)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showWrongFeedback = false
            }
        }
    }

    private func advanceExercise() {
        showCorrectFeedback = false
        correctNote = nil
        earTrainPlayedNote = nil

        let nextIndex = currentExerciseIndex + 1
        if nextIndex >= totalExercises {
            completeSession()
        } else {
            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
                currentExerciseIndex = nextIndex
                highlightedNote = exerciseSequence[nextIndex]
            }
        }
    }

    private func completeSession() {
        let duration = Int(Date().timeIntervalSince(startTime))
        let score = correctCount * 100 / max(totalExercises, 1)

        let session = PracticeSession(
            date: .now,
            moduleTitle: module.title,
            lessonTitle: lesson.title,
            score: score,
            durationSeconds: duration
        )
        modelContext.insert(session)

        if let settings = settingsQuery.first {
            settings.markLessonCompleted(lesson.id)
            updateStreak(settings: settings)
        }

        withAnimation(reduceMotion ? .none : .spring(response: 0.4)) {
            sessionComplete = true
        }
    }

    private func updateStreak(settings: UserSettings) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let lastDate = settings.lastPracticeDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                settings.streakCount += 1
            } else if diff > 1 {
                settings.streakCount = 1
            }
            // diff == 0 means same day, no change
        } else {
            settings.streakCount = 1
        }
        settings.lastPracticeDate = .now
    }
}

struct InstructionCard: View {
    let lesson: LessonContent
    let targetNote: Int?
    let earTrainNote: Int?
    let showCorrect: Bool
    let showWrong: Bool
    let moduleColor: Color

    private var instruction: String {
        guard let note = targetNote else { return lesson.description }
        switch lesson.type {
        case .noteIdentify:
            return "Find and tap: \(PianoEngine.noteName(note))"
        case .playNote:
            return "Press: \(PianoEngine.noteName(note))"
        case .scale:
            return "Play the next note: \(PianoEngine.noteName(note))"
        case .chord:
            return "Now press: \(PianoEngine.noteName(note))"
        case .song:
            return "Next note: \(PianoEngine.noteName(note))"
        case .earTrain:
            return earTrainNote != nil ? "Which note did you hear?" : "Listen, then identify the note"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(moduleColor.opacity(0.1))

                if showCorrect {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green)
                        Text("Correct!")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if showWrong {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                        Text("Try again")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundStyle(moduleColor)

                        Text(instruction)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(KeysTheme.text)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 24)
                }
            }
            .frame(height: 140)
            .animation(.spring(response: 0.25), value: showCorrect)
            .animation(.spring(response: 0.25), value: showWrong)
        }
    }
}

struct TipsCard: View {
    let tips: [String]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    expanded.toggle()
                }
            } label: {
                HStack {
                    Label("Tips", systemImage: "lightbulb.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(KeysTheme.accent)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(KeysTheme.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(expanded ? "Collapse tips" : "Expand tips")

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(KeysTheme.accent)
                            Text(tip)
                                .font(.subheadline)
                                .foregroundStyle(KeysTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SessionCompleteView: View {
    let score: Int
    let correctCount: Int
    let totalExercises: Int
    let lessonTitle: String
    let moduleColor: Color
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var grade: String {
        switch score {
        case 90...100: return "Excellent!"
        case 70..<90:  return "Great job!"
        case 50..<70:  return "Good effort!"
        default:       return "Keep practicing!"
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(moduleColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                VStack(spacing: 4) {
                    Text("\(score)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(moduleColor)
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(KeysTheme.textSecondary)
                }
            }

            VStack(spacing: 8) {
                Text(grade)
                    .font(.largeTitle.bold())
                    .foregroundStyle(KeysTheme.text)
                Text(lessonTitle)
                    .font(.headline)
                    .foregroundStyle(KeysTheme.textSecondary)
            }

            HStack(spacing: 24) {
                StatPill(label: "Correct", value: "\(correctCount)", color: .green)
                StatPill(label: "Total", value: "\(totalExercises)", color: moduleColor)
            }

            Spacer()

            Button(action: onDismiss) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(moduleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(KeysTheme.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
