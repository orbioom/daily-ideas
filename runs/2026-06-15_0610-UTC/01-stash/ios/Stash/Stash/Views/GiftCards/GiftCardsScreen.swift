import SwiftUI
import SwiftData

/// Gift Cards: a list with remaining-balance rings, expiry / depleted states, add, and
/// an empty state. Tracking gift-card balances is a Pro feature — a locked state shows
/// for free users.
struct GiftCardsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \GiftCard.createdAt, order: .reverse) private var cards: [GiftCard]

    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if !isPro {
                    lockedState
                } else if cards.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Gift Cards")
            .toolbar {
                if isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add gift card")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddGiftCardView()
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                summaryHeader
                ForEach(cards) { card in
                    NavigationLink {
                        GiftCardDetailView(card: card)
                    } label: {
                        GiftCardRow(card: card)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(card)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var summaryHeader: some View {
        let total = cards.reduce(Decimal.zero) { $0 + $1.remainingBalance }
        return CardSurface {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total remaining")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(Money.string(total))
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                Image(systemName: "giftcard.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total remaining \(Money.string(total)) across \(cards.count) gift cards")
    }

    private var emptyState: some View {
        EmptyStateView(symbol: "giftcard",
                       title: "No gift cards yet",
                       message: "Add a gift card to track its balance, log spends, and watch the remaining ring.",
                       actionTitle: "Add gift card") {
            showAdd = true
        }
    }

    private var lockedState: some View {
        VStack(spacing: 20) {
            EmptyStateView(symbol: "giftcard.fill",
                           title: "Gift-card tracking is Pro",
                           message: "Log spends against a balance, see the remaining ring, and get expiry reminders. It's part of the one-time Stash Pro unlock.")
            PrimaryButton(title: "Unlock Stash Pro · \(Pro.priceLabel)", systemImage: "crown.fill") {
                paywallReason = .giftCards
            }
            .padding(.horizontal, 32)
        }
    }

    private func delete(_ card: GiftCard) {
        context.delete(card)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}

/// A single gift-card row with a balance ring and state badges.
struct GiftCardRow: View {
    let card: GiftCard

    private var tint: Color { Color(hexString: card.colorHex, fallback: Theme.accent) }

    var body: some View {
        CardSurface {
            HStack(spacing: 14) {
                BalanceRing(fraction: card.remainingFraction,
                            lineWidth: 7,
                            label: shortRemaining)
                    .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.storeName)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text("\(Money.string(card.remainingBalance, code: card.currencyCode)) of \(Money.string(card.initialBalance, code: card.currencyCode))")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    badges
                }
                Spacer()
                Circle().fill(tint).frame(width: 12, height: 12)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.storeName), \(Money.string(card.remainingBalance, code: card.currencyCode)) remaining")
    }

    private var shortRemaining: String {
        let value = NSDecimalNumber(decimal: card.remainingBalance).doubleValue
        return value >= 1000 ? "\(Int(value / 1000))k" : "\(Int(value.rounded()))"
    }

    @ViewBuilder
    private var badges: some View {
        HStack(spacing: 6) {
            if card.isDepleted {
                StateBadge(text: "Depleted", color: Theme.bad, symbol: "checkmark.seal")
            } else if card.isExpired {
                StateBadge(text: "Expired", color: Theme.bad, symbol: "clock.badge.xmark")
            } else if card.isExpiringSoon {
                StateBadge(text: "Expiring soon", color: Theme.warn, symbol: "clock.badge.exclamationmark")
            }
        }
    }
}

/// A small colored status pill.
struct StateBadge: View {
    let text: String
    let color: Color
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 10, weight: .bold))
                    .accessibilityHidden(true)
            }
            Text(text).font(Theme.rounded(11, .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.15)))
    }
}
