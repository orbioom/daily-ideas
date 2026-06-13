import SwiftUI
import SwiftData

/// The guided morning/evening reflection flow, presented as a sheet. Steps
/// through each prompt, then a final commit step (virtue for morning, mood for
/// evening), and saves a single `Reflection`.
struct ReflectFlowView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var vm: ReflectionViewModel

    init(kind: Reflection.Kind, existing: Reflection?, promptSet: PromptSet? = nil) {
        let set = promptSet
            ?? existing.flatMap { PromptLibrary.set(for: $0.promptKey) }
            ?? PromptLibrary.defaultSet(for: kind)
        _vm = State(initialValue: ReflectionViewModel(kind: kind, promptSet: set, existing: existing))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if vm.phase == .done {
                    successView
                } else {
                    VStack(spacing: 0) {
                        ProgressView(value: vm.progress)
                            .tint(Theme.accent)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .accessibilityLabel("Step \(min(vm.step + 1, vm.totalSteps)) of \(vm.totalSteps)")

                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if vm.isFinalStep {
                                    finalStep
                                } else {
                                    promptStep
                                }
                                if let error = vm.errorMessage {
                                    Text(error)
                                        .font(Theme.rounded(14, .semibold))
                                        .foregroundStyle(Theme.bad)
                                }
                            }
                            .padding(20)
                        }
                        controls
                    }
                }
            }
            .navigationTitle(vm.promptSet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if vm.phase != .done {
                        Button("Close") { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(vm.phase == .saving)
    }

    // MARK: Steps

    @ViewBuilder private var promptStep: some View {
        if let prompt = vm.currentPrompt() {
            Text(prompt)
                .font(Theme.serif(24, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ReflectionEditor(text: Binding(
                get: { vm.binding(at: vm.step) },
                set: { newValue in
                    if vm.responses.indices.contains(vm.step) { vm.responses[vm.step] = newValue }
                }))
                .accessibilityLabel(prompt)
        }
    }

    @ViewBuilder private var finalStep: some View {
        Text(vm.kind == .morning ? "Set your focus" : "How was today?")
            .font(Theme.serif(24, .bold))
            .foregroundStyle(Theme.ink)

        if vm.kind == .morning {
            Text("Which virtue will you practise today?")
                .font(Theme.rounded(15, .regular))
                .foregroundStyle(Theme.inkSoft)
            VirtuePicker(selection: $vm.virtue)
        } else {
            Text("Rate the day from 1 (hard) to 5 (calm).")
                .font(Theme.rounded(15, .regular))
                .foregroundStyle(Theme.inkSoft)
            MoodPicker(mood: $vm.mood)
            Text("Which virtue did today most call for?")
                .font(Theme.rounded(15, .regular))
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 4)
            VirtuePicker(selection: $vm.virtue)
        }
    }

    private var successView: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            Text(vm.kind == .morning ? "Intention set." : "Day reviewed.")
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
            Text(vm.kind == .morning
                 ? "Carry \(vm.virtue.rawValue.lowercased()) with you today."
                 : "Rest well. Tomorrow is another chance to do better.")
                .font(Theme.rounded(16, .regular))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Haptics.tap(); dismiss()
            } label: {
                Text("Done")
                    .font(Theme.rounded(18, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            if vm.step > 0 {
                Button {
                    Haptics.soft(); vm.back()
                } label: {
                    Text("Back")
                        .font(Theme.rounded(17, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.ink)
                }
            }
            Button {
                if vm.isFinalStep {
                    vm.save(to: context)   // sets phase to .done, which swaps in the success view
                } else {
                    vm.advance()
                }
            } label: {
                Text(vm.isFinalStep ? (vm.isEditing ? "Update" : "Save") : "Next")
                    .font(Theme.rounded(17, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(continueEnabled ? Theme.accent : Theme.inkFaint,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .disabled(!continueEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var continueEnabled: Bool {
        vm.isFinalStep ? vm.canSave : true
    }
}

// MARK: - Pieces

private struct ReflectionEditor: View {
    @Binding var text: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Write freely…")
                    .font(Theme.rounded(16, .regular))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 14)
                    .padding(.leading, 14)
                    .accessibilityHidden(true)
            }
            TextEditor(text: $text)
                .font(Theme.rounded(16, .regular))
                .foregroundStyle(Theme.ink)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(6)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}

private struct VirtuePicker: View {
    @Binding var selection: Virtue
    var body: some View {
        VStack(spacing: 10) {
            ForEach(Virtue.allCases) { v in
                Button {
                    Haptics.tap(); selection = v
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: v.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(v.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v.rawValue)
                                .font(Theme.rounded(16, .bold))
                                .foregroundStyle(Theme.ink)
                            Text(v.definition)
                                .font(Theme.rounded(12, .regular))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: selection == v ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selection == v ? Theme.accent : Theme.inkFaint)
                    }
                    .padding(12)
                    .background(selection == v ? v.tint.opacity(0.12) : Theme.surface,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selection == v ? v.tint : Theme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(v.rawValue): \(v.definition)")
                .accessibilityAddTraits(selection == v ? .isSelected : [])
            }
        }
    }
}

private struct MoodPicker: View {
    @Binding var mood: Int
    private let faces = ["cloud.heavyrain.fill", "cloud.fill", "cloud.sun.fill", "sun.max.fill", "sparkles"]
    private let labels = ["Hard", "Low", "Even", "Good", "Calm"]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    Haptics.tap(); mood = value
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: faces[value - 1])
                            .font(.system(size: 24))
                            .foregroundStyle(mood == value ? .white : Theme.inkSoft)
                        Text(labels[value - 1])
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(mood == value ? .white : Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(mood == value ? Theme.accent : Theme.surfaceAlt,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mood \(value) of 5, \(labels[value - 1])")
                .accessibilityAddTraits(mood == value ? .isSelected : [])
            }
        }
    }
}
