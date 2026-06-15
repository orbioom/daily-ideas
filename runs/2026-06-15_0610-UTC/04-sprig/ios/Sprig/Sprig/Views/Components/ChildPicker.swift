import SwiftUI

/// A horizontal selector of children used at the top of the Growth/Milestones/Vaccines tabs.
struct ChildPicker: View {
    let children: [Child]
    @Binding var selectedID: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(children) { child in
                    chip(child)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func chip(_ child: Child) -> some View {
        let isSelected = child.id.uuidString == selectedID
        let color = ChildColors.color(hex: child.colorHex)
        return Button {
            selectedID = child.id.uuidString
        } label: {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 12, height: 12)
                Text(child.displayName)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(isSelected ? .white : Theme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule().fill(isSelected ? Theme.accent : Theme.surface)
            )
            .overlay(
                Capsule().strokeBorder(Theme.hairline, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Resolve the active child from a list and a persisted selection id, falling back to the first.
enum ActiveChild {
    static func resolve(from children: [Child], selectedID: String) -> Child? {
        if let match = children.first(where: { $0.id.uuidString == selectedID }) {
            return match
        }
        return children.first
    }
}
