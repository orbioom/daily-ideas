import SwiftUI

/// Interactive 5-4-3-2-1 senses walkthrough plus a small library of other
/// grounding techniques. Completing the walkthrough is a warm success state.
struct GroundingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true

    /// The senses steps in order.
    private let steps = GroundingStep.fiveFourThreeTwoOne

    @State private var stepIndex = 0
    @State private var notes: [[String]] = GroundingStep.fiveFourThreeTwoOne.map { Array(repeating: "", count: $0.count) }
    @State private var finished = false

    var body: some View {
        ZStack {
            HavenBackground()
            if finished {
                successView
            } else {
                walkthrough
            }
        }
    }

    // MARK: Walkthrough

    private var walkthrough: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    progressRow
                    stepCard
                    techniquesSection
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
            }
            .accessibilityLabel("Close grounding")
            Spacer()
            Text("Grounding")
                .font(.headline)
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Spacer()
            Color.clear.frame(width: 28, height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var progressRow: some View {
        HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i <= stepIndex ? HavenTheme.accent : HavenTheme.accent.opacity(0.2))
                    .frame(height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(stepIndex + 1) of \(steps.count)")
    }

    private var step: GroundingStep { steps[min(stepIndex, steps.count - 1)] }

    private var stepCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: step.icon)
                        .font(.system(size: 30))
                        .foregroundStyle(HavenTheme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.prompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(HavenTheme.primaryText(scheme))
                        Text(step.hint)
                            .font(.caption)
                            .foregroundStyle(HavenTheme.secondaryText(scheme))
                    }
                }

                VStack(spacing: 10) {
                    ForEach(0..<step.count, id: \.self) { slot in
                        noteRow(slot)
                    }
                }

                Button {
                    advance()
                } label: {
                    Text(isLastStep ? "I feel a little more here" : "Next sense")
                }
                .havenPillButton()
                .accessibilityHint(isLastStep ? "Completes the grounding exercise" : "Moves to the next sense")
            }
        }
    }

    private func noteRow(_ slot: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: filled(slot) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(filled(slot) ? HavenTheme.calmGreen : HavenTheme.secondaryText(scheme))
                .accessibilityHidden(true)
            TextField(step.placeholder, text: bindingFor(slot))
                .foregroundStyle(HavenTheme.primaryText(scheme))
                .submitLabel(.done)
                .accessibilityLabel("\(step.prompt), item \(slot + 1)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenTheme.subtleFill(scheme))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerSmall, style: .continuous))
    }

    private func filled(_ slot: Int) -> Bool {
        guard notes.indices.contains(stepIndex), notes[stepIndex].indices.contains(slot) else { return false }
        return !notes[stepIndex][slot].trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func bindingFor(_ slot: Int) -> Binding<String> {
        Binding(
            get: {
                guard notes.indices.contains(stepIndex), notes[stepIndex].indices.contains(slot) else { return "" }
                return notes[stepIndex][slot]
            },
            set: { newValue in
                guard notes.indices.contains(stepIndex), notes[stepIndex].indices.contains(slot) else { return }
                notes[stepIndex][slot] = newValue
            }
        )
    }

    private var isLastStep: Bool { stepIndex >= steps.count - 1 }

    private func advance() {
        if hapticsEnabled { Haptics.selection() }
        if isLastStep {
            if hapticsEnabled { Haptics.success() }
            withTransition { finished = true }
        } else {
            withTransition { stepIndex += 1 }
        }
    }

    private func withTransition(_ change: () -> Void) {
        if reduceMotion { change() }
        else { withAnimation(.easeInOut(duration: 0.3)) { change() } }
    }

    // MARK: Other techniques

    private var techniquesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Other ways to ground", systemImage: "leaf")
            ForEach(GroundingTechnique.all) { tech in
                HavenCard(padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tech.icon)
                            .font(.title3)
                            .foregroundStyle(HavenTheme.accentDeep)
                            .frame(width: 30)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tech.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(HavenTheme.primaryText(scheme))
                            Text(tech.detail)
                                .font(.caption)
                                .foregroundStyle(HavenTheme.secondaryText(scheme))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: Success

    private var successView: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(HavenTheme.calmGreen.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: "checkmark")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(HavenTheme.calmGreen)
            }
            .accessibilityHidden(true)
            Text("Well done")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Text("You brought yourself back to right now. That takes real courage. Stay as long as you need.")
                .font(.body)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            VStack(spacing: 12) {
                Button("Do it again") { restart() }
                    .havenPillButton(filled: false)
                Button("I'm okay for now") { dismiss() }
                    .havenPillButton()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .accessibilityElement(children: .contain)
    }

    private func restart() {
        withTransition {
            finished = false
            stepIndex = 0
            notes = steps.map { Array(repeating: "", count: $0.count) }
        }
    }
}

// MARK: - Data

struct GroundingStep {
    let count: Int
    let prompt: String
    let hint: String
    let placeholder: String
    let icon: String

    static let fiveFourThreeTwoOne: [GroundingStep] = [
        .init(count: 5, prompt: "5 things you can see", hint: "Look slowly around the room.", placeholder: "Something you see", icon: "eye"),
        .init(count: 4, prompt: "4 things you can feel", hint: "Notice textures, temperature, your clothes.", placeholder: "Something you feel", icon: "hand.tap"),
        .init(count: 3, prompt: "3 things you can hear", hint: "Listen for near and distant sounds.", placeholder: "Something you hear", icon: "ear"),
        .init(count: 2, prompt: "2 things you can smell", hint: "Take a gentle breath in.", placeholder: "Something you smell", icon: "nose"),
        .init(count: 1, prompt: "1 thing you can taste", hint: "Or one kind thing about yourself.", placeholder: "Something you taste", icon: "mouth")
    ]
}

struct GroundingTechnique: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String

    static let all: [GroundingTechnique] = [
        .init(title: "Cold water", detail: "Splash your face or hold something cold. It calms the body fast.", icon: "drop"),
        .init(title: "Temperature", detail: "Hold a warm mug or an ice cube and focus on the sensation.", icon: "thermometer.medium"),
        .init(title: "Body scan", detail: "Slowly move attention from your feet up to your head, softening as you go.", icon: "figure.mind.and.body"),
        .init(title: "Count backwards", detail: "Count down from 100 by 7s to gently occupy your mind.", icon: "number")
    ]
}
