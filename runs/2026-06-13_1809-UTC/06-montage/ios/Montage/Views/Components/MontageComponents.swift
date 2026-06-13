import SwiftUI

/// A brief floating confirmation toast.
struct Toast: View {
    let text: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(.white)
            Text(text).font(Theme.rounded(15, .bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.ink.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

/// A schematic preview of a template's frame layout.
struct TemplatePreview: View {
    let template: MontageTemplate
    var height: CGFloat = 150

    var body: some View {
        let size = CGSize(width: height * template.aspect, height: height)
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Theme.surfaceAlt, Theme.accentSoft.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: size.width, height: size.height)
            ForEach(Array(template.frames.enumerated()), id: \.element.id) { _, frame in
                let rect = CanvasGeo.frameRect(frame, in: size, template: template)
                RoundedRectangle(cornerRadius: max(3, CanvasGeo.radius(frame, in: size)), style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: min(rect.width, rect.height) * 0.3))
                            .foregroundStyle(Theme.inkFaint))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}
