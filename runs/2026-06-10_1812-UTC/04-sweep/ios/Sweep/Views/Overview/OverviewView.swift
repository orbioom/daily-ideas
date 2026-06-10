import SwiftUI
import UIKit
import SwiftData
import Photos

struct OverviewView: View {
    @EnvironmentObject private var library: PhotoLibraryService
    @Environment(\.modelContext) private var context
    @Query private var kept: [KeptPhoto]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                switch library.status {
                case .authorized, .limited:
                    authorizedContent
                case .notDetermined:
                    permissionPrompt
                default:
                    deniedPrompt
                }
            }
            .navigationTitle("Sweep")
            .navigationDestination(for: PhotoGroup.self) { group in
                SwipeDeckView(group: group)
            }
            .toolbar {
                if library.isAuthorized {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { Task { await rescan() } } label: { Image(systemName: "arrow.clockwise") }
                            .disabled(library.isScanning)
                            .accessibilityLabel("Rescan library")
                    }
                }
            }
            .task { await initialLoad() }
        }
    }

    @ViewBuilder private var authorizedContent: some View {
        if library.isScanning && library.groups.isEmpty {
            VStack(spacing: 16) {
                ProgressView().tint(Brand.text2)
                Text("Scanning your library…").font(.subheadline).foregroundStyle(Brand.text2)
            }
        } else if library.groups.isEmpty {
            EmptyStateView(icon: "checkmark.seal.fill", title: "All clear",
                           message: "There's nothing left to review right now. New photos will show up here over time.")
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    ForEach(library.groups) { group in
                        NavigationLink(value: group) { groupCard(group) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryStat("\(library.totalPhotos)", "Photos", "photo")
            Divider().frame(height: 40).background(Brand.hairline)
            summaryStat("\(library.totalVideos)", "Videos", "video")
            Divider().frame(height: 40).background(Brand.hairline)
            summaryStat(Format.bytes(library.estimatedLibraryBytes), "Approx.", "internaldrive")
        }
        .glassCard()
    }

    private func summaryStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.callout).foregroundStyle(Brand.info)
            Text(value).font(Brand.mono(17, weight: .semibold)).foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private func groupCard(_ group: PhotoGroup) -> some View {
        HStack(spacing: 14) {
            ZStack {
                if let cover = group.cover {
                    ThumbnailView(asset: cover, targetSize: CGSize(width: 200, height: 200))
                } else {
                    Rectangle().fill(Brand.mist2)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: group.kind.icon).font(.caption).foregroundStyle(Brand.info)
                    Text(group.title).font(.headline).foregroundStyle(Brand.text)
                }
                Text("\(group.count) items · ~\(Format.bytes(group.estimatedBytes))")
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.title), \(group.count) items, about \(Format.bytes(group.estimatedBytes))")
    }

    private var permissionPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52, weight: .light)).foregroundStyle(Brand.info)
            Text("Let Sweep see your photos")
                .font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Text("Sweep needs access to your library to find clutter. It never uploads anything — everything stays on your device.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            Button("Grant access") {
                Task {
                    await library.requestAccess()
                    await rescan()
                }
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(32)
    }

    private var deniedPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 52, weight: .light)).foregroundStyle(Brand.warn)
            Text("Access is turned off")
                .font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Text("To use Sweep, allow photo access in the Settings app under Privacy.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(32)
    }

    private func initialLoad() async {
        library.refreshStatus()
        if library.isAuthorized && library.groups.isEmpty {
            await rescan()
        }
    }

    private func rescan() async {
        await library.scan(kept: kept.map { $0.localIdentifier })
    }
}
