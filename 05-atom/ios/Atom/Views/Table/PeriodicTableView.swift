import SwiftUI

struct PeriodicTableView: View {
    let elements: [Element]
    var colorBlindMode: Bool = false
    var showMass: Bool = true

    @State private var selectedElement: Element? = nil
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @Environment(\.colorScheme) private var colorScheme

    private let cellW: CGFloat = 44
    private let cellH: CGFloat = 52
    private let gap: CGFloat = 2

    // Total canvas size
    private var canvasWidth: CGFloat  { (cellW + gap) * 18 + gap }
    private var canvasHeight: CGFloat { (cellH + gap) * 10 + gap }

    // MARK: - Position calculation

    func position(for element: Element) -> CGPoint? {
        let col: Int
        let row: Int

        if element.category == .lanthanide {
            // Lanthanides: row 9 (index 8), atomic 57-71 → cols 3-17
            let index = element.atomicNumber - 57
            col = index + 3
            row = 8
        } else if element.category == .actinide {
            // Actinides: row 10 (index 9), atomic 89-103 → cols 3-17
            let index = element.atomicNumber - 89
            col = index + 3
            row = 9
        } else {
            guard let grp = element.group else { return nil }
            col = grp - 1
            row = element.period - 1
        }

        let x = gap + CGFloat(col) * (cellW + gap) + cellW / 2
        let y = gap + CGFloat(row) * (cellH + gap) + cellH / 2
        return CGPoint(x: x, y: y)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let proposed = lastScale * value
                scale = min(2.5, max(0.5, proposed))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Background
                    Color.clear
                        .frame(width: canvasWidth, height: canvasHeight)

                    // Legend placeholder rows
                    lanthanidePlaceholder
                    actinidePlaceholder

                    // All element cells
                    ForEach(elements) { element in
                        if let pos = position(for: element) {
                            NavigationLink(destination: ElementDetailView(
                                element: element,
                                colorBlindMode: colorBlindMode
                            )) {
                                ElementCellView(
                                    element: element,
                                    width: cellW,
                                    height: cellH,
                                    colorBlindMode: colorBlindMode,
                                    showMass: showMass
                                )
                            }
                            .buttonStyle(.plain)
                            .position(pos)
                        }
                    }

                    // Period labels
                    ForEach(1...7, id: \.self) { period in
                        Text("P\(period)")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(AtomTheme.textTertiary)
                            .position(
                                x: gap + cellW / 2 - 28,
                                y: gap + CGFloat(period - 1) * (cellH + gap) + cellH / 2
                            )
                    }

                    // Group labels
                    ForEach(1...18, id: \.self) { group in
                        Text("\(group)")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(AtomTheme.textTertiary)
                            .position(
                                x: gap + CGFloat(group - 1) * (cellW + gap) + cellW / 2,
                                y: gap - 12
                            )
                    }
                }
                .frame(width: canvasWidth, height: canvasHeight)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: canvasWidth * scale, height: canvasHeight * scale)
            }
            .gesture(magnificationGesture.simultaneously(with: dragGesture))
            .ignoresSafeArea(edges: .bottom)
        }
        .background(AtomTheme.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.footnote)
                }
            }
        }
    }

    // MARK: - Placeholder markers for f-block

    @ViewBuilder
    private var lanthanidePlaceholder: some View {
        // Small "La–Lu" marker in period 6, groups 3 position
        let row = 5 // period 6, 0-indexed
        let col = 2 // group 3
        let x = gap + CGFloat(col) * (cellW + gap) + cellW / 2
        let y = gap + CGFloat(row) * (cellH + gap) + cellH / 2
        ZStack {
            RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                .fill(ElementCategory.lanthanide.displayColor(colorBlind: colorBlindMode).opacity(0.30))
                .overlay(
                    RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                        .stroke(AtomTheme.cellBorder, lineWidth: 1)
                )
            Text("La→Lu")
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .frame(width: cellW, height: cellH)
        .position(x: x, y: y)
    }

    @ViewBuilder
    private var actinidePlaceholder: some View {
        let row = 6 // period 7, 0-indexed
        let col = 2 // group 3
        let x = gap + CGFloat(col) * (cellW + gap) + cellW / 2
        let y = gap + CGFloat(row) * (cellH + gap) + cellH / 2
        ZStack {
            RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                .fill(ElementCategory.actinide.displayColor(colorBlind: colorBlindMode).opacity(0.30))
                .overlay(
                    RoundedRectangle(cornerRadius: AtomTheme.cellCornerRadius)
                        .stroke(AtomTheme.cellBorder, lineWidth: 1)
                )
            Text("Ac→Lr")
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .frame(width: cellW, height: cellH)
        .position(x: x, y: y)
    }
}

// MARK: - Legend

struct CategoryLegendView: View {
    var colorBlindMode: Bool = false

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ElementCategory.allCases) { cat in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cat.displayColor(colorBlind: colorBlindMode))
                        .frame(width: 16, height: 16)
                    Text(cat.rawValue)
                        .font(.caption)
                        .foregroundStyle(AtomTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        PeriodicTableView(elements: Element.all)
    }
    .preferredColorScheme(.dark)
}
