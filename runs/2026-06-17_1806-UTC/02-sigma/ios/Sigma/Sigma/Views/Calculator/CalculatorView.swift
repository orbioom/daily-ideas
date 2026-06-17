import SwiftUI
import SwiftData

/// The core calculator: live display + a tactile keypad with scientific rows,
/// memory, DEG/RAD, a 2nd/shift toggle, and `=` that appends to the history tape.
struct CalculatorView: View {
    @Bindable var calculator: CalculatorModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context

    @State private var showCopied = false
    @State private var showSettings = false
    @State private var showConstants = false
    @State private var showPaywall = false

    private var accent: Color { settings.activeTheme(isPro: pro.isPro).accent }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    display
                    keypad
                }
            }
            .navigationTitle("Sigma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if pro.isPro { showConstants = true } else { showPaywall = true }
                    } label: {
                        Image(systemName: "atom")
                            .accessibilityLabel("Constants library")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
            .toast(isPresented: $showCopied, message: "Copied")
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showConstants) {
                ConstantsView { constant in
                    calculator.insertResult(constant.insertableValue)
                    refresh()
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .onAppear(perform: refresh)
        .onChange(of: settings.defaultAngleRaw) { _, _ in
            calculator.angle = settings.defaultAngle
            refresh()
        }
    }

    // MARK: Display

    private var display: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                memoryIndicator
                Spacer()
                angleToggle
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)

            Spacer(minLength: 0)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(displayedExpression)
                    .font(Theme.rounded(34, .regular))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .defaultScrollAnchor(.trailing)

            Button(action: copyResult) {
                Text(resultText)
                    .font(Theme.rounded(56, .medium))
                    .foregroundStyle(calculator.hasError ? Theme.bad : Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .disabled(resultText.isEmpty)
            .accessibilityLabel("Result \(resultText.isEmpty ? "none" : resultText)")
            .accessibilityHint("Double tap to copy the result")
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
    }

    private var displayedExpression: String {
        calculator.expression.isEmpty ? " " : calculator.expression
    }

    private var resultText: String {
        if calculator.hasError { return calculator.liveResult }
        if !calculator.liveResult.isEmpty { return calculator.liveResult }
        return calculator.expression.isEmpty ? "0" : ""
    }

    private var memoryIndicator: some View {
        Group {
            if settings.memoryRegister != 0 {
                Text("M")
                    .font(Theme.rounded(14, .bold))
                    .foregroundStyle(accent)
                    .accessibilityLabel("Memory holds \(NumberFormatting.string(settings.memoryRegister, grouping: true, places: settings.effectivePlaces))")
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
    }

    private var angleToggle: some View {
        Button {
            calculator.angle = calculator.angle == .degrees ? .radians : .degrees
            Haptics.selection(enabled: settings.hapticsEnabled)
            refresh()
        } label: {
            Text(calculator.angle.rawValue)
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.accentInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(accent))
        }
        .accessibilityLabel("Angle unit")
        .accessibilityValue(calculator.angle == .degrees ? "Degrees" : "Radians")
        .accessibilityHint("Toggles between degrees and radians")
    }

    // MARK: Keypad

    private var keypad: some View {
        VStack(spacing: 8) {
            scientificRows
            mainGrid
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surfaceDeep)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var scientificRows: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                key(calculator.shifted ? "asin" : "sin", style: .function, label: shiftLabel("sine")) {
                    calculator.appendFunction(calculator.shifted ? "asin" : "sin"); refresh()
                }
                key(calculator.shifted ? "acos" : "cos", style: .function, label: shiftLabel("cosine")) {
                    calculator.appendFunction(calculator.shifted ? "acos" : "cos"); refresh()
                }
                key(calculator.shifted ? "atan" : "tan", style: .function, label: shiftLabel("tangent")) {
                    calculator.appendFunction(calculator.shifted ? "atan" : "tan"); refresh()
                }
                key("ln", style: .function) { calculator.appendFunction("ln"); refresh() }
                key("log", style: .function) { calculator.appendFunction("log"); refresh() }
            }
            HStack(spacing: 8) {
                shiftKey
                key("√", style: .function, label: "square root") { calculator.appendFunction("sqrt"); refresh() }
                key("x²", style: .function, label: "squared") { calculator.append("^2"); refresh() }
                key("xʸ", style: .function, label: "power") { calculator.append("^"); refresh() }
                key("1/x", style: .function, label: "reciprocal") { calculator.appendFunction("recip"); refresh() }
            }
            HStack(spacing: 8) {
                key("n!", style: .function, label: "factorial") { calculator.append("!"); refresh() }
                key("π", style: .function, label: "pi") { calculator.append("π"); refresh() }
                key("e", style: .function, label: "Euler's number") { calculator.append("e"); refresh() }
                key("(", style: .function, label: "open parenthesis") { calculator.append("("); refresh() }
                key(")", style: .function, label: "close parenthesis") { calculator.append(")"); refresh() }
            }
            HStack(spacing: 8) {
                key("MC", style: .function, label: "memory clear") { memoryClear() }
                key("MR", style: .function, label: "memory recall") { memoryRecall() }
                key("M+", style: .function, label: "memory add") { memoryAdd() }
                key("M−", style: .function, label: "memory subtract") { memorySubtract() }
                key("%", style: .function, label: "percent") { calculator.append("%"); refresh() }
            }
        }
    }

    private var shiftKey: some View {
        CalcKey(title: "2nd",
                style: .function,
                accent: accent,
                accessibilityLabelText: "Second function toggle") {
            calculator.shifted.toggle()
            Haptics.selection(enabled: settings.hapticsEnabled)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerKey, style: .continuous)
                .stroke(calculator.shifted ? accent : Color.clear, lineWidth: 2)
        )
        .frame(height: keyHeight)
    }

    private var mainGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                key("AC", style: .destructive, label: "all clear") { allClear() }
                key("±", style: .function, label: "toggle sign") { calculator.toggleSign(); refresh() }
                backspaceKey
                key("÷", style: .function, label: "divide") { calculator.append("÷"); refresh() }
            }
            HStack(spacing: 8) {
                digit("7"); digit("8"); digit("9")
                key("×", style: .function, label: "multiply") { calculator.append("×"); refresh() }
            }
            HStack(spacing: 8) {
                digit("4"); digit("5"); digit("6")
                key("−", style: .function, label: "minus") { calculator.append("−"); refresh() }
            }
            HStack(spacing: 8) {
                digit("1"); digit("2"); digit("3")
                key("+", style: .function, label: "plus") { calculator.append("+"); refresh() }
            }
            HStack(spacing: 8) {
                digit("0")
                digit(".")
                // Equals occupies the trailing two columns for a strong primary action.
                key("=", style: .accent, label: "equals") { evaluate() }
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
            }
        }
    }

    private var backspaceKey: some View {
        CalcKey(title: "",
                systemImage: "delete.left",
                style: .function,
                accent: accent,
                accessibilityLabelText: "Backspace") {
            calculator.backspace()
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            refresh()
        }
        .frame(height: keyHeight)
    }

    // MARK: Key builders

    private func digit(_ d: String) -> some View {
        key(d, style: .digit) {
            calculator.appendDigit(d)
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            refresh()
        }
    }

    private func key(_ title: String,
                     style: KeyStyle,
                     label: String? = nil,
                     action: @escaping () -> Void) -> some View {
        CalcKey(title: title,
                style: style,
                accent: accent,
                accessibilityLabelText: label) {
            if style != .digit { Haptics.impact(.light, enabled: settings.hapticsEnabled) }
            action()
        }
        .frame(height: keyHeight)
    }

    private func shiftLabel(_ base: String) -> String {
        calculator.shifted ? "inverse \(base)" : base
    }

    private var keyHeight: CGFloat { 58 }

    // MARK: Actions

    private func refresh() {
        calculator.refreshPreview(places: settings.effectivePlaces,
                                  grouping: settings.groupingEnabled,
                                  highPrecision: settings.highPrecision)
    }

    private func allClear() {
        calculator.clear()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }

    private func evaluate() {
        guard !calculator.isEmpty else { return }
        if let outcome = calculator.evaluate(places: settings.effectivePlaces,
                                             grouping: settings.groupingEnabled,
                                             highPrecision: settings.highPrecision) {
            saveEntry(expression: outcome.expression, result: outcome.result)
            settings.lastResult = outcome.result
            Haptics.success(enabled: settings.hapticsEnabled)
        } else {
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }

    private func saveEntry(expression: String, result: String) {
        let entry = CalcEntry(expression: expression, result: result)
        context.insert(entry)
        try? context.save()
        pruneIfNeeded()
    }

    /// Enforces the free-tier history cap by deleting the oldest entries.
    private func pruneIfNeeded() {
        guard !pro.isPro else { return }
        var descriptor = FetchDescriptor<CalcEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 500
        let entries = (try? context.fetch(descriptor)) ?? []
        guard entries.count > ProStore.freeHistoryCap else { return }
        for entry in entries.dropFirst(ProStore.freeHistoryCap) {
            context.delete(entry)
        }
        try? context.save()
    }

    private func copyResult() {
        let value = resultText
        guard !value.isEmpty, !calculator.hasError else { return }
        ClipboardService.copy(value)
        Haptics.success(enabled: settings.hapticsEnabled)
        showCopied = true
    }

    // MARK: Memory

    private func currentValueForMemory() -> Double? {
        let text = calculator.liveResult.isEmpty ? calculator.expression : calculator.liveResult
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private func memoryClear() {
        settings.memoryRegister = 0
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func memoryRecall() {
        guard settings.memoryRegister != 0 else { return }
        let value = NumberFormatting.string(settings.memoryRegister, grouping: false, places: settings.effectivePlaces, highPrecision: settings.highPrecision)
        calculator.insertResult(value)
        refresh()
    }

    private func memoryAdd() {
        if let value = currentValueForMemory() {
            settings.memoryRegister += value
            Haptics.selection(enabled: settings.hapticsEnabled)
        }
    }

    private func memorySubtract() {
        if let value = currentValueForMemory() {
            settings.memoryRegister -= value
            Haptics.selection(enabled: settings.hapticsEnabled)
        }
    }
}
