import SwiftUI
import SwiftData

/// Wishlist items you're eyeing, with "mark as acquired" to flip status to owned.
/// (Decants are juice you already own, so they live in the Collection tab.)
struct WishlistScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Fragrance.addedAt, order: .reverse) private var allFragrances: [Fragrance]

    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?

    private var wishlist: [Fragrance] {
        allFragrances.filter { $0.status == .wishlist }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Wishlist")
            .navigationDestination(for: Fragrance.self) { f in
                FragranceDetailView(fragrance: f)
            }
            .sheet(isPresented: $showAdd) {
                FragranceEditorView(defaultStatus: .wishlist)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if wishlist.isEmpty {
            EmptyStateView(symbol: "heart",
                           title: "No wishlist yet",
                           message: "Save the bottles you're eyeing. When one arrives, mark it acquired and it moves straight into your collection.",
                           actionTitle: "Add to wishlist") { startAdd() }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(wishlist) { f in
                        wishRow(f)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
        }
    }

    private func wishRow(_ f: Fragrance) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: f) {
                HStack(spacing: 12) {
                    JuiceSwatch(family: f.primaryFamily, colorHue: f.colorHue, size: 56)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(f.house.uppercased())
                            .font(Theme.rounded(10, .bold))
                            .foregroundStyle(Theme.inkFaint)
                        Text(f.name)
                            .font(Theme.serif(17, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(f.concentration.rawValue)
                                .font(Theme.rounded(11, .bold))
                                .foregroundStyle(Theme.accent)
                            if !settings.hidePrices && f.pricePaid > 0 {
                                Text("· ~\(settings.formatMoney(f.pricePaid))")
                                    .font(Theme.rounded(11))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                acquire(f)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 18))
                    Text("Acquired").font(Theme.rounded(9, .semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 62, height: 54)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.good))
            }
            .accessibilityLabel("Mark \(f.name) as acquired")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .swipeActions {
            Button(role: .destructive) {
                delete(f)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private var addButton: some View {
        Button {
            startAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add to wishlist")
    }

    private func startAdd() {
        if Pro.canAdd(currentCount: allFragrances.count, isPro: isPro) {
            showAdd = true
            Haptics.tap(settings.hapticsEnabled)
        } else {
            paywallReason = .collectionLimit
            Haptics.warning(settings.hapticsEnabled)
        }
    }

    private func acquire(_ f: Fragrance) {
        f.status = .owned
        if f.bottlesOwned < 1 { f.bottlesOwned = 1 }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func delete(_ f: Fragrance) {
        context.delete(f)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
