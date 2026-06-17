import SwiftUI
import SwiftData

/// The main input form with a live hero result card. Updates as inputs change.
struct CalculatorView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs
    @Environment(\.modelContext) private var modelContext

    @Bindable var calc: CalculatorModel
    /// Jumps to the Breakdown tab.
    var switchToBreakdown: () -> Void

    @Query private var scenarios: [PayScenario]

    @State private var showStatePicker = false
    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var showSavedToast = false
    @State private var showLimitPaywall = false
    @AppStorage("isPro") private var isPro = false

    private let freeScenarioLimit = 2

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    NetHeroCard(result: calc.result,
                                roundWhole: prefs.roundWhole,
                                showAnnual: prefs.showAnnualByDefault)

                    if let note = calc.validationNote {
                        infoBanner(note)
                    }

                    payTypeSection
                    payFrequencySection
                    filingSection
                    preTaxSection
                    postTaxSection

                    actionButtons
                }
                .padding(16)
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Stub")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        switchToBreakdown()
                    } label: {
                        Image(systemName: "chart.pie")
                    }
                    .accessibilityLabel("View full breakdown")
                }
            }
            .sheet(isPresented: $showStatePicker) {
                StatePickerView(selectedCode: $calc.stateCode)
            }
            .sheet(isPresented: $showSaveSheet) {
                saveSheet
            }
            .sheet(isPresented: $showLimitPaywall) {
                PaywallView()
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    toast("Saved to Scenarios")
                }
            }
        }
    }

    // MARK: - Sections

    private var payTypeSection: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "How are you paid?")
                Picker("Pay type", selection: $calc.payType) {
                    ForEach(PayType.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                if calc.payType == .salary {
                    CurrencyField(title: "Annual salary", prompt: "95,000", text: $calc.salaryText,
                                  help: "Gross pay per year before taxes.")
                } else {
                    CurrencyField(title: "Hourly rate", prompt: "30.00", text: $calc.rateText)
                    CurrencyField(title: "Hours per week", symbol: "h", prompt: "40", text: $calc.hoursText,
                                  help: "Annualized as rate × hours × 52 weeks.")
                }
            }
        }
    }

    private var payFrequencySection: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Pay frequency")
                Picker("Pay frequency", selection: $calc.frequency) {
                    ForEach(PayFrequency.allCases) { Text($0.shortLabel).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(StubTheme.green)
                Text("\(calc.frequency.periodsPerYear) paychecks a year • \(calc.frequency.label)")
                    .font(.caption)
                    .foregroundStyle(StubTheme.secondaryText(scheme))
            }
        }
    }

    private var filingSection: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Filing & location")
                Picker("Filing status", selection: $calc.filing) {
                    ForEach(FilingStatus.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(StubTheme.green)

                Button {
                    showStatePicker = true
                } label: {
                    HStack {
                        Text("Work state")
                            .foregroundStyle(StubTheme.primaryText(scheme))
                        Spacer()
                        Text(calc.state.name)
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                    }
                }
                Text(calc.state.hasIncomeTax
                     ? "≈ \(Format.percent(calc.state.effectiveRate)) approximate state tax"
                     : "No state income tax")
                    .font(.caption)
                    .foregroundStyle(StubTheme.secondaryText(scheme))
            }
        }
    }

    private var preTaxSection: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Pre-tax deductions")
                CurrencyField(title: "401(k) contribution", symbol: "%", prompt: "6", text: $calc.pct401kText,
                              help: "Percent of gross. Reduces income tax (not FICA).")
                CurrencyField(title: "Extra 401(k) dollars / year", prompt: "0", text: $calc.dollar401kText)
                CurrencyField(title: "HSA per year", prompt: "0", text: $calc.hsaText,
                              help: "Reduces income tax and FICA.")
                CurrencyField(title: "Health premium / paycheck", prompt: "0", text: $calc.healthText,
                              help: "Section-125: reduces income tax and FICA.")
                CurrencyField(title: "Other pre-tax / paycheck", prompt: "0", text: $calc.otherPretaxText,
                              help: "Reduces income tax only.")
            }
        }
    }

    private var postTaxSection: some View {
        StubCard {
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Post-tax & withholding")
                CurrencyField(title: "Post-tax deduction / paycheck", prompt: "0", text: $calc.postTaxText,
                              help: "e.g. Roth 401(k), garnishments.")
                CurrencyField(title: "Extra federal withholding / paycheck", prompt: "0", text: $calc.extraWithholdingText,
                              help: "W-4 line 4(c).")
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                saveName = calc.suggestedName
                showSaveSheet = true
            } label: {
                Label("Save as scenario", systemImage: "tray.and.arrow.down.fill")
            }
            .buttonStyle(StubPrimaryButtonStyle())

            Button {
                switchToBreakdown()
            } label: {
                Label("See full breakdown", systemImage: "chart.pie.fill")
            }
            .buttonStyle(StubSecondaryButtonStyle())
        }
        .padding(.top, 4)
    }

    // MARK: - Save sheet

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section("Scenario name") {
                    TextField("e.g. Offer — Acme Corp", text: $saveName)
                }
                Section {
                    HStack {
                        Text("Net per paycheck")
                        Spacer()
                        Text(Format.currency(calc.result.netPerPaycheck, whole: prefs.roundWhole))
                            .foregroundStyle(StubTheme.green)
                            .font(StubTheme.figureFont(.body, weight: .semibold))
                    }
                }
            }
            .navigationTitle("Save scenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { performSave() }
                        .disabled(saveName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func performSave() {
        // Free tier limited to `freeScenarioLimit` saved scenarios.
        if !isPro && scenarios.count >= freeScenarioLimit {
            showSaveSheet = false
            showLimitPaywall = true
            return
        }
        let name = saveName.trimmingCharacters(in: .whitespaces)
        let scenario = calc.makeScenario(name: name.isEmpty ? calc.suggestedName : name)
        modelContext.insert(scenario)
        try? modelContext.save()
        Haptics.success(enabled: prefs.hapticsEnabled)
        showSaveSheet = false
        flashToast()
    }

    private func flashToast() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showSavedToast = false }
        }
    }

    // MARK: - Small pieces

    private func infoBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(StubTheme.state)
            Text(text)
                .font(.footnote)
                .foregroundStyle(StubTheme.primaryText(scheme))
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(StubTheme.state.opacity(0.14))
        )
    }

    private func toast(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(StubTheme.greenDeep))
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityAddTraits(.isStaticText)
    }
}
