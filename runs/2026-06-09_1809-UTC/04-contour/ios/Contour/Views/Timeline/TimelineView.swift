import SwiftUI
import SwiftData

struct TimelineView: View {
    @Binding var showAdd: Bool

    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]

    @State private var poseFilter: Pose? = nil

    private var filtered: [ProgressPhoto] {
        guard let poseFilter else { return photos }
        return photos.filter { $0.pose == poseFilter }
    }

    private var groups: [ContourEngine.MonthGroup] {
        ContourEngine.groupByMonth(filtered)
    }

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add photo or measurement")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if photos.isEmpty {
            ScrollView {
                EmptyStateView(icon: "camera.viewfinder",
                               title: "No photos yet",
                               message: "Capture your first progress photo to start your timeline. Everything stays on this device.")
                Button {
                    Haptics.tap()
                    showAdd = true
                } label: {
                    Label("Add your first photo", systemImage: "plus")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 32)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    poseFilterBar
                    if filtered.isEmpty {
                        EmptyStateView(icon: "line.3.horizontal.decrease.circle",
                                       title: "No \(poseFilter?.label.lowercased() ?? "") photos",
                                       message: "No photos match this pose filter yet.")
                    } else {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: group.title)
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(group.photos) { photo in
                                        NavigationLink {
                                            PhotoDetailView(photo: photo)
                                        } label: {
                                            thumbnail(photo)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var poseFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectChip(text: "All", isSelected: poseFilter == nil) {
                    Haptics.selection()
                    withAnimation(Brand.ease(0.25)) { poseFilter = nil }
                }
                ForEach(Pose.allCases) { pose in
                    SelectChip(text: pose.label, isSelected: poseFilter == pose, systemImage: pose.symbol) {
                        Haptics.selection()
                        withAnimation(Brand.ease(0.25)) { poseFilter = pose }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func thumbnail(_ photo: ProgressPhoto) -> some View {
        let label = "\(photo.pose.label) pose, \(Format.shortDay.string(from: photo.date))"
        return ZStack(alignment: .bottomLeading) {
            PhotoImageView(filename: photo.filename, accessibilityText: label)
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.45)],
                           startPoint: .center, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Image(systemName: photo.pose.symbol).font(.system(size: 9, weight: .bold))
                Text(Format.shortDay.string(from: photo.date)).font(Brand.mono(10, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(8)
            .accessibilityHidden(true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}
