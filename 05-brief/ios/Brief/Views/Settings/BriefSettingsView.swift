import SwiftUI
import SwiftData

struct BriefSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [BriefSettings]
    @State private var showingProAlert = false

    private var settings: BriefSettings {
        if let existing = settingsQuery.first { return existing }
        let new = BriefSettings()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            Form {
                // Business profile
                Section("Business Profile") {
                    SettingsTextField(label: "Business Name", placeholder: "Your Business Name", value: Binding(
                        get: { settings.businessName },
                        set: { settings.businessName = $0; try? modelContext.save() }
                    ))
                    SettingsTextField(label: "Email", placeholder: "you@yourbusiness.com", value: Binding(
                        get: { settings.businessEmail },
                        set: { settings.businessEmail = $0; try? modelContext.save() }
                    ), keyboard: .emailAddress)
                    SettingsTextField(label: "Phone", placeholder: "+1 555-0100", value: Binding(
                        get: { settings.businessPhone },
                        set: { settings.businessPhone = $0; try? modelContext.save() }
                    ), keyboard: .phonePad)
                    SettingsTextArea(label: "Address", placeholder: "Street, City, State, ZIP", value: Binding(
                        get: { settings.businessAddress },
                        set: { settings.businessAddress = $0; try? modelContext.save() }
                    ))
                }

                // Invoice defaults
                Section("Invoice Defaults") {
                    HStack {
                        Text("Default Tax Rate")
                        Spacer()
                        TextField("0", text: Binding(
                            get: {
                                let pct = settings.defaultTaxRate * Decimal(100)
                                let fmt = NumberFormatter()
                                fmt.numberStyle = .decimal
                                fmt.maximumFractionDigits = 2
                                return fmt.string(from: pct as NSDecimalNumber) ?? "0"
                            },
                            set: { val in
                                let cleaned = val.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                                if let pct = Decimal(string: cleaned) {
                                    settings.defaultTaxRate = pct / Decimal(100)
                                    try? modelContext.save()
                                }
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .accessibilityLabel("Default tax rate")
                        Text("%")
                            .foregroundColor(.secondary)
                    }

                    Picker("Payment Terms", selection: Binding(
                        get: { settings.defaultPaymentTerms },
                        set: { settings.defaultPaymentTerms = $0; try? modelContext.save() }
                    )) {
                        Text("15 days").tag(15)
                        Text("30 days").tag(30)
                        Text("45 days").tag(45)
                        Text("60 days").tag(60)
                    }
                    .accessibilityLabel("Default payment terms")

                    Picker("Currency", selection: Binding(
                        get: { settings.defaultCurrency },
                        set: { settings.defaultCurrency = $0; try? modelContext.save() }
                    )) {
                        ForEach(["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CHF", "INR"], id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .accessibilityLabel("Default currency")
                }

                // Invoice numbering
                Section("Invoice Numbering") {
                    HStack {
                        Text("Prefix")
                        Spacer()
                        TextField("INV", text: Binding(
                            get: { settings.invoicePrefix },
                            set: { settings.invoicePrefix = $0; try? modelContext.save() }
                        ))
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .frame(width: 80)
                        .accessibilityLabel("Invoice number prefix")
                    }

                    HStack {
                        Text("Next Number")
                        Spacer()
                        TextField("1001", text: Binding(
                            get: { "\(settings.nextInvoiceNumber)" },
                            set: { val in
                                if let n = Int(val) {
                                    settings.nextInvoiceNumber = n
                                    try? modelContext.save()
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .accessibilityLabel("Next invoice number")
                    }

                    HStack {
                        Text("Preview")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(InvoiceNumberGenerator.preview(prefix: settings.invoicePrefix, number: settings.nextInvoiceNumber))
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }

                // Pro section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: settings.isPro ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                Text(settings.isPro ? "Brief Pro — Unlocked" : "Unlock Brief Pro")
                                    .fontWeight(.semibold)
                            }
                            Text(settings.isPro ? "Thank you for supporting Brief!" : "Custom templates, tax presets, CSV export")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !settings.isPro {
                            Text("$4.99")
                                .fontWeight(.bold)
                                .foregroundColor(BriefTheme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !settings.isPro {
                            showingProAlert = true
                        }
                    }
                    .accessibilityLabel(settings.isPro ? "Brief Pro unlocked" : "Unlock Brief Pro for $4.99")
                } header: {
                    Text("Pro")
                } footer: {
                    if !settings.isPro {
                        Text("One-time purchase. No subscription. Ever.")
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    Link(destination: URL(string: "mailto:support@brief-app.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    .accessibilityLabel("Contact support via email")
                    Link(destination: URL(string: "https://brief-app.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .accessibilityLabel("View privacy policy")
                }
            }
            .navigationTitle("Settings")
            .alert("Unlock Brief Pro", isPresented: $showingProAlert) {
                Button("Purchase — $4.99") {
                    settings.isPro = true
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Unlock custom invoice templates, tax presets, and CSV client export. One-time purchase, no subscription.")
            }
        }
    }
}

private struct SettingsTextField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $value)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .accessibilityLabel(label)
        }
    }
}

private struct SettingsTextArea: View {
    let label: String
    let placeholder: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $value, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
                .accessibilityLabel(label)
        }
    }
}
