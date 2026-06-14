import SwiftUI

struct AmortizationView: View {
    @Environment(CalculatorModel.self) private var calc
    @Environment(AppSettings.self) private var settings
    @State private var showPaywall = false
    @State private var isComputing = false
    @State private var rows: [AmortRow] = []
    @State private var baseline: [AmortRow] = []
    @State private var lastSignature: String = ""

    private var symbol: String { settings.currency.symbol }
    private var isPro: Bool { UserDefaults.standard.bool(forKey: "isPro") }

    var body: some View {
        NavigationStack {
            Group {
                if !calc.isValid {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No schedule yet",
                                   message: "Enter a valid loan in the Calculator to see its month-by-month amortization here.")
                } else if isComputing {
                    loadingState
                } else if rows.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No schedule yet",
                                   message: "Adjust your loan amount and rate to generate a schedule.")
                } else {
                    content
                }
            }
            .background(Theme.bg)
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if calc.isValid && !rows.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) { exportButton }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .onAppear { recomputeIfNeeded() }
        .onChange(of: signature) { _, _ in recomputeIfNeeded() }
    }

    // MARK: - Recompute (async so large schedules don't block the UI)

    private var signature: String {
        "\(calc.principal)|\(calc.annualRatePct)|\(calc.termMonths)|\(calc.startDate.timeIntervalSince1970)|\(calc.extraMonthly)|\(calc.extraOneTime)|\(calc.extraOneTimeMonth)|\(calc.isValid)"
    }

    private func recomputeIfNeeded() {
        let sig = signature
        guard sig != lastSignature else { return }
        lastSignature = sig
        guard calc.isValid else {
            rows = []; baseline = []
            return
        }
        let p = calc.principal, r = calc.annualRatePct, t = calc.termMonths
        let start = calc.startDate, em = calc.extraMonthly
        let eo = calc.extraOneTime, eom = calc.extraOneTimeMonth
        isComputing = true
        Task {
            let computed = await Task.detached(priority: .userInitiated) { () -> ([AmortRow], [AmortRow]) in
                let withExtra = LoanMath.schedule(principal: p, annualRatePct: r, termMonths: t,
                                                  startDate: start, extraMonthly: em,
                                                  extraOneTime: eo, extraOneTimeMonth: eom)
                let base = LoanMath.schedule(principal: p, annualRatePct: r, termMonths: t,
                                             startDate: start)
                return (withExtra, base)
            }.value
            await MainActor.run {
                self.rows = computed.0
                self.baseline = computed.1
                self.isComputing = false
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Building schedule…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                chartCard
                yearList
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text(calc.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                SectionLabel(text: "Balance over time")
                BalanceLineChart(baseline: baseline, withExtra: rows,
                                 symbol: symbol, showBaseline: calc.hasExtra)
                if calc.hasExtra, let s = calc.summary, s.monthsSaved > 0 {
                    Text("Extra payments clear this loan \(Fmt.termDescription(months: s.monthsSaved)) sooner.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.good)
                }
            }
        }
    }

    private var yearList: some View {
        let groups = YearGroup.build(from: rows)
        return VStack(spacing: 10) {
            HStack { SectionLabel(text: "By year"); Spacer() }
            ForEach(groups) { group in
                YearDisclosure(group: group, symbol: symbol)
            }
        }
    }

    // MARK: - Export

    private var exportButton: some View {
        Group {
            if isPro {
                ShareLink(item: CSVDocument(text: CSVBuilder.amortization(rows: rows, symbol: symbol),
                                            suggestedName: "\(safeFileName(calc.name))-amortization.csv"),
                          preview: SharePreview("Amortization schedule")) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Export schedule as CSV")
                }
            } else {
                Button {
                    showPaywall = true
                    Haptics.tap(enabled: settings.hapticsEnabled)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityLabel("Export schedule as CSV (Pro)")
                }
            }
        }
    }

    private func safeFileName(_ s: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = s.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let joined = String(cleaned)
        return joined.isEmpty ? "abacus" : joined
    }
}
