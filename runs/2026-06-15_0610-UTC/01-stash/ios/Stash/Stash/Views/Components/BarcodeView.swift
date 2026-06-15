import SwiftUI

/// Renders a scannable barcode for a value + format, choosing the right backend:
/// the hand-rolled EAN-13/UPC-A Canvas renderer, or a Core Image generator. Shows a
/// calm error state when the value can't be encoded.
struct BarcodeView: View {
    let value: String
    let format: BarcodeFormat
    /// Total height of the symbol area.
    var height: CGFloat = 150
    /// Show the raw / formatted human-readable value under the symbol.
    var showCaption: Bool = true

    var body: some View {
        switch BarcodeFactory.validate(value, format: format) {
        case .failure(let error):
            errorState(error)
        case .success(let normalized):
            content(normalized: normalized)
        }
    }

    @ViewBuilder
    private func content(normalized: String) -> some View {
        VStack(spacing: 10) {
            symbol(normalized: normalized)
            if showCaption {
                Text(BarcodeFactory.displayValue(for: value, format: format))
                    .font(Theme.mono(15, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func symbol(normalized: String) -> some View {
        switch format {
        case .ean13, .upca:
            EAN13BarcodeView(normalizedEAN13: normalized, height: height)
                .accessibilityElement()
                .accessibilityLabel("Barcode")
                .accessibilityValue(BarcodeFactory.displayValue(for: value, format: format))
        case .code128, .pdf417, .qr, .aztec:
            coreImageSymbol(normalized: normalized)
        }
    }

    @ViewBuilder
    private func coreImageSymbol(normalized: String) -> some View {
        if let image = BarcodeFactory.coreImage(for: normalized, format: format) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: format.isLinear ? height : min(height * 1.6, 240))
                .accessibilityElement()
                .accessibilityLabel("\(format.displayName) code")
                .accessibilityValue(value)
        } else {
            errorState(.renderFailed)
        }
    }

    private func errorState(_ error: BarcodeError) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 34))
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
            Text(error.message)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.horizontal, 16)
    }
}

/// Draws an EAN-13 / UPC-A symbol from the hand-rolled 95-module bit pattern using a
/// `Canvas`. Bars are drawn at exact module widths so the result stays crisp at any
/// size, with the guard bars extending slightly lower like a printed symbol.
struct EAN13BarcodeView: View {
    /// A normalized 13-digit string (UPC-A is passed as its EAN-13 equivalent).
    let normalizedEAN13: String
    var height: CGFloat = 150

    var body: some View {
        Canvas { context, size in
            guard let modules = EAN13Encoder.modules(forEAN13: normalizedEAN13),
                  modules.count == 95 else { return }

            // Reserve quiet zones on both sides (~7 modules each side is standard).
            let quiet: CGFloat = 7
            let totalModules = CGFloat(modules.count) + quiet * 2
            let moduleWidth = size.width / totalModules
            guard moduleWidth > 0 else { return }

            let guardExtra = height * 0.06
            let barHeight = size.height - guardExtra

            for (index, isDark) in modules.enumerated() where isDark {
                let x = (quiet + CGFloat(index)) * moduleWidth
                let isGuard = EAN13Encoder.isGuardModule(index)
                let rect = CGRect(x: x,
                                  y: 0,
                                  width: moduleWidth,
                                  height: isGuard ? barHeight + guardExtra : barHeight)
                context.fill(Path(rect), with: .color(.black))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.horizontal, 6)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
