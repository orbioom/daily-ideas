import SwiftUI
import SwiftData

struct MileageRatesView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \MileageRate.year, order: .reverse) private var rates: [MileageRate]

    @State private var editing: MileageRate?
    @State private var showEditor = false
    @State private var showPaywall = false
    @State private var toast: String?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            List {
                if !isPro {
                    ProLockBanner(message: "Editing and adding tax-year rates is a Pro feature. Built-in IRS rates are always available.") {
                        showPaywall = true
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                Section {
                    ForEach(rates) { rate in
                        Button {
                            if isPro {
                                editing = rate
                                showEditor = true
                            } else {
                                showPaywall = true
                                Haptics.warning(settings.hapticsEnabled)
                            }
                        } label: {
                            row(rate)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    Text("Standard mileage rates ($ per mile)")
                } footer: {
                    Text("Seeded with IRS standard mileage rates for 2022–2026. Charity is the statutory $0.14. Verify current figures at irs.gov.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Mileage Rates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isPro {
                        editing = nil
                        showEditor = true
                        Haptics.impact(settings.hapticsEnabled)
                    } else {
                        showPaywall = true
                        Haptics.warning(settings.hapticsEnabled)
                    }
                } label: {
                    Image(systemName: isPro ? "plus" : "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .accessibilityLabel(isPro ? "Add year" : "Add year — Pro required")
            }
        }
        .sheet(isPresented: $showEditor) {
            MileageRateEditorView(rate: editing, existingYears: rates.map { $0.year }) {
                toast = editing == nil ? "Rate added" : "Rate updated"
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .toast($toast)
    }

    private func row(_ rate: MileageRate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verbatim: "\(rate.year)")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if isPro {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            HStack(spacing: 14) {
                rateChip("Business", rate.businessRate, Theme.palette[0])
                rateChip("Medical", rate.medicalRate, Theme.palette[1])
                rateChip("Charity", rate.charityRate, Theme.palette[6])
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rate.year). Business \(rateString(rate.businessRate)), medical \(rateString(rate.medicalRate)), charity \(rateString(rate.charityRate)) per mile")
    }

    private func rateString(_ d: Decimal) -> String {
        CurrencyFormatter.string(d, code: settings.currencyCode)
    }

    private func rateChip(_ label: String, _ value: Decimal, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
            Text(rateString(value))
                .font(Theme.mono(14, .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct MileageRateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let rate: MileageRate?
    let existingYears: [Int]
    let onSave: () -> Void

    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var businessText = ""
    @State private var medicalText = ""
    @State private var charityText = ""
    @State private var saveError: String?

    private let isEditing: Bool

    init(rate: MileageRate?, existingYears: [Int], onSave: @escaping () -> Void) {
        self.rate = rate
        self.existingYears = existingYears
        self.onSave = onSave
        self.isEditing = rate != nil
    }

    private func parsed(_ text: String) -> Decimal? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let d = Decimal(string: cleaned), d >= 0 else { return nil }
        return d
    }

    private var canSave: Bool {
        guard parsed(businessText) != nil, parsed(medicalText) != nil, parsed(charityText) != nil else { return false }
        if !isEditing && existingYears.contains(year) { return false }
        return (1990...2100).contains(year)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tax year") {
                    if isEditing {
                        HStack {
                            Text("Year")
                            Spacer()
                            Text(verbatim: "\(year)").foregroundStyle(Theme.inkSoft)
                        }
                    } else {
                        Stepper(value: $year, in: 1990...2100) {
                            HStack {
                                Text("Year")
                                Spacer()
                                Text(verbatim: "\(year)")
                                    .font(Theme.mono(16, .semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        if existingYears.contains(year) {
                            Text("That year already exists.")
                                .font(Theme.rounded(13))
                                .foregroundStyle(Theme.warn)
                        }
                    }
                }
                .listRowBackground(Theme.surface)

                Section {
                    rateField("Business ($/mi)", $businessText)
                    rateField("Medical ($/mi)", $medicalText)
                    rateField("Charity ($/mi)", $charityText)
                } header: {
                    Text("Rates")
                } footer: {
                    Text("Enter dollars per mile, e.g. 0.70.")
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Rate" : "Add Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitial)
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: { Text(saveError ?? "") }
        }
    }

    private func rateField(_ title: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.mono(15, .semibold))
                .frame(maxWidth: 110)
        }
    }

    private func loadInitial() {
        if let rate {
            year = rate.year
            businessText = NSDecimalNumber(decimal: rate.businessRate).stringValue
            medicalText = NSDecimalNumber(decimal: rate.medicalRate).stringValue
            charityText = NSDecimalNumber(decimal: rate.charityRate).stringValue
        } else {
            businessText = "0.70"
            medicalText = "0.21"
            charityText = "0.14"
        }
    }

    private func save() {
        guard let b = parsed(businessText), let m = parsed(medicalText), let c = parsed(charityText) else {
            saveError = "Please enter valid rates."
            return
        }
        if !isEditing && existingYears.contains(year) {
            saveError = "A rate for \(year) already exists."
            return
        }
        if let rate {
            rate.businessRate = b
            rate.medicalRate = m
            rate.charityRate = c
        } else {
            context.insert(MileageRate(year: year, businessRate: b, medicalRate: m, charityRate: c))
        }
        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            saveError = "Something went wrong. Please try again."
        }
    }
}
