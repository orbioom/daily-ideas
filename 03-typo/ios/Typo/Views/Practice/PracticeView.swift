import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [TypoSettings]
    @State private var vm = TypingViewModel()
    @State private var showConfig = false
    @FocusState private var inputFocused: Bool

    private var settings: TypoSettings {
        settingsList.first ?? TypoSettings()
    }

    var body: some View {
        ZStack {
            TypoTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                if vm.state == .finished {
                    ResultView(vm: vm) {
                        saveResult()
                        vm.reset()
                        inputFocused = true
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                } else {
                    typingArea
                        .padding(.horizontal, 20)
                    Spacer()
                    if settings.showKeyboard {
                        hiddenInput
                    }
                    tapToStart
                        .padding(.bottom, 32)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.state)
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TypoTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showConfig = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(TypoTheme.accent)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button { vm.reset(); inputFocused = false } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(TypoTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showConfig) {
            ConfigSheet(vm: vm)
        }
        .onAppear {
            vm.configure(
                mode: TypingMode(rawValue: settings.selectedMode) ?? .words,
                duration: TestDuration(rawValue: settings.testDuration) ?? .sixty,
                wordCount: WordCount(rawValue: settings.wordCountMode) ?? .twenty
            )
        }
    }

    var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timerLabel)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(timerColor)
                Text(vm.mode.rawValue)
                    .font(.system(size: 12))
                    .foregroundStyle(TypoTheme.textSecondary)
            }
            Spacer()
            if vm.state != .idle && settings.showLiveWpm {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(vm.liveWpm))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(TypoTheme.accent)
                    Text("WPM")
                        .font(.system(size: 12))
                        .foregroundStyle(TypoTheme.textSecondary)
                }
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(vm.accuracy))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(accuracyColor)
                Text("ACC")
                    .font(.system(size: 12))
                    .foregroundStyle(TypoTheme.textSecondary)
            }
        }
    }

    var timerLabel: String {
        if vm.state == .idle { return "\(vm.timeRemaining)s" }
        return "\(vm.timeRemaining)s"
    }

    var timerColor: Color {
        if vm.timeRemaining > 30 { return TypoTheme.textPrimary }
        if vm.timeRemaining > 10 { return TypoTheme.accentPurple }
        return TypoTheme.wrongRed
    }

    var accuracyColor: Color {
        if vm.accuracy >= 95 { return TypoTheme.correctGreen }
        if vm.accuracy >= 85 { return TypoTheme.accent }
        return TypoTheme.wrongRed
    }

    var typingArea: some View {
        ScrollView {
            TypingTextView(charStates: vm.charStates)
                .padding(16)
        }
        .frame(height: 260)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture { inputFocused = true; vm.startIfNeeded() }
        .accessibilityLabel("Typing area. Tap to start.")
    }

    var hiddenInput: some View {
        TextField("", text: Binding(
            get: { vm.typed },
            set: { vm.handleInput($0) }
        ))
        .focused($inputFocused)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .frame(width: 0, height: 0)
        .opacity(0)
    }

    var tapToStart: some View {
        Group {
            if vm.state == .idle {
                Button {
                    inputFocused = true
                    vm.startIfNeeded()
                } label: {
                    Text("Tap to Start")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(TypoTheme.accent, in: Capsule())
                }
            }
        }
    }

    func saveResult() {
        let result = TypoResult(
            wpm: vm.wpm,
            accuracy: vm.accuracy,
            rawWpm: vm.rawWpm,
            mode: vm.mode.rawValue,
            duration: vm.duration.rawValue,
            wordCount: vm.wordCount.rawValue,
            correctChars: vm.correctChars,
            totalChars: vm.totalTypedChars
        )
        modelContext.insert(result)
    }
}

struct TypingTextView: View {
    let charStates: [(Character, CharState)]

