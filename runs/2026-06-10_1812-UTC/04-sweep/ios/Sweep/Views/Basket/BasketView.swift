import SwiftUI
import SwiftData
import Photos

struct BasketView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.modelContext) private var context
    @Query private var kept: [KeptPhoto]

    @AppStorage("confirmDelete") private var confirmDelete = true
    @State private var showConfirm = false
    @State private var isDeleting = false
    @State private var resultMessage: String?

    private let columns = [GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4),
                           GridItem(.flexible(), spacing: 4)]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if library.basket.isEmpty {
                    EmptyStateView(icon: "trash", title: "Nothing marked",
                                   message: "Photos you swipe left to clear will collect here, ready to delete in one batch.")
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(library.basket, id: \.localIdentifier) { asset in
                                    cell(asset)
                                }
                            }
                            .padding(8)
                        }
                        deleteBar
                    }
                }
            }
            .navigationTitle("To Delete")
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text("Deleting…").foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .overlay(alignment: .top) {
                if let resultMessage {
                    Text(resultMessage)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Brand.live, in: Capsule()).padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .alert("Delete \(library.basket.count) photos?", isPresented: $showConfirm) {
                Button("Delete", role: .destructive) { Task { await performDelete() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("They'll move to Recently Deleted in your Photos app, where they stay for 30 days.")
            }
        }
    }

    private func cell(_ asset: PHAsset) -> some View {
        ThumbnailView(asset: asset, targetSize: CGSize(width: 300, height: 300))
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    library.unmark(asset); Haptics.tap()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title3).foregroundStyle(.white)
                        .background(Circle().fill(.black.opacity(0.4)))
                        .padding(4)
                }
                .accessibilityLabel("Keep this photo")
            }
    }

    private var deleteBar: some View {
        VStack(spacing: 8) {
            Text("~\(Format.bytes(library.basketBytes)) will be reclaimed")
                .font(Brand.mono(13)).foregroundStyle(Brand.text2)
            Button {
                if confirmDelete { showConfirm = true } else { Task { await performDelete() } }
            } label: {
                Label("Delete \(library.basket.count) photos", systemImage: "trash.fill")
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(16)
        .background(.regularMaterial)
    }

    private func performDelete() async {
        let assets = library.basket
        let bytes = library.basketBytes
        let count = assets.count
        isDeleting = true
        let success = await library.delete(assets)
        isDeleting = false
        if success {
            context.insert(CleanSession(reviewedCount: count, deletedCount: count, bytesReclaimed: bytes))
            try? context.save()
            library.clearBasket()
            await library.scan(kept: kept.map { $0.localIdentifier })
            Haptics.success()
            withAnimation(Brand.ease()) { resultMessage = "Reclaimed ~\(Format.bytes(bytes))" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(Brand.ease()) { resultMessage = nil }
            }
        } else {
            Haptics.warning()
            withAnimation(Brand.ease()) { resultMessage = "Deletion canceled" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(Brand.ease()) { resultMessage = nil }
            }
        }
    }
}
