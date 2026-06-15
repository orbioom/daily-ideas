import SwiftUI

/// A lightweight horizontal-swipe action row for use inside LazyVStack
/// (where native List `.swipeActions` is unavailable). Reveals trailing
/// actions; respects Reduce Motion via simple animation.
struct SwipeRow<Content: View>: View {
    var favorite: () -> Void
    var isFavorite: Bool
    var archive: () -> Void
    var delete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @GestureState private var dragging: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let actionWidth: CGFloat = 64
    private var revealWidth: CGFloat { actionWidth * 3 + 12 }

    var body: some View {
        ZStack(alignment: .trailing) {
            actionButtons
            content()
                .offset(x: offset + dragging)
                .gesture(dragGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: offset)
    }

    private var actionButtons: some View {
        HStack(spacing: 6) {
            actionButton(
                title: isFavorite ? "Unfav" : "Fav",
                icon: isFavorite ? "heart.slash.fill" : "heart.fill",
                tint: Theme.accent
            ) { favorite(); close() }

            actionButton(title: "Archive", icon: "archivebox.fill", tint: Theme.warn) {
                archive()
            }

            actionButton(title: "Delete", icon: "trash.fill", tint: Theme.bad) {
                delete()
            }
        }
        .padding(.trailing, 4)
        .opacity(offset < -8 ? 1 : 0)
    }

    private func actionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(tint, in: RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        }
        .accessibilityLabel(title)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16)
            .updating($dragging) { value, state, _ in
                // Only allow leftward drag, clamp.
                let translation = value.translation.width
                if offset == 0 {
                    state = min(0, max(-revealWidth, translation))
                } else {
                    state = max(-revealWidth - offset, min(-offset, translation))
                }
            }
            .onEnded { value in
                let total = offset + value.translation.width
                offset = total < -revealWidth / 2 ? -revealWidth : 0
            }
    }

    private func close() {
        offset = 0
    }
}
