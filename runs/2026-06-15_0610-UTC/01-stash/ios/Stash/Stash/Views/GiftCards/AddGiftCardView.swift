import SwiftUI
import SwiftData

/// Add a gift card with an initial balance, optional code/format, color, and expiry.
struct AddGiftCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var storeName = ""
    @State private var balanceText = ""
    @State private var code = ""
    @State private var format: BarcodeFormat = .code128
    @State private var colorHex = StoreCatalog.palette.first ?? "#128F8A"
    @State private var hasExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var notes = ""

    private var parsedBalance: Decimal? { Money.parse(balanceText) }

    private var canSave: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty
            && (parsedBalance ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gift Card") {
                    TextField("Store name", text: $storeName)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Text("Initial balance")
                        Spacer()
                        TextField("0.00", text: $balanceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Theme.mono(15))
                    }
                    if !balanceText.isEmpty && parsedBalance == nil {
                        Label("Enter a valid amount.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.warn)
                    }
                }

                Section {
                    TextField("Card code (optional)", text: $code)
                        .font(Theme.mono(15))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Format", selection: $format) {
                        ForEach(BarcodeFormat.allCases) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    if !code.trimmingCharacters(in: .whitespaces).isEmpty {
                        BarcodeView(value: code, format: format,
                                    height: format.isLinear ? 110 : 150)
                            .padding(.vertical, 6)
                    }
                } header: {
                    Text("Barcode")
                } footer: {
                    Text("Add the code printed on the card so you can scan it at the register.")
                }

                Section("Expiry") {
                    Toggle("Has an expiry date", isOn: $hasExpiry.animation())
                    if hasExpiry {
                        DatePicker("Expires", selection: $expiryDate,
                                   in: Date()..., displayedComponents: .date)
                    }
                }

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
                                    .overlay(Circle().strokeBorder(.white, lineWidth: colorHex == hex ? 3 : 0))
                                    .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Color option")
                            .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Anything to remember", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("New Gift Card")
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
        }
    }

    private func save() {
        guard let balance = parsedBalance, balance > 0 else { return }
        let card = GiftCard(
            storeName: storeName.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            format: format,
            initialBalance: balance,
            expiryDate: hasExpiry ? expiryDate : nil,
            colorHex: colorHex,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(card)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
