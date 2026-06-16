import SwiftUI
import SwiftData
import UIKit

/// Settings: persisted preferences, Pro management, CSV export, reset, and About.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(StoreManager.self) private var store

    // Persisted preferences (@AppStorage).
    @AppStorage("defaultFilingStatus") private var defaultFilingStatus = FilingStatus.single.rawValue
    @AppStorage("defaultStateRate") private var defaultStateRate = 0.0
    @AppStorage("defaultTaxYear") private var defaultTaxYear = 2025
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @Query private var incomes: [IncomeEntry]
    @Query private var expenses: [ExpenseEntry]
    @Query private var scenarios: [TaxScenario]
    @Query private var payments: [EstimatedPayment]

    @State private var stateRateText: String = ""
    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showExportError = false

    private var filingBinding: Binding<FilingStatus> {
        Binding(
            get: { FilingStatus(rawValue: defaultFilingStatus) ?? .single },
            set: { defaultFilingStatus = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                defaultsSection
                appearanceSection
                proSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExporter) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAll() }
            } message: {
                Text("This permanently deletes all income, expenses, scenarios, and payment records. Your purchase and preferences are kept.")
            }
            .alert("Export failed", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Couldn't prepare the export file. Please try again.")
            }
            .onAppear {
                stateRateText = defaultStateRate > 0 ? EstimateViewModel.formatPlain(defaultStateRate) : ""
            }
        }
    }

    // MARK: - Sections

    private var defaultsSection: some View {
        Section {
            Picker("Default filing status", selection: filingBinding) {
                ForEach(FilingStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            HStack {
                Text("Default state rate %")
                Spacer()
                TextField("0", text: $stateRateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(maxWidth: 80)
                    .onChange(of: stateRateText) { _, newValue in
                        defaultStateRate = EstimateViewModel.parse(newValue).doubleValue
                    }
            }
            Picker("Default tax year", selection: $defaultTaxYear) {
                ForEach(TaxTables.supportedYears, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
        } header: {
            Text("Defaults")
        } footer: {
            Text("These pre-fill the Estimate and drive the Quarterly plan.")
        }
    }

    private var appearanceSection: some View {
        Section("Feedback") {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            .onChange(of: hapticsEnabled) { _, on in
                if on { Haptics.selection() }
            }
        }
    }

    private var proSection: some View {
        Section("Quarter Pro") {
            if store.isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accent)
                Button {
                    exportCSV()
                } label: {
                    Label("Export ledger as CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(incomes.isEmpty && expenses.isEmpty)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Quarter Pro", systemImage: "seal")
                        Spacer()
                        Text(StoreManager.priceString)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                HStack {
                    Label("Export ledger as CSV", systemImage: "square.and.arrow.up")
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    ProBadge()
                }
            }
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Text("Stored records")
                Spacer()
                Text("\(incomes.count + expenses.count + scenarios.count + payments.count)")
                    .foregroundStyle(Theme.secondaryText)
                    .monospacedDigit()
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Quarter", systemImage: "info.circle")
            }
            Text("Quarter is an educational estimate using published 2024–2025 federal figures and a flat state rate you enter. Not tax advice; not a substitute for a professional or IRS guidance.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        } header: {
            Text("About")
        }
    }

    // MARK: - Actions

    private func exportCSV() {
        let csv = CSVExporter.ledgerCSV(income: incomes, expenses: expenses)
        guard let url = CSVExporter.writeTemporaryFile(csv, filename: "Quarter-Ledger.csv") else {
            showExportError = true
            return
        }
        exportURL = url
        showExporter = true
        Haptics.tap()
    }

    private func resetAll() {
        for e in incomes { context.delete(e) }
        for e in expenses { context.delete(e) }
        for s in scenarios { context.delete(s) }
        for p in payments { context.delete(p) }
        try? context.save()
        Haptics.warning()
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Quarter")
                        .font(.largeTitle.weight(.bold))
                    Text("The private, one-time quarterly tax estimator for the self-employed.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                Text("Quarter does the real self-employment-tax math — SE tax, federal brackets, a state approximation, quarterly due dates, and safe-harbor guidance — entirely on your device. No account, no subscription.")
                    .font(.body)
                Text("By Orbioom iOS studio.")
                    .font(.footnote)
                    .foregroundStyle(Theme.tertiaryText)
                Divider()
                Text("Disclaimer: Quarter is an educational estimate using published 2024 and 2025 federal figures and a flat state rate you enter. It is not tax advice and not a substitute for a qualified professional or official IRS guidance.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
