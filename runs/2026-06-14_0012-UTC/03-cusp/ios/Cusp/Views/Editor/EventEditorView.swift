import SwiftUI
import SwiftData

/// Full editor for creating or editing an event. Lives in a sheet with its own
/// NavigationStack. Validates input and gates Pro-only themes.
struct EventEditorView: View {
    enum Mode {
        case create(defaults: Defaults)
        case edit(CountdownEvent)
        case template(EventTemplate, defaults: Defaults)
    }

    struct Defaults {
        var kind: EventKind = .until
        var themeTag: Int = 0
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    // Form state
    @State private var title = ""
    @State private var date = Date()
    @State private var includeTime = false
    @State private var kind: EventKind = .until
    @State private var symbol = "star.fill"
    @State private var themeTag = 0
    @State private var repeatRule: RepeatRule = .none
    @State private var note = ""

    @State private var showSymbolPicker = false
    @State private var paywall: PaywallReason?
    @State private var attemptedSave = false

    private var editingExisting: CountdownEvent? {
        if case let .edit(e) = mode { return e }
        return nil
    }

    private var isEditing: Bool { editingExisting != nil }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var titleValid: Bool { !trimmedTitle.isEmpty }
    private var theme: CardTheme { CardTheme.from(themeTag) }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                detailsSection
                appearanceSection
                repeatSection
                noteSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!titleValid)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPickerView(selected: $symbol, theme: theme)
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: Sections

    private var previewSection: some View {
        Section {
            ZStack {
                theme.gradient
                VStack(spacing: 10) {
                    EventSymbolView(symbol: symbol, isEmoji: symbolIsEmoji(symbol),
                                    size: 34, color: theme.onGradient)
                    Text(trimmedTitle.isEmpty ? "Your event" : trimmedTitle)
                        .font(Theme.rounded(20, .semibold))
                        .foregroundStyle(theme.onGradient)
                        .lineLimit(1)
                    Text(DateFmt.line(for: previewEvent, date: date))
                        .font(Theme.rounded(13))
                        .foregroundStyle(theme.onGradientSoft)
                }
                .padding(20)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Title", text: $title)
                .font(Theme.rounded(16))
                .submitLabel(.done)
            if attemptedSave && !titleValid {
                Label("Give your event a title", systemImage: "exclamationmark.circle")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.bad)
            }

            Picker("Type", selection: $kind) {
                ForEach(EventKind.allCases) { Text($0.shortTitle).tag($0) }
            }
            .pickerStyle(.segmented)

            DatePicker("Date",
                       selection: $date,
                       displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date])

            Toggle("Include time", isOn: $includeTime)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Button {
                showSymbolPicker = true
            } label: {
                HStack {
                    Text("Symbol").foregroundStyle(Theme.ink)
                    Spacer()
                    EventSymbolView(symbol: symbol, isEmoji: symbolIsEmoji(symbol),
                                    size: 22, color: Theme.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Gradient")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                ThemePicker(selectedTag: $themeTag, isPro: isPro) {
                    paywall = .theme
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var repeatSection: some View {
        Section("Repeat") {
            Picker("Repeats", selection: $repeatRule) {
                ForEach(RepeatRule.allCases) {
                    Label($0.title, systemImage: $0.symbol).tag($0)
                }
            }
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField("Optional note", text: $note, axis: .vertical)
                .font(Theme.rounded(15))
                .lineLimit(2...5)
        }
    }

    // MARK: Helpers

    private var previewEvent: CountdownEvent {
        CountdownEvent(title: trimmedTitle, date: date, includeTime: includeTime,
                       kind: kind, symbol: symbol, colorTag: themeTag,
                       repeatRule: repeatRule, note: note)
    }

    private func symbolIsEmoji(_ s: String) -> Bool {
        guard let scalar = s.unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }

    private func loadIfNeeded() {
        switch mode {
        case .create(let defaults):
            if title.isEmpty && !isEditing {
                kind = defaults.kind
                themeTag = defaults.themeTag
            }
        case .template(let t, let defaults):
            // Only seed once.
            if title.isEmpty {
                title = t.title
                symbol = t.symbol
                kind = t.kind
                repeatRule = t.repeatRule
                themeTag = Pro.canUse(theme: CardTheme.from(t.themeTag), isPro: isPro)
                    ? t.themeTag : defaults.themeTag
                date = t.seedDate()
            }
        case .edit(let e):
            // Load from the model once.
            if !loadedFromModel {
                title = e.title
                date = e.date
                includeTime = e.includeTime
                kind = e.kind
                symbol = e.symbol
                themeTag = e.colorTag
                repeatRule = e.repeatRule
                note = e.note
                loadedFromModel = true
            }
        }
    }

    @State private var loadedFromModel = false

    private func save() {
        attemptedSave = true
        guard titleValid else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        // Guard Pro theme selection at the boundary.
        let safeTag = Pro.canUse(theme: CardTheme.from(themeTag), isPro: isPro)
            ? themeTag : settings.defaultThemeTag

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = editingExisting {
            existing.title = trimmedTitle
            existing.date = date
            existing.includeTime = includeTime
            existing.kind = kind
            existing.symbol = symbol
            existing.colorTag = safeTag
            existing.repeatRule = repeatRule
            existing.note = cleanNote
        } else {
            let new = CountdownEvent(
                title: trimmedTitle, date: date, includeTime: includeTime,
                kind: kind, symbol: symbol, colorTag: safeTag,
                repeatRule: repeatRule, note: cleanNote, createdAt: Date()
            )
            context.insert(new)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
