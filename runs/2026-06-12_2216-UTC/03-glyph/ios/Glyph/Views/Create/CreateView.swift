import SwiftUI
import SwiftData
import UIKit

struct CreateView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCorrection") private var defaultCorrectionRaw = CorrectionLevel.medium.rawValue

    @State private var draft = PayloadDraft()
    @State private var foregroundHex = "111318"
    @State private var backgroundHex = "FFFFFF"
    @State private var correctionRaw = ""
    @State private var preview: UIImage?
    @State private var isRendering = false
    @State private var showingSaveSheet = false
    @State private var savedBanner = false

    private var correction: CorrectionLevel {
        CorrectionLevel(rawValue: correctionRaw.isEmpty ? defaultCorrectionRaw : correctionRaw) ?? .medium
    }

    private var renderKey: String {
        "\(draft.kind.rawValue)|\(draft.encoded())|\(foregroundHex)|\(backgroundHex)|\(correction.rawValue)|\(draft.validationError ?? "ok")"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    kindPicker
                    fields
                    previewPanel
                    stylePanel
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create")
            .scrollDismissesKeyboard(.interactively)
            .task(id: renderKey) { await render() }
            .sheet(isPresented: $showingSaveSheet) {
                SaveCodeSheet(
                    draft: draft,
                    foregroundHex: foregroundHex,
                    backgroundHex: backgroundHex,
                    correctionRaw: correction.rawValue
                ) {
                    savedBanner = true
                    Haptics.success()
                    Task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        savedBanner = false
                    }
                }
                .presentationDetents([.height(220)])
            }
            .overlay(alignment: .top) {
                if savedBanner {
                    Label("Saved to Library", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 4)
                }
            }
            .animation(.snappy(duration: 0.25), value: savedBanner)
        }
    }

    // MARK: - Kind picker

    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PayloadKind.allCases) { kind in
                    Button {
                        Haptics.tap()
                        draft.kind = kind
                    } label: {
                        Label(kind.displayName, systemImage: kind.symbol)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(draft.kind == kind ? GlyphTheme.mint.opacity(0.22) : Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                Capsule().strokeBorder(draft.kind == kind ? GlyphTheme.mint : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(kind.displayName)\(draft.kind == kind ? ", selected" : "")")
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Dynamic fields

    @ViewBuilder
    private var fields: some View {
        VStack(spacing: 10) {
            switch draft.kind {
            case .url:
                field("Link", text: $draft.urlString, prompt: "example.com or https://…", keyboard: .URL)
            case .text:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Text")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Anything — a note, a serial, a secret", text: $draft.text, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.plain)
                }
                .glyphPanel()
            case .wifi:
                field("Network name (SSID)", text: $draft.wifiSSID, prompt: "HomeWiFi")
                if draft.wifiSecurity != .none {
                    field("Password", text: $draft.wifiPassword, prompt: "••••••••")
                }
                Picker("Security", selection: $draft.wifiSecurity) {
                    ForEach(WifiSecurity.allCases) { sec in
                        Text(sec.displayName).tag(sec)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Hidden network", isOn: $draft.wifiHidden)
                    .glyphPanel()
            case .contact:
                field("First name", text: $draft.contactGivenName, prompt: "Amina")
                field("Last name", text: $draft.contactFamilyName, prompt: "Khan")
                field("Organization", text: $draft.contactOrganization, prompt: "Optional")
                field("Phone", text: $draft.contactPhone, prompt: "+1 555 010 0000", keyboard: .phonePad)
                field("Email", text: $draft.contactEmail, prompt: "amina@example.com", keyboard: .emailAddress)
                field("Website", text: $draft.contactURL, prompt: "Optional", keyboard: .URL)
            case .email:
                field("To", text: $draft.emailAddress, prompt: "person@example.com", keyboard: .emailAddress)
                field("Subject", text: $draft.emailSubject, prompt: "Optional")
                field("Body", text: $draft.emailBody, prompt: "Optional")
            case .sms:
                field("Number", text: $draft.smsNumber, prompt: "+1 555 010 0000", keyboard: .phonePad)
                field("Message", text: $draft.smsBody, prompt: "Optional")
            case .phone:
                field("Number", text: $draft.phoneNumber, prompt: "+1 555 010 0000", keyboard: .phonePad)
            }

            if let error = draft.validationError, !isDraftEmpty {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// True when the user hasn't typed anything for the current kind yet,
    /// so we show a neutral empty state instead of a validation nag.
    private var isDraftEmpty: Bool {
        switch draft.kind {
        case .url: return draft.urlString.isEmpty
        case .text: return draft.text.isEmpty
        case .wifi: return draft.wifiSSID.isEmpty && draft.wifiPassword.isEmpty
        case .contact:
            return draft.contactGivenName.isEmpty && draft.contactFamilyName.isEmpty
        case .email: return draft.emailAddress.isEmpty
        case .sms: return draft.smsNumber.isEmpty
        case .phone: return draft.phoneNumber.isEmpty
        }
    }

    private func field(
        _ title: String,
        text: Binding<String>,
        prompt: String,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .URL || keyboard == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .URL || keyboard == .emailAddress)
                .accessibilityLabel(title)
        }
        .glyphPanel()
    }

    // MARK: - Preview

    private var previewPanel: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: backgroundHex))
                    .frame(height: 260)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                if isRendering {
                    ProgressView()
                } else if let preview {
                    Image(uiImage: preview)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 210)
                        .accessibilityLabel("QR code preview for \(draft.suggestedTitle)")
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text(isDraftEmpty ? "Fill in the fields above and your code appears here." : (draft.validationError ?? "Couldn't render this code."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
            }

            if lowContrast {
                Label("These colors may be hard for scanners to read — keep the modules much darker than the background.", systemImage: "eye.trianglebadge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 10) {
                if let preview {
                    ShareLink(
                        item: Image(uiImage: preview),
                        preview: SharePreview(draft.suggestedTitle, image: Image(uiImage: preview))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    Haptics.tap()
                    showingSaveSheet = true
                } label: {
                    Label("Save", systemImage: "plus.square.on.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(GlyphTheme.mint)
                .foregroundStyle(.black)
                .disabled(preview == nil)
            }
        }
    }

    private var lowContrast: Bool {
        func luminance(_ hex: String) -> Double {
            let c = UIColor(hex: hex)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
        }
        return luminance(backgroundHex) - luminance(foregroundHex) < 0.35
    }

    @MainActor
    private func render() async {
        guard draft.validationError == nil else {
            preview = nil
            isRendering = false
            return
        }
        isRendering = true
        let payload = draft.encoded()
        let fg = UIColor(hex: foregroundHex)
        let bg = UIColor(hex: backgroundHex)
        let level = correction
        let image = await Task.detached(priority: .userInitiated) {
            QRRenderer.image(for: payload, correction: level, foreground: fg, background: bg)
        }.value
        preview = image
        isRendering = false
    }

    // MARK: - Style

    private var stylePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Modules")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(GlyphTheme.presetForegrounds, id: \.self) { hex in
                        colorSwatch(hex: hex, selected: foregroundHex == hex) {
                            foregroundHex = hex
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Background")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(GlyphTheme.presetBackgrounds, id: \.self) { hex in
                        colorSwatch(hex: hex, selected: backgroundHex == hex) {
                            backgroundHex = hex
                        }
                    }
                }
            }

            Picker("Error correction", selection: $correctionRaw) {
                ForEach(CorrectionLevel.allCases) { level in
                    Text(level.displayName).tag(level.rawValue)
                }
            }
            .pickerStyle(.menu)
            .onAppear {
                if correctionRaw.isEmpty { correctionRaw = defaultCorrectionRaw }
            }

            Text("Higher correction survives logos, damage, and small prints — at the cost of a denser code.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glyphPanel()
    }

    private func colorSwatch(hex: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
                .overlay {
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: hex) == Color(hex: "FFFFFF") || hex.hasPrefix("F") || hex.hasPrefix("E") ? .black : .white)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color \(hex)\(selected ? ", selected" : "")")
    }
}

// MARK: - Save sheet

private struct SaveCodeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let draft: PayloadDraft
    let foregroundHex: String
    let backgroundHex: String
    let correctionRaw: String
    var onSaved: () -> Void

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name this code", text: $title)
                    .onAppear {
                        if title.isEmpty { title = draft.suggestedTitle }
                    }
            }
            .navigationTitle("Save to Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        modelContext.insert(SavedCode(
                            title: trimmed.isEmpty ? draft.suggestedTitle : trimmed,
                            draft: draft,
                            foregroundHex: foregroundHex,
                            backgroundHex: backgroundHex,
                            correctionRaw: correctionRaw
                        ))
                        dismiss()
                        onSaved()
                    }
                    .disabled(draft.validationError != nil)
                }
            }
        }
    }
}
