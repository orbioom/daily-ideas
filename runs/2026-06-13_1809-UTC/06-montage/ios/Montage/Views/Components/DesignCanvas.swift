import SwiftUI

enum CanvasGeo {
    /// Pixel rect for a normalized frame inside a canvas of `size`, honoring inset & spacing.
    static func frameRect(_ frame: Frame, in size: CGSize, template: MontageTemplate) -> CGRect {
        let pad = template.inset * size.width
        let content = CGRect(x: pad, y: pad, width: size.width - 2 * pad, height: size.height - 2 * pad)
        let gap = template.spacing * size.width / 2
        return CGRect(x: content.minX + frame.rect.minX * content.width + gap,
                      y: content.minY + frame.rect.minY * content.height + gap,
                      width: max(1, frame.rect.width * content.width - 2 * gap),
                      height: max(1, frame.rect.height * content.height - 2 * gap))
    }

    /// Scale corner radii relative to a reference canvas width.
    static func radius(_ frame: Frame, in size: CGSize) -> CGFloat {
        frame.cornerRadius * (size.width / 400)
    }
}

/// Renders a montage at a given size. Used for both the live preview and export.
struct DesignCanvas: View {
    let design: DesignVM
    let size: CGSize
    var interactive: Bool = false
    var renderText: Bool = true
    var onTapSlot: ((Int) -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            design.background.fill
                .frame(width: size.width, height: size.height)

            ForEach(Array(design.template.frames.enumerated()), id: \.element.id) { index, frame in
                slot(index: index, frame: frame)
            }

            if renderText {
                ForEach(design.texts) { overlay in
                    textView(overlay)
                        .position(x: overlay.x * size.width, y: overlay.y * size.height)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    @ViewBuilder private func slot(index: Int, frame: Frame) -> some View {
        let rect = CanvasGeo.frameRect(frame, in: size, template: design.template)
        let radius = CanvasGeo.radius(frame, in: size)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Group {
            if let image = design.photos[index] {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: rect.width, height: rect.height)
                    .clipShape(shape)
            } else {
                shape.fill(Color.black.opacity(0.06))
                    .overlay(shape.strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                        .foregroundStyle(.white.opacity(0.8)))
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "photo.badge.plus").font(.system(size: min(rect.width, rect.height) * 0.18))
                            if interactive && rect.height > 60 {
                                Text("Add").font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    )
                    .frame(width: rect.width, height: rect.height)
            }
        }
        .frame(width: rect.width, height: rect.height)
        .contentShape(shape)
        .position(x: rect.midX, y: rect.midY)
        .onTapGesture { if interactive { onTapSlot?(index) } }
    }

    private func textView(_ overlay: TextOverlay) -> some View {
        Text(overlay.text.isEmpty ? " " : overlay.text)
            .font(overlay.weight.font(size: overlay.fontScale * size.height))
            .foregroundStyle(overlay.color)
            .multilineTextAlignment(.center)
            .shadow(color: overlay.hasShadow ? .black.opacity(0.35) : .clear, radius: 3, y: 1)
            .frame(maxWidth: size.width * 0.92)
            .fixedSize(horizontal: false, vertical: true)
    }
}
