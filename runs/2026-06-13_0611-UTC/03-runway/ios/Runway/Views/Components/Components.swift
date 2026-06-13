import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.surface))
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 46, weight: .light))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(title).font(Theme.num(22)).foregroundStyle(Theme.ink)
            Text(message).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent)).foregroundStyle(.white)
                }.padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 50)
    }
}

struct CategoryBadge: View {
    let category: String
    let kind: FlowKind
    var size: CGFloat = 38
    var body: some View {
        Image(systemName: CategoryCatalog.icon(for: category))
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(kind == .income ? Theme.accent : Theme.inkSoft)
            .frame(width: size, height: size)
            .background(Circle().fill(kind == .income ? Theme.accent.opacity(0.15) : Theme.surfaceAlt))
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 12, weight: .bold)).tracking(0.8)
            .foregroundStyle(Theme.inkFaint)
    }
}
