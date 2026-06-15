import SwiftUI

/// Accessible, non-visual way to color: pick a color, then tap a region row to fill it.
/// This makes the visual tap-canvas fully usable with VoiceOver.
struct RegionListView: View {
    @ObservedObject var model: ColoringViewModel
    var hapticsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    colorPicker
                } header: {
                    Text("Selected color")
                }

                Section {
                    ForEach(model.page.regions) { region in
                        regionRow(region)
                    }
                } header: {
                    Text("Regions")
                } footer: {
                    Text("Tap a region to fill it with color #\(model.selectedColorIndex + 1). In color-by-number mode only the matching color is accepted.")
                }
            }
            .navigationTitle("Regions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(model.palette.colors.enumerated()), id: \.offset) { index, color in
                    Button {
                        model.selectColor(index)
                    } label: {
                        ZStack {
                            Circle().fill(color).frame(width: 38, height: 38)
                                .overlay(Circle().strokeBorder(Theme.hairline))
                            Text("\(index + 1)").font(Theme.rounded(12, .bold))
                                .foregroundStyle(.white)
                                .shadow(radius: 1)
                        }
                        .overlay(Circle().strokeBorder(Theme.accent,
                                                       lineWidth: index == model.selectedColorIndex ? 3 : 0)
                            .frame(width: 46, height: 46))
                        .frame(width: 48, height: 48)
                    }
                    .accessibilityLabel("Color number \(index + 1)")
                    .accessibilityAddTraits(index == model.selectedColorIndex ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func regionRow(_ region: Region) -> some View {
        let filled = model.fills[region.id]
        let fillColor = filled.flatMap { Color(hexString: $0) }
        return Button {
            model.fill(region: region, hapticsEnabled: hapticsEnabled)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(fillColor ?? Theme.surfaceAlt)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().strokeBorder(Theme.hairline))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Region \(region.id + 1)")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.ink)
                    Text(filled == nil ? "Empty • wants #\(region.suggestedColorIndex + 1)"
                                       : "Filled")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if filled != nil {
                    Button {
                        model.clearRegion(region.id, hapticsEnabled: hapticsEnabled)
                    } label: {
                        Image(systemName: "eraser")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Clear region \(region.id + 1)")
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Region \(region.id + 1), \(filled == nil ? "empty, suggests color number \(region.suggestedColorIndex + 1)" : "filled")")
        .accessibilityHint("Fills with color number \(model.selectedColorIndex + 1)")
    }
}
