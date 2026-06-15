import SwiftUI
import SwiftData

/// Gift-card detail: big ring + remaining balance, barcode, log-a-spend, and the
/// transaction history. Brightness boosts while shown so the code scans.
struct GiftCardDetailView: View {
    @Bindable var card: GiftCard
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var showSpend = false
    @State private var showDeleteConfirm = false

    private var sortedTransactions: [BalanceTransaction] {
        card.transactions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ringHeader
                if !card.code.trimmingCharacters(in: .whitespaces).isEmpty {
                    barcodePanel
                }
                logSpendButton
                statePanel
                historyPanel
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(card.storeName)
        .navigationBarTitleDisplayMode(.inline)
        .brightnessBoost(settings.brightnessBoost && !card.code.trimmingCharacters(in: .whitespaces).isEmpty)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete gift card")
            }
        }
        .sheet(isPresented: $showSpend) {
            LogSpendView(card: card)
        }
        .confirmationDialog("Delete this gift card?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCard() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(card.storeName) and its spend history.")
        }
    }

    private var ringHeader: some View {
        CardSurface(padding: 20) {
            VStack(spacing: 14) {
                ZStack {
                    BalanceRing(fraction: card.remainingFraction, lineWidth: 12)
                        .frame(width: 150, height: 150)
                    VStack(spacing: 2) {
                        Text(Money.string(card.remainingBalance, code: card.currencyCode))
                            .font(Theme.rounded(24, .bold))
                            .foregroundStyle(Theme.ink)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("remaining")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Started with \(Money.string(card.initialBalance, code: card.currencyCode)) · spent \(Money.string(card.totalSpent, code: card.currencyCode))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Money.string(card.remainingBalance, code: card.currencyCode)) remaining of \(Money.string(card.initialBalance, code: card.currencyCode))")
    }

    private var barcodePanel: some View {
        CardSurface(padding: 18) {
            BarcodeView(value: card.code, format: card.format,
                        height: card.format.isLinear ? 130 : 180)
                .frame(maxWidth: .infinity)
        }
    }

    private var logSpendButton: some View {
        PrimaryButton(title: "Log a spend",
                      systemImage: "minus.circle",
                      enabled: !card.isDepleted) {
            showSpend = true
        }
    }

    @ViewBuilder
    private var statePanel: some View {
        if card.isDepleted || card.isExpired || card.isExpiringSoon || card.expiryDate != nil {
            CardSurface {
                VStack(alignment: .leading, spacing: 8) {
                    if card.isDepleted {
                        stateLine("Balance fully used", Theme.bad, "checkmark.seal.fill")
                    }
                    if card.isExpired {
                        stateLine("Expired \(expiryString)", Theme.bad, "clock.badge.xmark.fill")
                    } else if card.isExpiringSoon {
                        stateLine("Expires \(expiryString)", Theme.warn, "clock.badge.exclamationmark.fill")
                    } else if let _ = card.expiryDate {
                        stateLine("Expires \(expiryString)", Theme.inkSoft, "calendar")
                    }
                }
            }
        }
    }

    private func stateLine(_ text: String, _ color: Color, _ symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.rounded(14, .medium))
            .foregroundStyle(color)
    }

    private var expiryString: String {
        guard let date = card.expiryDate else { return "" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var historyPanel: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Spend history", symbol: "list.bullet")
                if sortedTransactions.isEmpty {
                    Text("No spends logged yet. Tap “Log a spend” after you use this card.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                } else {
                    ForEach(sortedTransactions) { tx in
                        transactionRow(tx)
                        if tx.id != sortedTransactions.last?.id {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
            }
        }
    }

    private func transactionRow(_ tx: BalanceTransaction) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.note.isEmpty ? "Spend" : tx.note)
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.ink)
                Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Text("−" + Money.string(tx.amount, code: card.currencyCode))
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.bad)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                deleteTransaction(tx)
            } label: {
                Label("Delete spend", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tx.note.isEmpty ? "Spend" : tx.note), \(Money.string(tx.amount, code: card.currencyCode)) on \(tx.date.formatted(date: .abbreviated, time: .omitted))")
    }

    // MARK: Actions

    private func deleteTransaction(_ tx: BalanceTransaction) {
        card.transactions.removeAll { $0.id == tx.id }
        context.delete(tx)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }

    private func deleteCard() {
        context.delete(card)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }
}
