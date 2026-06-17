import SwiftUI

struct KitsView: View {
    @Environment(SequencerStore.self) private var store
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var toast: ToastMessage?
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(KitLibrary.all) { kit in
                                KitCard(
                                    kit: kit,
                                    isSelected: store.kitID == kit.id,
                                    isLocked: kit.requiresPro && !isPro,
                                    isLoading: store.audio.isLoadingKit && store.kitID == kit.id
                                ) { select(kit) }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Kits")
            .toast($toast)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var header: some View {
        PanelCard {
            HStack(spacing: 14) {
                Image(systemName: store.kit.symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color(hex: store.kit.swatch)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Now playing")
                        .font(Theme.rounded(12, .heavy))
                        .tracking(1)
                        .foregroundStyle(Theme.inkSoft)
                    Text(store.kit.name)
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(store.kit.tagline)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Current kit: \(store.kit.name). \(store.kit.tagline)"))
    }

    private func select(_ kit: Kit) {
        if kit.requiresPro && !isPro {
            Haptics.warning(settings.hapticsEnabled)
            showPaywall = true
            return
        }
        guard kit.id != store.kitID else { return }
        store.selectKit(kit.id)
        Haptics.success(settings.hapticsEnabled)
        toast = ToastMessage(text: "Loaded \(kit.name)", symbol: "checkmark.circle.fill")
    }
}

private struct KitCard: View {
    let kit: Kit
    let isSelected: Bool
    let isLocked: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(Color(hex: kit.swatch))
                            .frame(width: 46, height: 46)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: isLocked ? "lock.fill" : kit.symbol)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    } else if isLocked {
                        ProBadge()
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(kit.name)
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(kit.tagline)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(kit.name)\(isLocked ? ", locked, Pro" : "")\(isSelected ? ", selected" : "")"))
        .accessibilityHint(Text(isLocked ? "Unlock Pro to use this kit" : "Selects this kit and reloads sounds"))
    }
}