    var body: some View {
        Text(attributedString)
            .font(.system(size: 20, design: .monospaced))
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var attributedString: AttributedString {
        var result = AttributedString()
        for (ch, state) in charStates {
            var attr = AttributedString(String(ch))
            switch state {
            case .correct:
                attr.foregroundColor = TypoTheme.charCorrect
            case .wrong:
                attr.foregroundColor = TypoTheme.charWrong
                attr.backgroundColor = TypoTheme.charWrong.opacity(0.15)
            case .cursor:
                attr.foregroundColor = TypoTheme.textPrimary
                attr.backgroundColor = TypoTheme.cursorBlue.opacity(0.5)
            case .pending:
                attr.foregroundColor = TypoTheme.charPending
            }
            result.append(attr)
        }
        return result
    }
}

struct ResultView: View {
    let vm: TypingViewModel
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Result")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(TypoTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                resultStat(value: "\(Int(vm.wpm))", label: "WPM", color: TypoTheme.accent)
                resultStat(value: "\(Int(vm.accuracy))%", label: "Accuracy", color: accuracyColor)
                resultStat(value: "\(Int(vm.rawWpm))", label: "Raw WPM", color: TypoTheme.textSecondary)
                resultStat(value: "\(vm.correctChars)/\(vm.totalTypedChars)", label: "Correct", color: TypoTheme.correctGreen)
            }

            HStack(spacing: 0) {
                Text("Mode: ")
                    .foregroundStyle(TypoTheme.textSecondary)
                Text("\(vm.mode.rawValue) · \(vm.duration.label)")
                    .foregroundStyle(TypoTheme.textPrimary)
            }
            .font(.system(size: 14))

            Button("Try Again") { onNext() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(TypoTheme.accent, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(20)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    func resultStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(TypoTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(TypoTheme.background, in: RoundedRectangle(cornerRadius: 12))
    }

    var accuracyColor: Color {
        if vm.accuracy >= 95 { return TypoTheme.correctGreen }
        if vm.accuracy >= 85 { return TypoTheme.accent }
        return TypoTheme.wrongRed
    }
}

struct ConfigSheet: View {
    @Bindable var vm: TypingViewModel
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [TypoSettings]
    @Environment(\.modelContext) private var modelContext

    private var settings: TypoSettings {
        if let s = settingsList.first { return s }
        let s = TypoSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TypoTheme.background.ignoresSafeArea()
                Form {
                    Section("Mode") {
                        ForEach(TypingMode.allCases, id: \.self) { mode in
                            Button {
                                settings.selectedMode = mode.rawValue
                                vm.configure(mode: mode, duration: TestDuration(rawValue: settings.testDuration) ?? .sixty, wordCount: WordCount(rawValue: settings.wordCountMode) ?? .twenty)
                            } label: {
                                HStack {
                                    Text(mode.rawValue).foregroundStyle(TypoTheme.textPrimary)
                                    Spacer()
                                    if settings.selectedMode == mode.rawValue {
                                        Image(systemName: "checkmark").foregroundStyle(TypoTheme.accent)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(TypoTheme.surface)

                    Section("Duration") {
                        ForEach(TestDuration.allCases, id: \.self) { dur in
                            Button {
                                settings.testDuration = dur.rawValue
                                vm.configure(mode: TypingMode(rawValue: settings.selectedMode) ?? .words, duration: dur, wordCount: WordCount(rawValue: settings.wordCountMode) ?? .twenty)
                            } label: {
                                HStack {
                                    Text(dur.label).foregroundStyle(TypoTheme.textPrimary)
                                    Spacer()
                                    if settings.testDuration == dur.rawValue {
                                        Image(systemName: "checkmark").foregroundStyle(TypoTheme.accent)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(TypoTheme.surface)

                    Section("Word Count") {
                        ForEach(WordCount.allCases, id: \.self) { wc in
                            Button {
                                settings.wordCountMode = wc.rawValue
                                vm.configure(mode: TypingMode(rawValue: settings.selectedMode) ?? .words, duration: TestDuration(rawValue: settings.testDuration) ?? .sixty, wordCount: wc)
                            } label: {
                                HStack {
                                    Text(wc.label).foregroundStyle(TypoTheme.textPrimary)
                                    Spacer()
                                    if settings.wordCountMode == wc.rawValue {
                                        Image(systemName: "checkmark").foregroundStyle(TypoTheme.accent)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(TypoTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Test Config")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TypoTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(TypoTheme.accent)
                }
            }
        }
    }
}
