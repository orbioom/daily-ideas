import SwiftUI
import SwiftData

/// Create or edit an account by hand. Validates Base32 live and gates the Save
/// button until the entry is valid. Reused for manual entry, URI/QR preview
/// (prefilled), and editing an existing account.
struct AccountEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var allAccounts: [Account]
    @Query(sort: \Folder.sortIndex) private var folders: [Folder]

    /// When non-nil, we're editing an existing account in place.
    var editing: Account?
    /// Prefill values (from a parsed URI). Ignored when `editing` is set.
    var prefill: OTPAuthURI?
    /// Called after a successful save (e.g. to dismiss a parent flow).
    var onSaved: (() -> Void)?

    @State private var issuer = ""
    @State private var label = ""
    @State private var secret = ""
    @State private var algorithm: OTPAlgorithm = .sha1
    @State private var digits = 6
    @State private var period = 30
    @State private var type: OTPType = .totp
    @State private var counter = 0
    @State private var colorHue = 0.62
    @State private var folderID: UUID? = nil
    @State private var showPaywall = false
    @State private var didLoad = false

    private var isEditing: Bool { editing != nil }

    private var secretValid: Bool {
        !secret.trimmingCharacters(in: .whitespaces).isEmpty && Base32.isValid(secret)
    }

    private var canSave: Bool {
        secretValid && !(issuer.trimmingCharacters(in: .whitespaces).isEmpty &&
                         label.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var accountCount: Int { allAccounts.count }

    var body: some View {
        Form {
            identitySection
            secretSection
            parametersSection
            if !folders.isEmpty || isPro {
                folderSection
            }
            colorSection
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(isEditing ? "Edit account" : "New account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .font(Theme.rounded(16, .semibold))
                    .disabled(!canSave)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reason: .accountLimit)
        }
        .onAppear(perform: loadInitial)
    }

    // MARK: Sections

    private var identitySection: some View {
        Section {
            TextField("Issuer (e.g. GitHub)", text: $issuer)
                .textInputAutocapitalization(.words)
            TextField("Account (e.g. you@email.com)", text: $label)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Identity")
        } footer: {
            Text("At least one of issuer or account is required.")
        }
    }

    private var secretSection: some View {
        Section {
            TextField("Base32 secret", text: $secret)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(Theme.mono(15))
            HStack(spacing: 6) {
                Image(systemName: secret.isEmpty ? "key" :
                        (secretValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill"))
                    .foregroundStyle(secret.isEmpty ? Theme.inkFaint :
                                        (secretValid ? Theme.good : Theme.bad))
                Text(secret.isEmpty ? "Enter the secret your provider shows" :
                        (secretValid ? "Valid Base32 secret" : "Not valid Base32"))
                    .font(Theme.rounded(13))
                    .foregroundStyle(secret.isEmpty ? Theme.inkFaint :
                                        (secretValid ? Theme.good : Theme.bad))
            }
            .accessibilityElement(children: .combine)
        } header: {
            Text("Secret")
        }
    }

    private var parametersSection: some View {
        Section {
            Picker("Type", selection: $type) {
                ForEach(OTPType.allCases) { t in Text(t.shortName).tag(t) }
            }
            Picker("Algorithm", selection: $algorithm) {
                ForEach(OTPAlgorithm.allCases) { a in Text(a.displayName).tag(a) }
            }
            Picker("Digits", selection: $digits) {
                ForEach([6, 7, 8], id: \.self) { d in Text("\(d)").tag(d) }
            }
            if type == .totp {
                Stepper(value: $period, in: 10...120, step: 5) {
                    HStack {
                        Text("Period")
                        Spacer()
                        Text("\(period)s").foregroundStyle(Theme.inkSoft)
                    }
                }
            } else {
                Stepper(value: $counter, in: 0...1_000_000) {
                    HStack {
                        Text("Counter")
                        Spacer()
                        Text("\(counter)").foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        } header: {
            Text("Parameters")
        } footer: {
            Text(type == .totp
                 ? "Most providers use time-based codes, SHA1, 6 digits, 30 seconds."
                 : "Counter-based codes advance each time you reveal them.")
        }
    }

    private var folderSection: some View {
        Section {
            Picker("Folder", selection: $folderID) {
                Text("None").tag(UUID?.none)
                ForEach(folders) { folder in
                    Text(folder.name).tag(UUID?.some(folder.id))
                }
            }
        } header: {
            Text("Folder")
        }
    }

    private var colorSection: some View {
        Section {
            Slider(value: $colorHue, in: 0...1) {
                Text("Color")
            }
            .tint(Theme.accountColor(hue: colorHue))
            HStack {
                Text("Preview")
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.accountColor(hue: colorHue).opacity(0.25))
                    Text(monogram)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.accountColor(hue: colorHue))
                }
                .frame(width: 38, height: 38)
            }
        } header: {
            Text("Avatar color")
        }
    }

    private var monogram: String {
        let src = (issuer.isEmpty ? label : issuer).trimmingCharacters(in: .whitespaces)
        guard let first = src.first else { return "?" }
        return String(first).uppercased()
    }

    // MARK: Load + Save

    private func loadInitial() {
        guard !didLoad else { return }
        didLoad = true
        if let account = editing {
            issuer = account.issuer
            label = account.label
            secret = account.secretBase32
            algorithm = account.algorithm
            digits = account.digits
            period = account.period
            type = account.type
            counter = account.counter
            colorHue = account.colorHue
            folderID = account.folder?.id
        } else if let p = prefill {
            issuer = p.issuer
            label = p.accountName
            secret = p.secretBase32
            algorithm = p.algorithm
            digits = OTPGenerator.clampDigits(p.digits)
            period = max(p.period, 1)
            type = p.type
            counter = p.counter
        }
    }

    private func save() {
        guard canSave else { return }

        // Enforce the free-tier limit only when creating a new account.
        if editing == nil, !Pro.canAddAccount(currentCount: accountCount, isPro: isPro) {
            showPaywall = true
            return
        }

        let cleanSecret = secret.trimmingCharacters(in: .whitespaces).uppercased()
        let resolvedFolder = folders.first { $0.id == folderID }

        if let account = editing {
            account.issuer = issuer.trimmingCharacters(in: .whitespaces)
            account.label = label.trimmingCharacters(in: .whitespaces)
            account.secretBase32 = cleanSecret
            account.algorithm = algorithm
            account.digits = OTPGenerator.clampDigits(digits)
            account.period = max(period, 1)
            account.type = type
            account.counter = max(counter, 0)
            account.colorHue = colorHue
            account.folder = resolvedFolder
        } else {
            let nextIndex = (allAccounts.map { $0.sortIndex }.max() ?? -1) + 1
            let account = Account(issuer: issuer.trimmingCharacters(in: .whitespaces),
                                  label: label.trimmingCharacters(in: .whitespaces),
                                  secretBase32: cleanSecret,
                                  algorithm: algorithm,
                                  digits: OTPGenerator.clampDigits(digits),
                                  period: max(period, 1),
                                  type: type,
                                  counter: max(counter, 0),
                                  colorHue: colorHue,
                                  sortIndex: nextIndex,
                                  folder: resolvedFolder)
            context.insert(account)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        onSaved?()
        dismiss()
    }
}
