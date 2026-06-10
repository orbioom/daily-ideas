import SwiftUI
import SwiftData

/// The guided seven-step thought record. Nothing is saved until the final
/// step, so backing out is always clean.
struct ReframeFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Step: Int, CaseIterable {
        case situation, emotions, thought, traps, evidence, balanced, rerate, done

        var title: String {
            switch self {
            case .situation: return "The situation"
            case .emotions: return "The feeling"
            case .thought: return "The thought"
            case .traps: return "Thinking traps"
            case .evidence: return "The evidence"
            case .balanced: return "A fairer thought"
            case .rerate: return "Re-rate"
            case .done: return "Done"
            }
        }
    }

    @AppStorage("defaultBelief") private var defaultBelief = 75.0
    @AppStorage("gentleLanguage") private var gentleLanguage = true
    @State private var seeded = false
    @State private var step: Step = .situation
    @State private var situation = ""
    @State private var emotions: [EmotionRating] = []
    @State private var customEmotion = ""
    @State private var thought = ""
    @State private var beliefBefore = 75.0
    @State private var selectedTraps: Set<String> = []
    @State private var evidenceFor = ""
    @State private var evidenceAgainst = ""
    @State private var balanced = ""
    @State private var emotionsAfter: [EmotionRating] = []
    @State private var beliefAfter = 40.0
    @State private var confirmLeave = false
    @State private var saved: ThoughtRecord?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    if step != .done {
                        ProgressView(value: Double(step.rawValue), total: Double(Step.done.rawValue))
                            .tint(Brand.live)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .accessibilityLabel("Step \(step.rawValue + 1) of \(Step.done.rawValue)")
                    }
                    ScrollView {
                        VStack(spacing: 14) {
                            content
                        }
                        .padding(16)
                    }
                    if step != .done { navButtons }
                }
            }
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if step == .done { dismiss() } else { confirmLeave = true }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                }
            }
            .alert("Leave this record?", isPresented: $confirmLeave) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep writing", role: .cancel) {}
            } message: {
                Text("Nothing is saved until the last step.")
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            guard !seeded else { return }
            seeded = true
            beliefBefore = defaultBelief
            beliefAfter = min(beliefAfter, defaultBelief)
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var content: some View {
        switch step {
        case .situation: situationStep
        case .emotions: emotionsStep
        case .thought: thoughtStep
        case .traps: trapsStep
        case .evidence: evidenceStep
        case .balanced: balancedStep
        case .rerate: rerateStep
        case .done: doneStep
        }
    }

    private var situationStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("What happened? Just the facts — where you were, what occurred.")
            editor("e.g. My message from this morning is still on 'read'.", text: $situation)
        }
        .glassCard()
    }

    private var emotionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("Name what you're feeling and how strongly, 0–100. Naming it tames it.")
            FlowChips(options: EmotionLibrary.common,
                      isSelected: { name in emotions.contains { $0.name == name } },
                      toggle: toggleEmotion)
            HStack {
                TextField("Add your own…", text: $customEmotion)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomEmotion)
                Button("Add", action: addCustomEmotion)
                    .buttonStyle(.bordered)
                    .disabled(customEmotion.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ForEach($emotions) { $emotion in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(emotion.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(emotion.intensity)")
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: Binding(
                        get: { Double(emotion.intensity) },
                        set: { emotion.intensity = Int($0) }
                    ), in: 0...100, step: 5)
                    .tint(Brand.live)
                    .accessibilityLabel("\(emotion.name) intensity")
                    .accessibilityValue("\(emotion.intensity) of 100")
                }
            }
        }
        .glassCard()
    }

    private var thoughtStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("What went through your mind? Write the thought exactly as it sounded.")
            editor("e.g. They're ignoring me — I must have done something wrong.", text: $thought)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("How much do you believe it right now?")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(Int(beliefBefore))%")
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $beliefBefore, in: 0...100, step: 5)
                    .tint(Brand.live)
                    .accessibilityLabel("Belief in the thought")
                    .accessibilityValue("\(Int(beliefBefore)) percent")
            }
        }
        .glassCard()
    }

    private var trapsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("Does the thought fall into any of these traps? Tap all that fit — or none.")
            ForEach(Distortions.all) { d in
                Button {
                    if selectedTraps.contains(d.id) {
                        selectedTraps.remove(d.id)
                    } else {
                        selectedTraps.insert(d.id)
                    }
                    Haptics.selection()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedTraps.contains(d.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedTraps.contains(d.id) ? Brand.live : Brand.text3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(d.blurb)
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(d.name)
                .accessibilityValue(selectedTraps.contains(d.id) ? "selected" : "not selected")
            }
        }
        .glassCard()
    }

    private var evidenceStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("Be the lawyer for both sides.")
            Text("Evidence the thought is true")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
            editor("Facts only — what actually supports it?", text: $evidenceFor)
            Text("Evidence it isn't the whole story")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
            editor("Other explanations, exceptions, past counterexamples…", text: $evidenceAgainst)
        }
        .glassCard()
    }

    private var balancedStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("Write a fairer, more balanced thought — believable, not fake-positive.")
            if !selectedTraps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Distortions.all.filter { selectedTraps.contains($0.id) }) { d in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                                .foregroundStyle(Brand.live)
                                .padding(.top, 2)
                                .accessibilityHidden(true)
                            Text(d.challenge)
                                .font(.caption)
                                .foregroundStyle(Brand.text2)
                        }
                    }
                }
                .padding(10)
                .background(Brand.live.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            editor("e.g. There are a dozen reasons people reply late; silence isn't a verdict on me.", text: $balanced)
        }
        .glassCard()
    }

    private var rerateStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("Read your balanced thought once more. Now — how strong are the feelings?")
            Text("“\(balanced)”")
                .font(.subheadline.italic())
                .foregroundStyle(Brand.text)
                .fixedSize(horizontal: false, vertical: true)
            ForEach($emotionsAfter) { $emotion in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(emotion.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text("\(emotion.intensity)")
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: Binding(
                        get: { Double(emotion.intensity) },
                        set: { emotion.intensity = Int($0) }
                    ), in: 0...100, step: 5)
                    .tint(Brand.live)
                    .accessibilityLabel("\(emotion.name) intensity now")
                    .accessibilityValue("\(emotion.intensity) of 100")
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Belief in the original thought now")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(Int(beliefAfter))%")
                        .font(Brand.mono(14, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $beliefAfter, in: 0...100, step: 5)
                    .tint(Brand.live)
                    .accessibilityLabel("Belief in the original thought now")
                    .accessibilityValue("\(Int(beliefAfter)) percent")
            }
        }
        .glassCard()
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)
            StatusDot().scaleEffect(2)
            Text("Record saved")
                .font(.title.weight(.semibold))
                .foregroundStyle(Brand.text)
            if let saved {
                VStack(spacing: 12) {
                    summaryRow("Belief in the thought",
                               "\(saved.beliefBefore)% → \(saved.beliefAfter)%",
                               positive: saved.beliefDrop > 0)
                    if let top = saved.topEmotion,
                       let after = saved.emotionsAfter.first(where: { $0.name == top.name }) {
                        summaryRow(top.name, "\(top.intensity) → \(after.intensity)",
                                   positive: after.intensity < top.intensity)
                    }
                }
                .glassCard()
                Text(saved.beliefDrop > 0
                     ? "That drop is the work. The more records you do, the faster your brain learns the move."
                     : (gentleLanguage
                        ? "Not every record moves the number — writing it down still loosens the thought's grip."
                        : "No change this time. Revisit the evidence step: what would you tell a friend with this exact thought?"))
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button("Done") { dismiss() }
                .buttonStyle(InkButtonStyle())
                .padding(.top, 8)
        }
    }

    // MARK: Navigation

    private var navButtons: some View {
        HStack(spacing: 12) {
            if step.rawValue > 0 {
                Button("Back") {
                    withAnimation(reduceMotion ? nil : Brand.ease(0.3)) {
                        step = Step(rawValue: step.rawValue - 1) ?? .situation
                    }
                }
                .buttonStyle(GlassButtonStyle())
                .frame(width: 110)
            }
            Button(step == .rerate ? "Save record" : "Next") { advance() }
                .buttonStyle(InkButtonStyle())
                .disabled(!canAdvance)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var canAdvance: Bool {
        switch step {
        case .situation: return !situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .emotions: return !emotions.isEmpty
        case .thought: return !thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .balanced: return !balanced.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return true
        }
    }

    private func advance() {
        guard canAdvance else { return }
        Haptics.tap()
        if step == .balanced {
            // Seed the re-rate sliders from the before-ratings.
            if emotionsAfter.isEmpty {
                emotionsAfter = emotions
            }
            beliefAfter = min(beliefAfter, beliefBefore)
        }
        if step == .rerate {
            save()
            withAnimation(reduceMotion ? nil : Brand.ease()) { step = .done }
            return
        }
        withAnimation(reduceMotion ? nil : Brand.ease(0.3)) {
            step = Step(rawValue: step.rawValue + 1) ?? .done
        }
    }

    private func save() {
        let record = ThoughtRecord(
            situation: situation.trimmingCharacters(in: .whitespacesAndNewlines),
            emotions: emotions,
            automaticThought: thought.trimmingCharacters(in: .whitespacesAndNewlines),
            distortions: Array(selectedTraps),
            evidenceFor: evidenceFor.trimmingCharacters(in: .whitespacesAndNewlines),
            evidenceAgainst: evidenceAgainst.trimmingCharacters(in: .whitespacesAndNewlines),
            balancedThought: balanced.trimmingCharacters(in: .whitespacesAndNewlines),
            emotionsAfter: emotionsAfter,
            beliefBefore: Int(beliefBefore),
            beliefAfter: Int(beliefAfter)
        )
        context.insert(record)
        saved = record
        Haptics.success()
    }

    // MARK: Helpers

    private func toggleEmotion(_ name: String) {
        if let index = emotions.firstIndex(where: { $0.name == name }) {
            emotions.remove(at: index)
        } else {
            emotions.append(EmotionRating(name: name, intensity: 60))
        }
        Haptics.selection()
    }

    private func addCustomEmotion() {
        let name = customEmotion.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !emotions.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }
        emotions.append(EmotionRating(name: name, intensity: 60))
        customEmotion = ""
        Haptics.selection()
    }

    private func prompt(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Brand.text2)
    }

    private func editor(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(3...8)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
    }
}

/// Simple wrapping chip grid for emotion selection.
struct FlowChips: View {
    let options: [String]
    let isSelected: (String) -> Bool
    let toggle: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { name in
                let on = isSelected(name)
                Button {
                    toggle(name)
                } label: {
                    Text(name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(on ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                                    in: Capsule())
                        .foregroundStyle(on ? Color.white : Brand.text)
                        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(on ? 0 : 0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}
