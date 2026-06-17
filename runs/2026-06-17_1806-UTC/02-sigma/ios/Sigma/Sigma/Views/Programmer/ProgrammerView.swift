import SwiftUI

/// Programmer calculator: a value shown simultaneously in DEC / HEX / BIN / OCT,
/// a base-aware keypad, bitwise operations and a selectable bit width.
struct ProgrammerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var value: UInt64 = 0
    @State private var inputBase: NumberBase = .dec
    @State private var width: BitWidth = .thirtyTwo
    @State private var pendingOp: BitOp? = nil
    @State private var operand: UInt64? = nil
    @State private var showCopied = false

    private var accent: Color { settings.activeTheme(isPro: pro.isPro).accent }

    private enum BitOp: String { case and = "AND", or = "OR", xor = "XOR" }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    BaseReadoutCard(value: value,
                                    width: width,
                                    inputBase: inputBase,
                                    accent: accent) { base in
                        inputBase = base
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    }
                    .padding(16)
                    Spacer(minLength: 0)
                    controls
                    keypad
                }
            }
            .navigationTitle("Programmer")
            .navigationBarTitleDisplayMode(.inline)
            .toast(isPresented: $showCopied, message: "Copied")
        }
    }

    // MARK: Controls (width + bitwise)

    private var controls: some View {
        VStack(spacing: 8) {
            PillPicker(options: BitWidth.allCases, selection: $width, label: { $0.label + "-bit" }, accent: accent) { _ in
                value = value & width.mask
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
            HStack(spacing: 8) {
                opKey("AND") { setOp(.and) }
                opKey("OR") { setOp(.or) }
                opKey("XOR") { setOp(.xor) }
                opKey("NOT") { value = BaseConverter.not(value, width: width) }
                opKey("<<") { value = BaseConverter.shiftLeft(value, by: 1, width: width) }
                opKey(">>") { value = BaseConverter.shiftRight(value, by: 1, width: width) }
            }
        }
        .padding(.horizontal, 16)
    }

    private func opKey(_ title: String, action: @escaping () -> Void) -> some View {
        let active = pendingOp?.rawValue == title
        return Button {
            Haptics.impact(.light, enabled: settings.hapticsEnabled)
            action()
        } label: {
            Text(title)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(active ? Theme.accentInk : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(active ? accent : Theme.surface)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(opLabel(title))
    }

    private func opLabel(_ title: String) -> String {
        switch title {
        case "<<": return "Shift left"
        case ">>": return "Shift right"
        default: return title
        }
    }

    // MARK: Keypad

    private var keypad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                hexKey("A"); hexKey("B"); hexKey("C"); hexKey("D")
            }
            HStack(spacing: 8) {
                hexKey("E"); hexKey("F")
                progKey("AC", style: .destructive, label: "all clear") { clearAll() }
                progKey("", systemImage: "delete.left", style: .function, label: "backspace") { backspace() }
            }
            HStack(spacing: 8) {
                digitKey("7"); digitKey("8"); digitKey("9")
                progKey("=", style: .accent, label: "equals") { applyPending() }
            }
            HStack(spacing: 8) {
                digitKey("4"); digitKey("5"); digitKey("6")
                progKey("÷2", style: .function, label: "halve") { value = BaseConverter.shiftRight(value, by: 1, width: width) }
            }
            HStack(spacing: 8) {
                digitKey("1"); digitKey("2"); digitKey("3")
                progKey("×2", style: .function, label: "double") { value = BaseConverter.shiftLeft(value, by: 1, width: width) }
            }
            HStack(spacing: 8) {
                digitKey("0")
                progKey("FF", style: .function, label: "set all bits") { value = width.mask }
                progKey("Copy", systemImage: "doc.on.doc", style: .function, label: "copy current base") { copyCurrent() }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.surfaceDeep)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func digitKey(_ d: String) -> some View {
        let enabled = digitAllowed(d)
        return progKey(d, style: .digit, enabled: enabled) { appendDigit(d) }
    }

    private func hexKey(_ d: String) -> some View {
        let enabled = inputBase == .hex
        return progKey(d, style: .function, enabled: enabled) { appendDigit(d) }
    }

    private func progKey(_ title: String,
                         systemImage: String? = nil,
                         style: KeyStyle,
                         enabled: Bool = true,
                         label: String? = nil,
                         action: @escaping () -> Void) -> some View {
        CalcKey(title: title,
                systemImage: systemImage,
                style: style,
                accent: accent,
                isEnabled: enabled,
                accessibilityLabelText: label) {
            if style != .digit { Haptics.impact(.light, enabled: settings.hapticsEnabled) }
            action()
        }
        .frame(height: 52)
    }

    // MARK: Input logic

    /// Whether a decimal digit is permissible for the active input base.
    private func digitAllowed(_ d: String) -> Bool {
        guard let v = UInt64(d, radix: 16) else { return false }
        return v < UInt64(inputBase.rawValue)
    }

    private func appendDigit(_ d: String) {
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        let current = BaseConverter.format(value, base: inputBase, width: width)
        let candidate = (current == "0" ? "" : current) + d
        if let parsed = BaseConverter.parse(candidate, base: inputBase, width: width) {
            value = parsed
        }
    }

    private func backspace() {
        let current = BaseConverter.format(value, base: inputBase, width: width)
        let trimmed = String(current.dropLast())
        value = BaseConverter.parse(trimmed.isEmpty ? "0" : trimmed, base: inputBase, width: width) ?? 0
    }

    private func clearAll() {
        value = 0
        pendingOp = nil
        operand = nil
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }

    private func setOp(_ op: BitOp) {
        operand = value
        pendingOp = op
        value = 0
    }

    private func applyPending() {
        guard let op = pendingOp, let lhs = operand else {
            Haptics.selection(enabled: settings.hapticsEnabled)
            return
        }
        let rhs = value
        switch op {
        case .and: value = BaseConverter.and(lhs, rhs, width: width)
        case .or:  value = BaseConverter.or(lhs, rhs, width: width)
        case .xor: value = BaseConverter.xor(lhs, rhs, width: width)
        }
        pendingOp = nil
        operand = nil
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func copyCurrent() {
        ClipboardService.copy(BaseConverter.format(value, base: inputBase, width: width))
        Haptics.success(enabled: settings.hapticsEnabled)
        showCopied = true
    }
}
