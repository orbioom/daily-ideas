import SwiftUI

/// A small line-art preview of a template's cell arrangement.
struct TemplateThumb: View {
    let template: Template
    var selected: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                ForEach(Array(template.frames.enumerated()), id: \.offset) { _, f in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(selected ? Brand.dynamic(0xB0653E, 0xE0A878) : Brand.text3)
                        .frame(width: f.width * geo.size.width - 6,
                               height: f.height * geo.size.height - 6)
                        .offset(x: f.minX * geo.size.width + 3, y: f.minY * geo.size.height + 3)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(selected ? Brand.dynamic(0xB0653E, 0xE0A878) : Brand.hairline,
                              lineWidth: selected ? 2 : 1))
        }
        .accessibilityHidden(true)
    }
}

/// A filtered thumbnail for the filter picker. Filters a downscaled copy so the
/// row stays smooth.
struct FilterThumb: View {
    let image: UIImage
    let filter: PhotoFilter
    @State private var rendered: UIImage?

    var body: some View {
        ZStack {
            if let rendered {
                Image(uiImage: rendered).resizable().scaledToFill()
            } else {
                Rectangle().fill(Brand.hairline)
            }
        }
        .onAppear {
            let small = ImageStore.downscale(image, maxDimension: 140)
            rendered = FilterEngine.apply(filter, to: small)
        }
        .accessibilityHidden(true)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
    }
}
