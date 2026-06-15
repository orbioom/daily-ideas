import SwiftUI

/// Renders a paper template using a SwiftUI `Canvas`. Drawn behind the
/// transparent `PKCanvasView`.
struct PaperBackground: View {
    let template: PaperTemplate

    var body: some View {
        Canvas { context, size in
            var ctx = context
            PaperRenderer.draw(
                in: &ctx,
                size: size,
                template: template,
                lineColor: Theme.paperLine
            )
        }
        .background(Theme.paperColor)
        .accessibilityHidden(true)
    }
}
