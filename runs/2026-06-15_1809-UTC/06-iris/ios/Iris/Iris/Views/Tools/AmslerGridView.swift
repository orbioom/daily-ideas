import SwiftUI

/// A Canvas-drawn Amsler grid for self-monitoring central vision.
/// Informational only — clearly not a medical exam.
struct AmslerGridView: View {
    @Environment(\.colorScheme) private var scheme

    private let steps = [
        "Wear your reading glasses if you use them.",
        "Hold your device about 14 inches (35 cm) away.",
        "Cover one eye, and look only at the centre dot.",
        "Notice the lines around it — do any look wavy, blurry, or missing?",
        "Repeat with the other eye."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                grid
                instructions
                disclaimer
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Amsler grid")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var grid: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            let cells = 20
            let step = side / CGFloat(cells)

            let lineColor = scheme == .dark ? Color(white: 0.85) : Color(white: 0.15)
            var path = Path()
            for i in 0...cells {
                let offset = CGFloat(i) * step
                // Vertical
                path.move(to: CGPoint(x: origin.x + offset, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x + offset, y: origin.y + side))
                // Horizontal
                path.move(to: CGPoint(x: origin.x, y: origin.y + offset))
                path.addLine(to: CGPoint(x: origin.x + side, y: origin.y + offset))
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 0.75)

            // Centre fixation dot.
            let center = CGPoint(x: origin.x + side / 2, y: origin.y + side / 2)
            let dotRect = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
            context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: 0x2F86B8)))
        }
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(scheme == .dark ? Color(white: 0.06) : .white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityLabel("Amsler grid: a square grid of fine lines with a dot in the centre. Cover one eye, look at the centre dot, and watch for wavy or missing lines.")
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How to use it", systemImage: "list.number")
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(Theme.rounded(13, .bold)).foregroundStyle(Theme.accent)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Theme.accentSoft))
                        .accessibilityHidden(true)
                    Text(step).font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(idx + 1): \(step)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
    }

    private var disclaimer: some View {
        Text("If any lines look wavy, blurry, dark, or missing — or if anything looks different from before — contact an eye-care professional. This is a self-check, not a diagnosis.")
            .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }
}
