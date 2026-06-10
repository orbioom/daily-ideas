import SwiftUI
import SwiftData
import Photos

struct SwipeDeckView: View {
    let group: PhotoGroup
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var dragOffset: CGSize = .zero
    @State private var history: [(asset: PHAsset, kept: Bool)] = []

    private var assets: [PHAsset] { group.assets }
    private var current: PHAsset? { index < assets.count ? assets[index] : nil }
    private var next: PHAsset? { index + 1 < assets.count ? assets[index + 1] : nil }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 16) {
                progressBar
                if let current {
                    deck(current: current)
                    controls(for: current)
                } else {
                    completion
                }
            }
            .padding(16)
        }
        .navigationTitle(group.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { undo() } label: { Image(systemName: "arrow.uturn.backward") }
                    .disabled(history.isEmpty)
                    .accessibilityLabel("Undo last decision")
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(min(index + 1, assets.count)) of \(assets.count)")
                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                Spacer()
                Label("\(library.basket.count)", systemImage: "trash")
                    .font(Brand.mono(13)).foregroundStyle(Brand.danger)
            }
            ProgressView(value: Double(min(index, assets.count)), total: Double(max(assets.count, 1)))
                .tint(Brand.info)
        }
    }

    private func deck(current: PHAsset) -> some View {
        ZStack {
            if let next {
                cardImage(next)
                    .scaleEffect(0.94)
                    .opacity(0.6)
            }
            cardImage(current)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 22)))
                .overlay(decisionBadge)
                .gesture(reduceMotion ? nil : dragGesture)
                .animation(Brand.ease(0.3), value: dragOffset)
        }
        .frame(maxHeight: .infinity)
    }

    private func cardImage(_ asset: PHAsset) -> some View {
        ThumbnailView(asset: asset, targetSize: CGSize(width: 1000, height: 1000))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .overlay(alignment: .bottomLeading) {
                if asset.mediaType == .video {
                    Label(durationText(asset), systemImage: "video.fill")
                        .font(Brand.mono(12, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.black.opacity(0.5), in: Capsule())
                        .padding(12)
                }
            }
            .shadow(color: Brand.cardShadow, radius: 16, y: 10)
    }

    @ViewBuilder private var decisionBadge: some View {
        let keeping = dragOffset.width > 0
        let strength = min(1, abs(dragOffset.width) / 120)
        if abs(dragOffset.width) > 12 {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill((keeping ? Brand.live : Brand.danger).opacity(0.18 * strength))
                .overlay(alignment: keeping ? .topLeading : .topTrailing) {
                    Text(keeping ? "KEEP" : "CLEAR")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(keeping ? Brand.live : Brand.danger)
                        .padding(10)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(keeping ? Brand.live : Brand.danger, lineWidth: 3))
                        .rotationEffect(.degrees(keeping ? -12 : 12))
                        .opacity(strength)
                        .padding(24)
                }
                .allowsHitTesting(false)
        }
    }

    private func controls(for current: PHAsset) -> some View {
        HStack(spacing: 22) {
            decisionButton(icon: "trash.fill", color: Brand.danger, label: "Clear") { decide(keep: false) }
            decisionButton(icon: "heart.fill", color: Brand.live, label: "Keep") { decide(keep: true) }
        }
        .padding(.bottom, 6)
    }

    private func decisionButton(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2).foregroundStyle(color)
                    .frame(width: 64, height: 64)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(color.opacity(0.5), lineWidth: 1.5))
                Text(label).font(Brand.mono(11)).foregroundStyle(Brand.text2)
            }
        }
        .accessibilityLabel(label)
    }

    private var completion: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56, weight: .light)).foregroundStyle(Brand.live)
            Text("Group reviewed").font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Text(library.basket.isEmpty
                 ? "You kept everything here. Nicely tidy."
                 : "\(library.basket.count) photos are waiting in To Delete. Review and remove them when ready.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            if !library.basket.isEmpty {
                Text("~\(Format.bytes(library.basketBytes)) to reclaim")
                    .font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.live)
            }
        }
        .padding(24)
        .frame(maxHeight: .infinity)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation }
            .onEnded { value in
                if value.translation.width > 110 {
                    decide(keep: true)
                } else if value.translation.width < -110 {
                    decide(keep: false)
                } else {
                    withAnimation(Brand.ease(0.3)) { dragOffset = .zero }
                }
            }
    }

    private func decide(keep: Bool) {
        guard let asset = current else { return }
        if keep {
            let record = KeptPhoto(localIdentifier: asset.localIdentifier)
            context.insert(record)
            try? context.save()
            Haptics.selection()
        } else {
            library.mark(asset)
            Haptics.tap()
        }
        history.append((asset, keep))
        withAnimation(reduceMotion ? nil : Brand.ease(0.25)) {
            dragOffset = .zero
            index += 1
        }
    }

    private func undo() {
        guard let last = history.popLast() else { return }
        if last.kept {
            // remove the persisted KeptPhoto
            let id = last.asset.localIdentifier
            let descriptor = FetchDescriptor<KeptPhoto>(predicate: #Predicate { $0.localIdentifier == id })
            if let record = try? context.fetch(descriptor).first {
                context.delete(record)
                try? context.save()
            }
        } else {
            library.unmark(last.asset)
        }
        withAnimation(Brand.ease(0.25)) { index = max(0, index - 1) }
        Haptics.tap()
    }

    private func durationText(_ asset: PHAsset) -> String {
        let total = Int(asset.duration.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
