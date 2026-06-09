import SwiftUI
import SwiftData

struct CompareView: View {
    @Query(sort: \ProgressPhoto.date) private var photos: [ProgressPhoto]
    @AppStorage("contour.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("contour.defaultPose") private var defaultPoseRaw = Pose.front.rawValue

    @State private var pose: Pose = .front
    @State private var beforeID: PersistentIdentifier?
    @State private var afterID: PersistentIdentifier?

    private var weightUnit: WeightUnit { WeightUnit(rawValue: weightUnitRaw) ?? .kg }

    private var poolForPose: [ProgressPhoto] {
        photos.filter { $0.pose == pose && $0.hasImage }.sorted { $0.date < $1.date }
    }

    private var beforePhoto: ProgressPhoto? {
        if let beforeID, let p = poolForPose.first(where: { $0.persistentModelID == beforeID }) { return p }
        return poolForPose.first
    }

    private var afterPhoto: ProgressPhoto? {
        if let afterID, let p = poolForPose.first(where: { $0.persistentModelID == afterID }) { return p }
        return poolForPose.last
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                content
            }
            .navigationTitle("Compare")
            .onAppear {
                pose = Pose(rawValue: defaultPoseRaw) ?? .front
                resetSelection()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                poseBar
                if poolForPose.count < 2 {
                    EmptyStateView(icon: "rectangle.split.2x1",
                                   title: "Need two photos",
                                   message: "Add at least two \(pose.label.lowercased()) photos to compare your before and after.")
                } else {
                    comparison
                    selectors
                }
            }
            .padding(16)
        }
    }

    private var poseBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Pose.allCases) { p in
                    SelectChip(text: p.label, isSelected: pose == p, systemImage: p.symbol) {
                        Haptics.selection()
                        withAnimation(Brand.ease(0.25)) {
                            pose = p
                            resetSelection()
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var comparison: some View {
        if let before = beforePhoto, let after = afterPhoto {
            let days = ContourEngine.daysBetween(before.date, after.date)
            let weightDelta: Double? = {
                guard let a = before.weightAtTime, let b = after.weightAtTime else { return nil }
                return b - a
            }()

            HStack(alignment: .top, spacing: 12) {
                comparePane(title: "Before", photo: before)
                comparePane(title: "After", photo: after)
            }

            GlassCard {
                VStack(spacing: 12) {
                    HStack {
                        Eyebrow(text: "Time between")
                        Spacer()
                        Text(Format.days(days))
                            .font(Brand.mono(16, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    if let weightDelta {
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Eyebrow(text: "Weight change")
                            Spacer()
                            Text("\(Units.signed(Units.kgToDisplay(weightDelta, unit: weightUnit))) \(weightUnit.short)")
                                .font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(weightDelta < 0 ? Brand.live : (weightDelta > 0 ? Brand.warn : Brand.text))
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func comparePane(title: String, photo: ProgressPhoto) -> some View {
        VStack(spacing: 6) {
            Eyebrow(text: title)
            PhotoImageView(filename: photo.filename,
                           accessibilityText: "\(title), \(pose.label) pose, \(Format.shortDay.string(from: photo.date))")
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(Format.shortDay.string(from: photo.date))
                .font(Brand.mono(12, weight: .medium))
                .foregroundStyle(Brand.text2)
        }
    }

    private var selectors: some View {
        VStack(spacing: 14) {
            picker(title: "Before", selection: Binding(
                get: { beforePhoto?.persistentModelID },
                set: { beforeID = $0; Haptics.selection() }
            ))
            picker(title: "After", selection: Binding(
                get: { afterPhoto?.persistentModelID },
                set: { afterID = $0; Haptics.selection() }
            ))
        }
    }

    private func picker(title: String, selection: Binding<PersistentIdentifier?>) -> some View {
        GlassCard(padding: 12) {
            Picker(title, selection: selection) {
                ForEach(poolForPose) { p in
                    Text(Format.shortDayYear.string(from: p.date))
                        .tag(Optional(p.persistentModelID))
                }
            }
            .pickerStyle(.menu)
            .tint(Brand.text)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func resetSelection() {
        beforeID = poolForPose.first?.persistentModelID
        afterID = poolForPose.last?.persistentModelID
    }
}
