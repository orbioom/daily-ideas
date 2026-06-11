import SwiftUI

struct PoseLibraryView: View {
    @State private var selectedCategory: PoseCategory? = nil
    @State private var searchText = ""
    @State private var selectedPose: YogaPose? = nil

    private var filteredPoses: [YogaPose] {
        var poses = YogaPose.catalog
        if let cat = selectedCategory { poses = poses.filter { $0.category == cat } }
        if !searchText.isEmpty {
            poses = poses.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sanskrit.localizedCaseInsensitiveContains(searchText)
            }
        }
        return poses.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryFilter
                    .padding(.vertical, 8)
                    .background(FlowTheme.bg)

                if filteredPoses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.yoga")
                            .font(.system(size: 56))
                            .foregroundStyle(FlowTheme.subtle.opacity(0.4))
                            .accessibilityHidden(true)
                        Text("No poses found")
                            .foregroundStyle(FlowTheme.subtle)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredPoses) { pose in
                        PoseRow(pose: pose)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedPose = pose }
                    }
                    .scrollContentBackground(.hidden)
                    .background(FlowTheme.bg)
                }
            }
            .background(FlowTheme.bg)
            .navigationTitle("Pose Library")
            .searchable(text: $searchText, prompt: "Search poses")
            .sheet(item: $selectedPose) { pose in
                PoseDetailSheet(pose: pose)
            }
        }
    }

    @ViewBuilder
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill2(label: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(PoseCategory.allCases, id: \.self) { cat in
                    FilterPill2(label: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct FilterPill2: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? FlowTheme.sage : FlowTheme.card)
                .foregroundStyle(isSelected ? .white : FlowTheme.text)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct PoseRow: View {
    let pose: YogaPose
    var body: some View {
        HStack(spacing: 12) {
            Text(pose.emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(FlowTheme.sage.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(pose.name).font(.subheadline.weight(.medium)).foregroundStyle(FlowTheme.text)
                Text(pose.sanskrit).font(.caption.italic()).foregroundStyle(FlowTheme.subtle)
            }
            Spacer()
            Text(pose.category.rawValue)
                .font(.caption2)
                .foregroundStyle(FlowTheme.sage)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(FlowTheme.sage.opacity(0.15), in: Capsule())
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pose.name), \(pose.sanskrit), \(pose.category.rawValue)")
    }
}

struct PoseDetailSheet: View {
    let pose: YogaPose
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(pose.emoji).font(.system(size: 64)).accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(pose.name).font(.title2.weight(.bold)).foregroundStyle(FlowTheme.text)
                            Text(pose.sanskrit).font(.subheadline.italic()).foregroundStyle(FlowTheme.subtle)
                            Text(pose.category.rawValue)
                                .font(.caption.weight(.medium)).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(FlowTheme.sage, in: Capsule())
                        }
                    }

                    Text(pose.breathCue)
                        .font(.body.italic())
                        .foregroundStyle(FlowTheme.sage)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FlowTheme.sage.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions").font(.headline).foregroundStyle(FlowTheme.text)
                        ForEach(pose.instructions.indices, id: \.self) { i in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)").font(.caption.weight(.bold)).foregroundStyle(FlowTheme.sage)
                                    .frame(width: 20).padding(.top, 1)
                                Text(pose.instructions[i]).font(.body).foregroundStyle(FlowTheme.text)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benefits").font(.headline).foregroundStyle(FlowTheme.text)
                        ForEach(pose.benefits, id: \.self) { benefit in
                            Label(benefit, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(FlowTheme.text)
                        }
                    }
                }
                .padding()
            }
            .background(FlowTheme.bg)
            .navigationTitle(pose.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
