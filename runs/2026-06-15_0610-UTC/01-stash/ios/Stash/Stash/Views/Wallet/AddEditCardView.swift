import SwiftUI
import SwiftData

/// Add or edit a loyalty card: store/name fields, a format picker with a live barcode
/// preview, category, a generated color palette, notes, plus validation + error states.
struct AddEditCardView: View {
    /// When non-nil we're editing; otherwise we're adding a new card.
    let card: LoyaltyCard?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @State private var storeName = ""
    @State private var codeValue = ""
    @State private var format: BarcodeFormat = .code128
    @State private var category: CardCategory = .retail
    @State private var colorHex = StoreCatalog.palette.first ?? "#128F8A"
    @State private var notes = ""
    @State private var isFavorite = false
    @State private var didLoad = false

    private var isEditing: Bool { card != nil }

    /// Validation result for the current code/format combination.
    private var validation: Result<String, BarcodeError> {
        BarcodeFactory.validate(codeValue, format: format)
    }

    private var canSave: Bool {
        let hasTitle = !name.trimmingCharacters(in: .whitespaces).isEmpty
            || !storeName.trimmingCharacters(in: .whitespaces).isEmpty
        // An empty code is allowed (quick-added cards); a non-empty one must validate.
        let codeOK = codeValue.trimmingCharacters(in: .whitespaces).isEmpty
            || (try? validation.get()) != nil
        return hasTitle && codeOK
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                formatSection
                previewSection
                colorSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
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
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section("Card") {
            TextField("Store name", text: $storeName)
                .textInputAutocapitalization(.words)
            TextField("Card name (optional)", text: $name)
                .textInputAutocapitalization(.words)
            Picker("Category", selection: $category) {
                ForEach(CardCategory.allCases) { c in
                    Label(c.displayName, systemImage: c.symbol).tag(c)
                }
            }
            Toggle("Favorite", isOn: $isFavorite)
        }
    }

    private var formatSection: some View {
        Section {
            TextField("Code value", text: $codeValue)
                .font(Theme.mono(15))
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Picker("Format", selection: $format) {
                ForEach(BarcodeFormat.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            }
            Text(format.inputHint)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            if case .failure(let error) = validation,
               !codeValue.trimmingCharacters(in: .whitespaces).isEmpty {
                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.warn)
                if error == .badCheckDigit {
                    Button("Fix check digit for me") { fixCheckDigit() }
                        .font(Theme.rounded(13, .semibold))
                }
            }
        } header: {
            Text("Barcode")
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        Section("Live preview") {
            if codeValue.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Enter a code value to preview the barcode.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                BarcodeView(value: codeValue, format: format,
                            height: format.isLinear ? 120 : 160)
                    .padding(.vertical, 6)
            }
        }
    }

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(StoreCatalog.palette, id: \.self) { hex in
                    Button {
                        colorHex = hex
                        Haptics.select(settings.hapticsEnabled)
                    } label: {
                        Circle()
                            .fill(Color(hexString: hex, fallback: Theme.accent))
                            .frame(height: 34)
                            .overlay(
                                Circle().strokeBorder(.white, lineWidth: colorHex == hex ? 3 : 0)
                            )
                            .overlay(
                                Circle().strokeBorder(Theme.hairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Color option")
                    .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Anything to remember", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var keyboardType: UIKeyboardType {
        switch format {
        case .ean13, .upca: return .numberPad
        default: return .default
        }
    }

    // MARK: Load / save

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let card {
            name = card.name
            storeName = card.storeName
            codeValue = card.codeValue
            format = card.format
            category = card.category
            colorHex = card.colorHex
            notes = card.notes
            isFavorite = card.isFavorite
        } else {
            format = settings.defaultFormat
        }
    }

    private func fixCheckDigit() {
        // Re-run normalization which appends/repairs the check digit, then adopt it.
        if case .success(let normalized) = (format == .upca
            ? EAN13Encoder.normalizedUPCA(from: codeValue)
            : EAN13Encoder.normalizedEAN13(from: codeValue)) {
            codeValue = format == .upca ? String(normalized.dropFirst()) : normalized
            Haptics.success(settings.hapticsEnabled)
        }
    }

    private func save() {
        let trimmedCode = codeValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalStore = storeName.trimmingCharacters(in: .whitespaces)
        let finalName = name.trimmingCharacters(in: .whitespaces)

        if let card {
            card.name = finalName
            card.storeName = finalStore.isEmpty ? finalName : finalStore
            card.codeValue = trimmedCode
            card.format = format
            card.category = category
            card.colorHex = colorHex
            card.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            card.isFavorite = isFavorite
        } else {
            let newCard = LoyaltyCard(
                name: finalName,
                storeName: finalStore.isEmpty ? finalName : finalStore,
                codeValue: trimmedCode,
                format: format,
                category: category,
                colorHex: colorHex,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isFavorite: isFavorite
            )
            context.insert(newCard)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
